import 'dart:async';
import '../../../../core/identity/account_data_barrier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../../../progress/domain/usecases/get_progress_usecase.dart';
import '../../../quran/domain/usecases/get_surahs_usecase.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/data/datasources/bookmark_service.dart';
import '../../../quran/domain/bookmark_reader_location.dart';
import '../../../quran/domain/entities/bookmark_entry.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../memorization_plus/domain/navigation/memorization_navigation_resolver.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/smart_coach_recommendation.dart';
import '../../../../core/memorization/usecases/get_smart_coach_recommendation_usecase.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/services/daily_reading_log_service.dart';
import '../../../../core/services/get_daily_wird_usecase.dart';
import '../../../../core/services/streak_risk_evaluator.dart';
import '../../../../core/services/audio_resume_store.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/services/streak_service.dart';
import '../../domain/usecases/get_activity_heatmap_usecase.dart';
import '../../domain/usecases/get_today_checklist_usecase.dart';
import '../../domain/usecases/get_ayah_of_day_usecase.dart';
import '../../domain/usecases/get_recent_activity_usecase.dart';
import '../../domain/entities/today_checklist.dart';
import '../../domain/entities/ayah_of_day.dart';
import '../../domain/entities/home_contextual_slot.dart';
import '../../domain/entities/continue_recitation.dart';
import '../../domain/entities/activity_event.dart';
import '../../domain/services/home_occasion_service.dart';
import '../../domain/services/continue_recitation_mapper.dart';
import '../../data/home_slot_snooze_store.dart';
import '../../../../core/journey/unified_journey_action.dart';
import '../../../../core/journey/unified_journey_engine.dart';
import '../../../../core/journey/unified_journey_input.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../../core/services/xp_service.dart';
import '../../../memorization_plus/domain/services/memorization_insights_aggregator.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../khatmah/domain/entities/khatmah_plan.dart';
import '../../../khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import '../../../azkar/domain/entities/azkar_entities.dart';
import '../../../azkar/domain/usecases/get_azkar_usecase.dart';
import '../../../azkar/data/datasources/azkar_completion_store.dart';
import '../../../../core/router/app_router.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetProgressUsecase _getProgress;
  final GetQuranPageUsecase _getQuranPage;
  final GetCustomPlanUsecase _getCustomPlan;
  final MemorizationPlusRepository _memorizationRepository;
  final AppSessionService _sessionService;
  final GetActivityHeatmapUsecase _getHeatmap;
  final MemorizationPathResolver _pathResolver;
  final GetSmartCoachRecommendationUsecase _getCoachRecommendation;
  final UnifiedJourneyEngine _journeyEngine;
  final SharedPreferences _prefs;
  final ProgressEventsBus _progressEvents;
  final XpService _xpService;
  final GetActiveKhatmahUsecase? _getActiveKhatmah;
  final GetDailyWirdUsecase? _getDailyWird;
  final DailyReadingLogService? _readingLog;
  final AzkarCompletionStore? _azkarStore;
  final GetAzkarUsecase? _getAzkar;
  final StreakRiskEvaluator _streakRiskEvaluator;
  final StreakService? _streakService;
  final AudioResumeStore? _audioResumeStore;
  final BookmarkService? _bookmarkService;
  final GetAyahOfDayUsecase? _getAyahOfDay;
  final PrayerTimesService? _prayerTimes;
  final HomeOccasionService _occasionService;
  final GetTodayChecklistUsecase _todayChecklist;
  final GetRecentActivityUsecase? _getRecentActivity;
  late final StreamSubscription<void> _pathChangesSub;
  late final StreamSubscription<ProgressChangedReason> _progressChangesSub;
  Timer? _reloadDebounce;
  StreamSubscription<void>? _khatmahChangesSub;
  int _khatmahRevision = 0;
  int _loadRevision = 0;

  HomeCubit(
    this._getProgress,
    this._getQuranPage,
    this._getCustomPlan,
    this._memorizationRepository,
    this._sessionService,
    this._getHeatmap,
    this._pathResolver,
    this._getCoachRecommendation,
    this._journeyEngine,
    this._prefs,
    this._progressEvents,
    this._xpService, [
    this._getActiveKhatmah,
  ]) : _getDailyWird = null,
       _readingLog = null,
       _azkarStore = null,
       _getAzkar = null,
       _streakRiskEvaluator = const StreakRiskEvaluator(),
       _streakService = null,
       _audioResumeStore = null,
       _bookmarkService = null,
       _getAyahOfDay = null,
       _prayerTimes = null,
       _occasionService = const HomeOccasionService(),
       _todayChecklist = const GetTodayChecklistUsecase(),
       _getRecentActivity = null,
       super(const HomeInitial()) {
    _listen();
  }

  HomeCubit.withExtras(
    this._getProgress,
    this._getQuranPage,
    this._getCustomPlan,
    this._memorizationRepository,
    this._sessionService,
    this._getHeatmap,
    this._pathResolver,
    this._getCoachRecommendation,
    this._journeyEngine,
    this._prefs,
    this._progressEvents,
    this._xpService, {
    GetActiveKhatmahUsecase? getActiveKhatmah,
    GetDailyWirdUsecase? getDailyWird,
    DailyReadingLogService? readingLog,
    AzkarCompletionStore? azkarStore,
    GetAzkarUsecase? getAzkar,
    StreakRiskEvaluator streakRiskEvaluator = const StreakRiskEvaluator(),
    StreakService? streakService,
    AudioResumeStore? audioResumeStore,
    GetFamilyDashboardUsecase? getFamilyDashboard,
    BookmarkService? bookmarkService,
    GetAyahOfDayUsecase? getAyahOfDay,
    PrayerTimesService? prayerTimes,
    HomeOccasionService occasionService = const HomeOccasionService(),
    GetTodayChecklistUsecase todayChecklist = const GetTodayChecklistUsecase(),
    GetRecentActivityUsecase? getRecentActivity,
  }) : _getActiveKhatmah = getActiveKhatmah,
       _getDailyWird = getDailyWird,
       _readingLog = readingLog,
       _azkarStore = azkarStore,
       _getAzkar = getAzkar,
       _streakRiskEvaluator = streakRiskEvaluator,
       _streakService = streakService,
       _audioResumeStore = audioResumeStore,
       _bookmarkService = bookmarkService,
       _getAyahOfDay = getAyahOfDay,
       _prayerTimes = prayerTimes,
       _occasionService = occasionService,
       _todayChecklist = todayChecklist,
       _getRecentActivity = getRecentActivity,
       super(const HomeInitial()) {
    _listen();
  }

  void _listen() {
    _pathChangesSub = _pathResolver.changes.listen((_) {
      if (!isClosed) {
        _scheduleFullReload();
      }
    });
    _progressChangesSub = _progressEvents.changes.listen(_onProgressChanged);
    _khatmahChangesSub = _getActiveKhatmah?.changes?.listen((_) {
      if (isClosed) return;
      final current = state;
      if (current is HomeLoaded) {
        try {
          _checkKhatmahAuthority(current.activeKhatmah);
        } catch (error) {
          emit(current.copyWith(activeKhatmah: null, khatmahError: error));
        }
        unawaited(_refreshKhatmah());
      }
    });
  }

  HomeSlotSnoozeStore get snoozeStore => HomeSlotSnoozeStore(_prefs);

  void _checkKhatmahAuthority(KhatmahPlan? plan) {
    final authority = plan?.authority;
    if (authority is AccountDataLease) authority.check();
  }

  Future<void> _refreshKhatmah() async {
    final revision = ++_khatmahRevision;
    KhatmahPlan? plan;
    Object? error;
    try {
      plan = await _getActiveKhatmah?.call();
      _checkKhatmahAuthority(plan);
    } catch (failure) {
      error = failure;
      plan = null;
    }
    final current = state;
    if (!isClosed && revision == _khatmahRevision && current is HomeLoaded) {
      emit(current.copyWith(activeKhatmah: plan, khatmahError: error));
    }
  }

  void _onProgressChanged(ProgressChangedReason reason) {
    if (reason == ProgressChangedReason.xp) {
      unawaited(_refreshXpOnly());
      return;
    }
    if (ProgressEventsBus.affectsHomeFullReload(reason)) {
      _scheduleFullReload();
    }
  }

  void _scheduleFullReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!isClosed) {
        unawaited(load());
      }
    });
  }

  Future<void> _refreshXpOnly() async {
    final current = state;
    if (current is! HomeLoaded) return;
    try {
      final totalXp = await _xpService.getTotalXp();
      if (!isClosed && state is HomeLoaded) {
        emit((state as HomeLoaded).copyWith(totalXp: totalXp));
      }
    } catch (_) {}
  }

  Future<void> snoozeSlot(HomeSlotKind kind) async {
    await snoozeStore.snooze(kind);
    if (state is HomeLoaded && !isClosed) {
      emit((state as HomeLoaded).copyWith(activeSlot: null));
      unawaited(load());
    }
  }

  Future<void> load() async {
    final revision = ++_loadRevision;
    if (isClosed) return;
    final hadLoaded = state is HomeLoaded;
    if (!hadLoaded) {
      emit(const HomeLoading());
    } else {
      emit((state as HomeLoaded).copyWith(isRefreshing: true));
    }

    final wirdPage = await _resolveWirdPage();

    final progressFuture = _getProgress();
    final quranPageFuture = _getQuranPage(wirdPage);
    final planFuture = _getCustomPlan();
    final heatmapFuture = _getHeatmap();
    final coachFuture = _getCoachRecommendation();
    Object? khatmahError;
    final khatmahFuture =
        Future<KhatmahPlan?>.sync(() => _getActiveKhatmah?.call()).catchError((
          Object error,
        ) {
          khatmahError = error;
          return null;
        });

    final progressResult = await progressFuture;
    OverallProgress? overallProgress;
    progressResult.fold((_) {}, (progress) => overallProgress = progress);
    final quranPageResult = await quranPageFuture;
    QuranPageDetail? dailyWirdDetail;
    quranPageResult.fold((l) => null, (r) => dailyWirdDetail = r);

    CustomMemorizationPlan? customPlan;
    final planResult = await planFuture;
    planResult.fold((l) => null, (plan) => customPlan = plan);
    final heatmap = await heatmapFuture;
    SmartCoachRecommendation? coachRecommendation;
    final coachResult = await coachFuture;
    coachResult.fold((_) => null, (r) => coachRecommendation = r);
    var activeKhatmah = await khatmahFuture;

    final lastLocation = _sessionService.getLastRestorableLocation();

    final profileResult = await _memorizationRepository
        .getMemorizationProfile();
    final profile = profileResult.fold((_) => null, (p) => p);
    final selectedTrack = profile?.selectedPath == MemorizationPath.child
        ? MemorizationTrack.kids
        : profile?.selectedPath == MemorizationPath.adult
        ? MemorizationTrack.adults
        : null;
    final isParentMode = profile?.isParentGuardian ?? false;
    final isKids = profile?.isChild ?? false;

    if (isClosed) return;
    UnifiedJourneyAction? heroAction;
    var alternativeActions = const <UnifiedJourneyAction>[];
    try {
      final evaluated = await _evaluateUnifiedActions(
        lastLocation: lastLocation,
        coachRecommendation: coachRecommendation,
        customPlan: customPlan,
        dailyWirdDetail: dailyWirdDetail,
        isKids: isKids,
        overallProgress: overallProgress,
        activeKhatmah: activeKhatmah,
      );
      heroAction = evaluated.$1;
      alternativeActions = evaluated.$2;
    } catch (e, s) {
      TaliaLogger.w('Failed to evaluate hero action', e, s);
    }

    if (isClosed) return;
    final totalXp = await _xpService.getTotalXp();
    if (isClosed) return;
    try {
      _checkKhatmahAuthority(activeKhatmah);
    } catch (error) {
      activeKhatmah = null;
      khatmahError = error;
    }

    final extras = await _loadExtras(
      progress: overallProgress,
      isKids: isKids,
      isParentMode: isParentMode,
      wirdPage: wirdPage,
      dailyWirdDetail: dailyWirdDetail,
      activeKhatmah: activeKhatmah,
      lastLocation: lastLocation,
      activityCountsByDay: heatmap.countsByDay,
      heroAction: heroAction,
    );

    if (!_isCurrentLoad(revision)) return;
    try {
      _checkKhatmahAuthority(activeKhatmah);
    } catch (error) {
      activeKhatmah = null;
      khatmahError = error;
    }
    progressResult.fold((f) => emit(HomeError(f.message)), (progress) {
      emit(
        HomeLoaded(
          progress: progress,
          greeting: extras.greeting,
          dailyWirdPageDetail: dailyWirdDetail,
          customPlan: customPlan,
          selectedTrack: selectedTrack,
          isParentMode: isParentMode,
          isKids: isKids,
          lastRestorableLocation: lastLocation,
          activityCountsByDay: heatmap.countsByDay,
          activityStartDate: heatmap.startDate,
          coachRecommendation: coachRecommendation,
          heroAction: heroAction,
          totalXp: totalXp,
          activeKhatmah: activeKhatmah,
          khatmahError: khatmahError,
          isRefreshing: false,
          todayChecklist: extras.checklist,
          ayahOfDay: extras.ayahOfDay,
          streakRisk: extras.streakRisk,
          audioResume: extras.audioResume,
          alternativeActions: alternativeActions,
          occasion: extras.occasion,
          hijriLabel: extras.hijriLabel,
          gregorianLabel: extras.gregorianLabel,
          activeSlot: extras.activeSlot,
          familyChildren: extras.familyChildren,
          prayerSnapshot: extras.prayerSnapshot,
          weeklyActiveDays: extras.weeklyActiveDays,
          weeklyActivityCount: extras.weeklyActivityCount,
          recentBookmarkRoute: extras.recentBookmarkRoute,
          heroMinutes: extras.heroMinutes,
          continueRecitation: extras.continueRecitation,
          recentActivity: extras.recentActivity,
        ),
      );
    });
  }

  Future<int> _resolveWirdPage() async {
    try {
      if (_getDailyWird != null) return await _getDailyWird();
    } catch (e, s) {
      TaliaLogger.w('Daily wird resolution failed', e, s);
    }
    return 1;
  }

  Future<
    ({
      String greeting,
      TodayChecklist? checklist,
      AyahOfDay? ayahOfDay,
      StreakRisk? streakRisk,
      AudioResumePosition? audioResume,
      HomeOccasion occasion,
      String hijriLabel,
      String gregorianLabel,
      HomeSlotCandidate? activeSlot,
      List<FamilyChildEntry> familyChildren,
      PrayerTimesSnapshot? prayerSnapshot,
      int weeklyActiveDays,
      int weeklyActivityCount,
      String? recentBookmarkRoute,
      int heroMinutes,
      ContinueRecitation? continueRecitation,
      List<ActivityEvent> recentActivity,
    })
  >
  _loadExtras({
    required OverallProgress? progress,
    required bool isKids,
    required bool isParentMode,
    required int wirdPage,
    required QuranPageDetail? dailyWirdDetail,
    required KhatmahPlan? activeKhatmah,
    required String? lastLocation,
    required Map<String, int> activityCountsByDay,
    required UnifiedJourneyAction? heroAction,
  }) async {
    final occasion = _occasionService.current(isArabic: true);

    // Drives the checklist's memorize/review completion from work the user
    // actually logged today rather than from lifetime totals.
    var kindsToday = const <ActivityEventKind>{};
    try {
      kindsToday = await _getRecentActivity?.kindsToday() ?? const {};
    } catch (_) {}

    StreakRisk? risk;
    try {
      final streak = await _streakService?.getStreak();
      if (streak != null) {
        risk = _streakRiskEvaluator.evaluate(streak);
      }
    } catch (_) {}

    DailyPlan? dailyPlan;
    try {
      final planResult = await _memorizationRepository.getCachedDailyPlan();
      dailyPlan = planResult.fold((_) => null, (plan) => plan);
    } catch (_) {}

    var memorizeRoute = AppRoutes.memorizationHub;
    var reviewRoute = AppRoutes.memorizationHub;
    try {
      final targets = await MemorizationNavigationResolver(
        _memorizationRepository,
      ).resolve();
      memorizeRoute = targets.todayPlanLocation;
      reviewRoute = targets.reviewQuizLocation;
    } catch (_) {}

    final hour = DateTime.now().hour;
    final azkarCategory = hour < 12
        ? AzkarCategory.morning
        : hour >= 16
        ? AzkarCategory.evening
        : AzkarCategory.general;
    var azkarComplete = false;
    try {
      if (_azkarStore != null && _getAzkar != null) {
        final items = await _getAzkar(azkarCategory);
        items.fold((_) {}, (zikr) {
          azkarComplete = _azkarStore.isCompleteFromSessions(
            category: azkarCategory,
            items: zikr,
          );
        });
      } else {
        azkarComplete = _azkarStore?.isCategoryComplete(azkarCategory) ?? false;
      }
    } catch (_) {}

    final readingComplete =
        _readingLog?.contains(wirdPage) ?? false;
    final readingRoute = activeKhatmah != null &&
            activeKhatmah.status == KhatmahStatus.active
        ? '/quran/page/${activeKhatmah.nextUnreadPage}?mode=khatmah'
        : activeKhatmah != null && activeKhatmah.status == KhatmahStatus.paused
        ? AppRoutes.khatmahDashboard
        : '/quran/page/$wirdPage';

    TodayChecklist? checklist;
    if (progress != null) {
      checklist = _todayChecklist(
        TodayChecklistParams(
          progress: progress,
          wirdPage: wirdPage,
          wirdComplete: readingComplete,
          readingRoute: readingRoute,
          memorizeRoute: memorizeRoute,
          reviewRoute: reviewRoute,
          azkarRoute: '/azkar/${azkarCategory.name}',
          azkarComplete: azkarComplete,
          khatmah: activeKhatmah,
          dailyPlan: dailyPlan,
          azkarCategory: azkarCategory,
          memorizedToday: kindsToday.contains(ActivityEventKind.memorize),
          reviewedToday: kindsToday.contains(ActivityEventKind.review),
        ),
      );
    }

    AyahOfDay? ayah;
    try {
      final userGoal = _prefs.getString('user_primary_goal');
      ayah = userGoal == null
          ? await _getAyahOfDay?.call()
          : await _getAyahOfDay?.call(userGoal: userGoal);
    } catch (_) {}

    // Family data stays exclusively behind FamilyDashboardCubit's PIN gate.
    // Home shows the parent-tools entry point but never fetches child details.
    const children = <FamilyChildEntry>[];

    PrayerTimesSnapshot? prayer;
    try {
      prayer = await _prayerTimes?.current(isArabic: true);
    } catch (_) {}

    String? bookmarkRoute;
    try {
      await _bookmarkService?.ensureLoaded();
      final recent = _bookmarkService?.getAll().firstOrNull;
      if (recent is BookmarkEntry) {
        bookmarkRoute = bookmarkReaderLocation(recent);
      }
    } catch (_) {}

    var weeklyDays = 0;
    var weeklyCount = 0;
    final today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final count = activityCountsByDay[key] ?? 0;
      weeklyCount += count;
      if (count > 0) weeklyDays += 1;
    }

    final candidates = <HomeSlotCandidate>[
      if (occasion.occasion == HomeOccasion.friday)
        const HomeSlotCandidate(
          kind: HomeSlotKind.fridayKahf,
          route: '/quran/surah/18',
          priority: 0,
        ),
      if (occasion.occasion == HomeOccasion.ramadan)
        const HomeSlotCandidate(
          kind: HomeSlotKind.ramadan,
          route: AppRoutes.quran,
          priority: 1,
        ),
      if (occasion.occasion == HomeOccasion.lastTenNights)
        const HomeSlotCandidate(
          kind: HomeSlotKind.lastTenNights,
          route: AppRoutes.quran,
          priority: 1,
        ),
      if (risk?.isAtRisk == true)
        const HomeSlotCandidate(
          kind: HomeSlotKind.streakRisk,
          route: AppRoutes.memorizationHub,
          priority: 2,
        ),
      if (activeKhatmah != null && activeKhatmah.progressPercentage >= 0.9)
        const HomeSlotCandidate(
          kind: HomeSlotKind.khatmahNearComplete,
          route: AppRoutes.khatmahDashboard,
          priority: 3,
        ),
      if (isParentMode)
        const HomeSlotCandidate(
          kind: HomeSlotKind.parentTools,
          route: AppRoutes.familyDashboard,
          priority: 5,
        ),
      const HomeSlotCandidate(
        kind: HomeSlotKind.signIn,
        route: AppRoutes.login,
        priority: 6,
      ),
      if (lastLocation == null)
        const HomeSlotCandidate(
          kind: HomeSlotKind.tutorial,
          route: AppRoutes.tutorialGuide,
          priority: 7,
        ),
    ];
    final slot = const HomeContextualSlotSelector().select(
      candidates,
      isSnoozed: snoozeStore.isSnoozed,
    );

    List<ActivityEvent> recent = const [];
    try {
      recent = await _getRecentActivity?.call() ?? const [];
    } catch (_) {}

    final continueRecitation = const ContinueRecitationMapper().map(
      isArabic: true,
      heroAction: heroAction,
      lastRestorableLocation: lastLocation,
      dailyWirdPageDetail: dailyWirdDetail,
      activeKhatmah: activeKhatmah,
      confirmedReadPages: progress?.readPagesCount ?? 0,
    );

    return (
      greeting: occasion.greetingPeriod,
      checklist: checklist,
      ayahOfDay: ayah,
      streakRisk: risk,
      audioResume: _audioResumeStore?.position,
      occasion: occasion.occasion,
      hijriLabel: occasion.hijriLabel,
      gregorianLabel: occasion.gregorianLabel,
      activeSlot: slot,
      familyChildren: children,
      prayerSnapshot: prayer,
      weeklyActiveDays: weeklyDays,
      weeklyActivityCount: weeklyCount,
      recentBookmarkRoute: bookmarkRoute,
      heroMinutes: heroAction == null ? 0 : journeyActionMinutes(heroAction),
      continueRecitation: continueRecitation,
      recentActivity: recent,
    );
  }

  Future<(UnifiedJourneyAction?, List<UnifiedJourneyAction>)>
  _evaluateUnifiedActions({
    required String? lastLocation,
    required SmartCoachRecommendation? coachRecommendation,
    required CustomMemorizationPlan? customPlan,
    required QuranPageDetail? dailyWirdDetail,
    required bool isKids,
    required OverallProgress? overallProgress,
    required KhatmahPlan? activeKhatmah,
  }) async {
    final isEnabled = _prefs.getBool('unified_journey_enabled') ?? true;
    if (!isEnabled) {
      return (null, const <UnifiedJourneyAction>[]);
    }

    final recordsResult = await _memorizationRepository.getAllReviewRecords(
      scope: isKids ? ReviewRecordReadScope.kids : ReviewRecordReadScope.adult,
    );
    final records = recordsResult.getOrElse(() => []);
    final now = DateTime.now().toUtc();
    const aggregator = MemorizationInsightsAggregator();
    final insights = aggregator.generateAdultProduction(records, now);
    const adaptiveUsecase = AdaptiveRecommendationsUsecase();
    final recommendations = insights.totalRecordsAnalyzed == 0
        ? const <MemorizationRecommendation>[]
        : adaptiveUsecase.generate(insights).recommendations;

    final criticals = recommendations
        .where(
          (r) =>
              (r.priority == RecommendationPriority.critical ||
                  r.priority == RecommendationPriority.high) &&
              r.type != RecommendationType.reviewBacklog,
        )
        .toList();
    final backlogs = recommendations
        .where((r) => r.type == RecommendationType.reviewBacklog)
        .toList();

    final khatmahRoute = activeKhatmah == null
        ? null
        : activeKhatmah.status == KhatmahStatus.paused
        ? AppRoutes.khatmahDashboard
        : '/quran/page/${activeKhatmah.nextUnreadPage}?mode=khatmah';

    final input = UnifiedJourneyInput(
      lastRestorableLocation: lastLocation,
      hasCriticalLearningAlert: criticals.isNotEmpty,
      learningAlertType: criticals.isNotEmpty ? criticals.first.type : null,
      hasReviewBacklog:
          (overallProgress?.reviewAyahs ?? 0) > 0 && backlogs.isNotEmpty,
      overdueAyahs: overallProgress?.overdueReviews ?? 0,
      hasSmartPlan: coachRecommendation != null || customPlan != null,
      isSmartPlanReview:
          coachRecommendation != null &&
          (coachRecommendation.kind ==
                  SmartCoachRecommendationKind.reviewDueNear ||
              coachRecommendation.kind ==
                  SmartCoachRecommendationKind.reviewDueFar ||
              coachRecommendation.kind ==
                  SmartCoachRecommendationKind.memorizedReviewDue ||
              coachRecommendation.kind ==
                  SmartCoachRecommendationKind.reviewWeakAyah),
      smartPlanType: customPlan != null
          ? SmartPlanType.customPlan
          : (coachRecommendation != null ? SmartPlanType.reviewPlan : null),
      smartPlanRoute:
          coachRecommendation?.route ??
          (customPlan != null ? '/memorization' : null),
      hasDailyWird: dailyWirdDetail != null,
      dailyWirdPageNumber: dailyWirdDetail?.pageNumber,
      hasActiveKhatmah:
          activeKhatmah != null &&
          activeKhatmah.status != KhatmahStatus.completed,
      khatmahRoute: khatmahRoute,
      isKids: isKids,
      userGoal: _prefs.getString('user_primary_goal'),
    );

    final all = _journeyEngine.evaluateAll(input);
    final unifiedAction = all.first;
    final hero = _resolveHeroAction(
      unifiedAction: unifiedAction,
      coachRecommendation: coachRecommendation,
    );
    return (hero, all);
  }

  bool _isCurrentLoad(int revision) => !isClosed && revision == _loadRevision;

  UnifiedJourneyAction? _resolveHeroAction({
    required UnifiedJourneyAction unifiedAction,
    SmartCoachRecommendation? coachRecommendation,
  }) {
    if (coachRecommendation == null) return unifiedAction;

    final coachUrgent = switch (coachRecommendation.kind) {
      SmartCoachRecommendationKind.reviewWeakAyah ||
      SmartCoachRecommendationKind.reviewDueNear ||
      SmartCoachRecommendationKind.reviewDueFar ||
      SmartCoachRecommendationKind.memorizedReviewDue => true,
      _ => false,
    };
    if (!coachUrgent) return unifiedAction;

    if (unifiedAction.priority == UnifiedJourneyPriority.p5DailyGoal ||
        unifiedAction.priority == UnifiedJourneyPriority.p6FreeExploration) {
      return null;
    }
    return unifiedAction;
  }

  @override
  Future<void> close() async {
    _loadRevision++;
    await _khatmahChangesSub?.cancel();
    _reloadDebounce?.cancel();
    await _pathChangesSub.cancel();
    await _progressChangesSub.cancel();
    return super.close();
  }
}
