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
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/memorization/micro_review_picker.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/review_record_read_batch.dart';
import '../../../../core/memorization/smart_coach_recommendation.dart';
import '../../../../core/memorization/usecases/get_smart_coach_recommendation_usecase.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/services/get_daily_wird_usecase.dart';
import '../../../../core/services/streak_risk_evaluator.dart';
import '../../../../core/services/audio_resume_store.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/services/streak_service.dart';
import '../../domain/usecases/get_activity_heatmap_usecase.dart';
import '../../domain/usecases/get_ayah_of_day_usecase.dart';
import '../../domain/usecases/get_recent_activity_usecase.dart';
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
import '../../../prayer_companion/application/prayer_companion_usecases.dart';
import '../../../prayer_companion/data/datasources/prayer_companion_preferences.dart';
import '../../../prayer_companion/domain/entities/prayer_companion.dart';
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
  final StreakRiskEvaluator _streakRiskEvaluator;
  final StreakService? _streakService;
  final AudioResumeStore? _audioResumeStore;
  final GetAyahOfDayUsecase? _getAyahOfDay;
  final PrayerTimesService? _prayerTimes;
  final PrayerCompanionPreferences? _companionPreferences;
  final GetPrayerCompanionDaySummary? _getCompanionSummary;
  final HomeOccasionService _occasionService;
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
       _streakRiskEvaluator = const StreakRiskEvaluator(),
       _streakService = null,
       _audioResumeStore = null,
       _getAyahOfDay = null,
       _prayerTimes = null,
       _companionPreferences = null,
       _getCompanionSummary = null,
       _occasionService = const HomeOccasionService(),
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
    StreakRiskEvaluator streakRiskEvaluator = const StreakRiskEvaluator(),
    StreakService? streakService,
    AudioResumeStore? audioResumeStore,
    GetFamilyDashboardUsecase? getFamilyDashboard,
    GetAyahOfDayUsecase? getAyahOfDay,
    PrayerTimesService? prayerTimes,
    PrayerCompanionPreferences? companionPreferences,
    GetPrayerCompanionDaySummary? getCompanionSummary,
    HomeOccasionService occasionService = const HomeOccasionService(),
    GetRecentActivityUsecase? getRecentActivity,
  }) : _getActiveKhatmah = getActiveKhatmah,
       _getDailyWird = getDailyWird,
       _streakRiskEvaluator = streakRiskEvaluator,
       _streakService = streakService,
       _audioResumeStore = audioResumeStore,
       _getAyahOfDay = getAyahOfDay,
       _prayerTimes = prayerTimes,
       _companionPreferences = companionPreferences,
       _getCompanionSummary = getCompanionSummary,
       _occasionService = occasionService,
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
    final recitation = await _khatmahRecitation(plan);
    final current = state;
    if (!isClosed && revision == _khatmahRevision && current is HomeLoaded) {
      emit(
        current.copyWith(
          activeKhatmah: plan,
          khatmahError: error,
          continueRecitation: recitation,
        ),
      );
    }
  }

  /// Builds the khatmah "continue recitation" card from the khatmah's own
  /// next unread page. The ordinary daily wird is a separate journey and
  /// never feeds this card.
  Future<ContinueRecitation?> _khatmahRecitation(KhatmahPlan? plan) async {
    QuranPageDetail? page;
    if (plan != null &&
        plan.status == KhatmahStatus.active &&
        plan.nextUnreadPage <= 604) {
      try {
        final result = await _getQuranPage(plan.nextUnreadPage);
        page = result.fold((_) => null, (detail) => detail);
      } catch (error, stackTrace) {
        TaliaLogger.w('Failed to load khatmah page', error, stackTrace);
      }
    }
    return const ContinueRecitationMapper().map(
      isArabic: true,
      activeKhatmah: plan,
      khatmahPageDetail: page,
    );
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

  /// Loads home in two emits: the visible page first, then the deferred
  /// extras. The review-record reads made by progress, the smart coach, the
  /// navigation resolver and home itself share one store read per load.
  Future<void> load() => ReviewRecordReadBatch.run(_load);

  Future<void> _load() async {
    final revision = ++_loadRevision;
    if (isClosed) return;
    final hadLoaded = state is HomeLoaded;
    if (!hadLoaded) {
      emit(const HomeLoading());
    } else {
      emit((state as HomeLoaded).copyWith(isRefreshing: true));
    }

    // Start every independent local read before resolving the daily page.
    // The daily-page resolver can itself read the memorization plan; waiting
    // for it first made the initial home skeleton accumulate the latency of
    // all the remaining data sources.
    final progressFuture = _getProgress();
    final planFuture = _getCustomPlan();
    final heatmapFuture = _getHeatmap();
    final coachFuture = _getCoachRecommendation();
    final profileFuture = _memorizationRepository.getMemorizationProfile();
    final totalXpFuture = _xpService.getTotalXp();
    Object? khatmahError;
    final khatmahFuture =
        Future<KhatmahPlan?>.sync(() => _getActiveKhatmah?.call()).catchError((
          Object error,
        ) {
          khatmahError = error;
          return null;
        });

    // The extras' store reads don't depend on anything above, so they run
    // alongside the core reads instead of after them.
    final extraReads = _startExtraReads();

    final wirdPage = await _resolveWirdPage();
    final quranPageFuture = _getQuranPage(wirdPage);

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

    final profileResult = await profileFuture;
    final profile = profileResult.fold((_) => null, (p) => p);
    final selectedTrack = profile?.selectedPath == MemorizationPath.child
        ? MemorizationTrack.kids
        : profile?.selectedPath == MemorizationPath.adult
        ? MemorizationTrack.adults
        : null;
    final isParentMode = profile?.isParentGuardian ?? false;
    final isKids = profile?.isChild ?? false;

    var reviewRecords = const <AyahReviewRecord>[];
    try {
      final reviewRecordsResult = await _memorizationRepository
          .getAllReviewRecords(
            scope: isKids
                ? ReviewRecordReadScope.kids
                : ReviewRecordReadScope.adult,
          );
      reviewRecords = reviewRecordsResult.getOrElse(() => []);
    } catch (error, stackTrace) {
      TaliaLogger.w('Failed to load home review records', error, stackTrace);
    }
    final microReview = const MicroReviewPicker().pick(
      records: reviewRecords,
      now: DateTime.now(),
    );

    if (isClosed) return;
    UnifiedJourneyAction? heroAction;
    var alternativeActions = const <UnifiedJourneyAction>[];
    final unifiedJourneyEnabled =
        _prefs.getBool('unified_journey_enabled') ?? true;
    try {
      final evaluated = await _evaluateUnifiedActions(
        lastLocation: lastLocation,
        coachRecommendation: coachRecommendation,
        customPlan: customPlan,
        dailyWirdDetail: dailyWirdDetail,
        isKids: isKids,
        reviewRecords: reviewRecords,
        overallProgress: overallProgress,
        activeKhatmah: activeKhatmah,
        isEnabled: unifiedJourneyEnabled,
      );
      heroAction = evaluated.$1;
      alternativeActions = evaluated.$2;
    } catch (e, s) {
      TaliaLogger.w('Failed to evaluate hero action', e, s);
    }

    if (isClosed) return;
    final totalXp = await totalXpFuture;
    if (isClosed) return;
    try {
      _checkKhatmahAuthority(activeKhatmah);
    } catch (error) {
      activeKhatmah = null;
      khatmahError = error;
    }

    final extras = await _loadExtras(
      reads: extraReads,
      isParentMode: isParentMode,
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
    final failure = progressResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(HomeError(failure.message));
      return;
    }
    final progress = overallProgress!;

    // Paint the page as soon as everything visible above the fold is ready.
    // The ayah of the day and the checklist inputs follow in a second emit;
    // a refresh keeps the previous values (and its progress bar) until then.
    final previous = state is HomeLoaded ? state as HomeLoaded : null;
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
        unifiedJourneyEnabled: unifiedJourneyEnabled,
        totalXp: totalXp,
        activeKhatmah: activeKhatmah,
        khatmahError: khatmahError,
        isRefreshing: hadLoaded,
        ayahOfDay: previous?.ayahOfDay,
        streakRisk: extras.streakRisk,
        audioResume: extras.audioResume,
        alternativeActions: alternativeActions,
        occasion: extras.occasion,
        hijriLabel: extras.hijriLabel,
        gregorianLabel: extras.gregorianLabel,
        activeSlot: extras.activeSlot,
        familyChildren: extras.familyChildren,
        prayerSnapshot: extras.prayerSnapshot,
        prayerCompanionSummary: extras.prayerCompanionSummary,
        weeklyActiveDays: extras.weeklyActiveDays,
        weeklyActivityCount: extras.weeklyActivityCount,
        heroMinutes: extras.heroMinutes,
        continueRecitation: extras.continueRecitation,
        recentActivity: extras.recentActivity,
        microReview: microReview,
      ),
    );

    final ayahOfDay = await extraReads.ayahOfDay;
    if (!_isCurrentLoad(revision)) return;
    final current = state;
    if (current is! HomeLoaded) return;
    emit(current.copyWith(isRefreshing: false, ayahOfDay: ayahOfDay));
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
      StreakRisk? streakRisk,
      AudioResumePosition? audioResume,
      HomeOccasion occasion,
      String hijriLabel,
      String gregorianLabel,
      HomeSlotCandidate? activeSlot,
      List<FamilyChildEntry> familyChildren,
      PrayerTimesSnapshot? prayerSnapshot,
      PrayerCompanionDaySummary? prayerCompanionSummary,
      int weeklyActiveDays,
      int weeklyActivityCount,
      int heroMinutes,
      ContinueRecitation? continueRecitation,
      List<ActivityEvent> recentActivity,
    })
  >
  _loadExtras({
    required _HomeExtraReads reads,
    required bool isParentMode,
    required KhatmahPlan? activeKhatmah,
    required String? lastLocation,
    required Map<String, int> activityCountsByDay,
    required UnifiedJourneyAction? heroAction,
  }) async {
    final occasion = _occasionService.current(isArabic: true);

    // Companion summary is queried at most once per load, only when the
    // feature is enabled; it is never queried per row and failures degrade
    // to a null summary (the sheet then renders like the legacy time list).
    Future<PrayerCompanionDaySummary?> companionSummaryFor(
      PrayerTimesSnapshot? prayer,
    ) async {
      final getSummary = _getCompanionSummary;
      if (prayer == null || getSummary == null) return null;
      if (!(_companionPreferences?.read().enabled ?? false)) return null;
      try {
        final times = <({PrayerKey key, DateTime time})>[
          if (prayer.fajr != null) (key: PrayerKey.fajr, time: prayer.fajr!),
          if (prayer.dhuhr != null) (key: PrayerKey.dhuhr, time: prayer.dhuhr!),
          if (prayer.asr != null) (key: PrayerKey.asr, time: prayer.asr!),
          if (prayer.maghrib != null)
            (key: PrayerKey.maghrib, time: prayer.maghrib!),
          if (prayer.isha != null) (key: PrayerKey.isha, time: prayer.isha!),
        ];
        final now = DateTime.now();
        return await getSummary(
          localDate: DateTime(now.year, now.month, now.day),
          prayerTimes: times,
          now: now,
        );
      } catch (_) {
        return null;
      }
    }

    final risk = await reads.streakRisk;

    // Family data stays exclusively behind FamilyDashboardCubit's PIN gate.
    // Home shows the parent-tools entry point but never fetches child details.
    const children = <FamilyChildEntry>[];

    final prayer = await reads.prayer;
    final companionSummary = await companionSummaryFor(prayer);

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

    final recent = await reads.recentActivity;

    final continueRecitation = await _khatmahRecitation(activeKhatmah);

    return (
      greeting: occasion.greetingPeriod,
      streakRisk: risk,
      audioResume: _audioResumeStore?.position,
      occasion: occasion.occasion,
      hijriLabel: occasion.hijriLabel,
      gregorianLabel: occasion.gregorianLabel,
      activeSlot: slot,
      familyChildren: children,
      prayerSnapshot: prayer,
      prayerCompanionSummary: companionSummary,
      weeklyActiveDays: weeklyDays,
      weeklyActivityCount: weeklyCount,
      heroMinutes: heroAction == null ? 0 : journeyActionMinutes(heroAction),
      continueRecitation: continueRecitation,
      recentActivity: recent,
    );
  }

  /// Starts every home extra that only reads a local store. None of them
  /// depend on the core home reads, so [load] starts them first.
  _HomeExtraReads _startExtraReads() {
    // These reads are independent. Starting them together prevents the home
    // skeleton from paying the sum of several local-store reads on first load.
    final streakRiskFuture = Future<StreakRisk?>.sync(() async {
      try {
        final streak = await _streakService?.getStreak();
        return streak == null ? null : _streakRiskEvaluator.evaluate(streak);
      } catch (_) {
        return null;
      }
    });
    final ayahFuture = Future<AyahOfDay?>.sync(() async {
      try {
        final userGoal = _prefs.getString('user_primary_goal');
        return userGoal == null
            ? await _getAyahOfDay?.call()
            : await _getAyahOfDay?.call(userGoal: userGoal);
      } catch (_) {
        return null;
      }
    });
    final prayerFuture = Future<PrayerTimesSnapshot?>.sync(() async {
      try {
        return await _prayerTimes?.current(isArabic: true);
      } catch (_) {
        return null;
      }
    });

    final recentActivityFuture = Future<List<ActivityEvent>>.sync(() async {
      try {
        return await _getRecentActivity?.call() ?? const [];
      } catch (_) {
        return const [];
      }
    });

    return _HomeExtraReads(
      streakRisk: streakRiskFuture,
      ayahOfDay: ayahFuture,
      prayer: prayerFuture,
      recentActivity: recentActivityFuture,
    );
  }

  Future<(UnifiedJourneyAction?, List<UnifiedJourneyAction>)>
  _evaluateUnifiedActions({
    required String? lastLocation,
    required SmartCoachRecommendation? coachRecommendation,
    required CustomMemorizationPlan? customPlan,
    required QuranPageDetail? dailyWirdDetail,
    required bool isKids,
    required List<AyahReviewRecord> reviewRecords,
    required OverallProgress? overallProgress,
    required KhatmahPlan? activeKhatmah,
    required bool isEnabled,
  }) async {
    if (!isEnabled) {
      return (null, const <UnifiedJourneyAction>[]);
    }

    final now = DateTime.now().toUtc();
    const aggregator = MemorizationInsightsAggregator();
    final insights = aggregator.generateAdultProduction(reviewRecords, now);
    const adaptiveUsecase = AdaptiveRecommendationsUsecase();
    final recommendations = insights.totalRecordsAnalyzed == 0
        ? const <MemorizationRecommendation>[]
        : adaptiveUsecase.generate(insights).recommendations;

    final backlogs = recommendations
        .where((r) => r.type == RecommendationType.reviewBacklog)
        .toList();
    final criticals = recommendations
        .where(
          (r) =>
              (r.priority == RecommendationPriority.critical ||
                  r.priority == RecommendationPriority.high) &&
              r.type != RecommendationType.reviewBacklog &&
              !(backlogs.isNotEmpty &&
                  r.type == RecommendationType.overloadRisk),
        )
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
      learningAlertRoute: coachRecommendation?.route,
      coachRecommendation: coachRecommendation,
      hasReviewBacklog:
          (overallProgress?.reviewAyahs ?? 0) > 0 && backlogs.isNotEmpty,
      overdueAyahs: overallProgress?.overdueReviews ?? 0,
      reviewBacklogRoute: coachRecommendation?.route,
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
          : coachRecommendation == null
          ? null
          : _smartPlanTypeForCoach(coachRecommendation),
      smartPlanRoute:
          coachRecommendation?.route ??
          (customPlan != null ? '/memorization' : null),
      hasDailyWird: dailyWirdDetail != null,
      dailyWirdPageNumber: dailyWirdDetail?.pageNumber,
      dailyWirdSurahNameAr:
          dailyWirdDetail != null && dailyWirdDetail.surahs.isNotEmpty
          ? dailyWirdDetail.surahs.first.nameAr
          : null,
      dailyWirdSurahNameEn:
          dailyWirdDetail != null && dailyWirdDetail.surahs.isNotEmpty
          ? dailyWirdDetail.surahs.first.nameEn
          : null,
      hasActiveKhatmah:
          activeKhatmah != null &&
          activeKhatmah.status != KhatmahStatus.completed,
      khatmahRoute: khatmahRoute,
      isKids: isKids,
      userGoal: _prefs.getString('user_primary_goal'),
    );

    final all = _journeyEngine.evaluateAll(input);
    return (all.first, all);
  }

  bool _isCurrentLoad(int revision) => !isClosed && revision == _loadRevision;

  SmartPlanType _smartPlanTypeForCoach(SmartCoachRecommendation coach) {
    return switch (coach.kind) {
      SmartCoachRecommendationKind.reviewDueNear ||
      SmartCoachRecommendationKind.reviewDueFar ||
      SmartCoachRecommendationKind.memorizedReviewDue ||
      SmartCoachRecommendationKind.reviewWeakAyah => SmartPlanType.reviewPlan,
      _ => SmartPlanType.continueMemorization,
    };
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

/// Local-store reads for the home extras, started together at the top of
/// [HomeCubit.load]. Each future already degrades failures to a fallback.
class _HomeExtraReads {
  const _HomeExtraReads({
    required this.streakRisk,
    required this.ayahOfDay,
    required this.prayer,
    required this.recentActivity,
  });

  final Future<StreakRisk?> streakRisk;
  final Future<AyahOfDay?> ayahOfDay;
  final Future<PrayerTimesSnapshot?> prayer;
  final Future<List<ActivityEvent>> recentActivity;
}
