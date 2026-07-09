import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/review_record_cloud_merge.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  group('ReviewRecordCloudMerge', () {
    final baseTime = DateTime.utc(2026, 7, 1);

    AyahReviewRecord record({
      required int strength,
      required DateTime reviewedAt,
      required int totalReviews,
      ReviewRecordCreatedByMode mode = ReviewRecordCreatedByMode.v2Session,
    }) {
      return AyahReviewRecord(
        surahId: 67,
        ayahNumber: 3,
        strengthLevel: strength,
        intervalDays: strength * 2,
        lastReviewedAt: reviewedAt,
        nextReviewDate: reviewedAt.add(Duration(days: strength * 2)),
        totalReviews: totalReviews,
        lastRating: PerformanceRating.excellent,
        createdByMode: mode,
      );
    }

    test('returns remote when local is null', () {
      final remote = record(
        strength: 4,
        reviewedAt: baseTime,
        totalReviews: 2,
      );

      expect(
        ReviewRecordCloudMerge.merge(local: null, remote: remote),
        remote,
      );
    });

    test('keeps adult strength when kids pass is merged later', () {
      final adult = record(
        strength: 5,
        reviewedAt: baseTime,
        totalReviews: 8,
        mode: ReviewRecordCreatedByMode.v2Session,
      );
      final kids = record(
        strength: 1,
        reviewedAt: baseTime.add(const Duration(hours: 1)),
        totalReviews: 1,
        mode: ReviewRecordCreatedByMode.kidsMode,
      );

      final merged = ReviewRecordCloudMerge.merge(local: adult, remote: kids);

      expect(merged.strengthLevel, 5);
      expect(merged.totalReviews, 8);
      expect(merged.createdByMode, ReviewRecordCreatedByMode.kidsMode);
    });

    test('takes latest scheduling fields from most recent review', () {
      final older = record(
        strength: 3,
        reviewedAt: baseTime,
        totalReviews: 3,
      );
      final newer = record(
        strength: 4,
        reviewedAt: baseTime.add(const Duration(days: 1)),
        totalReviews: 4,
      );

      final merged = ReviewRecordCloudMerge.merge(local: older, remote: newer);

      expect(merged.strengthLevel, 4);
      expect(merged.totalReviews, 4);
      expect(merged.nextReviewDate, newer.nextReviewDate);
      expect(merged.lastReviewedAt, newer.lastReviewedAt);
    });
  });
}
