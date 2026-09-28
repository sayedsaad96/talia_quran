import '../../../../../core/memorization/review_record_filters.dart';
import '../../../domain/entities/memorization_entities.dart';

/// Selects due adult review records independently of the currently memorized
/// surah. The existing [DailyPlan] buckets remain unchanged for compatibility.
class DailyPlanReviewQueue {
  const DailyPlanReviewQueue._();

  static DailyPlanReviewSelection select({
    required Iterable<AyahReviewRecord> records,
    required DateTime now,
    required int nearLimit,
    required int farLimit,
    required int retentionLimit,
    required bool includeNear,
    required bool includeFar,
  }) {
    // Never-reviewed records are new material served by the new-ayah bucket.
    // Counting them as review backlog would block new memorization while
    // listing nothing to review (they fit no weak/near/far bucket).
    final due = records
        .where(ReviewRecordFilters.isAdultCompatible)
        .where((record) => record.classifyAt(now).isVisibleForReview)
        .toList();
    final required =
        due.where((record) => !record.classifyAt(now).isMemorized).toList()
          ..sort((a, b) => _compareRequired(a, b, now));
    final retention = due.where((record) {
      return record.classifyAt(now).isMemorizedDue;
    }).toList()..sort(ReviewRecordFilters.compareMemorizedDue);

    final reviewCapacity =
        (includeNear ? nearLimit : 0) + (includeFar ? farLimit : 0);
    // The toggles must filter, not just shrink capacity: with near revision
    // disabled, near items may not fill the remaining far slots.
    final eligible = required.where((record) {
      if (_isWeakRecovery(record)) return true; // recovery is always due work
      final classification = record.classifyAt(now);
      if (classification.isNearRevision) return includeNear;
      if (classification.isFarRevision) return includeFar;
      return true; // overdue-but-unclassified required work stays schedulable
    }).toList();
    // Weak recovery is mandatory consolidation work: it keeps a capacity
    // floor even when both routine revision toggles are off, so the plan
    // never dead-ends (a blocking backlog with nothing scheduled to do).
    final weakDueCount = required.where(_isWeakRecovery).length;
    final effectiveCapacity = weakDueCount > reviewCapacity
        ? weakDueCount
        : reviewCapacity;
    final selected = eligible.take(effectiveCapacity).toList();
    final weak = selected.where(_isWeakRecovery).toList();
    final near = selected
        .where((record) => !_isWeakRecovery(record))
        .where((record) => record.classifyAt(now).isNearRevision)
        .toList();
    final far = selected
        .where((record) => !_isWeakRecovery(record))
        .where((record) => record.classifyAt(now).isFarRevision)
        .toList();

    return DailyPlanReviewSelection(
      weak: weak,
      near: near,
      far: far,
      retention: retention
          .take(_adaptiveRetentionLimit(retention.length, retentionLimit))
          .toList(),
      dueBacklogCount: required.length,
      reviewCapacity: reviewCapacity,
    );
  }

  /// Retention catch-up: a fixed 3/day cap lets a growing backlog of overdue
  /// memorized ayahs drift indefinitely. Serve more per day as the backlog
  /// grows, bounded so the plan never drowns the learner.
  static int _adaptiveRetentionLimit(int overdueCount, int configured) {
    if (overdueCount <= configured * 2) return configured;
    return (configured + overdueCount ~/ 4).clamp(configured, 15);
  }

  static bool _isWeakRecovery(AyahReviewRecord record) =>
      record.lastRating == PerformanceRating.weak || record.lapses > 0;

  static int _compareRequired(
    AyahReviewRecord a,
    AyahReviewRecord b,
    DateTime now,
  ) {
    final priority = _priority(a, now).compareTo(_priority(b, now));
    if (priority != 0) return priority;
    final due = a.nextReviewDate.compareTo(b.nextReviewDate);
    if (due != 0) return due;
    final strength = a.strengthLevel.compareTo(b.strengthLevel);
    if (strength != 0) return strength;
    final surah = a.surahId.compareTo(b.surahId);
    return surah != 0 ? surah : a.ayahNumber.compareTo(b.ayahNumber);
  }

  static int _priority(AyahReviewRecord record, DateTime now) {
    final classification = record.classifyAt(now);
    if (classification.isOverdue ||
        record.lastRating == PerformanceRating.weak ||
        record.lapses > 0) {
      return 0;
    }
    return classification.isNearRevision ? 1 : 2;
  }
}

class DailyPlanReviewSelection {
  const DailyPlanReviewSelection({
    required this.weak,
    required this.near,
    required this.far,
    required this.retention,
    required this.dueBacklogCount,
    required this.reviewCapacity,
  });

  final List<AyahReviewRecord> weak;
  final List<AyahReviewRecord> near;
  final List<AyahReviewRecord> far;
  final List<AyahReviewRecord> retention;
  final int dueBacklogCount;
  final int reviewCapacity;

  /// New material is withheld until the due backlog fits in the configured
  /// near/far daily capacity. Equality still permits new memorization.
  bool get blocksNewMemorization => dueBacklogCount > reviewCapacity;
}
