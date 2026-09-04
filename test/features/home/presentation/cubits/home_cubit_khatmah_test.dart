import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';

import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/journey/unified_journey_engine.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/home/domain/usecases/get_activity_heatmap_usecase.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';

import 'home_cubit_test.mocks.dart';

class FakeGetActiveKhatmahUsecase extends Fake
    implements GetActiveKhatmahUsecase {
  KhatmahPlan? planToReturn;
  int callCount = 0;
  Object? error;
  Stream<void>? changeEvents;
  Future<KhatmahPlan?>? pending;
  @override
  Stream<void>? get changes => changeEvents;

  @override
  Future<KhatmahPlan?> call() async {
    callCount++;
    if (error != null) throw error!;
    return pending ?? planToReturn;
  }
}

class _FakeXpService extends Fake implements XpService {
  @override
  Future<int> getTotalXp() async => 100;
}

void main() {
  HomeCubit? cubit;
  late MockGetProgressUsecase mockGetProgress;
  late MockGetQuranPageUsecase mockGetQuranPage;
  late MockGetCustomPlanUsecase mockGetCustomPlan;
  late MockMemorizationPlusRepository mockMemRepo;
  late MockAppSessionService mockSessionService;
  late MockGetActivityHeatmapUsecase mockGetHeatmap;
  late MockMemorizationPathResolver mockPathResolver;
  late MockGetSmartCoachRecommendationUsecase mockGetCoachRecommendation;
  late UnifiedJourneyEngine journeyEngine;
  late MockSharedPreferences mockPrefs;
  late ProgressEventsBus progressEvents;
  late _FakeXpService xpService;
  late FakeGetActiveKhatmahUsecase fakeGetActiveKhatmah;

  final testPlan = KhatmahPlan(
    id: 'test-khatmah-1',
    title: 'Ramadan Khatmah',
    startPage: 1,
    completedPages: {for (var page = 1; page <= 30; page++) page},
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
    status: KhatmahStatus.active,
    dedication: const KhatmahDedication(
      isDedicated: true,
      recipientName: 'Mother',
      relationship: 'Mother',
      condition: DedicationCondition.deceased,
    ),
  );

  setUp(() {
    mockGetProgress = MockGetProgressUsecase();
    mockGetQuranPage = MockGetQuranPageUsecase();
    mockGetCustomPlan = MockGetCustomPlanUsecase();
    mockMemRepo = MockMemorizationPlusRepository();
    mockSessionService = MockAppSessionService();
    mockGetHeatmap = MockGetActivityHeatmapUsecase();
    mockPathResolver = MockMemorizationPathResolver();
    mockGetCoachRecommendation = MockGetSmartCoachRecommendationUsecase();
    journeyEngine = const UnifiedJourneyEngine();
    mockPrefs = MockSharedPreferences();
    progressEvents = ProgressEventsBus();
    xpService = _FakeXpService();
    fakeGetActiveKhatmah = FakeGetActiveKhatmahUsecase();

    when(mockPathResolver.changes).thenAnswer((_) => const Stream.empty());
    when(mockPrefs.getString(any)).thenReturn(null);
    when(mockPrefs.getBool('unified_journey_enabled')).thenReturn(true);

    when(mockGetProgress.call()).thenAnswer(
      (_) async => const Right(
        OverallProgress(
          memorizedAyahs: 10,
          totalAyahs: 100,
          memorizedSurahs: 1,
          totalSurahs: 114,
          memorizedJuz: 0,
          totalJuz: 30,
          readAyahs: 50,
          readSurahs: 2,
          readJuz: 1,
          streakDays: 5,
          lastActiveDate: null,
          achievements: [],
          readPagesCount: 10,
          totalQuranPages: 604,
          learningAyahs: 5,
          reviewAyahs: 5,
        ),
      ),
    );

    when(
      mockGetQuranPage.call(any),
    ).thenAnswer((_) async => const Left(CacheFailure('no cache')));
    when(mockGetCustomPlan.call()).thenAnswer((_) async => const Right(null));
    when(mockGetHeatmap.call()).thenAnswer(
      (_) async =>
          ActivityHeatmapData(countsByDay: const {}, startDate: DateTime.now()),
    );
    when(
      mockGetCoachRecommendation.call(),
    ).thenAnswer((_) async => const Right(null));
    when(mockSessionService.getLastRestorableLocation()).thenReturn(null);

    when(
      mockMemRepo.getMemorizationProfile(),
    ).thenAnswer((_) async => Right(MemorizationProfile.empty()));
    when(
      mockMemRepo.getAllReviewRecords(),
    ).thenAnswer((_) async => const Right([]));
  });

  tearDown(() async {
    await cubit?.close();
    progressEvents.dispose();
  });

  test(
    'retained Home immediately hides invalidated Khatmah and retry recovers',
    () async {
      SharedPreferences.setMockInitialValues({});
      final barrier = AccountDataBarrier.forPreferences(
        await SharedPreferences.getInstance(),
      );
      fakeGetActiveKhatmah.changeEvents = barrier.changes;
      fakeGetActiveKhatmah.planToReturn = testPlan.copyWith(
        authority: barrier.capture(),
      );
      cubit = HomeCubit(
        mockGetProgress,
        mockGetQuranPage,
        mockGetCustomPlan,
        mockMemRepo,
        mockSessionService,
        mockGetHeatmap,
        mockPathResolver,
        mockGetCoachRecommendation,
        journeyEngine,
        mockPrefs,
        progressEvents,
        xpService,
        fakeGetActiveKhatmah,
      );
      await cubit!.load();
      fakeGetActiveKhatmah.error = const AccountDataUnavailableException();
      barrier.invalidate();
      await Future<void>.delayed(Duration.zero);
      expect((cubit!.state as HomeLoaded).activeKhatmah, isNull);
      expect((cubit!.state as HomeLoaded).khatmahError, isNotNull);
      fakeGetActiveKhatmah.error = null;
      fakeGetActiveKhatmah.planToReturn = testPlan.copyWith(id: 'new-owner');
      await cubit!.load();
      expect((cubit!.state as HomeLoaded).activeKhatmah!.id, 'new-owner');
      expect((cubit!.state as HomeLoaded).khatmahError, isNull);
    },
  );
  test('pending Home load cannot restore invalidated old Khatmah', () async {
    SharedPreferences.setMockInitialValues({});
    final barrier = AccountDataBarrier.forPreferences(
      await SharedPreferences.getInstance(),
    );
    final old = testPlan.copyWith(authority: barrier.capture());
    final pending = Completer<KhatmahPlan?>();
    fakeGetActiveKhatmah.pending = pending.future;
    cubit = HomeCubit(
      mockGetProgress,
      mockGetQuranPage,
      mockGetCustomPlan,
      mockMemRepo,
      mockSessionService,
      mockGetHeatmap,
      mockPathResolver,
      mockGetCoachRecommendation,
      journeyEngine,
      mockPrefs,
      progressEvents,
      xpService,
      fakeGetActiveKhatmah,
    );
    final loading = cubit!.load();
    barrier.invalidate();
    pending.complete(old);
    await loading;
    expect((cubit!.state as HomeLoaded).activeKhatmah, isNull);
    expect((cubit!.state as HomeLoaded).khatmahError, isNotNull);
  });

  test(
    'corrupt optional Khatmah keeps Home usable and recovers on retry',
    () async {
      fakeGetActiveKhatmah.error = const FormatException('corrupt Khatmah');
      cubit = HomeCubit(
        mockGetProgress,
        mockGetQuranPage,
        mockGetCustomPlan,
        mockMemRepo,
        mockSessionService,
        mockGetHeatmap,
        mockPathResolver,
        mockGetCoachRecommendation,
        journeyEngine,
        mockPrefs,
        progressEvents,
        xpService,
        fakeGetActiveKhatmah,
      );
      final failure = await cubit!.load().then<Object?>(
        (_) => null,
        onError: (Object e) => e,
      );
      expect(failure, isNull);
      expect(cubit!.state, isA<HomeLoaded>());
      fakeGetActiveKhatmah.error = null;
      fakeGetActiveKhatmah.planToReturn = testPlan;
      await cubit!.load();
      expect((cubit!.state as HomeLoaded).activeKhatmah, testPlan);
    },
  );

  test(
    'load() queries GetActiveKhatmahUsecase and emits activeKhatmah in HomeLoaded',
    () async {
      fakeGetActiveKhatmah.planToReturn = testPlan;

      cubit = HomeCubit(
        mockGetProgress,
        mockGetQuranPage,
        mockGetCustomPlan,
        mockMemRepo,
        mockSessionService,
        mockGetHeatmap,
        mockPathResolver,
        mockGetCoachRecommendation,
        journeyEngine,
        mockPrefs,
        progressEvents,
        xpService,
        fakeGetActiveKhatmah,
      );

      await cubit!.load();

      expect(cubit!.state, isA<HomeLoaded>());
      final loadedState = cubit!.state as HomeLoaded;
      expect(loadedState.activeKhatmah, equals(testPlan));
      expect(fakeGetActiveKhatmah.callCount, equals(1));
    },
  );

  test(
    'load() emits null activeKhatmah when GetActiveKhatmahUsecase returns null',
    () async {
      fakeGetActiveKhatmah.planToReturn = null;

      cubit = HomeCubit(
        mockGetProgress,
        mockGetQuranPage,
        mockGetCustomPlan,
        mockMemRepo,
        mockSessionService,
        mockGetHeatmap,
        mockPathResolver,
        mockGetCoachRecommendation,
        journeyEngine,
        mockPrefs,
        progressEvents,
        xpService,
        fakeGetActiveKhatmah,
      );

      await cubit!.load();

      expect(cubit!.state, isA<HomeLoaded>());
      final loadedState = cubit!.state as HomeLoaded;
      expect(loadedState.activeKhatmah, isNull);
      expect(fakeGetActiveKhatmah.callCount, equals(1));
    },
  );

  test(
    'load() surfaces a paused Khatmah distinctly from an immediately readable plan',
    () async {
      fakeGetActiveKhatmah.planToReturn = testPlan.copyWith(
        status: KhatmahStatus.paused,
      );

      cubit = HomeCubit(
        mockGetProgress,
        mockGetQuranPage,
        mockGetCustomPlan,
        mockMemRepo,
        mockSessionService,
        mockGetHeatmap,
        mockPathResolver,
        mockGetCoachRecommendation,
        journeyEngine,
        mockPrefs,
        progressEvents,
        xpService,
        fakeGetActiveKhatmah,
      );

      await cubit!.load();

      final loadedState = cubit!.state as HomeLoaded;
      expect(loadedState.khatmahPlanState, HomeKhatmahPlanState.paused);
      expect(loadedState.canContinueKhatmahReading, isFalse);
    },
  );

  test(
    'HomeCubit constructor works without GetActiveKhatmahUsecase (optional)',
    () async {
      cubit = HomeCubit(
        mockGetProgress,
        mockGetQuranPage,
        mockGetCustomPlan,
        mockMemRepo,
        mockSessionService,
        mockGetHeatmap,
        mockPathResolver,
        mockGetCoachRecommendation,
        journeyEngine,
        mockPrefs,
        progressEvents,
        xpService,
      );

      await cubit!.load();

      expect(cubit!.state, isA<HomeLoaded>());
      final loadedState = cubit!.state as HomeLoaded;
      expect(loadedState.activeKhatmah, isNull);
    },
  );

  test('completed Khatmah is terminal rather than readable on Home', () async {
    fakeGetActiveKhatmah.planToReturn = testPlan.copyWith(
      status: KhatmahStatus.completed,
    );
    cubit = HomeCubit(
      mockGetProgress,
      mockGetQuranPage,
      mockGetCustomPlan,
      mockMemRepo,
      mockSessionService,
      mockGetHeatmap,
      mockPathResolver,
      mockGetCoachRecommendation,
      journeyEngine,
      mockPrefs,
      progressEvents,
      xpService,
      fakeGetActiveKhatmah,
    );
    await cubit!.load();
    final state = cubit!.state as HomeLoaded;
    expect(state.khatmahPlanState, HomeKhatmahPlanState.none);
    expect(state.canContinueKhatmahReading, isFalse);
  });

  test('HomeLoaded copyWith updates activeKhatmah', () {
    final initialState = HomeLoaded(
      progress: const OverallProgress(
        memorizedAyahs: 0,
        totalAyahs: 100,
        memorizedSurahs: 0,
        totalSurahs: 114,
        memorizedJuz: 0,
        totalJuz: 30,
        readAyahs: 0,
        readSurahs: 0,
        readJuz: 0,
        streakDays: 0,
        lastActiveDate: null,
        achievements: [],
        readPagesCount: 0,
        totalQuranPages: 604,
        learningAyahs: 0,
        reviewAyahs: 0,
      ),
      greeting: 'morning',
      activityStartDate: DateTime(2026, 1, 1),
    );

    expect(initialState.activeKhatmah, isNull);

    final updatedState = initialState.copyWith(activeKhatmah: testPlan);
    expect(updatedState.activeKhatmah, equals(testPlan));

    final clearedState = updatedState.copyWith(activeKhatmah: null);
    expect(clearedState.activeKhatmah, isNull);
  });
}
