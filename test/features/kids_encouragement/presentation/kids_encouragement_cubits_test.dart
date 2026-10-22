import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/kids_encouragement/domain/entities/kids_encouragement.dart';
import 'package:talia_quran/features/kids_encouragement/domain/repositories/kids_encouragement_repository.dart';
import 'package:talia_quran/features/kids_encouragement/presentation/cubits/child_encouragement_inbox_cubit.dart';
import 'package:talia_quran/features/kids_encouragement/presentation/cubits/parent_encouragement_composer_cubit.dart';

void main() {
  group('ParentEncouragementComposerCubit', () {
    late SharedPreferences prefs;
    late AccountDataBarrier barrier;
    late _Owner owner;
    late StreamController<void> changes;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      owner = _Owner('parent-a');
      barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      changes = StreamController<void>.broadcast();
    });

    test(
      'keeps one request id while retrying the same fixed payload',
      () async {
        final repository = _Repository()..sendError = StateError('offline');
        var ids = 0;
        final cubit = ParentEncouragementComposerCubit(
          repository: repository,
          barrier: barrier,
          owner: owner,
          accountChanges: changes.stream,
          newRequestId: () =>
              '00000000-0000-4000-8000-${(++ids).toString().padLeft(12, '0')}',
        );
        cubit.selectMessage(KidsEncouragementMessage.keepGoing);
        await cubit.send('child-a');
        cubit.selectMessage(KidsEncouragementMessage.keepGoing);
        cubit.selectSticker(KidsEncouragementSticker.starReward);
        await cubit.retry('child-a');

        expect(repository.requests, hasLength(2));
        expect(
          repository.requests.map((request) => request.requestId).toSet(),
          hasLength(1),
        );
        expect(cubit.state.failed, isTrue);
        await cubit.close();
      },
    );

    test('a changed choice receives a new request id', () async {
      final repository = _Repository();
      var ids = 0;
      final cubit = ParentEncouragementComposerCubit(
        repository: repository,
        barrier: barrier,
        owner: owner,
        accountChanges: changes.stream,
        newRequestId: () =>
            '00000000-0000-4000-8000-${(++ids).toString().padLeft(12, '0')}',
      );
      await cubit.send('child-a');
      cubit.selectSticker(KidsEncouragementSticker.taliaEncourage);
      await cubit.send('child-a');

      expect(
        repository.requests.map((request) => request.requestId).toSet(),
        hasLength(2),
      );
      await cubit.close();
    });

    test('account change clears a late parent send result', () async {
      final release = Completer<KidsEncouragementSendResult>();
      final repository = _Repository()..sendGate = release.future;
      final cubit = ParentEncouragementComposerCubit(
        repository: repository,
        barrier: barrier,
        owner: owner,
        accountChanges: changes.stream,
        newRequestId: () => '00000000-0000-4000-8000-000000000001',
      );
      final sending = cubit.send('child-a');
      changes.add(null);
      release.complete(KidsEncouragementSendSuccess(_encouragement(1)));
      await sending;
      expect(cubit.state.sent, isFalse);
      expect(cubit.state.isSending, isFalse);
      await cubit.close();
    });

    test('the server daily limit produces the quota state', () async {
      final repository = _Repository()
        ..sendError = StateError('Encouragement daily limit reached');
      final cubit = ParentEncouragementComposerCubit(
        repository: repository,
        barrier: barrier,
        owner: owner,
        accountChanges: changes.stream,
        newRequestId: () => '00000000-0000-4000-8000-000000000001',
      );
      await cubit.send('child-a');
      expect(cubit.state.quotaReached, isTrue);
      await cubit.close();
    });
  });

  group('ChildEncouragementInboxCubit', () {
    late SharedPreferences prefs;
    late AccountDataBarrier barrier;
    late _Owner owner;
    late StreamController<void> changes;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      owner = _Owner('child-a');
      barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      changes = StreamController<void>.broadcast();
    });

    test(
      'does not acknowledge on load; dismiss queues and suppresses offline rows',
      () async {
        final repository = _Repository()
          ..rows = [_encouragement(1), _encouragement(2)]
          ..markError = StateError('offline');
        final cubit = ChildEncouragementInboxCubit(
          repository: repository,
          owner: owner,
          barrier: barrier,
          accountChanges: changes.stream,
        );
        await cubit.load();
        expect(cubit.state.pending.map((row) => row.id), [1, 2]);
        expect(repository.markRequests, isEmpty);

        await cubit.dismiss(1);
        expect(repository.markRequests, [
          [1],
        ]);
        expect(cubit.state.pending.map((row) => row.id), [2]);
        repository.pending = [1];
        await cubit.load();
        expect(cubit.state.pending.map((row) => row.id), [2]);
        await cubit.close();
      },
    );

    test(
      'account change clears rows and stale load cannot repopulate them',
      () async {
        final release = Completer<void>();
        final repository = _Repository()
          ..rows = [_encouragement(1)]
          ..refreshGate = release.future;
        final cubit = ChildEncouragementInboxCubit(
          repository: repository,
          owner: owner,
          barrier: barrier,
          accountChanges: changes.stream,
        );
        final load = cubit.load();
        changes.add(null);
        release.complete();
        await load;
        expect(cubit.state.pending, isEmpty);
        await cubit.close();
      },
    );

    test(
      'blocked account load and dismiss do not escape or keep private rows',
      () async {
        final repository = _Repository()..rows = [_encouragement(1)];
        final cubit = ChildEncouragementInboxCubit(
          repository: repository,
          owner: owner,
          barrier: barrier,
          accountChanges: barrier.changes,
        );
        await cubit.load();
        barrier.invalidate();
        await cubit.load();
        await cubit.dismiss(1);
        expect(cubit.state.pending, isEmpty);
        expect(repository.markRequests, isEmpty);
        await cubit.close();
      },
    );

    test(
      'late acknowledgement failure cannot affect another account',
      () async {
        final gate = Completer<int>();
        final repository = _Repository()..retryGate = gate.future;
        final cubit = ChildEncouragementInboxCubit(
          repository: repository,
          owner: owner,
          barrier: barrier,
          accountChanges: barrier.changes,
        );
        final retry = cubit.retryAcknowledgements();
        barrier.invalidate();
        gate.completeError(StateError('offline'));
        await retry;
        expect(cubit.state.failed, isFalse);
        expect(cubit.state.pending, isEmpty);
        await cubit.close();
      },
    );
  });
}

