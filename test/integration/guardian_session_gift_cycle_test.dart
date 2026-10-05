import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/security/parent_pin_secure_store.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/memorization_plus/application/guardian_session_controller.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/parent_reward_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_treasures_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

/// One child device, one guardian: the guardian opens a short session with
/// the PIN, handles the gift, and the child sees each step. Real repository,
/// use cases, cubits, session controller and route guard; only the Quran
/// repository is faked.
void main() {
  final getIt = GetIt.instance;
  late MemorizationPlusRepositoryImpl repository;
  late GuardianSessionController session;
  late DateTime now;
  const pin = '2468';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = MemorizationPlusRepositoryImpl(
      MemorizationPlusLocalDatasourceImpl(prefs),
      _EmptyQuranRepository(),
      _ZeroStreakReader(),
      ProgressEventsBus(),
      prefs,
      parentPinStore: _MemoryParentPinStore(),
    );
    now = DateTime(2026, 10, 5, 18);
    session = GuardianSessionController(clock: () => now);
    getIt
      ..registerSingleton<MemorizationPlusRepository>(repository)
      ..registerSingleton<GuardianSessionController>(session);

    final child = await repository.selectMemorizationPath(
      MemorizationPath.child,
    );
    expect(child.getOrElse(() => throw StateError('$child')).isChild, isTrue);
    expect((await repository.setParentPin(pin)).isRight(), isTrue);
  });

  tearDown(() async {
    session.dispose();
    await getIt.reset();
  });

  FamilyDashboardCubit guardianDashboard() => FamilyDashboardCubit(
    ParentAccessUsecase(repository),
    ParentRemoteLinkUsecase(repository),
    GetFamilyDashboardUsecase(repository),
    rewards: ParentRewardUsecase(repository),
    guardianSessionActive: () => session.isActive,
  );

  KidsTreasuresCubit childTreasures() => KidsTreasuresCubit(
    repository,
    _EmptyQuranRepository(),
    certificatesLoader: () => const [],
    rewards: ParentRewardUsecase(repository),
  );

  Future<String?> dashboardRedirect() async {
    final auth = AppRouter.redirectForAuth(
      const AuthUnauthenticated(),
      AppRoutes.familyDashboard,
      guardianSessionActive: MemorizationRouteGuard.guardianSessionActive(),
    );
    return auth ?? await MemorizationRouteGuard.parentDashboardRedirect();
  }

  ParentReward deviceGift(FamilyDashboardState state) {
    final loaded = state as FamilyDashboardLoaded;
    return loaded.dashboard.children.single.localData!.rewards.single;
  }

  Future<ParentReward> childSees() async {
    final cubit = childTreasures();
    try {
      await cubit.load();
      return (cubit.state as KidsTreasuresLoaded).rewards.single;
    } finally {
      await cubit.close();
    }
  }

  test(
    'a child cannot reach the dashboard without a guardian session',
    () async {
      expect(await dashboardRedirect(), AppRoutes.login);

      final dashboard = guardianDashboard();
      addTearDown(dashboard.close);
      await dashboard.load();

      expect(dashboard.state, isA<FamilyDashboardLocked>());
    },
  );

  test('the full gift cycle across guardian sessions', () async {
    // Guardian visit 1: PIN, add a gift, open it early.
    session.start(returnLocation: AppRoutes.memorizationPlusKidsHome);
    expect(await dashboardRedirect(), isNull);
    final visit1 = guardianDashboard();
    await visit1.load();
    expect(visit1.state, isA<FamilyDashboardLoaded>());
    expect(
      (visit1.state as FamilyDashboardLoaded).dashboard.children.single.isLocal,
      isTrue,
    );

    await visit1.addReward('نزهة');
    final giftId = deviceGift(visit1.state).id;
    expect(deviceGift(visit1.state).status, ParentRewardStatus.locked);
    await visit1.unlockReward(giftId);
    expect(deviceGift(visit1.state).status, ParentRewardStatus.unlocked);
    await visit1.close();

    // Back to the child: the dashboard is closed again.
    session.end();
    expect(await dashboardRedirect(), AppRoutes.login);
    expect(MemorizationRouteGuard.guardianSessionActive(), isFalse);

    // The child asks for the gift; it is not handed over yet.
    final treasures = childTreasures();
    await treasures.load();
    expect(
      (treasures.state as KidsTreasuresLoaded).rewards.single.status,
      ParentRewardStatus.unlocked,
    );
    await treasures.requestReward(giftId);
    final requested = (treasures.state as KidsTreasuresLoaded).rewards.single;
    expect(requested.status, ParentRewardStatus.requested);
    expect(requested.claimedAt, isNull);
    await treasures.close();

    // Guardian visit 2: an idle session expires before the approval.
    session.start(returnLocation: AppRoutes.memorizationPlusKidsHome);
    now = now.add(session.idleTimeout);
    expect(session.isActive, isFalse);
    expect(await dashboardRedirect(), AppRoutes.login);
    final expired = guardianDashboard();
    addTearDown(expired.close);
    await expired.load();
    expect(expired.state, isA<FamilyDashboardLocked>());

    // The PIN reopens it and the guardian confirms the hand-over.
    await expired.unlock(pin);
    expect(deviceGift(expired.state).status, ParentRewardStatus.requested);
    await expired.approveReward(giftId);
    expect(deviceGift(expired.state).status, ParentRewardStatus.claimed);

    final received = await childSees();
    expect(received.status, ParentRewardStatus.claimed);
    expect(received.requestedAt, requested.requestedAt);
    expect(received.claimedAt, isNotNull);
  });

  test('the guardian cannot approve before the child asks', () async {
    session.start(returnLocation: AppRoutes.memorizationPlusKidsHome);
    final dashboard = guardianDashboard();
    addTearDown(dashboard.close);
    await dashboard.load();
    await dashboard.addReward('كتاب');
    final giftId = deviceGift(dashboard.state).id;
    await dashboard.unlockReward(giftId);

    await dashboard.approveReward(giftId);

    expect(deviceGift(dashboard.state).status, ParentRewardStatus.unlocked);
    expect((dashboard.state as FamilyDashboardLoaded).feedback, isNotNull);
    expect((await childSees()).status, ParentRewardStatus.unlocked);
  });

  test('a long stay in the background ends the session', () async {
    session.start(returnLocation: AppRoutes.memorizationPlusKidsHome);
    session.appPaused();
    now = now.add(session.backgroundGrace + const Duration(seconds: 1));
    session.appResumed();

    expect(session.isActive, isFalse);
    expect(await dashboardRedirect(), AppRoutes.login);
  });
}

