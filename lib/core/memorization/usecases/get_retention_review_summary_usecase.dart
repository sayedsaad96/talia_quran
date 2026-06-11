import '../../../features/memorization_plus/domain/entities/memorization_entities.dart';
import '../retention_review_summary.dart';

/// Pure use case for calculating internal diagnostics on the memorized-due
/// (retention review) pool.
///
/// **Design Constraints**:
/// - Operates purely on `List<AyahReviewRecord>`.
/// - No repository dependency.
/// - Does not modify Smart Coach or Daily Plan logic.
///
/// **Sprint 7B update**:
/// [summarize] now computes [RetentionReviewSummary.hasPotentialPathAmbiguity]
/// based on whether any memorized-due record has an untrusted source:
/// - [ReviewRecordCreatedByMode.unknown] — predates source tagging
/// - [ReviewRecordCreatedByMode.migration] — from SharedPreferences migration
/// - `null` source index in Isar (mapped to `unknown` during deserialisation)
///
/// [hasPotentialPathAmbiguity] is `false` only when **all** memorized-due
/// records carry a trusted explicit source tag (`adultMemPlus`, `kidsMode`,
/// or `hifz`).
class GetRetentionReviewSummaryUseCase {
  const GetRetentionReviewSummaryUseCase();

  /// Untrusted source modes that indicate ambiguous record origin.
  static const _ambiguousModes = {
    ReviewRecordCreatedByMode.unknown,
    ReviewRecordCreatedByMode.migration,
  };

  RetentionReviewSummary summarize(List<AyahReviewRecord> records) {
    if (records.isEmpty) {
      return const RetentionReviewSummary.empty();
    }

    final dueMemorizedRecords = records.where((r) {
      return r.reviewClassification.isMemorizedDue;
    }).toList();

    if (dueMemorizedRecords.isEmpty) {
      return const RetentionReviewSummary.empty();
    }

    final affectedSurahs = <int>{};
    DateTime? oldestDate;
    int? weakestLevel;
    var hasAmbiguity = false;

    for (final record in dueMemorizedRecords) {
      affectedSurahs.add(record.surahId);

      if (oldestDate == null || record.nextReviewDate.isBefore(oldestDate)) {
        oldestDate = record.nextReviewDate;
      }

      if (weakestLevel == null || record.strengthLevel < weakestLevel) {
        weakestLevel = record.strengthLevel;
      }

      // Sprint 7B: ambiguity is true if any record lacks a trusted source tag.
      if (_ambiguousModes.contains(record.createdByMode)) {
        hasAmbiguity = true;
      }
    }

    return RetentionReviewSummary(
      totalDue: dueMemorizedRecords.length,
      affectedSurahCount: affectedSurahs.length,
      oldestDueAt: oldestDate,
      weakestStrengthLevel: weakestLevel,
      hasPotentialPathAmbiguity: hasAmbiguity,
    );
  }
}
