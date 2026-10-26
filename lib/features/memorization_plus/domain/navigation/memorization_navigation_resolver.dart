import '../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../../../../core/memorization/learning_launch_context.dart';
import '../../../../core/memorization/pending_ayah_resolver.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/smart_coach_engine.dart';
import '../../../../core/router/app_router.dart';
import '../entities/kids_child_policy.dart';
import '../entities/kids_journey_path_definition.dart';
import '../entities/memorization_entities.dart';
import '../repositories/memorization_plus_repository.dart';
import '../usecases/get_last_reviewed_surah_id_usecase.dart';
import '../services/kids_daily_budget.dart';
import '../services/kids_due_review_policy.dart';
import '../services/plan_schedule_policy.dart';
import 'kids_next_mission_resolver.dart';
import 'kids_split_choice.dart';

/// The completion screen's "Next" outcome: the mission to open, or — when
/// none is left because today's new-ayah quota is used up — that quota, so
/// the child sees an encouraging day-complete end instead of a dead button.
/// [sessionGoalReached]: today's sessions reached the parent's session goal,
/// so the celebration adds a gentle "that's enough for today" (K36).
typedef KidsMissionAfterCompletion = ({
  KidsNextMission? mission,
  int? dailyGoalCap,
  bool sessionGoalReached,

  /// [mission] starts a surah whose split is not chosen yet (spec §4.4).
  bool needsSplitChoice,
});

class MemorizationNavigationTargets {
  const MemorizationNavigationTargets({
    required this.profile,
    required this.todayPlanLocation,
    required this.reviewQuizLocation,
    required this.kidsHomeLocation,
    required this.kidsJourneyLocation,
    this.adultDueReviewCount = 0,
    this.hasActiveAdultPlan = false,
    this.memorizeBlockSize,
  });

  final MemorizationProfile? profile;
  final String todayPlanLocation;
  final String reviewQuizLocation;
  final String kidsHomeLocation;
  final String kidsJourneyLocation;

  /// Adult review records currently due; 0 for child profiles.
  final int adultDueReviewCount;

  /// Whether an active adult custom plan exists. Without one there is no
  /// daily plan, which must not be presented as "nothing due today".
  final bool hasActiveAdultPlan;

  /// Block size from the active adult plan's difficulty; null without one.
  final int? memorizeBlockSize;
}

/// Resolves memorization entry routes (domain layer — may read repository).
class MemorizationNavigationResolver {
  const MemorizationNavigationResolver(
    this._repository, [
    PendingAyahResolver? pendingAyahResolver,
  ]) : _pendingAyahResolver =
           pendingAyahResolver ?? const PendingAyahResolver();

  final MemorizationPlusRepository _repository;
  final PendingAyahResolver _pendingAyahResolver;

  Future<MemorizationNavigationTargets> resolve() async {
    final profile = await _profile();
    final customPlan = await _customPlan();
    final cachedPlan = await _cachedPlan();
    final reviewRecords = await _reviewRecords(
      profile?.isChild == true
          ? ReviewRecordReadScope.kids
          : ReviewRecordReadScope.adult,
    );
    final cachedPlanSurahId = await _cachedPlanSurahId(customPlan, cachedPlan);
    final adultPlanSurahId =
        cachedPlanSurahId ?? await _activeAdultPlanSurahId(customPlan);
    final quizSurahId = await _reviewQuizSurahId(adultPlanSurahId);
    final dueReview = profile?.isChild == true
        ? null
        : const SmartCoachEngine().recommendAdultDueReview(reviewRecords);
    final kidsSurahId = await _activeKidsSurahId();

    return MemorizationNavigationTargets(
      profile: profile,
      todayPlanLocation: _v2SessionLocation(
        surahId: adultPlanSurahId,
        intent: PendingAyahIntent.continueDailyPlan,
        cachedPlan: cachedPlan,
        reviewRecords: reviewRecords,
        customPlan: customPlan,
      ),
      reviewQuizLocation:
          dueReview?.route ??
          _v2SessionLocation(
            surahId: quizSurahId,
            intent: PendingAyahIntent.reviewSession,
            cachedPlan: cachedPlan,
            reviewRecords: reviewRecords,
          ),
      kidsHomeLocation: _kidsHomeLocation(kidsSurahId),
      kidsJourneyLocation: _kidsJourneyLocation(kidsSurahId),
      hasActiveAdultPlan:
          customPlan != null &&
          customPlan.isActive &&
          customPlan.targetUser == PlanTargetUser.adult,
      memorizeBlockSize:
          customPlan != null &&
              customPlan.isActive &&
              customPlan.targetUser == PlanTargetUser.adult
          ? PlanSchedulePolicy.blockSize(customPlan)
          : null,
      adultDueReviewCount: profile?.isChild == true
          ? 0
          : reviewRecords.where((record) => record.isVisibleForReview).length,
    );
  }

