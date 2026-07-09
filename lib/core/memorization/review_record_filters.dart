import '../../features/memorization_plus/domain/entities/memorization_entities.dart';

/// Source-aware filter predicates for [AyahReviewRecord].
///
/// Sprint 8B introduced these helpers to centralise source-policy decisions
/// so that each consumer applies a consistent, named, and tested policy
/// instead of scattering ad-hoc `.createdByMode` checks throughout the
/// codebase.
///
/// ## Source semantics (as of Sprint 7B / 8B)
///
/// | Mode          | Meaning                                                      |
/// |---------------|--------------------------------------------------------------|
/// | adultMemPlus  | Written by adult Daily Plan or adult Quiz.  Fully trusted.  |
/// | kidsMode      | Written by Kids Mode completion.  Excluded from adult SRS.  |
/// | hifz          | Repaired legacy Hifz imports. Adult-compatible.              |
/// | migration     | Migrated from SharedPreferences. Origin unknown. Kept for   |
/// |               | backward compatibility but not treated as trusted adult.    |
/// | unknown       | Pre-Sprint 7B records. Kept for backward compatibility.     |
///
/// ## Source semantics (V2 addition — Memorization V2)
///
/// | Mode          | Meaning                                                      |
/// |---------------|--------------------------------------------------------------|
/// | v2Session     | Written by MemorizationSessionCubit (Memorization V2).      |
/// |               | Adult-compatible — included in Smart Coach, Quiz, Progress. |
///
/// ## Usage
///
/// ```dart
/// // In SmartCoachEngine — Priority 4 memorized-due only:
/// final memorizedDue = records
///     .where((r) => r.reviewClassification.isMemorizedDue)
///     .where(ReviewRecordFilters.isAdultCompatible)
///     .toList();
///
/// // In QuizCubit — eligible records for adult quiz:
/// final surahRecords = records
///     .where((r) => r.surahId == surahId && r.totalReviews > 0)
///     .where(ReviewRecordFilters.isAdultCompatible)
///     .toList();
/// ```
///
/// ## Policy decisions NOT made here
///
/// * **AchievementService / certificates** — use [isCertificateEligibleSource]
///   (`v2Session`, `hifz`, and `kidsMode`).
/// * **NavigationResolver** — low-consequence fallback. Not filtered yet.
class ReviewRecordFilters {
  // Non-instantiable — pure static helpers.
  const ReviewRecordFilters._();

  // ── Source classification ─────────────────────────────────────────────────

  /// Returns `true` when the record originated from the Kids Mode path.
  ///
  /// These records must not influence adult SRS consumers such as Smart Coach
  /// memorized-due, adult Quiz eligibility, or adult Progress smart stats.
  static bool isKidsSource(AyahReviewRecord record) =>
      record.createdByMode == ReviewRecordCreatedByMode.kidsMode;

  /// Returns `true` when the record's origin cannot be trusted.
  ///
  /// Ambiguous sources:
  /// - [ReviewRecordCreatedByMode.unknown] — written before Sprint 7B source
  ///   tagging was introduced.
  /// - [ReviewRecordCreatedByMode.migration] — migrated from SharedPreferences;
  ///   original write path is permanently lost.
  ///
  /// Ambiguous records are excluded from adult production consumers via
  /// [isAdultProductionCount].
  static bool isAmbiguousSource(AyahReviewRecord record) =>
      record.createdByMode == ReviewRecordCreatedByMode.unknown ||
      record.createdByMode == ReviewRecordCreatedByMode.migration;

  /// Returns `true` when the record carries a trustworthy explicit source tag.
  ///
  /// Trusted sources: [ReviewRecordCreatedByMode.adultMemPlus],
  /// [ReviewRecordCreatedByMode.kidsMode], [ReviewRecordCreatedByMode.hifz],
  /// [ReviewRecordCreatedByMode.v2Session].
  ///
  /// Note that `kidsMode` is trusted in the sense that we know its origin,
  /// but it must still be excluded from adult consumers via [isAdultCompatible].
  static bool isTrustedSource(AyahReviewRecord record) =>
      record.createdByMode == ReviewRecordCreatedByMode.adultMemPlus ||
      record.createdByMode == ReviewRecordCreatedByMode.kidsMode ||
      record.createdByMode == ReviewRecordCreatedByMode.hifz ||
      record.createdByMode == ReviewRecordCreatedByMode.v2Session;

