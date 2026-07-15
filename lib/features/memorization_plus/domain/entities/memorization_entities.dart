import 'package:equatable/equatable.dart';

import '../../../../core/memorization/review_classification.dart';
import '../../../../core/memorization/smart_coach_recommendation.dart';

export 'memorization_profile.dart';
export 'pairing_session.dart';
export 'smart_memorization_settings.dart';
export 'memorization_insights_report.dart';
export 'memorization_recommendation.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum MemorizationTrack { adults, kids }

enum PerformanceRating { excellent, average, weak }

enum KidsJourneyStageStatus { locked, current, completed, needsReview }

enum ParentRewardStatus { locked, unlocked, claimed }

enum PlanTargetUser { adult, child }

/// Identifies the originating write path for an [AyahReviewRecord].
///
/// Used to safely separate adult and kids memorization records that share the
/// same Isar collection.  New records receive an explicit tag at the write site;
/// records that existed before this field was introduced are treated as
/// [unknown] (their `createdByModeIndex` is `null` in Isar).
enum ReviewRecordCreatedByMode {
  /// Written by the Adult MemPlus path (V2 session or quiz flows).
  adultMemPlus,

  /// Written by Kids Gamified via the V2 session engine/review adapter.
  kidsMode,

  /// Reserved for future Hifz SRS integration.
  hifz,

  /// Written during SharedPreferences → Isar migration; source is ambiguous.
  migration,

  /// Existing records that predate source-metadata tagging.
  unknown,

  /// Created by a Memorization V2 session (MemorizationSessionCubit).
  /// Treated as adult-compatible for Smart Coach and Quiz filtering.
  v2Session,
}

// ─── Memorization Identity (Moved to separate files) ──────────

enum ReviewState {
  newCard,
  learning,
  review,
  relearning,
}

// ─── AyahReviewRecord ─────────────────────────────────────────────────────────

/// Enhanced per-ayah progress record used exclusively by MemorizationPlus.
/// Lives alongside existing [AyahProgress] without replacing it.
class AyahReviewRecord extends Equatable {
  const AyahReviewRecord({
    required this.surahId,
    required this.ayahNumber,
    required this.strengthLevel,
    required this.intervalDays,
    required this.lastReviewedAt,
    required this.nextReviewDate,
    required this.totalReviews,
    required this.lastRating,
    this.easeFactor = 2.5,
    this.lapses = 0,
    this.difficulty = 5.0,
    this.stability = 0.0,
    this.reviewState = ReviewState.newCard,
    this.createdByMode = ReviewRecordCreatedByMode.unknown,
    this.predictedRetrievability,
    this.predictedFsrsIntervalDays,
    this.predictedFsrsDueDate,
    this.predictedRecallProbability,
    this.schedulerVsFsrsGapDays,
    this.schedulerVsFsrsRatio,
    this.schedulerEarlierThanFsrs,
  });

  final int surahId;
  final int ayahNumber;

  /// 0 = new, 1–5 = weak→strong, 6+ = memorized
  final int strengthLevel;

  /// Current interval in days
  final int intervalDays;

  final DateTime lastReviewedAt;
  final DateTime nextReviewDate;
  final int totalReviews;
  final PerformanceRating? lastRating;

  /// SM-2 derived multiplier for the next interval
  final double easeFactor;

  /// Number of times this ayah was rated as weak after being reviewed
  final int lapses;

  /// FSRS: Current difficulty level
  final double difficulty;

  /// FSRS: Memory stability (in days)
  final double stability;

  /// FSRS: Current state of the card
  final ReviewState reviewState;

  /// Preparation for future leech detection (lapses >= 8)
  bool get isLeech => lapses >= 8;

  /// Source metadata added in Sprint 7B. Records written before this field
  /// was introduced default to [ReviewRecordCreatedByMode.unknown].
  final ReviewRecordCreatedByMode createdByMode;

  /// FSRS: Shadow predicted retrievability
  final double? predictedRetrievability;

  /// FSRS: Shadow predicted interval
  final int? predictedFsrsIntervalDays;

  /// FSRS: Shadow predicted next review date
  final DateTime? predictedFsrsDueDate;

  /// FSRS: Future shadow probability of recall
  final double? predictedRecallProbability;

  /// FSRS Analytics: Gap in days between FSRS predicted interval and Scheduler interval
  final int? schedulerVsFsrsGapDays;

