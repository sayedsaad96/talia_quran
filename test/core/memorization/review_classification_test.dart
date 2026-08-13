import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/review_classification.dart';

void main() {
  const classifier = ReviewClassifier();

  group('ReviewClassifier', () {
    test('classifies due near reviews', () {
      final now = DateTime.utc(2026, 6, 9, 12);
      final classification = classifier.classify(
        ReviewClassificationInput(
          now: now,
          lastReviewedAt: now.subtract(const Duration(days: 5)),
          nextReviewDate: now,
          strengthLevel: 3,
          totalReviews: 2,
        ),
      );

      expect(classification.isDue, isTrue);
      expect(classification.isNearRevision, isTrue);
      expect(classification.isFarRevision, isFalse);
      expect(classification.isVisibleForReview, isTrue);
    });

    test('classifies due far reviews', () {
      final now = DateTime.utc(2026, 6, 9, 12);
      final classification = classifier.classify(
        ReviewClassificationInput(
          now: now,
          lastReviewedAt: now.subtract(const Duration(days: 6)),
          nextReviewDate: now.subtract(const Duration(hours: 1)),
          strengthLevel: 3,
          totalReviews: 2,
        ),
      );

      expect(classification.isDue, isTrue);
      expect(classification.isNearRevision, isFalse);
      expect(classification.isFarRevision, isTrue);
      expect(classification.isVisibleForReview, isTrue);
    });

    test(
      'classifies a due review from a prior local calendar day as overdue',
      () {
        final now = DateTime(2026, 6, 9, 0, 30);
        final classification = classifier.classify(
          ReviewClassificationInput(
            now: now,
            lastReviewedAt: now.subtract(const Duration(days: 6)),
            nextReviewDate: DateTime(2026, 6, 8, 23, 59),
            strengthLevel: 3,
            totalReviews: 2,
          ),
        );

        expect(classification.isDue, isTrue);
        expect(classification.isOverdue, isTrue);
      },
    );

    test('surfaces memorized due records without legacy near/far buckets', () {
      final now = DateTime.utc(2026, 6, 9, 12);
      final classification = classifier.classify(
        ReviewClassificationInput(
          now: now,
          lastReviewedAt: now.subtract(const Duration(days: 30)),
          nextReviewDate: now.subtract(const Duration(days: 1)),
          strengthLevel: 6,
          totalReviews: 5,
        ),
      );

      expect(classification.isDue, isTrue);
      expect(classification.isMemorized, isTrue);
      expect(classification.isMemorizedDue, isTrue);
      expect(classification.isVisibleForReview, isTrue);
      expect(classification.isNearRevision, isFalse);
      expect(classification.isFarRevision, isFalse);
    });

    test('does not expose new ayahs as due review visibility', () {
      final now = DateTime.utc(2026, 6, 9, 12);
      final classification = classifier.classify(
        ReviewClassificationInput(
          now: now,
          lastReviewedAt: now,
          nextReviewDate: now,
          strengthLevel: 0,
          totalReviews: 0,
        ),
      );

      expect(classification.isNew, isTrue);
      expect(classification.isDue, isTrue);
      expect(classification.isVisibleForReview, isFalse);
      expect(classification.isNearRevision, isFalse);
      expect(classification.isFarRevision, isFalse);
    });
  });
}