  /// Next kids mission after finishing [completedAyah], using the same
  /// SRS-first priority and daily budget as the kids home screen (N2), so
  /// "Next" never contradicts home or offers a mission the gate refuses.
  Future<KidsMissionAfterCompletion> kidsMissionAfterCompletion({
    required int surahId,
    required int completedAyah,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final journeyResult = await _repository.getKidsJourney(surahId: surahId);
    final reviewRecords = await _reviewRecords(ReviewRecordReadScope.kids);
    final stages = journeyResult.getOrElse(() => const <KidsJourneyStage>[]);
    final budget = await _kidsDailyBudget(at);
    const resolver = KidsNextMissionResolver();
    final path = await _kidsJourneyPath();
    final continuation = await resolver.findContinuation(
      activeSurahId: surahId,
      stages: stages,
      path: path,
      loadStages: (id) async => (await _repository.getKidsJourney(
        surahId: id,
      )).fold((_) => null, (stages) => stages),
    );
    KidsNextMission? resolveWith(KidsDailyBudget budget) => resolver.resolve(
      activeSurahId: surahId,
      stages: stages,
      reviewRecords: reviewRecords,
      now: at.toUtc(),
      budget: budget,
      continuation: continuation,
      path: path,
    );
    final mission = resolveWith(budget);
    return (
      mission: mission,
      dailyGoalCap: resolver.dailyGoalCap(
        mission: mission,
        budget: budget,
        resolveWith: resolveWith,
      ),
      sessionGoalReached: budget.sessionGoalReached(
        await _kidsSessionGoalMinutes(),
      ),
      needsSplitChoice: await _missionNeedsSplitChoice(path, mission),
    );
  }

  /// Whether "Next" must open [mission]'s journey page to ask the split
  /// question first; any read failure means it does not ask.
  Future<bool> _missionNeedsSplitChoice(
    KidsJourneyPathDefinition path,
    KidsNextMission? mission,
  ) async {
    if (!kidsMissionNeedsSplitChoice(mission, surahNeedsChoice: (_) => true)) {
      return false;
    }
    final surahId = mission!.surahId;
    try {
      final stages = (await _repository.getKidsJourney(
        surahId: surahId,
      )).getOrElse(() => const <KidsJourneyStage>[]);
      return kidsSurahNeedsSplitChoice(
        path: path,
        surahId: surahId,
        ayahCount: kidsAyahCountFromStages(surahId, stages),
        settings: (await _repository.getParentSettings()).fold(
          (_) => null,
          (settings) => settings,
        ),
        logs: (await _repository.getKidsSessionLogs()).fold(
          (_) => null,
          (logs) => logs,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// The parent's session goal (1..60), else the age band's default (K36).
  /// An out-of-range goal also falls back to the age band.
  Future<int> _kidsSessionGoalMinutes() async {
    final settings = (await _repository.getParentSettings()).fold(
      (_) => null,
      (settings) => settings,
    );
    final goal = sanitizeKidsSessionGoalMinutes(settings?.sessionGoalMinutes);
    if (goal != null) return goal;
    final profile = await _profile();
    return KidsSessionPolicy.forChildAge(profile?.childAge).maxSessionMinutes;
  }

  Future<String> adultEntryLocation() async {
    final customPlan = await _customPlan();
    final cachedPlan = await _cachedPlan();
    final reviewRecords = await _reviewRecords(ReviewRecordReadScope.adult);
    final surahId =
        await _cachedPlanSurahId(customPlan, cachedPlan) ??
        await _activeAdultPlanSurahId(customPlan);
    return _v2SessionLocation(
      surahId: surahId,
      intent: PendingAyahIntent.continueDailyPlan,
      cachedPlan: cachedPlan,
      reviewRecords: reviewRecords,
      customPlan: customPlan,
    );
  }

  /// The next session in today's plan and how many items remain, or null
  /// when the plan is finished (or absent) — drives the "next" action on the
  /// session completion screen so the learner never detours via the hub.
  Future<({String route, int remaining})?> nextDailyPlanStep() async {
    final plan = await _cachedPlan();
    if (plan == null || plan.totalItems == 0 || plan.isRequiredPlanCompleted) {
      return null;
    }
    final location = await adultEntryLocation();
    if (!location.startsWith(AppRoutes.memorizationV2Session)) return null;
    return (
      route: location,
      remaining: plan.totalItems - plan.requiredCompletedCount,
    );
  }

  /// Resolves a V2 session URL for Hifz / practice-by-surah (B5).
  Future<String> practiceSurahSessionLocation(
    int surahId, {
    int? surahAyahCount,
    int? startAyah,
    int? ayahCount,
  }) async {
    final cachedPlan = await _cachedPlan();
    final reviewRecords = await _reviewRecords(ReviewRecordReadScope.adult);
    return _v2SessionLocation(
      surahId: surahId,
      intent: PendingAyahIntent.practiceSurah,
      cachedPlan: cachedPlan,
      reviewRecords: reviewRecords,
      surahAyahCount: surahAyahCount,
      explicitStartAyah: startAyah,
      explicitAyahCount: ayahCount,
      customPlan: await _customPlan(),
    );
  }

  Future<String> childOnboardingLocation() async {
    final profile = await _profile();
    if (profile?.isChild == true) {
      final surahId = await _activeKidsSurahId();
      return _kidsHomeLocation(surahId);
    }
    return '${AppRoutes.memorizationPlus}?preferred=kids';
  }

  Future<String> guardianLinkedLocation() async {
    final surahId = await _activeKidsSurahId();
    return _kidsJourneyLocation(surahId);
  }

  Future<String> parentDashboardLocation() async {
    return AppRoutes.familyDashboard;
  }

  Future<MemorizationProfile?> _profile() async {
    final result = await _repository.getMemorizationProfile();
    return result.fold((_) => null, (profile) => profile);
  }

  Future<int?> _activeAdultPlanSurahId([
    CustomMemorizationPlan? customPlan,
  ]) async {
    final plan = customPlan ?? await _customPlan();
    if (plan != null &&
        plan.isActive &&
        plan.targetUser == PlanTargetUser.adult) {
      final entrySurah = plan.startSurahId;
      if (_isValidSurahId(entrySurah)) return entrySurah;
    }

    return null;
  }

  Future<int?> _cachedPlanSurahId([
    CustomMemorizationPlan? customPlan,
    DailyPlan? cachedPlan,
  ]) async {
    final plan = cachedPlan ?? await _cachedPlan();
    final cachedSurahId = plan?.surahId;
    if (!_isValidSurahId(cachedSurahId)) return null;

    final activePlan = customPlan ?? await _customPlan();
    if (activePlan != null &&
        activePlan.isActive &&
        activePlan.targetUser == PlanTargetUser.adult) {
      final lo = activePlan.startSurahId <= activePlan.endSurahId
          ? activePlan.startSurahId
          : activePlan.endSurahId;
      final hi = activePlan.startSurahId <= activePlan.endSurahId
          ? activePlan.endSurahId
          : activePlan.startSurahId;
      final inRange = cachedSurahId! >= lo && cachedSurahId <= hi;
      if (!inRange) return null;
    }

    return cachedSurahId;
  }

  Future<int?> _reviewQuizSurahId(int? adultPlanSurahId) async {
    if (_isValidSurahId(adultPlanSurahId)) return adultPlanSurahId;

    final result = await GetLastReviewedSurahIdUseCase(_repository)(
      ReviewRecordReadScope.adult,
    );
    return result.fold((_) => null, (surahId) => surahId);
  }

  Future<int?> _activeKidsSurahId() async {
    // A due or weak kids review is always the next mission before adding new
    // memorization or reopening the latest journey position.
    final reviewRecords = await _reviewRecords(ReviewRecordReadScope.kids);
    final now = DateTime.now();
    final mandatorySurah = await _mandatoryKidsHouseSurah();
    if (mandatorySurah != null) return mandatorySurah;
    final dueReviews =
        reviewRecords
            .where(
              (record) =>
                  record.createdByMode == ReviewRecordCreatedByMode.kidsMode &&
                  KidsDueReviewPolicy.isDue(record, now),
            )
            .toList()
          ..sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
    // A spent review budget hands the day back to the journey, matching the
    // mission the home resolver will pick for this surah.
    if (dueReviews.isNotEmpty &&
        !(await _kidsDailyBudget(now)).dueReviewBudgetExhausted) {
      return dueReviews.first.surahId;
    }

    final logsResult = await _repository.getKidsSessionLogs();
    final logs = logsResult.fold((_) => <KidsSessionLog>[], (logs) {
      return logs.where((log) => _isValidSurahId(log.surahId)).toList()..sort(
        (a, b) => b.completedAt.toUtc().compareTo(a.completedAt.toUtc()),
      );
    });
    // The journey frontier is where the child last memorized something new.
    // A review of an older surah must not pull home back there (K17).
    for (final log in logs) {
      if (KidsSessionLogsCloudMerge.isCanonicalRewardLog(log)) {
        return log.surahId;
      }
    }
    if (logs.isNotEmpty) return logs.first.surahId;

    final customPlan = await _customPlan();
    // A plan start left over from another path (or an adult plan) is stale
    // (R10): only honour it when the active path contains it.
    final path = await _kidsJourneyPath();
    if (customPlan != null &&
        customPlan.isActive &&
        customPlan.targetUser == PlanTargetUser.child &&
        _isValidSurahId(customPlan.startSurahId) &&
        path.contains(customPlan.startSurahId)) {
      return customPlan.startSurahId;
    }

    final settingsResult = await _repository.getParentSettings();
    final configuredStart = settingsResult.fold(
      (_) => null,
      (settings) => settings.startingSurahId,
    );
    if (_isValidSurahId(configuredStart) && path.contains(configuredStart!)) {
      return configuredStart;
    }
    return path.surahIds.first;
  }

  /// The selected kids journey path; any failure means the adventure.
  Future<KidsJourneyPathDefinition> _kidsJourneyPath() async {
    try {
      final result = await _repository.getKidsJourneyPath();
      return result.getOrElse(() => KidsJourneyPathDefinition.adventure);
    } catch (_) {
      return KidsJourneyPathDefinition.adventure;
    }
  }

  /// The first started surah with a pending house review, if any.
  Future<int?> _mandatoryKidsHouseSurah() async {
    final profile = await _profile();
    if (profile?.isChild != true) return null;
    final logs = (await _repository.getKidsSessionLogs()).fold(
      (_) => <KidsSessionLog>[],
      (logs) => logs,
    );
    final started = logs
        .where(KidsSessionLogsCloudMerge.isCanonicalRewardLog)
        .map((log) => log.surahId)
        .toSet();
    final settings = (await _repository.getParentSettings()).fold(
      (_) => null,
      (settings) => settings,
    );
    final path = await _kidsJourneyPath();
    // The Quran journey locks nothing ahead, so a pending house review may sit
    // in any started surah: scan them all, with no starting-surah skip.
    final first = path.locksAhead
        ? KidsJourneyPath.surahIds.indexOf(
            settings?.startingSurahId ?? KidsJourneyPath.firstSurahId,
          )
        : 0;
    final candidates = [
      ...path.surahIds.skip(first < 0 ? 0 : first),
      // A house review left pending on the Quran journey still binds the
      // child after switching back to the adventure (R9). With no off-path
      // logs this adds nothing and the adventure is unchanged.
      if (path.locksAhead)
        ...(started.where((id) => !KidsJourneyPath.contains(id)).toList()
          ..sort()),
    ];
    for (final id in candidates) {
      if (!started.contains(id)) continue;
      final stages = (await _repository.getKidsJourney(
        surahId: id,
      )).fold((_) => null, (stages) => stages);
      if (stages == null) return id;
      if (stages.any(
        (stage) => stage.requiresHouseReview && stage.isUnlocked,
      )) {
        return id;
      }
    }
    return null;
  }

  /// Same age-band budget the home screen and session gate use; a log read
  /// failure is unlimited (fail-open).
  Future<KidsDailyBudget> _kidsDailyBudget(DateTime now) async {
    final logsResult = await _repository.getKidsSessionLogs();
    final logs = logsResult.fold((_) => null, (logs) => logs);
    if (logs == null) return KidsDailyBudget.unlimited;
    final profile = await _profile();
    return KidsDailyBudget.fromLogs(
      logs: logs,
      policy: KidsSessionPolicy.forChildAge(profile?.childAge),
      now: now,
    );
  }

  Future<DailyPlan?> _cachedPlan() async {
    final result = await _repository.getCachedDailyPlan();
    return result.fold((_) => null, (plan) => plan);
  }

  Future<List<AyahReviewRecord>> _reviewRecords(
    ReviewRecordReadScope scope,
  ) async {
    final result = await _repository.getAllReviewRecords(scope: scope);
    return result.fold((_) => <AyahReviewRecord>[], (records) => records);
  }

  Future<CustomMemorizationPlan?> _customPlan() async {
    final result = await _repository.getCustomPlan();
    return result.fold((_) => null, (plan) => plan);
  }

  String _v2SessionLocation({
    required int? surahId,
    required PendingAyahIntent intent,
    required DailyPlan? cachedPlan,
    required List<AyahReviewRecord> reviewRecords,
    int? surahAyahCount,
    int? explicitStartAyah,
    int? explicitAyahCount,
    CustomMemorizationPlan? customPlan,
  }) {
    if (!_isValidSurahId(surahId)) return AppRoutes.memorizationPlusCustomPlan;

    if (intent == PendingAyahIntent.continueDailyPlan &&
        cachedPlan != null &&
        cachedPlan.surahId == surahId &&
        cachedPlan.isRequiredPlanCompleted) {
      return AppRoutes.memorizationHub;
    }
    if (intent == PendingAyahIntent.continueDailyPlan &&
        customPlan != null &&
        customPlan.isActive &&
        customPlan.targetUser == PlanTargetUser.adult &&
        (cachedPlan == null ||
            cachedPlan.totalItems == 0 ||
            cachedPlan.isRequiredPlanCompleted)) {
      // A configured plan without a usable generated plan is a rest day,
      // completed range, or generation failure. Never invent a practice
      // session from the plan's difficulty settings.
      return AppRoutes.memorizationHub;
    }

    final target =
        intent == PendingAyahIntent.practiceSurah &&
            explicitStartAyah != null &&
            explicitAyahCount != null &&
            explicitStartAyah >= 1 &&
            explicitAyahCount >= 1
        ? PendingAyahTarget(
            surahId: surahId!,
            startAyah: explicitStartAyah,
            blockSize: explicitAyahCount,
            intent: PendingAyahIntent.practiceSurah,
          )
        : _pendingAyahResolver.resolve(
            PendingAyahResolverInput(
              surahId: surahId!,
              intent: intent,
              cachedDailyPlan: cachedPlan,
              reviewRecords: reviewRecords,
              surahAyahCount: surahAyahCount,
            ),
          );
    final launchContext = switch (intent) {
      // Same rule as [dailyPlanAyahLocation]: recall work on a reviewed ayah
      // is a review; launching it as memorize would re-teach known material.
      PendingAyahIntent.continueDailyPlan => LearningLaunchContext(
        ayah: AyahReference(
          surahId: target.surahId,
          ayahNumber: target.startAyah,
        ),
        intent: target.isReview
            ? LearningIntent.review
            : LearningIntent.memorize,
        origin: LearningOrigin.dailyPlan,
      ),
      PendingAyahIntent.reviewSession => LearningLaunchContext(
        ayah: AyahReference(
          surahId: target.surahId,
          ayahNumber: target.startAyah,
        ),
        intent: LearningIntent.review,
        origin: LearningOrigin.review,
      ),
      PendingAyahIntent.practiceSurah => LearningLaunchContext(
        ayah: AyahReference(
          surahId: target.surahId,
          ayahNumber: target.startAyah,
        ),
        intent: LearningIntent.memorize,
        origin: LearningOrigin.surahPractice,
      ),
    };

    // Practice blocks follow the plan's difficulty. Daily-plan memorization
    // instead uses every contiguous unfinished generated new ayah; reviews
    // retain their own passage picker in the session Cubit.
    final adultPlan =
        customPlan != null &&
            customPlan.isActive &&
            customPlan.targetUser == PlanTargetUser.adult
        ? customPlan
        : null;
    return Uri(
      path: AppRoutes.memorizationV2Session,
      queryParameters: {
        ...launchContext.toRouteQuery(),
        if (adultPlan != null &&
            launchContext.intent == LearningIntent.memorize)
          'blockSize':
              '${explicitAyahCount ?? PlanSchedulePolicy.fitToDailyPlan(PlanSchedulePolicy.blockSize(adultPlan), intent == PendingAyahIntent.continueDailyPlan ? cachedPlan : null, surahId: target.surahId, startAyah: target.startAyah)}',
        if (adultPlan == null && explicitAyahCount != null)
          'blockSize': '$explicitAyahCount',
      },
    ).toString();
  }

  static String _kidsHomeLocation(int? surahId) {
    if (!_isValidSurahId(surahId)) return AppRoutes.memorizationPlusKidsHome;
    return Uri(
      path: AppRoutes.memorizationPlusKidsHome,
      queryParameters: {'surahId': '$surahId'},
    ).toString();
  }

  static String _kidsJourneyLocation(int? surahId) {
    if (!_isValidSurahId(surahId)) return _kidsHomeLocation(null);
    return Uri(
      path: AppRoutes.memorizationPlusKidsJourney,
      queryParameters: {'surahId': '$surahId'},
    ).toString();
  }

  static bool _isValidSurahId(int? surahId) =>
      surahId != null && surahId >= 1 && surahId <= 114;

  static String kidsHomeFallbackLocation(int surahId) => _kidsHomeLocation(
    _isValidSurahId(surahId)
        ? surahId
        : KidsJourneyCursor.initial.activeSurahId,
  );

  /// Review session for one ayah (Listening Review weak links). Recall work
  /// on known material, so always a review — never re-teaching.
  static String reviewAyahLocation(int surahId, int ayahNumber) {
    final launchContext = LearningLaunchContext(
      ayah: AyahReference(surahId: surahId, ayahNumber: ayahNumber),
      intent: LearningIntent.review,
      origin: LearningOrigin.review,
    );
    return Uri(
      path: AppRoutes.memorizationV2Session,
      queryParameters: launchContext.toRouteQuery(),
    ).toString();
  }

  static String dailyPlanAyahLocation(DailyPlanAyah ayah, {int? blockSize}) {
    // Plan items with an existing record are recall work — launching them
    // as "memorize" would force the learner through listen/hint stages and
    // re-learn material they already know.
    final launchContext = LearningLaunchContext(
      ayah: AyahReference(surahId: ayah.surahId, ayahNumber: ayah.ayahNumber),
      intent: ayah.isNew ? LearningIntent.memorize : LearningIntent.review,
      origin: LearningOrigin.dailyPlan,
    );
    return Uri(
      path: AppRoutes.memorizationV2Session,
      queryParameters: {
        ...launchContext.toRouteQuery(),
        if (ayah.isNew && blockSize != null) 'blockSize': '$blockSize',
      },
    ).toString();
  }
}
