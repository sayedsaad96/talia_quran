import 'review_due_evaluator.dart';

/// Central classification for Memorization Plus review records.
///
/// Assumptions preserved from the current scheduler and plan logic:
/// - A reviewed ayah is near revision for 0-5 days after its last review.
/// - A reviewed ayah is far revision after more than 5 days.
/// - Strength level 6+ means memorized.
/// - Memorized records stay out of legacy near/far buckets, but due memorized
///   records are exposed through [isMemorizedDue] and [isVisibleForReview].
class ReviewClassification {
  const ReviewClassification({
    required this.isDue,
    required this.isNew,
    required this.isMemorized,
    required this.isNearRevision,
    required this.isFarRevision,
  });

  final bool isDue;
  final bool isNew;
  final bool isMemorized;
  final bool isNearRevision;
  final bool isFarRevision;

  bool get isMemorizedDue => isDue && isMemorized && !isNew;

  /// Foundation-layer visibility for due reviewed records.
  ///
  /// This intentionally includes memorized-due records so future Adaptive
  /// Review work can consume them without rediscovering classification rules.
  bool get isVisibleForReview => isDue && !isNew;
}

class ReviewClassifier {
  const ReviewClassifier();

  static const _nearReviewWindowDays = 5;
  static const _dueEvaluator = ReviewDueEvaluator();

  ReviewClassification classify(ReviewClassificationInput input) {
    final isNew = input.totalReviews == 0;
    final isMemorized = input.strengthLevel >= 6;
    final daysSinceLastReview = input.now
        .toUtc()
        .difference(input.lastReviewedAt.toUtc())
        .inDays;
    final isReviewed = !isNew;
    final isDue = _dueEvaluator.isDue(
      now: input.now,
      scheduledAt: input.nextReviewDate,
      policy: ReviewDuePolicy.onOrAfterScheduledTime,
    );

    return ReviewClassification(
      isDue: isDue,
      isNew: isNew,
      isMemorized: isMemorized,
      isNearRevision:
          isReviewed &&
          !isMemorized &&
          daysSinceLastReview <= _nearReviewWindowDays,
      isFarRevision:
          isReviewed &&
          !isMemorized &&
          daysSinceLastReview > _nearReviewWindowDays,
    );
  }
}

class ReviewClassificationInput {
  const ReviewClassificationInput({
    required this.now,
    required this.lastReviewedAt,
    required this.nextReviewDate,
    required this.strengthLevel,
    required this.totalReviews,
  });

  final DateTime now;
  final DateTime lastReviewedAt;
  final DateTime nextReviewDate;
  final int strengthLevel;
  final int totalReviews;
}