  /// FSRS Analytics: Ratio of FSRS predicted interval to Scheduler interval
  final double? schedulerVsFsrsRatio;

  /// FSRS Analytics: True if Scheduler interval is strictly less than FSRS interval
  final bool? schedulerEarlierThanFsrs;

  ReviewClassification get reviewClassification =>
      const ReviewClassifier().classify(
        ReviewClassificationInput(
          now: DateTime.now().toUtc(),
          lastReviewedAt: lastReviewedAt,
          nextReviewDate: nextReviewDate,
          strengthLevel: strengthLevel,
          totalReviews: totalReviews,
        ),
      );

  bool get isDue => reviewClassification.isDue;
  bool get isNew => reviewClassification.isNew;
  bool get isMemorized => reviewClassification.isMemorized;
  bool get isMemorizedDue => reviewClassification.isMemorizedDue;
  bool get isVisibleForReview => reviewClassification.isVisibleForReview;

  /// Near revision: reviewed within last 5 days
  bool get isNearRevision => reviewClassification.isNearRevision;

  /// Far revision: reviewed more than 5 days ago
  bool get isFarRevision => reviewClassification.isFarRevision;

  String get key => '${surahId}_$ayahNumber';

  AyahReviewRecord copyWith({
    int? strengthLevel,
    int? intervalDays,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
    int? totalReviews,
    PerformanceRating? lastRating,
    double? easeFactor,
    int? lapses,
    double? difficulty,
    double? stability,
    ReviewState? reviewState,
    ReviewRecordCreatedByMode? createdByMode,
    double? predictedRetrievability,
    int? predictedFsrsIntervalDays,
    DateTime? predictedFsrsDueDate,
    double? predictedRecallProbability,
    int? schedulerVsFsrsGapDays,
    double? schedulerVsFsrsRatio,
    bool? schedulerEarlierThanFsrs,
  }) => AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel ?? this.strengthLevel,
    intervalDays: intervalDays ?? this.intervalDays,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    totalReviews: totalReviews ?? this.totalReviews,
    lastRating: lastRating ?? this.lastRating,
    easeFactor: easeFactor ?? this.easeFactor,
    lapses: lapses ?? this.lapses,
    difficulty: difficulty ?? this.difficulty,
    stability: stability ?? this.stability,
    reviewState: reviewState ?? this.reviewState,
    createdByMode: createdByMode ?? this.createdByMode,
    predictedRetrievability: predictedRetrievability ?? this.predictedRetrievability,
    predictedFsrsIntervalDays: predictedFsrsIntervalDays ?? this.predictedFsrsIntervalDays,
    predictedFsrsDueDate: predictedFsrsDueDate ?? this.predictedFsrsDueDate,
    predictedRecallProbability: predictedRecallProbability ?? this.predictedRecallProbability,
    schedulerVsFsrsGapDays: schedulerVsFsrsGapDays ?? this.schedulerVsFsrsGapDays,
    schedulerVsFsrsRatio: schedulerVsFsrsRatio ?? this.schedulerVsFsrsRatio,
    schedulerEarlierThanFsrs: schedulerEarlierThanFsrs ?? this.schedulerEarlierThanFsrs,
  );

  @override
  List<Object?> get props => [
    surahId,
    ayahNumber,
    strengthLevel,
    intervalDays,
    nextReviewDate,
    totalReviews,
    lastRating,
    easeFactor,
    lapses,
    difficulty,
    stability,
    reviewState,
    createdByMode,
    predictedRetrievability,
    predictedFsrsIntervalDays,
    predictedFsrsDueDate,
    predictedRecallProbability,
    schedulerVsFsrsGapDays,
    schedulerVsFsrsRatio,
    schedulerEarlierThanFsrs,
  ];
}

// ─── DailyPlan ────────────────────────────────────────────────────────────────

class DailyPlanAyah extends Equatable {
  const DailyPlanAyah({
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
    required this.record,
  });

  final int surahId;
  final int ayahNumber;
  final String ayahText;
  final AyahReviewRecord? record;

  bool get isNew => record == null || record!.isNew;

  @override
  List<Object?> get props => [surahId, ayahNumber, ayahText];
}

class DailyPlan extends Equatable {
  const DailyPlan({
    required this.generatedAt,
    required this.surahId,
    required this.newAyahs,
    required this.nearRevision,
    required this.farRevision,
    required this.completedAyahNums,
    this.retentionReview = const [],
  });

