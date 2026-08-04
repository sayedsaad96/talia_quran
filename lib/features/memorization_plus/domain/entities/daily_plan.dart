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
