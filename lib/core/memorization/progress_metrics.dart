import 'package:equatable/equatable.dart';

/// Which population of records a [ProgressMetrics] snapshot describes.
///
/// Adult surfaces count [v2Session]/[hifz] records; kids surfaces count
/// [kidsMode] records; certificate eligibility counts all production sources
/// ([v2Session], [hifz], [kidsMode]). Adult and kids never mix in UI totals.
enum ProgressAudience { adult, kids, certificates }

/// Immutable, fully-computed progress snapshot.
///
/// This is the single value object every progress consumer reads from. It is
/// produced exclusively by `ProgressMetricsService.calculate()` — no widget,
/// cubit, or repository should recompute any of these numbers independently.
///
/// ## Metric definitions (authoritative)
/// - [startedAyahs]   : distinct ayahs with `totalReviews > 0`.
/// - [memorizedAyahs] : distinct ayahs with `strengthLevel >= 6` (true SRS memorized).
/// - [learningAyahs]  : `started && !memorized` (disjoint from memorized).
/// - [totalReviewEvents] : sum of `totalReviews` across counted records.
/// - [dueReviews]     : started ayahs currently due for review (`now >= nextReviewDate`).
/// - [overdueReviews] : started ayahs whose scheduled day is strictly in the past.
/// - [retentionRate]  : `memorizedAyahs / startedAyahs` (0 when nothing started).
class ProgressMetrics extends Equatable {
  const ProgressMetrics({
    required this.audience,
    required this.startedAyahs,
    required this.memorizedAyahs,
    required this.learningAyahs,
    required this.totalReviewEvents,
    required this.memorizedSurahs,
    required this.memorizedJuz,
    required this.dueReviews,
    required this.overdueReviews,
    required this.totalAyahs,
    required this.totalSurahs,
    required this.totalJuz,
    required this.readPagesCount,
    required this.totalQuranPages,
    required this.readAyahs,
    required this.readSurahs,
    required this.readJuz,
    required this.streakDays,
    this.memorizedKeys = const {},
    this.lastReviewedAt,
    this.lastMemorizedSurahId,
    this.lastMemorizedAyahNumber,
  });

  final ProgressAudience audience;

  /// Distinct `"surahId_ayahNumber"` keys for ayahs counted as memorized
  /// (`strengthLevel >= 6`) within this [audience]. Used by certificate
  /// eligibility checks without recomputing filters locally.
  final Set<String> memorizedKeys;

  // ── Memorization ──────────────────────────────────────────────────────────
  final int startedAyahs;
  final int memorizedAyahs;
  final int learningAyahs;
  final int totalReviewEvents;
  final int memorizedSurahs;
  final int memorizedJuz;

  // ── Review workload ───────────────────────────────────────────────────────
  final int dueReviews;
  final int overdueReviews;

  // ── Totals (denominators) ─────────────────────────────────────────────────
  final int totalAyahs;
  final int totalSurahs;
  final int totalJuz;

  // ── Reading ───────────────────────────────────────────────────────────────
  final int readPagesCount;
  final int totalQuranPages;
  final int readAyahs;
  final int readSurahs;
  final int readJuz;

  // ── Streak ────────────────────────────────────────────────────────────────
  final int streakDays;

  /// Most recent review timestamp among counted, started records.
  final DateTime? lastReviewedAt;

  /// Location of the most recently reviewed memorized ayah (`strength >= 6`).
  final int? lastMemorizedSurahId;
  final int? lastMemorizedAyahNumber;

  // ── Derived percentages / rates ───────────────────────────────────────────

  /// Memorization completion: memorized ayahs over the whole Quran.
  double get memorizationCompletionPercent =>
      totalAyahs == 0 ? 0 : (memorizedAyahs / totalAyahs).clamp(0.0, 1.0);

  /// Reading completion: confirmed read pages over the whole Quran.
  double get readingCompletionPercent => totalQuranPages == 0
      ? 0
      : (readPagesCount / totalQuranPages).clamp(0.0, 1.0);

  /// Share of started ayahs that reached full memorization.
  double get retentionRate =>
      startedAyahs == 0 ? 0 : (memorizedAyahs / startedAyahs).clamp(0.0, 1.0);

  double get memorizedSurahsPercent =>
      totalSurahs == 0 ? 0 : (memorizedSurahs / totalSurahs).clamp(0.0, 1.0);

  double get memorizedJuzPercent =>
      totalJuz == 0 ? 0 : (memorizedJuz / totalJuz).clamp(0.0, 1.0);

  static ProgressMetrics empty(ProgressAudience audience) => ProgressMetrics(
    audience: audience,
    startedAyahs: 0,
    memorizedAyahs: 0,
    learningAyahs: 0,
    totalReviewEvents: 0,
    memorizedSurahs: 0,
    memorizedJuz: 0,
    dueReviews: 0,
    overdueReviews: 0,
    totalAyahs: 0,
    totalSurahs: 0,
    totalJuz: 0,
    readPagesCount: 0,
    totalQuranPages: 0,
    readAyahs: 0,
    readSurahs: 0,
    readJuz: 0,
    streakDays: 0,
    memorizedKeys: const {},
    lastReviewedAt: null,
    lastMemorizedSurahId: null,
    lastMemorizedAyahNumber: null,
  );

  @override
  List<Object?> get props => [
    audience,
    startedAyahs,
    memorizedAyahs,
    learningAyahs,
    totalReviewEvents,
    memorizedSurahs,
    memorizedJuz,
    dueReviews,
    overdueReviews,
    totalAyahs,
    totalSurahs,
    totalJuz,
    readPagesCount,
    totalQuranPages,
    readAyahs,
    readSurahs,
    readJuz,
    streakDays,
    memorizedKeys,
    lastReviewedAt,
    lastMemorizedSurahId,
    lastMemorizedAyahNumber,
  ];
}
