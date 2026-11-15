import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/share_good_config.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_remote_datasource.dart';
import 'package:talia_quran/features/share_good/data/repositories/share_good_repository_impl.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';

class FakeRemote extends ShareGoodRemoteDatasource {
  FakeRemote() : super(null);
  final calls = <String>[];
  final params = <Map<String, dynamic>?>[];
  ShareGoodFailure? failure;
  @override
  Future<Map<String, dynamic>> call(
    String function, [
    Map<String, dynamic>? values,
  ]) async {
    calls.add(function);
    params.add(values);
    if (failure != null) throw ShareGoodRemoteException(failure!);
    if (function == 'advance_share_good_participation_v1') {
      return {'status': values!['p_status']};
    }
    return {
      'target': {'v': 1, 'type': 'quran_page', 'page': 1},
      'moment': 'before',
      'mode': 'personal',
      'inviter': {'mode': 'anonymous'},
      'status': 'active',
      'expires_at': '2027-01-01T00:00:00Z',
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ShareGoodLocalStore local;
  late FakeRemote remote;
  late ShareGoodRepositoryImpl repo;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    local = ShareGoodLocalStore(
      const FlutterSecureStorage(),
      await SharedPreferences.getInstance(),
    );
    remote = FakeRemote();
    repo = ShareGoodRepositoryImpl(
      remote: remote,
      local: local,
      links: const ShareGoodLinks('example.com'),
      timezone: () async => 'Africa/Cairo',
      clock: () => DateTime.utc(2026, 11, 6),
    );
  });
  test('unconfigured remote reports unavailable', () async {
    expect(
      () => ShareGoodRemoteDatasource(null).call('get_share_good_impact_v1'),
      throwsA(
        isA<ShareGoodRemoteException>().having(
          (e) => e.failure,
          'failure',
          ShareGoodFailure.featureUnavailable,
        ),
      ),
    );
  });
  test('start timestamp survives completion and server refresh', () async {
    const token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    await repo.resolve(token);
    await repo.advance(token, InviteParticipationStatus.started);
    final started = (await local.session(token))!.startedAt;
    expect(started, DateTime.utc(2026, 11, 6));
    await repo.advance(token, InviteParticipationStatus.completedPrivate);
    await repo.resolve(token);
    expect((await local.session(token))!.startedAt, started);
  });
  test('an invalidated account cannot send a queued invite', () async {
    final barrier = AccountDataBarrier.forPreferences(
      await SharedPreferences.getInstance(),
    );
    final started = Completer<void>();
    final timezone = Completer<String>();
    final guarded = ShareGoodRepositoryImpl(
      remote: remote,
      local: local,
      links: const ShareGoodLinks('example.com'),
      timezone: () {
        started.complete();
        return timezone.future;
      },
      accountBarrier: barrier,
    );
    final result = guarded.create(
      const InviteContext(
        target: QuranPageInviteTarget(42),
        moment: InviteMoment.beforeActivity,
        mode: InviteMode.personal,
        identity: InviterIdentity(mode: InviteIdentityMode.anonymous),
      ),
    );
    await started.future;
    barrier.invalidate();
    timezone.complete('Africa/Cairo');
    expect(
      (await result).fold((failure) => failure, (_) => null),
      ShareGoodFailure.authRequired,
    );
    expect(remote.calls, isEmpty);
  });
  test(
    'offline pending replays monotonically and preserves local ID',
    () async {
      final resolved = (await repo.resolve(
        'token',
      )).getOrElse(() => throw StateError('resolve'));
      remote.failure = ShareGoodFailure.network;
      final first = (await repo.advance(
        'token',
        InviteParticipationStatus.started,
      )).getOrElse(() => throw StateError('advance'));
      expect(first.pendingStatus, InviteParticipationStatus.started);
      final completed = (await repo.advance(
        'token',
        InviteParticipationStatus.completedPrivate,
      )).getOrElse(() => throw StateError('advance'));
      expect(
        completed.pendingStatus,
        InviteParticipationStatus.completedPrivate,
      );
      remote.failure = null;
      await repo.replayPending();
      final stored = await local.session('token');
      expect(stored!.serverStatus, InviteParticipationStatus.completedPrivate);
      expect(stored.pendingStatus, isNull);
      expect(stored.localSessionId, resolved.localSessionId);
    },
  );
  test('only network failure uses cached snapshot', () async {
    await repo.resolve('token');
    remote.failure = ShareGoodFailure.network;
    expect((await repo.resolve('token')).isRight(), isTrue);
    expect(
      (await repo.resolve(
        'new',
      )).swap().getOrElse(() => throw StateError('left')),
      ShareGoodFailure.network,
    );
    remote.failure = ShareGoodFailure.expired;
    expect(
      (await repo.resolve(
        'token',
      )).swap().getOrElse(() => throw StateError('left')),
      ShareGoodFailure.expired,
    );
  });
  test('feature and child guards prevent all remote calls', () async {
    final blocked = ShareGoodRepositoryImpl(
      remote: remote,
      local: local,
      links: const ShareGoodLinks('example.com'),
      timezone: () async => 'UTC',
      isAvailable: () => false,
      isChild: () async => true,
    );
    await blocked.resolve('token');
    await blocked.replayPending();
    expect(remote.calls, isEmpty);
  });
  test(
    'permanent rejection clears pending and never returns stale success',
    () async {
      await repo.resolve('token');
      remote.failure = ShareGoodFailure.network;
      await repo.advance('token', InviteParticipationStatus.started);
      remote.failure = ShareGoodFailure.expired;
      final result = await repo.advance(
        'token',
        InviteParticipationStatus.started,
      );
      expect(
        result.swap().getOrElse(() => throw StateError('left')),
        ShareGoodFailure.expired,
      );
      expect((await local.session('token'))!.pendingStatus, isNull);
    },
  );
  test('expired cached snapshot is not active while offline', () async {
    final timed = ShareGoodRepositoryImpl(
      remote: remote,
      local: local,
      links: const ShareGoodLinks('example.com'),
      timezone: () async => 'UTC',
      clock: () => DateTime.utc(2028),
    );
    await timed.resolve('token');
    remote.failure = ShareGoodFailure.network;
    final session = (await timed.resolve(
      'token',
    )).getOrElse(() => throw StateError('resolve'));
    expect(session.snapshot.status, InviteLifecycleStatus.expired);
  });
  test('child guard prevents remote calls even when enabled', () async {
    final blocked = ShareGoodRepositoryImpl(
      remote: remote,
      local: local,
      links: const ShareGoodLinks('example.com'),
      timezone: () async => 'UTC',
      isChild: () async => true,
    );
    await blocked.resolve('token');
    await blocked.replayPending();
    expect(remote.calls, isEmpty);
  });
}