KidsEncouragement _encouragement(int id) => KidsEncouragement(
  id: id,
  parentUserId: 'parent-a',
  childUserId: 'child-a',
  message: KidsEncouragementMessage.proud,
  sticker: KidsEncouragementSticker.starReward,
  createdAt: DateTime.utc(2026, 10, 21),
  seenAt: null,
  clientRequestId: '00000000-0000-4000-8000-000000000001',
);

final class _Request {
  const _Request(this.requestId);
  final String requestId;
}

final class _Repository implements KidsEncouragementRepository {
  final requests = <_Request>[];
  final markRequests = <List<int>>[];
  List<KidsEncouragement> rows = [];
  List<int> pending = [];
  Object? sendError;
  Object? markError;
  Future<void>? refreshGate;
  Future<KidsEncouragementSendResult>? sendGate;
  Future<int>? retryGate;

  @override
  List<KidsEncouragement> cached({required String childUserId}) => rows;
  @override
  Future<List<KidsEncouragement>> refresh({required String childUserId}) async {
    await refreshGate;
    return rows;
  }

  @override
  Future<KidsEncouragementSendResult> send({
    required String childUserId,
    required KidsEncouragementMessage message,
    required KidsEncouragementSticker sticker,
    required String clientRequestId,
  }) async {
    requests.add(_Request(clientRequestId));
    if (sendGate != null) return sendGate!;
    if (sendError != null) throw sendError!;
    return KidsEncouragementSendSuccess(_encouragement(1));
  }

  @override
  Future<int> markSeen(List<int> ids) async {
    markRequests.add(ids);
    if (markError != null) throw markError!;
    return ids.length;
  }

  @override
  Future<List<int>> pendingSeenIds() async => pending;
  @override
  Future<int> retryPendingSeen() async =>
      retryGate == null ? pending.length : await retryGate!;
}

final class _Owner implements RecordOwnerProvider {
  _Owner(this.currentOwnerId);
  @override
  String currentOwnerId;
  @override
  bool get isSignedIn => true;
}