  final DateTime generatedAt;
  final int surahId;
  final List<DailyPlanAyah> newAyahs;
  final List<DailyPlanAyah> nearRevision;
  final List<DailyPlanAyah> farRevision;
  final List<int> completedAyahNums;

  /// Optional memorized-due retention items (Sprint 10B). Not part of required
  /// daily workload.
  final List<DailyPlanAyah> retentionReview;

  int get totalItems =>
      newAyahs.length + nearRevision.length + farRevision.length;

  // ── Required-only progress helpers (P0 hotfix: retention must not count) ──

  /// All ayahs that are part of the required daily workload (new + revisions).
  List<DailyPlanAyah> get requiredAyahs => [
    ...newAyahs,
    ...nearRevision,
    ...farRevision,
  ];

  /// Composite identity keys for required ayahs. Uses `surahId:ayahNumber`
  /// to remain correct if multiple surahs ever share a plan.
  Set<String> get _requiredAyahKeys =>
      requiredAyahs.map((a) => '${a.surahId}:${a.ayahNumber}').toSet();

  /// Returns how many required ayahs have been completed.
  /// Retention completions are excluded.
  int get requiredCompletedCount => completedAyahNums
      .where((n) => _requiredAyahKeys.contains('$surahId:$n'))
      .length;

  /// Required plan progress in [0.0, 1.0]. Always 0 when there are no
  /// required items (retention-only day).
  double get requiredProgress =>
      totalItems == 0 ? 0 : requiredCompletedCount / totalItems;

  /// True when all required items are completed. Never true for a
  /// retention-only day (totalItems == 0).
  bool get isRequiredPlanCompleted =>
      totalItems > 0 && requiredCompletedCount >= totalItems;

  // ── Legacy aliases (kept for retention visual-check compatibility) ──────

  /// Total completed ayahs including optional retention completions.
  /// Do NOT use for required-plan progress or completion gating.
  int get completedCount => completedAyahNums.length;

  /// Overall progress including optional retention.
  /// Do NOT use for required-plan progress display.
  double get progress =>
      totalItems == 0 ? 0 : requiredCompletedCount / totalItems;

  bool get hasRetentionReview => retentionReview.isNotEmpty;

  int get optionalRetentionCount => retentionReview.length;

  int get completedRetentionCount => retentionReview
      .where((ayah) => completedAyahNums.contains(ayah.ayahNumber))
      .length;

  bool isCompleted(int ayahNumber) => completedAyahNums.contains(ayahNumber);

  DailyPlan withCompleted(int ayahNumber) {
    if (completedAyahNums.contains(ayahNumber)) return this;
    return DailyPlan(
      generatedAt: generatedAt,
      surahId: surahId,
      newAyahs: newAyahs,
      nearRevision: nearRevision,
      farRevision: farRevision,
      completedAyahNums: [...completedAyahNums, ayahNumber],
      retentionReview: retentionReview,
    );
  }

  @override
  List<Object?> get props => [
    generatedAt,
    surahId,
    newAyahs,
    nearRevision,
    farRevision,
    completedAyahNums,
    retentionReview,
  ];
}

// ─── KidsProgress ─────────────────────────────────────────────────────────────
//
// Gamification aggregate for the Kids path (points, level, stars, session timing).
//
// **Streak** — [currentStreak] is *not* owned here. It is hydrated at read time
// from [StreakService] (Isar `streakIsars`). Kids sessions call
// [StreakService.recordActivity] in [KidsModeCubit]; never increment streak in
// [addPoints].
//
// **Memorization** — cumulative ayah counts for certificates and parent
// metrics come from Isar review records tagged `kidsMode`
// ([ReviewRecordFilters.isKidsSource]). Journey stage visuals come from
// [KidsSessionLog] entries in SharedPreferences.

class KidsProgress extends Equatable {
  const KidsProgress({
    required this.totalPoints,
    required this.currentLevel,
    required this.currentStreak,
    required this.starsEarned,
    required this.ayahsCompleted,
    required this.lastSessionAt,
  });

  const KidsProgress.initial()
    : totalPoints = 0,
      currentLevel = 1,
      currentStreak = 0,
      starsEarned = 0,
      ayahsCompleted = 0,
      lastSessionAt = null;

