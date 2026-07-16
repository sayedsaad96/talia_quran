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
      PerformanceRating rating = PerformanceRating.excellent,
    }) {
      return AyahReviewRecord(
        surahId: 67,
        ayahNumber: 3,
        strengthLevel: strength,
        intervalDays: strength * 2,
        lastReviewedAt: reviewedAt,
        nextReviewDate: reviewedAt.add(Duration(days: strength * 2)),
        totalReviews: totalReviews,
        lastRating: rating,
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

    test('later weak review replaces earlier strong (no field-wise max)', () {
      final adult = record(
        strength: 5,
        reviewedAt: baseTime,
        totalReviews: 8,
        mode: ReviewRecordCreatedByMode.v2Session,
      );
      final kids = record(
        strength: 1,
        reviewedAt: baseTime.add(const Duration(hours: 1)),
        totalReviews: 9,
        mode: ReviewRecordCreatedByMode.kidsMode,
        rating: PerformanceRating.weak,
      );

      final merged = ReviewRecordCloudMerge.merge(local: adult, remote: kids);

      expect(merged.strengthLevel, 1);
      expect(merged.totalReviews, 9);
      expect(merged.lastRating, PerformanceRating.weak);
      expect(merged.createdByMode, ReviewRecordCreatedByMode.kidsMode);
    });

    test('keeps local when it is the newer review event', () {
      final newerLocal = record(
        strength: 2,
        reviewedAt: baseTime.add(const Duration(days: 1)),
        totalReviews: 5,
        rating: PerformanceRating.weak,
      );
      final olderRemote = record(
        strength: 6,
        reviewedAt: baseTime,
        totalReviews: 4,
      );

      final merged = ReviewRecordCloudMerge.merge(
        local: newerLocal,
        remote: olderRemote,
      );

      expect(merged.strengthLevel, 2);
      expect(merged.totalReviews, 5);
      expect(merged.lastReviewedAt, newerLocal.lastReviewedAt);
    });

    test('takes complete newer remote review event', () {
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
