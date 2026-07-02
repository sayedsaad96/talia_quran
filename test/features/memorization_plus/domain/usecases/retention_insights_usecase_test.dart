import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/retention_insights_usecase.dart';

void main() {
  late RetentionInsightsUsecase usecase;
  late DateTime now;

  setUp(() {
    usecase = const RetentionInsightsUsecase();
    now = DateTime(2026, 1, 1).toUtc();
  });

  AyahReviewRecord createRecord({
    int totalReviews = 1,
    PerformanceRating? lastRating,
  }) {
    return AyahReviewRecord(
      surahId: 1,
      ayahNumber: 1,
      strengthLevel: 1,
      intervalDays: 1,
      lastReviewedAt: now,
      nextReviewDate: now,
      totalReviews: totalReviews,
      lastRating: lastRating,
    );
  }

  group('RetentionInsightsUsecase', () {
    test('Empty list returns 0.0', () {
      final result = usecase.analyze([]);
      expect(result, 0.0);
    });

    test('Records with 0 totalReviews are excluded', () {
      final records = [
        createRecord(totalReviews: 0, lastRating: null),
        createRecord(totalReviews: 0, lastRating: PerformanceRating.excellent), // Should still be excluded despite rating
      ];
      final result = usecase.analyze(records);
      expect(result, 0.0);
    });

    test('Calculates excellent retention score correctly', () {
      final records = [
        createRecord(totalReviews: 1, lastRating: PerformanceRating.excellent),
        createRecord(totalReviews: 5, lastRating: PerformanceRating.excellent),
        createRecord(totalReviews: 2, lastRating: PerformanceRating.average),
        createRecord(totalReviews: 3, lastRating: PerformanceRating.weak),
      ];

      // 2 excellent out of 4 total reviewed = 0.5
      final result = usecase.analyze(records);
      expect(result, 0.5);
    });

    test('All excellent returns 1.0', () {
      final records = [
        createRecord(totalReviews: 1, lastRating: PerformanceRating.excellent),
        createRecord(totalReviews: 2, lastRating: PerformanceRating.excellent),
      ];
      final result = usecase.analyze(records);
      expect(result, 1.0);
    });
  });
}