  final int totalPoints;
  final int currentLevel;
  final int currentStreak;
  final int starsEarned;
  final int ayahsCompleted;
  final DateTime? lastSessionAt;

  /// Points needed to reach next level (exponential growth)
  int get pointsForNextLevel => currentLevel * 100;

  /// Points earned in current level
  int get pointsInCurrentLevel {
    int spent = 0;
    for (int i = 1; i < currentLevel; i++) {
      spent += i * 100;
    }
    return totalPoints - spent;
  }

  double get levelProgress => pointsInCurrentLevel / pointsForNextLevel;

  int get starsForLevel => switch (currentLevel) {
    <= 3 => 1,
    <= 7 => 2,
    _ => 3,
  };

  KidsProgress copyWith({
    int? totalPoints,
    int? currentLevel,
    int? currentStreak,
    int? starsEarned,
    int? ayahsCompleted,
    DateTime? lastSessionAt,
  }) {
    return KidsProgress(
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      starsEarned: starsEarned ?? this.starsEarned,
      ayahsCompleted: ayahsCompleted ?? this.ayahsCompleted,
      lastSessionAt: lastSessionAt ?? this.lastSessionAt,
    );
  }

  KidsProgress addPoints(int points) {
    final newTotal = totalPoints + points;
    int level = currentLevel;
    int needed = level * 100;
    int spent = 0;
    for (int i = 1; i < level; i++) {
      spent += i * 100;
    }
    while (newTotal - spent >= needed) {
      spent += needed;
      level++;
      needed = level * 100;
    }

    final now = DateTime.now().toUtc();

    return KidsProgress(
      totalPoints: newTotal,
      currentLevel: level,
      currentStreak: currentStreak,
      starsEarned: starsEarned + _starsForRating(),
      ayahsCompleted: ayahsCompleted + 1,
      lastSessionAt: now,
    );
  }

  int _starsForRating() => 1; // base, can be extended

  KidsProgress withStar() => KidsProgress(
    totalPoints: totalPoints,
    currentLevel: currentLevel,
    currentStreak: currentStreak,
    starsEarned: starsEarned + 1,
    ayahsCompleted: ayahsCompleted,
    lastSessionAt: lastSessionAt,
  );

  @override
  List<Object?> get props => [
    totalPoints,
    currentLevel,
    currentStreak,
    starsEarned,
    ayahsCompleted,
  ];
}

class KidsCompletionResult extends Equatable {
  const KidsCompletionResult({
    required this.progress,
    required this.pointsEarned,
    required this.starsEarned,
    required this.alreadyCompleted,
  });

  final KidsProgress progress;
  final int pointsEarned;
  final int starsEarned;
  final bool alreadyCompleted;

  @override
  List<Object?> get props => [
    progress,
    pointsEarned,
    starsEarned,
    alreadyCompleted,
  ];
}

class KidsJourneyStage extends Equatable {
  const KidsJourneyStage({
    required this.stageNumber,
    required this.surahId,
    required this.startAyah,
    required this.endAyah,
    required this.completedAyahs,
    required this.status,
  });

  final int stageNumber;
  final int surahId;
  final int startAyah;
  final int endAyah;
  final List<int> completedAyahs;
  final KidsJourneyStageStatus status;

  int get totalAyahs => endAyah - startAyah + 1;
  int get completedCount => completedAyahs.length;
  double get progress => totalAyahs <= 0 ? 0 : completedCount / totalAyahs;
  bool get isUnlocked => status != KidsJourneyStageStatus.locked;

  /// The next ayah to start memorizing. If all ayahs are completed,
  /// returns [startAyah] to allow reviewing from the beginning.
  int get nextAyahToStart => completedAyahs.length >= totalAyahs
      ? startAyah
      : startAyah + completedAyahs.length;

  @override
  List<Object?> get props => [
    stageNumber,
    surahId,
    startAyah,
    endAyah,
    completedAyahs,
    status,
  ];
}

class KidsSessionLog extends Equatable {
  const KidsSessionLog({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.repeatsCompleted,
    required this.pointsEarned,
    required this.completedAt,
    this.syncedAt,
  });

  final String id;
  final int surahId;
  final int ayahNumber;
  final int repeatsCompleted;
  final int pointsEarned;
  final DateTime completedAt;
  final DateTime? syncedAt;

  bool get isSynced => syncedAt != null;

