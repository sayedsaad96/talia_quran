import 'package:equatable/equatable.dart';

import 'ayah_review_record.dart';

// ─── DailyPlan ────────────────────────────────────────────────────────────────

/// Display band for a plan item's retention strength. Computed in the domain
/// so presentation never compares raw review-record metrics.
enum DailyPlanStrengthBand { unscheduled, weak, learning, strong }

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

  DailyPlanStrengthBand get strengthBand {
    final strength = record?.strengthLevel;
    if (strength == null) return DailyPlanStrengthBand.unscheduled;
    if (strength <= 2) return DailyPlanStrengthBand.weak;
    if (strength <= 5) return DailyPlanStrengthBand.learning;
    return DailyPlanStrengthBand.strong;
  }

  /// Whole days until the next review, rounded up so an item due later today
  /// or tomorrow never reads as "in 0 days". Null when there is no record or
  /// the review is already due.
  int? daysUntilReview(DateTime nowUtc) {
    final next = record?.nextReviewDate;
    if (next == null || !next.isAfter(nowUtc)) return null;
    final days = (next.difference(nowUtc).inMinutes / Duration.minutesPerDay)
        .ceil();
    return days < 1 ? 1 : days;
  }

  @override
  List<Object?> get props => [surahId, ayahNumber, ayahText];
}

class DailyPlan extends Equatable {
  const DailyPlan({
    required this.generatedAt,
    required this.surahId,
    required this.newAyahs,
    this.weakRecovery = const [],
    required this.nearRevision,
    required this.farRevision,
    required this.completedAyahNums,
    this.retentionReview = const [],
    this.completedAyahKeys = const [],
    this.dueBacklogCount = 0,
    this.newMemorizationBlocked = false,
    this.isReviewDay = false,
  });

  final DateTime generatedAt;
  final int surahId;
  final List<DailyPlanAyah> newAyahs;

  /// Due ayahs with a lapse or a weak final assessment, scheduled before
  /// routine review buckets.
  final List<DailyPlanAyah> weakRecovery;
  final List<DailyPlanAyah> nearRevision;
  final List<DailyPlanAyah> farRevision;
  final List<int> completedAyahNums;

  /// Additive, composite completion identities for multi-surah review plans.
  /// Older cached plans only contain [completedAyahNums] and remain readable.
  final List<String> completedAyahKeys;

  /// Memorized-due retention items scheduled as required daily work.
  final List<DailyPlanAyah> retentionReview;

  /// Total due non-memorized ayahs behind today's plan — why new
  /// memorization may be withheld. 0 on legacy cached plans.
  final int dueBacklogCount;

  /// Set by the generator when the review backlog exceeded the daily
  /// capacity and new ayahs were withheld as a result. Surfaced so the UI
  /// can explain itself instead of showing an unexplained empty section.
  final bool newMemorizationBlocked;

  /// A rest day in the learner's weekly schedule: reviews only, no new ayahs.
  final bool isReviewDay;

  int get totalItems => requiredAyahs.length;

  // ── Required daily-workload progress helpers ───────────────────────────────

  /// All ayahs that are part of the required daily workload.
  ///
  /// Retention is deliberately required once scheduled: it prevents fresh
  /// memorization from masking already-due consolidation work.
  List<DailyPlanAyah> get requiredAyahs {
    final unique = <String, DailyPlanAyah>{};
    for (final ayah in [
      ...weakRecovery,
      ...nearRevision,
      ...farRevision,
      ...retentionReview,
      ...newAyahs,
    ]) {
      unique.putIfAbsent('${ayah.surahId}:${ayah.ayahNumber}', () => ayah);
    }
    return unique.values.toList(growable: false);
  }

  /// Returns how many required ayahs have been completed.
  int get requiredCompletedCount => requiredAyahs
      .where((ayah) => isAyahCompleted(ayah.surahId, ayah.ayahNumber))
      .length;

  /// Required plan progress in [0.0, 1.0].
  double get requiredProgress =>
      totalItems == 0 ? 0 : requiredCompletedCount / totalItems;

  /// True when all required items are completed.
  bool get isRequiredPlanCompleted =>
      totalItems > 0 && requiredCompletedCount >= totalItems;

  // ── Legacy aliases (kept for retention visual-check compatibility) ──────

  /// Total completed ayahs in the daily workload.
  int get completedCount => {
    ...completedAyahNums.map((ayah) => '$surahId:$ayah'),
    ...completedAyahKeys,
  }.length;

  /// Overall daily-workload progress.
  double get progress =>
      totalItems == 0 ? 0 : requiredCompletedCount / totalItems;

  bool get hasRetentionReview => retentionReview.isNotEmpty;

  /// Compatibility alias. Scheduled retention is now required work.
  int get optionalRetentionCount => retentionReview.length;

  int get completedRetentionCount => retentionReview
      .where((ayah) => isAyahCompleted(ayah.surahId, ayah.ayahNumber))
      .length;

  /// Legacy same-surah completion lookup.
  bool isCompleted(int ayahNumber) => isAyahCompleted(surahId, ayahNumber);

  bool isAyahCompleted(int ayahSurahId, int ayahNumber) {
    final key = '$ayahSurahId:$ayahNumber';
    return completedAyahKeys.contains(key) ||
        (ayahSurahId == surahId && completedAyahNums.contains(ayahNumber));
  }

  DailyPlan withCompleted(int ayahNumber, {int? ayahSurahId}) {
    final completedSurahId = ayahSurahId ?? surahId;
    if (isAyahCompleted(completedSurahId, ayahNumber)) return this;
    final key = '$completedSurahId:$ayahNumber';
    return DailyPlan(
      generatedAt: generatedAt,
      surahId: surahId,
      newAyahs: newAyahs,
      weakRecovery: weakRecovery,
      nearRevision: nearRevision,
      farRevision: farRevision,
      completedAyahNums: completedSurahId == surahId
          ? [...completedAyahNums, ayahNumber]
          : completedAyahNums,
      retentionReview: retentionReview,
      completedAyahKeys: [...completedAyahKeys, key],
      dueBacklogCount: dueBacklogCount,
      newMemorizationBlocked: newMemorizationBlocked,
      isReviewDay: isReviewDay,
    );
  }

  @override
  List<Object?> get props => [
    generatedAt,
    surahId,
    newAyahs,
    weakRecovery,
    nearRevision,
    farRevision,
    completedAyahNums,
    retentionReview,
    completedAyahKeys,
    dueBacklogCount,
    newMemorizationBlocked,
    isReviewDay,
  ];
}
