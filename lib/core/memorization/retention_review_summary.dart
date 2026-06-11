import 'package:equatable/equatable.dart';

/// Read-only internal summary of memorized-due (retention-review) records.
///
/// ## Purpose
///
/// This value object answers measurement questions about the pool of ayahs
/// that have reached "memorized" status (strengthLevel ≥ 6) and whose
/// `nextReviewDate` is now in the past. It is used for internal diagnostics,
/// not for any user-facing Daily Plan or UI surface.
///
/// ## Boundary Safety Warning
///
/// [hasPotentialPathAmbiguity] is `true` whenever this summary is constructed
/// from records that may contain both adult- and kids-written entries.
///
/// **Root cause**: `KidsModeCubit.completeAyah()` calls `MarkAyahMemorizedUsecase`
/// which writes an `AyahReviewRecord` (strengthLevel ≥ 6, intervalDays ≥ 30)
/// into the **same Isar collection** as adult SRS records. The
/// `IsarAyahReviewRecord` schema has **no path/source field**, so there is no
/// reliable way to attribute a memorized record to the kids path or the adult
/// path without additional metadata.
///
/// Until source-metadata is added to the schema, any consumer of this summary
/// must treat the pool as **potentially mixed** and must not use it as input
/// for adult-only Daily Plan Retention Review buckets.
///
/// ## Non-changes
///
/// This class does **not**:
/// - write to any store
/// - modify any existing entity
/// - change Daily Plan generation behaviour
/// - change Smart Coach priority
class RetentionReviewSummary extends Equatable {
  const RetentionReviewSummary({
    required this.totalDue,
    required this.affectedSurahCount,
    required this.hasPotentialPathAmbiguity,
    this.oldestDueAt,
    this.weakestStrengthLevel,
  });

  /// Convenience constructor for the empty-store case.
  const RetentionReviewSummary.empty()
    : totalDue = 0,
      affectedSurahCount = 0,
      hasPotentialPathAmbiguity = false,
      oldestDueAt = null,
      weakestStrengthLevel = null;

  /// Total number of memorized ayahs whose `nextReviewDate` is in the past.
  final int totalDue;

  /// Number of distinct surahs that have at least one memorized-due ayah.
  final int affectedSurahCount;

  /// Earliest `nextReviewDate` across all memorized-due records, or `null`
  /// when [totalDue] is zero.
  final DateTime? oldestDueAt;

  /// Lowest `strengthLevel` found among memorized-due records, or `null`
  /// when [totalDue] is zero.
  ///
  /// A lower strength level among memorized records means those ayahs are
  /// closer to the memorized/non-memorized boundary and most at risk of decay.
  final int? weakestStrengthLevel;

  /// `true` when any memorized-due record in the pool has an untrusted or
  /// ambiguous source tag:
  ///
  /// - [ReviewRecordCreatedByMode.unknown] — record predates Sprint 7B tagging
  /// - [ReviewRecordCreatedByMode.migration] — migrated from SharedPreferences;
  ///   origin is permanently ambiguous
  ///
  /// `false` only when **all** memorized-due records carry an explicit trusted
  /// source tag (`adultMemPlus`, `kidsMode`, or `hifz`).
  ///
  /// **Implication**: Daily Plan Retention Review MUST NOT be activated while
  /// this flag is `true` — doing so would risk surfacing ambiguous or
  /// kids-memorized ayahs inside the adult Daily Plan.
  final bool hasPotentialPathAmbiguity;

  @override
  List<Object?> get props => [
    totalDue,
    affectedSurahCount,
    oldestDueAt,
    weakestStrengthLevel,
    hasPotentialPathAmbiguity,
  ];
}