  KidsSessionLog copyWith({DateTime? syncedAt}) => KidsSessionLog(
    id: id,
    surahId: surahId,
    ayahNumber: ayahNumber,
    repeatsCompleted: repeatsCompleted,
    pointsEarned: pointsEarned,
    completedAt: completedAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );

  @override
  List<Object?> get props => [
    id,
    surahId,
    ayahNumber,
    repeatsCompleted,
    pointsEarned,
    completedAt,
    syncedAt,
  ];
}

class ParentSettings extends Equatable {
  const ParentSettings({
    this.pinHash,
    this.reminderEnabled = true,
    this.reminderHour = 18,
    this.reminderMinute = 30,
    this.weeklyGoalSessions = 5,
    this.remoteLinkEnabled = false,
    this.localChildNickname,
  });

  final String? pinHash;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int weeklyGoalSessions;
  final bool remoteLinkEnabled;

  /// Optional nickname for the local child on this device.
  final String? localChildNickname;

  bool get hasPin => pinHash != null && pinHash!.isNotEmpty;

  ParentSettings copyWith({
    String? pinHash,
    bool clearPin = false,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? weeklyGoalSessions,
    bool? remoteLinkEnabled,
    String? localChildNickname,
  }) => ParentSettings(
    pinHash: clearPin ? null : (pinHash ?? this.pinHash),
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    weeklyGoalSessions: weeklyGoalSessions ?? this.weeklyGoalSessions,
    remoteLinkEnabled: remoteLinkEnabled ?? this.remoteLinkEnabled,
    localChildNickname: localChildNickname ?? this.localChildNickname,
  );

  @override
  List<Object?> get props => [
    pinHash,
    reminderEnabled,
    reminderHour,
    reminderMinute,
    weeklyGoalSessions,
    remoteLinkEnabled,
    localChildNickname,
  ];
}

class ParentReward extends Equatable {
  const ParentReward({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.unlockedAt,
    this.claimedAt,
  });

  final String id;
  final String title;
  final ParentRewardStatus status;
  final DateTime createdAt;
  final DateTime? unlockedAt;
  final DateTime? claimedAt;

  ParentReward copyWith({
    String? title,
    ParentRewardStatus? status,
    DateTime? unlockedAt,
    DateTime? claimedAt,
  }) => ParentReward(
    id: id,
    title: title ?? this.title,
    status: status ?? this.status,
    createdAt: createdAt,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    claimedAt: claimedAt ?? this.claimedAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    status,
    createdAt,
    unlockedAt,
    claimedAt,
  ];
}

class ParentDashboard extends Equatable {
  const ParentDashboard({
    required this.progress,
    required this.stages,
    required this.logs,
    required this.rewards,
    required this.settings,
  });

  final KidsProgress progress;
  final List<KidsJourneyStage> stages;
  final List<KidsSessionLog> logs;
  final List<ParentReward> rewards;
  final ParentSettings settings;

  int get weeklyCompletedSessions {
    final now = DateTime.now().toUtc();
    final weekStart = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return logs
        .where((log) => !log.completedAt.toUtc().isBefore(weekStart))
        .length;
  }

  @override
  List<Object?> get props => [progress, stages, logs, rewards, settings];
}

class RemoteChildSummary extends Equatable {
  const RemoteChildSummary({
    required this.childUserId,
    required this.displayName,
    required this.progress,
    required this.logs,
    required this.rewards,
    this.production,
  });

  final String childUserId;
  final String displayName;
  final KidsProgress progress;
  final List<KidsSessionLog> logs;
  final List<ParentReward> rewards;

  /// Additive Phase 7 production-sync summary (V2 SRS, daily plan,
  /// certificates, streak, heatmap, Smart Coach). Null when the cloud rows
  /// could not be read (e.g. RLS not yet applied, or child never synced).
  final RemoteChildProductionSummary? production;

  @override
  List<Object?> get props => [
    childUserId,
    displayName,
    progress,
    logs,
    rewards,
    production,
  ];
}

/// A single certificate earned by a linked child, as mirrored to
/// `certificate_awards_cloud`.
class RemoteCertificateAward extends Equatable {
  const RemoteCertificateAward({
    required this.certId,
    required this.titleAr,
    required this.certType,
    required this.earnedAt,
  });

  final String certId;
  final String titleAr;
  final String certType;
  final DateTime earnedAt;

  @override
  List<Object?> get props => [certId, titleAr, certType, earnedAt];
}

