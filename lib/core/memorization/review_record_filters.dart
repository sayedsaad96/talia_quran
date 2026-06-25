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
/// | hifz          | Reserved for future Hifz SRS. Not yet used in adult MemPlus.|
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
/// * **AchievementService** — Sprint 9B policy decision:
///   `AchievementService` intentionally does not use adult-compatible source
///   filtering. Certificates are shared/device-wide achievements. All
///   memorized sources may contribute: `adultMemPlus`, `kidsMode`,
///   `hifz`/Hifz progress, `migration`, and `unknown` legacy records.
///   Do not apply `ReviewRecordFilters` to `AchievementService` unless the
///   product policy changes.
/// * **Daily Plan near/far** — already safe because kidsMode records are
///   `isMemorized`, which near/far classification excludes. No filter needed.
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
  /// Ambiguous records are included in adult consumers for backward
  /// compatibility.  See [isAdultCompatible].
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

  /// Returns `true` when the record is appropriate for adult MemPlus SRS
  /// consumers (Smart Coach, Quiz, Progress smart stats).
  ///
  /// Included:
  /// - [ReviewRecordCreatedByMode.adultMemPlus] — trusted adult source.
  /// - [ReviewRecordCreatedByMode.unknown] — backward compatibility.
  /// - [ReviewRecordCreatedByMode.migration] — backward compatibility.
  ///
  /// Excluded:
  /// - [ReviewRecordCreatedByMode.kidsMode] — kids source; must not influence
  ///   adult recommendations or statistics.
  /// - [ReviewRecordCreatedByMode.hifz] — reserved for a separate Hifz SRS
  ///   surface; not part of adult MemPlus until explicitly designed.
  static bool isAdultCompatible(AyahReviewRecord record) =>
      record.createdByMode != ReviewRecordCreatedByMode.kidsMode &&
      record.createdByMode != ReviewRecordCreatedByMode.hifz;

  /// Returns `true` when the record is appropriate for adult retention review
  /// consumers.
  ///
  /// For Sprint 8B this is identical to [isAdultCompatible].  The separate
  /// predicate exists so that a future sprint can tighten the retention policy
  /// independently (e.g., excluding `migration` once enough data has
  /// self-healed) without touching the broader compatibility predicate.
  static bool isAdultRetentionCompatible(AyahReviewRecord record) =>
      record.createdByMode != ReviewRecordCreatedByMode.kidsMode &&
      record.createdByMode != ReviewRecordCreatedByMode.hifz;

  /// Returns `true` when the record is eligible for the Daily Plan retention
  /// bucket (Sprint 10B).
  ///
  /// Stricter than [isAdultCompatible]: only fully trusted adult MemPlus
  /// memorized-due records. Excludes `unknown`, `migration`, `kidsMode`, and
  /// `hifz`.
  ///
  /// Sprint 4.5: [ReviewRecordCreatedByMode.v2Session] is now included so
  /// that V2 adult memorization records appear in retention review — keeping
  /// Daily Plan consistent with Smart Coach, Progress, and AchievementService,
  /// which already treat `v2Session` as adult-compatible. The record must
  /// still be `isMemorizedDue`.
  static bool isDailyPlanRetentionEligible(AyahReviewRecord record) {
    // Source allowlist — explicit positive list, not a negative filter, so
    // any future mode defaults to excluded (fail-closed).
    switch (record.createdByMode) {
      case ReviewRecordCreatedByMode.adultMemPlus:
      case ReviewRecordCreatedByMode.v2Session:
        break;
      case ReviewRecordCreatedByMode.kidsMode:
      case ReviewRecordCreatedByMode.hifz:
      case ReviewRecordCreatedByMode.migration:
      case ReviewRecordCreatedByMode.unknown:
        return false;
    }
    return record.reviewClassification.isMemorizedDue;
  }

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
