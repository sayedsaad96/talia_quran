import 'package:equatable/equatable.dart';

import 'ayah_review_record.dart';

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
    this.weakRecovery = const [],
    required this.nearRevision,
    required this.farRevision,
    required this.completedAyahNums,
    this.retentionReview = const [],
    this.completedAyahKeys = const [],
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

  int get totalItems => requiredAyahs.length;

  // ── Required daily-workload progress helpers ───────────────────────────────

  /// All ayahs that are part of the required daily workload.
  ///
  /// Retention is deliberately required once scheduled: it prevents fresh
  /// memorization from masking already-due consolidation work.
  List<DailyPlanAyah> get requiredAyahs {
    final unique = <String, DailyPlanAyah>{};
    for (final ayah in [
      ...newAyahs,
      ...weakRecovery,
      ...nearRevision,
      ...farRevision,
      ...retentionReview,
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
  ];
}