/// Aggregated production-state summary for a linked child, reconstructed on
/// the parent device from the Phase 7 cloud sync tables
/// (`ayah_review_records_cloud`, `daily_plans_cloud`,
/// `certificate_awards_cloud`, `streaks`, `daily_activities`).
///
/// This is purely a read-side reconstruction: the underlying classification
/// (`ReviewClassification`) and recommendation (`SmartCoachEngine`) logic is
/// reused as-is, fed by these synced rows — no second engine is introduced.
class RemoteChildProductionSummary extends Equatable {
  const RemoteChildProductionSummary({
    required this.totalMemorizedAyahs,
    required this.totalAyahsTracked,
    required this.completionPercent,
    this.currentSurahId,
    this.lastMemorizedSurahId,
    this.lastMemorizedAyahNumber,
    this.lastMemorizedAt,
    required this.reviewsCompleted,
    required this.reviewsOverdue,
    this.nextReviewAt,
    this.dailyPlanSurahId,
    required this.dailyPlanTotal,
    required this.dailyPlanCompleted,
    this.currentStreak,
    this.longestStreak,
    required this.activeDaysLast30,
    this.certificates = const [],
    this.smartCoachKind,
  });

  final int totalMemorizedAyahs;
  final int totalAyahsTracked;
  final double completionPercent;
  final int? currentSurahId;
  final int? lastMemorizedSurahId;
  final int? lastMemorizedAyahNumber;
  final DateTime? lastMemorizedAt;
  final int reviewsCompleted;
  final int reviewsOverdue;
  final DateTime? nextReviewAt;
  final int? dailyPlanSurahId;
  final int dailyPlanTotal;
  final int dailyPlanCompleted;
  final int? currentStreak;
  final int? longestStreak;

  /// Number of distinct UTC calendar days with recorded activity in the
  /// trailing 30-day window (lightweight heatmap summary).
  final int activeDaysLast30;
  final List<RemoteCertificateAward> certificates;

  /// Learning-status label source; `null` when no recommendation applies.
  final SmartCoachRecommendationKind? smartCoachKind;

  int get dailyPlanRemaining =>
      (dailyPlanTotal - dailyPlanCompleted).clamp(0, dailyPlanTotal);

  @override
  List<Object?> get props => [
    totalMemorizedAyahs,
    totalAyahsTracked,
    completionPercent,
    currentSurahId,
    lastMemorizedSurahId,
    lastMemorizedAyahNumber,
    lastMemorizedAt,
    reviewsCompleted,
    reviewsOverdue,
    nextReviewAt,
    dailyPlanSurahId,
    dailyPlanTotal,
    dailyPlanCompleted,
    currentStreak,
    longestStreak,
    activeDaysLast30,
    certificates,
    smartCoachKind,
  ];
}

// ─── CustomMemorizationPlan ───────────────────────────────────────────────────

/// Difficulty level affects the spaced repetition multiplier.
enum MemorizationDifficulty { easy, moderate, challenging }

/// A user-defined memorization plan with all scheduling parameters.
class CustomMemorizationPlan extends Equatable {
  const CustomMemorizationPlan({
    required this.name,
    required this.startSurahId,
    required this.endSurahId,
    required this.newAyahsPerDay,
    required this.availableDaysPerWeek,
    required this.sessionMinutes,
    required this.difficulty,
    required this.enableNearRevision,
    required this.enableFarRevision,
    required this.nearRevisionCount,
    required this.farRevisionCount,
    required this.startAyah,
    required this.createdAt,
    this.isActive = true,
    this.targetUser = PlanTargetUser.adult,
  });

  /// User-given plan name, e.g. "خطتي لحفظ جزء عمّ"
  final String name;

  /// Surah range (inclusive)
  final int startSurahId;
  final int endSurahId;

  /// Starting ayah inside [startSurahId] (1-based)
  final int startAyah;

  /// How many new ayahs to introduce each session
  final int newAyahsPerDay;

  /// How many days per week the user can dedicate
  final int availableDaysPerWeek;

  /// Ideal session duration in minutes
  final int sessionMinutes;

  /// Affects review interval multiplier
  final MemorizationDifficulty difficulty;

  /// Whether to include near-revision and far-revision sections
  final bool enableNearRevision;
  final bool enableFarRevision;

  /// Max ayahs to include in each revision section
  final int nearRevisionCount;
  final int farRevisionCount;

