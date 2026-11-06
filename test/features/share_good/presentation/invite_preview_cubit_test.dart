import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/share_good/application/active_invite_sessions.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/domain/repositories/share_good_repository.dart';
import 'package:talia_quran/features/share_good/domain/services/invite_target_labeler.dart';
import 'package:talia_quran/features/share_good/presentation/cubits/invite_preview_cubit.dart';

class FakeQuran implements QuranRepository {
  FakeQuran([this.detail]);

  final SurahDetail? detail;

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async =>
      detail == null ? const Left(NotFoundFailure()) : Right(detail!);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeShare implements ShareGoodRepository {
  FakeShare(this.session);
  InviteSession session;
  ShareGoodFailure? failure;
  int resolves = 0;
  final calls = <InviteParticipationStatus>[];
  @override
  Future<Either<ShareGoodFailure, InviteSession>> resolve(String token) async {
    resolves++;
    return failure == null ? Right(session) : Left(failure!);
  }

  @override
  Future<Either<ShareGoodFailure, InviteSession>> advance(
    String token,
    InviteParticipationStatus status,
  ) async {
    calls.add(status);
    session = InviteSession(
      token: token,
      snapshot: session.snapshot,
      serverStatus: status,
    );
    return Right(session);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  late ShareGoodLocalStore store;
  late ActiveInviteSessions active;
  late FakeShare repo;
  InviteSession session({
    InviteLifecycleStatus lifecycle = InviteLifecycleStatus.active,
    InviteParticipationStatus? status,
    InviteActivityTarget target = const QuranPageInviteTarget(18),
  }) => InviteSession(
    token: token,
    snapshot: ResolvedInvite(
      token: token,
      target: target,
      moment: InviteMoment.beforeActivity,
      mode: InviteMode.personal,
      inviter: const InviterIdentity(mode: InviteIdentityMode.anonymous),
      status: lifecycle,
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    ),
    serverStatus: status,
  );
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    store = ShareGoodLocalStore(
      const FlutterSecureStorage(),
      await SharedPreferences.getInstance(),
    );
    active = ActiveInviteSessions(store);
    repo = FakeShare(session());
  });
  InvitePreviewCubit cubit({bool child = false, SurahDetail? detail}) =>
      InvitePreviewCubit(
        repository: repo,
        labeler: InviteTargetLabeler(FakeQuran(detail)),
        activeSessions: active,
        isChild: () async => child,
        cachedSession: store.session,
        acknowledgeIncoming: store.acknowledgePendingIncomingToken,
      );
  test('opens once, starts and activates', () async {
    final c = cubit();
    await c.load(token);
    await c.load(token);
    expect(c.state, isA<InvitePreviewReady>());
    expect(repo.calls, [InviteParticipationStatus.opened]);
    expect(await c.startActivity(), '/quran/page/18');
    expect(active.forTarget(const QuranPageInviteTarget(18)), isNotNull);
    await c.close();
    await active.dispose();
  });
  test(
    'only an accepted preview acknowledges the matching pending invite',
    () async {
      final c = cubit();
      await store.setPendingIncomingToken(token);
      expect(await store.pendingIncomingToken(), token);
      await c.load(token);
      expect(await store.pendingIncomingToken(), isNull);

      final newer = 'b' * 43;
      await store.setPendingIncomingToken(newer);
      await c.load(token);
      expect(await store.pendingIncomingToken(), newer);
      await c.close();
      await active.dispose();
    },
  );
  test('child and invalid token never resolve', () async {
    final c = cubit(child: true);
    await c.load(token);
    expect(c.state, isA<InvitePreviewKidsBlocked>());
    await c.load('invalid');
    expect(c.state, isA<InvitePreviewInvalid>());
    expect(repo.resolves, 0);
    expect(repo.calls, isEmpty);
    await c.close();
    await active.dispose();
  });
  test('expired allows fresh reading without participation', () async {
    repo.session = session(lifecycle: InviteLifecycleStatus.expired);
    final c = cubit();
    await c.load(token);
    expect(c.state, isA<InvitePreviewExpired>());
    expect(c.startFresh(), '/quran/page/18');
    expect(repo.calls, isEmpty);
    await c.close();
    await active.dispose();
  });
  test('restores a synced started session without pending status', () async {
    await store.saveSession(session(status: InviteParticipationStatus.started));
    await active.restore();
    expect(active.forTarget(const QuranPageInviteTarget(18)), isNotNull);
    await active.dispose();
  });
  test(
    'unavailable surah uses safe hub and records no participation',
    () async {
      repo.session = session(target: const QuranSurahInviteTarget(18));
      final c = cubit();
      await c.load(token);
      expect(c.state, isA<InvitePreviewUnavailable>());
      expect(c.startFresh(), '/');
      expect(repo.calls, isEmpty);
      await c.close();
      await active.dispose();
    },
  );
  test('starting a surah invite opens the exact surah route', () async {
    const target = QuranSurahInviteTarget(18);
    repo.session = session(target: target);
    final c = cubit(
      detail: const SurahDetail(
        surah: Surah(
          id: 18,
          nameAr: 'الكهف',
          nameEn: 'Al-Kahf',
          ayahCount: 1,
          juz: 15,
          type: 'meccan',
          page: 293,
        ),
        ayahs: [
          Ayah(number: 1, surahId: 18, text: '', numberInSurah: 1, page: 293),
        ],
      ),
    );
    await c.load(token);
    expect(await c.startActivity(), '/quran/surah/18');
    expect(active.forTarget(target), isNotNull);
    await c.close();
    await active.dispose();
  });
  test(
    'offline is retained and restoration excludes completed sessions',
    () async {
      repo.failure = ShareGoodFailure.network;
      await store.setPendingIncomingToken(token);
      final c = cubit();
      await c.load(token);
      expect(c.state, isA<InvitePreviewOffline>());
      expect(await store.pendingIncomingToken(), token);
      await store.saveSession(
        session(status: InviteParticipationStatus.completedPrivate),
      );
      await active.restore();
      expect(active.forTarget(const QuranPageInviteTarget(18)), isNull);
      await c.close();
      await active.dispose();
    },
  );
}