class _MemoryParentPinStore implements ParentPinSecureStore {
  final _verifiers = <String, String>{};
  final _blockedUntil = <String, DateTime>{};
  final _failures = <String, int>{};

  @override
  Future<void> clearVerifier(String ownerId) async =>
      _verifiers.remove(ownerId);

  @override
  Future<DateTime?> readBlockedUntil(String ownerId) async =>
      _blockedUntil[ownerId];

  @override
  Future<int> readFailureCount(String ownerId) async => _failures[ownerId] ?? 0;

  @override
  Future<String?> readVerifier(String ownerId) async => _verifiers[ownerId];

  @override
  Future<void> writeBlockedUntil(String ownerId, DateTime? blockedUntil) async {
    if (blockedUntil == null) {
      _blockedUntil.remove(ownerId);
    } else {
      _blockedUntil[ownerId] = blockedUntil;
    }
  }

  @override
  Future<void> writeFailureCount(String ownerId, int count) async =>
      _failures[ownerId] = count;

  @override
  Future<void> writeVerifier(String ownerId, String verifier) async =>
      _verifiers[ownerId] = verifier;
}

class _ZeroStreakReader implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _EmptyQuranRepository implements QuranRepository {
  @override
  Future<Either<Failure, List<Surah>>> getSurahs() async => const Right([]);

  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) =>
      throw UnimplementedError();
}