  final DateTime createdAt;
  final bool isActive;
  final PlanTargetUser targetUser;

  bool get isForChild => targetUser == PlanTargetUser.child;

  /// Estimated days to finish based on **actual** surah ayah counts.
  /// Works for both ascending (startSurahId < endSurahId) and descending plans.
  int get estimatedDays {
    int totalAyahs = 0;
    final lo = startSurahId <= endSurahId ? startSurahId : endSurahId;
    final hi = startSurahId <= endSurahId ? endSurahId : startSurahId;
    for (int s = lo; s <= hi; s++) {
      totalAyahs += _surahAyahCounts[s] ?? 20;
    }
    // Subtract ayahs before startAyah in the first memorized surah (startSurahId)
    if (startAyah > 1) {
      totalAyahs -= (startAyah - 1);
    }
    if (newAyahsPerDay == 0) return 0;
    final sessionsNeeded = (totalAyahs / newAyahsPerDay).ceil();
    return (sessionsNeeded / (availableDaysPerWeek / 7.0)).ceil();
  }

  // RISK-4 FIX: actual ayah counts for all 114 surahs
  static const Map<int, int> _surahAyahCounts = {
    1: 7,
    2: 286,
    3: 200,
    4: 176,
    5: 120,
    6: 165,
    7: 206,
    8: 75,
    9: 129,
    10: 109,
    11: 123,
    12: 111,
    13: 43,
    14: 52,
    15: 99,
    16: 128,
    17: 111,
    18: 110,
    19: 98,
    20: 135,
    21: 112,
    22: 78,
    23: 118,
    24: 64,
    25: 77,
    26: 227,
    27: 93,
    28: 88,
    29: 69,
    30: 60,
    31: 34,
    32: 30,
    33: 73,
    34: 54,
    35: 45,
    36: 83,
    37: 182,
    38: 88,
    39: 75,
    40: 85,
    41: 54,
    42: 53,
    43: 89,
    44: 59,
    45: 37,
    46: 35,
    47: 38,
    48: 29,
    49: 18,
    50: 45,
    51: 60,
    52: 49,
    53: 62,
    54: 55,
    55: 78,
    56: 96,
    57: 29,
    58: 22,
    59: 24,
    60: 13,
    61: 14,
    62: 11,
    63: 11,
    64: 18,
    65: 12,
    66: 12,
    67: 30,
    68: 52,
    69: 52,
    70: 44,
    71: 28,
    72: 28,
    73: 20,
    74: 56,
    75: 40,
    76: 31,
    77: 50,
    78: 40,
    79: 46,
    80: 42,
    81: 29,
    82: 19,
    83: 36,
    84: 25,
    85: 22,
    86: 17,
    87: 19,
    88: 26,
    89: 30,
    90: 20,
    91: 15,
    92: 21,
    93: 11,
    94: 8,
    95: 8,
    96: 19,
    97: 5,
    98: 8,
    99: 8,
    100: 11,
    101: 11,
    102: 8,
    103: 3,
    104: 9,
    105: 5,
    106: 4,
    107: 7,
    108: 3,
    109: 6,
    110: 3,
    111: 5,
    112: 4,
    113: 5,
    114: 6,
  };

  CustomMemorizationPlan copyWith({
    String? name,
    int? startSurahId,
    int? endSurahId,
    int? newAyahsPerDay,
    int? availableDaysPerWeek,
    int? sessionMinutes,
    MemorizationDifficulty? difficulty,
    bool? enableNearRevision,
    bool? enableFarRevision,
    int? nearRevisionCount,
    int? farRevisionCount,
    int? startAyah,
    DateTime? createdAt,
    bool? isActive,
    PlanTargetUser? targetUser,
  }) => CustomMemorizationPlan(
    name: name ?? this.name,
    startSurahId: startSurahId ?? this.startSurahId,
    endSurahId: endSurahId ?? this.endSurahId,
    newAyahsPerDay: newAyahsPerDay ?? this.newAyahsPerDay,
    availableDaysPerWeek: availableDaysPerWeek ?? this.availableDaysPerWeek,
    sessionMinutes: sessionMinutes ?? this.sessionMinutes,
    difficulty: difficulty ?? this.difficulty,
    enableNearRevision: enableNearRevision ?? this.enableNearRevision,
    enableFarRevision: enableFarRevision ?? this.enableFarRevision,
    nearRevisionCount: nearRevisionCount ?? this.nearRevisionCount,
    farRevisionCount: farRevisionCount ?? this.farRevisionCount,
    startAyah: startAyah ?? this.startAyah,
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
    targetUser: targetUser ?? this.targetUser,
  );