  // ── Adult consumer policies ───────────────────────────────────────────────

  /// Source policy for adult production records (`v2Session` and repaired `hifz`).
  ///
  /// Used by Progress counting, Smart Coach, Daily Plan, Quiz, and retention
  /// diagnostics. Excludes `kidsMode` so adult surfaces never mix child data.
  static bool isAdultProductionCount(AyahReviewRecord record) =>
      record.createdByMode == ReviewRecordCreatedByMode.v2Session ||
      record.createdByMode == ReviewRecordCreatedByMode.hifz;

  /// Returns `true` when the record is appropriate for adult MemPlus SRS
  /// consumers (Smart Coach, Quiz, Daily Plan near/far, Progress smart stats).
  ///
  /// Alias of [isAdultProductionCount] — adult V2 and repaired legacy Hifz only.
  static bool isAdultCompatible(AyahReviewRecord record) =>
      isAdultProductionCount(record);

  /// Returns `true` when the record is appropriate for adult retention review
  /// consumers.
  ///
  /// Identical to [isAdultCompatible]. The separate predicate exists so a
  /// future sprint can tighten retention independently if needed.
  static bool isAdultRetentionCompatible(AyahReviewRecord record) =>
      isAdultProductionCount(record);

  /// Returns `true` when the record is eligible for the Daily Plan retention
  /// bucket (Sprint 10B).
  ///
  /// Requires an adult production source ([isAdultProductionCount]) and
  /// [ReviewClassification.isMemorizedDue].
  static bool isDailyPlanRetentionEligible(AyahReviewRecord record) {
    return isAdultProductionCount(record) &&
        record.reviewClassification.isMemorizedDue;
  }

  // ── Metric predicates (Phase 0 — shared counting vocabulary) ───────────────
  //
  // These are time-independent classification helpers used by the unified
  // [ProgressMetricsService] and every counting consumer (Progress, Home,
  // AchievementService, Parent Dashboard). Centralising them here guarantees
  // that "memorized", "started", and "learning" mean the same thing everywhere.

  /// Returns `true` when the ayah is fully memorized by SRS semantics
  /// (`strengthLevel >= 6`). This is the single authoritative definition of
  /// "memorized" — it must match [ReviewClassification.isMemorized].
  static bool isMemorized(AyahReviewRecord record) => record.strengthLevel >= 6;

  /// Returns `true` when the ayah has been reviewed at least once
  /// (`totalReviews > 0`). Represents an ayah the user has *started*, which is
  /// a superset of [isMemorized]. Never present this as "memorized".
  static bool isStarted(AyahReviewRecord record) => record.totalReviews > 0;

  /// Returns `true` when the ayah is in progress: started but not yet memorized.
  /// Disjoint from [isMemorized] by construction.
  static bool isLearning(AyahReviewRecord record) =>
      isStarted(record) && !isMemorized(record);

  /// Source policy for device-wide certificate eligibility.
  ///
  /// Includes adult production sources plus [kidsMode] so children can earn
  /// certificates without polluting adult progress totals.
  static bool isCertificateEligibleSource(AyahReviewRecord record) =>
      isAdultProductionCount(record) || isKidsSource(record);

  /// Tie-breaker for memorized-due ordering (Smart Coach + Daily Plan).
  ///
  /// 1. oldest [AyahReviewRecord.nextReviewDate]
  /// 2. lowest [AyahReviewRecord.strengthLevel]
  /// 3. longest [AyahReviewRecord.intervalDays]
  /// 4. highest [AyahReviewRecord.totalReviews]
  static int compareMemorizedDue(AyahReviewRecord a, AyahReviewRecord b) {
    final dateCmp = a.nextReviewDate.compareTo(b.nextReviewDate);
    if (dateCmp != 0) return dateCmp;
    final strengthCmp = a.strengthLevel.compareTo(b.strengthLevel);
    if (strengthCmp != 0) return strengthCmp;
    final intervalCmp = b.intervalDays.compareTo(a.intervalDays);
    if (intervalCmp != 0) return intervalCmp;
    return b.totalReviews.compareTo(a.totalReviews);
  }
}
