import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/review_workload_insights_usecase.dart';

void main() {
  late ReviewWorkloadInsightsUsecase usecase;
  late DateTime now;

  setUp(() {
    usecase = const ReviewWorkloadInsightsUsecase();
    now = DateTime(2026, 1, 1).toUtc();
  });

  AyahReviewRecord createRecord({
    int strengthLevel = 1,
    required DateTime nextReviewDate,
  }) {
    return AyahReviewRecord(
      surahId: 1,
      ayahNumber: 1,
      strengthLevel: strengthLevel,
      intervalDays: 1,
      lastReviewedAt: now.subtract(const Duration(days: 1)),
      nextReviewDate: nextReviewDate,
      totalReviews: 1,
      lastRating: PerformanceRating.excellent,
    );
  }

  group('ReviewWorkloadInsightsUsecase', () {
    test('Ignores new ayahs (strengthLevel == 0)', () {
      final records = [
        createRecord(
          strengthLevel: 0,
          nextReviewDate: now.subtract(const Duration(days: 1)),
        ),
      ];

      final result = usecase.analyze(records, now);
      expect(result.dueNow, 0);
      expect(result.dueNext7Days, 0);
      expect(result.dueNext30Days, 0);
      expect(result.healthScore, WorkloadHealth.healthy);
    });

    test('Correctly buckets due dates', () {
      final records = [
        createRecord(nextReviewDate: now.subtract(const Duration(days: 1))), // Overdue
        createRecord(nextReviewDate: now), // Due exactly now
        createRecord(nextReviewDate: now.add(const Duration(days: 3))), // Next 7 days
        createRecord(nextReviewDate: now.add(const Duration(days: 20))), // Next 30 days
        createRecord(nextReviewDate: now.add(const Duration(days: 40))), // Future
      ];

      final result = usecase.analyze(records, now);
      expect(result.dueNow, 2); // Overdue + exact now
      expect(result.dueNext7Days, 3); // Overdue + now + 3 days
      expect(result.dueNext30Days, 4); // Overdue + now + 3 days + 20 days
    });

    test('Health Score: Critical (>100 due now)', () {
      final records = List.generate(
        101,
        (_) => createRecord(nextReviewDate: now.subtract(const Duration(days: 1))),
      );

      final result = usecase.analyze(records, now);
      expect(result.healthScore, WorkloadHealth.critical);
    });

    test('Health Score: Heavy (>50 due now OR >300 due next 7 days)', () {
      final heavyNow = List.generate(
        51,
        (_) => createRecord(nextReviewDate: now.subtract(const Duration(days: 1))),
      );
      expect(usecase.analyze(heavyNow, now).healthScore, WorkloadHealth.heavy);

      final heavyWeek = List.generate(
        301,
        (_) => createRecord(nextReviewDate: now.add(const Duration(days: 3))),
      );
      expect(usecase.analyze(heavyWeek, now).healthScore, WorkloadHealth.heavy);
    });

    test('Health Score: Moderate (>20 due now OR >100 due next 7 days)', () {
      final modNow = List.generate(
        21,
        (_) => createRecord(nextReviewDate: now.subtract(const Duration(days: 1))),
      );
      expect(usecase.analyze(modNow, now).healthScore, WorkloadHealth.moderate);

      final modWeek = List.generate(
        101,
        (_) => createRecord(nextReviewDate: now.add(const Duration(days: 3))),
      );
      expect(usecase.analyze(modWeek, now).healthScore, WorkloadHealth.moderate);
    });

    test('Health Score: Healthy', () {
      final healthy = List.generate(
        20,
        (_) => createRecord(nextReviewDate: now.subtract(const Duration(days: 1))),
      );
      expect(usecase.analyze(healthy, now).healthScore, WorkloadHealth.healthy);
    });
  });
}