  @override
  List<Object?> get props => [
    name,
    startSurahId,
    endSurahId,
    newAyahsPerDay,
    availableDaysPerWeek,
    sessionMinutes,
    difficulty,
    enableNearRevision,
    enableFarRevision,
    nearRevisionCount,
    farRevisionCount,
    startAyah,
    createdAt,
    isActive,
    targetUser,
  ];
}

// ─── FamilyChildEntry ─────────────────────────────────────────────────────────

/// Represents a single child entry in the Family Dashboard.
/// Can be either a local child (same device) or a remote child (linked via QR).
class FamilyChildEntry extends Equatable {
  const FamilyChildEntry({
    required this.childUserId,
    required this.displayName,
    this.avatarEmoji,
    required this.isLocal,
    this.localData,
    this.remoteSummary,
  });

  final String childUserId;
  final String displayName;

  /// Optional emoji avatar chosen by parent. Defaults shown in UI.
  final String? avatarEmoji;

  /// True when this child uses the same physical device as the parent.
  final bool isLocal;

  /// Non-null for local children — data read from Isar / SharedPrefs.
  final ParentDashboard? localData;

  /// Non-null for remote children — data read from Supabase.
  final RemoteChildSummary? remoteSummary;

  /// Points earned today (all sessions since UTC midnight).
  int get todayPoints {
    final today = DateTime.now().toUtc();
    final todayStart = DateTime.utc(today.year, today.month, today.day);
    if (isLocal) {
      return localData?.logs
              .where((l) => !l.completedAt.toUtc().isBefore(todayStart))
              .fold<int>(0, (s, l) => s + l.pointsEarned) ??
          0;
    }
    return remoteSummary?.logs
            .where((l) => !l.completedAt.toUtc().isBefore(todayStart))
            .fold<int>(0, (s, l) => s + l.pointsEarned) ??
        0;
  }

  /// Sessions completed today.
  int get todaySessions {
    final today = DateTime.now().toUtc();
    final todayStart = DateTime.utc(today.year, today.month, today.day);
    if (isLocal) {
      return localData?.logs
              .where((l) => !l.completedAt.toUtc().isBefore(todayStart))
              .length ??
          0;
    }
    return remoteSummary?.logs
            .where((l) => !l.completedAt.toUtc().isBefore(todayStart))
            .length ??
        0;
  }

  /// Current streak (days in a row).
  int get currentStreak =>
      isLocal
          ? (localData?.progress.currentStreak ?? 0)
          : (remoteSummary?.progress.currentStreak ?? 0);

  /// Current level.
  int get currentLevel =>
      isLocal
          ? (localData?.progress.currentLevel ?? 1)
          : (remoteSummary?.progress.currentLevel ?? 1);

  /// Stars earned.
  int get starsEarned =>
      isLocal
          ? (localData?.progress.starsEarned ?? 0)
          : (remoteSummary?.progress.starsEarned ?? 0);

  /// Level progress ratio [0.0, 1.0].
  double get levelProgress =>
      isLocal
          ? (localData?.progress.levelProgress ?? 0.0)
          : (remoteSummary?.progress.levelProgress ?? 0.0);

  /// Whether the child had any activity today.
  bool get isActiveToday => todaySessions > 0;

  @override
  List<Object?> get props =>
      [childUserId, displayName, isLocal, localData, remoteSummary];
}

// ─── FamilyDashboard ──────────────────────────────────────────────────────────

/// Unified family view: all children linked to a parent, plus parent settings.
class FamilyDashboard extends Equatable {
  const FamilyDashboard({
    required this.children,
    required this.settings,
  });

  final List<FamilyChildEntry> children;
  final ParentSettings settings;

  bool get hasAnyChild => children.isNotEmpty;

  /// Count of children who had at least one session today.
  int get totalActiveToday =>
      children.where((c) => c.isActiveToday).length;

  /// Sum of all points earned today across all children.
  int get totalPointsToday =>
      children.fold<int>(0, (sum, c) => sum + c.todayPoints);

  @override
  List<Object?> get props => [children, settings];
}
