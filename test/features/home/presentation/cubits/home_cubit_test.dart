import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/core/journey/unified_journey_engine.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/smart_coach_recommendation.dart';
import 'package:talia_quran/core/memorization/usecases/get_smart_coach_recommendation_usecase.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/home/domain/entities/ayah_of_day.dart';
import 'package:talia_quran/features/home/domain/usecases/get_activity_heatmap_usecase.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import 'package:talia_quran/features/home/domain/repositories/activity_feed_repository.dart';
import 'package:talia_quran/features/home/domain/usecases/get_ayah_of_day_usecase.dart';
import 'package:talia_quran/features/home/domain/usecases/get_recent_activity_usecase.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/progress/domain/usecases/get_progress_usecase.dart';
import 'package:talia_quran/features/quran/domain/usecases/get_surahs_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

import 'home_cubit_test.mocks.dart';

class _MockGetAyahOfDay extends Mock implements GetAyahOfDayUsecase {
  @override
  Future<AyahOfDay?> call() => super.noSuchMethod(
    Invocation.method(#call, const []),
    returnValue: Future<AyahOfDay?>.value(),
  ) as Future<AyahOfDay?>;
}

class _MockGetFamilyDashboard extends Mock
    implements GetFamilyDashboardUsecase {
  @override
  Future<Either<Failure, FamilyDashboard>> call() => super.noSuchMethod(
    Invocation.method(#call, const []),
    returnValue: Future<Either<Failure, FamilyDashboard>>.value(
      const Left(CacheFailure('not configured')),
    ),
  ) as Future<Either<Failure, FamilyDashboard>>;
}

@GenerateMocks([
  GetProgressUsecase,
  GetQuranPageUsecase,
  GetCustomPlanUsecase,
  MemorizationPlusRepository,
  AppSessionService,
  GetActivityHeatmapUsecase,
  MemorizationPathResolver,
  GetSmartCoachRecommendationUsecase,
  SharedPreferences,
])
void main() {
  late HomeCubit cubit;
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

  HomeCubit buildCubit({
    GetAyahOfDayUsecase? getAyahOfDay,
    GetFamilyDashboardUsecase? getFamilyDashboard,
    GetRecentActivityUsecase? getRecentActivity,
  }) => HomeCubit.withExtras(
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
    getAyahOfDay: getAyahOfDay,
    getFamilyDashboard: getFamilyDashboard,
    getRecentActivity: getRecentActivity,
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

    when(mockPathResolver.changes).thenAnswer((_) => const Stream.empty());
    when(mockPrefs.getString(any)).thenReturn(null);
    when(mockPrefs.getBool(any)).thenReturn(false);
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
    final defaultRecord = AyahReviewRecord(
      surahId: 1,
      ayahNumber: 1,
      lastReviewedAt: DateTime.now(),
      nextReviewDate: DateTime.now().add(const Duration(days: 10)),
      totalReviews: 1,
      intervalDays: 1,
      easeFactor: 2.5,
      strengthLevel: 5,
      reviewState: ReviewState.review,
      lastRating: PerformanceRating.excellent,
    );
    when(
      mockMemRepo.getAllReviewRecords(),
    ).thenAnswer((_) async => Right([defaultRecord]));

    cubit = buildCubit();
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
    progressEvents.dispose();
  });

  test('Scenario 1: Resume Session emits P1 Action', () async {
    when(
      mockSessionService.getLastRestorableLocation(),
    ).thenReturn('/quran/2/1');

    await cubit.load();
    final state = cubit.state;
    expect(state, isA<HomeLoaded>());

    final loadedState = state as HomeLoaded;
    expect(loadedState.heroAction, isNotNull);
    expect(
      loadedState.heroAction!.priority,
      UnifiedJourneyPriority.p1ActiveSession,
    );
    expect(loadedState.heroAction!.intent, JourneyIntent.resume);
  });

  test('Scenario 2: Critical Learning Alert emits P2 Action', () async {
    final record = AyahReviewRecord(
      surahId: 1,
      ayahNumber: 1,
      lastReviewedAt: DateTime.now().subtract(const Duration(days: 30)),
      nextReviewDate: DateTime.now().subtract(const Duration(days: 10)),
      totalReviews: 1,
      intervalDays: 1,
      easeFactor: 1.0,
      strengthLevel: 0,
      reviewState: ReviewState.learning,
      lastRating: PerformanceRating.average,
      createdByMode: ReviewRecordCreatedByMode.v2Session,
    );
    when(
      mockMemRepo.getAllReviewRecords(),
    ).thenAnswer((_) async => Right([record]));

    await cubit.load();
    final state = cubit.state as HomeLoaded;

    expect(state.heroAction, isNotNull);
    expect(state.heroAction!.priority, UnifiedJourneyPriority.p2CriticalAlert);
    expect(state.heroAction!.intent, JourneyIntent.review);
  });

  test('Scenario 3: Review Backlog emits P3 Action', () async {
    final records = List.generate(
      101,
      (index) => AyahReviewRecord(
        surahId: 1,
        ayahNumber: index + 1,
        lastReviewedAt: DateTime.now().subtract(const Duration(days: 5)),
        nextReviewDate: DateTime.now().subtract(const Duration(days: 1)),
        totalReviews: 3,
        intervalDays: 5,
        easeFactor: 2.5,
        strengthLevel: 3,
        reviewState: ReviewState.relearning,
        lastRating: PerformanceRating.excellent,
        createdByMode: ReviewRecordCreatedByMode.v2Session,
      ),
    );
    when(
      mockMemRepo.getAllReviewRecords(),
    ).thenAnswer((_) async => Right(records));

    await cubit.load();
    final state = cubit.state as HomeLoaded;

    expect(state.heroAction, isNotNull);
    // Note: because dueAyahs > 100 also triggers overloadRisk (priority: high),
    // HomeCubit will prioritize p2CriticalAlert over p3ReviewBacklog.
    expect(state.heroAction!.priority, UnifiedJourneyPriority.p2CriticalAlert);
    expect(state.heroAction!.intent, JourneyIntent.review);
  });

  test('ignores kids rows when evaluating the adult review workload', () async {
    final records = List.generate(
      101,
      (index) => AyahReviewRecord(
        surahId: 1,
        ayahNumber: index + 1,
        lastReviewedAt: DateTime.now().subtract(const Duration(days: 5)),
        nextReviewDate: DateTime.now().subtract(const Duration(days: 1)),
        totalReviews: 3,
        intervalDays: 5,
        easeFactor: 2.5,
        strengthLevel: 3,
        reviewState: ReviewState.relearning,
        lastRating: PerformanceRating.excellent,
        createdByMode: ReviewRecordCreatedByMode.kidsMode,
      ),
    );
    when(
      mockMemRepo.getAllReviewRecords(),
    ).thenAnswer((_) async => Right(records));

    await cubit.load();
    final state = cubit.state as HomeLoaded;

    expect(
      state.heroAction?.priority,
      UnifiedJourneyPriority.p6FreeExploration,
    );
  });

  test('Scenario 4: Smart Coach Recommendation emits P4 Action', () async {
    const coach = SmartCoachRecommendation(
      kind: SmartCoachRecommendationKind.memorizeNewAyahs,
      route: '/some/route',
    );
    when(
      mockGetCoachRecommendation.call(),
    ).thenAnswer((_) async => const Right(coach));

    await cubit.load();
    final state = cubit.state as HomeLoaded;

    expect(state.heroAction, isNotNull);
    expect(state.heroAction!.priority, UnifiedJourneyPriority.p4SmartPlan);
    expect(state.heroAction!.intent, JourneyIntent.memorize);
  });

  test('Scenario 5: Daily Wird emits P5 Action', () async {
    const wirdDetail = QuranPageDetail(pageNumber: 5, surahs: [], ayahs: []);
    when(
      mockGetQuranPage.call(any),
    ).thenAnswer((_) async => const Right(wirdDetail));

    await cubit.load();
    final state = cubit.state as HomeLoaded;

    expect(state.heroAction, isNotNull);
    expect(state.heroAction!.priority, UnifiedJourneyPriority.p5DailyGoal);
    expect(state.heroAction!.intent, JourneyIntent.reading);
  });

  test('Scenario 6: Azkar Goal emits Azkar Intent', () async {
    when(mockPrefs.getString('user_primary_goal')).thenReturn('azkar');

    await cubit.load();
    final state = cubit.state as HomeLoaded;

    expect(state.heroAction, isNotNull);
    expect(state.heroAction!.intent, JourneyIntent.azkar);
  });

  test('Scenario 7: Default Explore emits Explore Intent', () async {
    await cubit.load();
    final state = cubit.state as HomeLoaded;

    expect(state.heroAction, isNotNull);
    expect(state.heroAction!.intent, JourneyIntent.explore);
  });

  test(
    'Scenario 8: Unified Journey Feature Flag Disabled uses legacy branch',
    () async {
      when(mockPrefs.getBool('unified_journey_enabled')).thenReturn(false);

      await cubit.load();
      final state = cubit.state as HomeLoaded;

      expect(state.heroAction, isNull);
    },
  );

  test(
    'xp-only progress event refreshes totalXp without full reload',
    () async {
      var progressLoads = 0;
      when(mockGetProgress.call()).thenAnswer((_) async {
        progressLoads++;
        return const Right(
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
        );
      });

      await cubit.load();
      expect((cubit.state as HomeLoaded).totalXp, 120);
      expect(progressLoads, 1);

      xpService.totalXp = 250;
      progressEvents.notify(ProgressChangedReason.xp);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect((cubit.state as HomeLoaded).totalXp, 250);
      expect(progressLoads, 1);
    },
  );

  test('second load keeps HomeLoaded and does not emit HomeLoading', () async {
    final states = <HomeState>[];
    final sub = cubit.stream.listen(states.add);
    addTearDown(sub.cancel);

    await cubit.load();
    expect(cubit.state, isA<HomeLoaded>());
    states.clear();

    await cubit.load();
    expect(states.whereType<HomeLoading>(), isEmpty);
    expect(cubit.state, isA<HomeLoaded>());
    expect((cubit.state as HomeLoaded).isRefreshing, isFalse);
  });

  test('load completes quietly when cubit closes during XP fetch', () async {
    xpService.pendingTotalXp = Completer<int>();

    final load = cubit.load();
    await xpService.totalXpRequested.future;
    await cubit.close();
    xpService.pendingTotalXp!.complete(120);

    await expectLater(load, completes);
  });

  test('does not load family data outside the parent PIN gate', () async {
    final family = _MockGetFamilyDashboard();
    when(family.call()).thenAnswer(
      (_) async => const Right(
        FamilyDashboard(children: [], settings: ParentSettings()),
      ),
    );
    await cubit.close();
    cubit = buildCubit(getFamilyDashboard: family);

    await cubit.load();

    verifyNever(family.call());
  });

  test('load completes quietly when cubit closes during extras loading', () async {
    final ayah = _MockGetAyahOfDay();
    final pending = Completer<AyahOfDay?>();
    when(ayah.call()).thenAnswer((_) => pending.future);
    await cubit.close();
    cubit = buildCubit(getAyahOfDay: ayah);

    final load = cubit.load();
    await untilCalled(ayah.call());
    await cubit.close();
    pending.complete(null);

    await expectLater(load, completes);
  });

  test('newer Home load is not overwritten by an older extras result', () async {
    final ayah = _MockGetAyahOfDay();
    final first = Completer<AyahOfDay?>();
    final second = Completer<AyahOfDay?>();
    var calls = 0;
    when(ayah.call()).thenAnswer(
      (_) => calls++ == 0 ? first.future : second.future,
    );
    when(mockMemRepo.getMemorizationProfile()).thenAnswer(
      (_) async => Right(
        MemorizationProfile.empty().copyWith(isParentGuardian: true),
      ),
    );
    await cubit.close();
    cubit = buildCubit(getAyahOfDay: ayah);

    final firstLoad = cubit.load();
    await untilCalled(ayah.call());

    final secondCall = untilCalled(ayah.call());
    final secondLoad = cubit.load();
    await secondCall;
    second.complete(const AyahOfDay(
      surahId: 2,
      ayahNumber: 2,
      text: 'الثانية',
      surahNameAr: 'البقرة',
      surahNameEn: 'Al-Baqarah',
      pageNumber: 2,
    ));
    await secondLoad;

    first.complete(const AyahOfDay(
      surahId: 2,
      ayahNumber: 1,
      text: 'الأولى',
      surahNameAr: 'البقرة',
      surahNameEn: 'Al-Baqarah',
      pageNumber: 2,
    ));
    await firstLoad;

    expect((cubit.state as HomeLoaded).ayahOfDay?.ayahNumber, 2);
  });

  test('loads recent activity from the feed usecase', () async {
    final events = [
      ActivityEvent(
        occurredAt: DateTime.utc(2026, 9, 9, 12),
        kind: ActivityEventKind.reading,
        idempotencyKey: 'reading|20260909|5',
        pageNumber: 5,
      ),
    ];
    await cubit.close();
    cubit = buildCubit(
      getRecentActivity: GetRecentActivityUsecase(_MemoryActivityFeed(events)),
    );

    await cubit.load();

    final state = cubit.state;
    expect(state, isA<HomeLoaded>());
    expect((state as HomeLoaded).recentActivity, events);
  });
}

class _MemoryActivityFeed implements ActivityFeedRepository {
  const _MemoryActivityFeed(this.events);

  final List<ActivityEvent> events;

  @override
  Future<void> append(ActivityEvent event) async {}

  @override
  Future<List<ActivityEvent>> recent({int limit = 20}) async =>
      events.take(limit).toList();

  @override
  Future<Set<ActivityEventKind>> kindsSince(DateTime start) async => {
    for (final event in events)
      if (!event.occurredAt.isBefore(start)) event.kind,
  };
}

class _FakeXpService implements XpService {
  int totalXp = 120;
  Completer<int>? pendingTotalXp;
  final totalXpRequested = Completer<void>();

  @override
  Future<int> getTotalXp() {
    if (!totalXpRequested.isCompleted) totalXpRequested.complete();
    return pendingTotalXp?.future ?? Future.value(totalXp);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
