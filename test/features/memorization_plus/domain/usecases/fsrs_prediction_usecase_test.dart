import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';

void main() {
  late FsrsPredictionUsecase usecase;
  late DateTime now;

  setUp(() {
    usecase = const FsrsPredictionUsecase();
    now = DateTime(2026, 1, 1).toUtc();
  });

  AyahReviewRecord createRecord({
    double difficulty = 5.0,
    double stability = 0.0,
    int intervalDays = 7,
    DateTime? nextReviewDate,
    double easeFactor = 2.5,
    int strengthLevel = 0,
    PerformanceRating? lastRating,
  }) {
    return AyahReviewRecord(
      surahId: 1,
      ayahNumber: 1,
      strengthLevel: strengthLevel,
      intervalDays: intervalDays,
      lastReviewedAt: now.subtract(const Duration(days: 5)),
      nextReviewDate: nextReviewDate ?? now.add(const Duration(days: 7)),
      totalReviews: 1,
      lastRating: lastRating,
      difficulty: difficulty,
      stability: stability,
      easeFactor: easeFactor,
    );
  }

  group('FsrsPredictionUsecase (V3.4 Shadow Mode)', () {
    test('Low Stability produces low interval and low retrievability', () {
      final record = createRecord(stability: 1.0, difficulty: 5.0);
      const actualElapsedDays = 10;
      
      final result = usecase.predict(record, actualElapsedDays, now);

      // Interval = (1.0 * (11 - 5) / 5).round() = (6/5) = 1
      expect(result.predictedFsrsIntervalDays, 1);
      
      // Retrievability = exp(-10 / 1.0) = exp(-10) = ~0.000045
      expect(result.predictedRetrievability, lessThan(0.01));
      expect(result.predictedRecallProbability, result.predictedRetrievability);
    });

    test('High Stability produces larger interval and higher retrievability', () {
      final record = createRecord(stability: 100.0, difficulty: 5.0);
      const actualElapsedDays = 10;
      
      final result = usecase.predict(record, actualElapsedDays, now);

      // Interval = (100.0 * (11 - 5) / 5).round() = 120
      expect(result.predictedFsrsIntervalDays, 120);
      
      // Retrievability = exp(-10 / 100.0) = exp(-0.1) = ~0.9048
      expect(result.predictedRetrievability, greaterThan(0.9));
      expect(result.predictedRecallProbability, result.predictedRetrievability);
    });

    test('Difficulty Scaling: easier ayah gets longer interval', () {
      final recordHard = createRecord(stability: 20.0, difficulty: 9.0);
      final recordEasy = createRecord(stability: 20.0, difficulty: 2.0);
      
      final resultHard = usecase.predict(recordHard, 5, now);
      final resultEasy = usecase.predict(recordEasy, 5, now);

      // Hard: 20 * (11 - 9) / 5 = 8
      // Easy: 20 * (11 - 2) / 5 = 36
      expect(resultHard.predictedFsrsIntervalDays, 8);
      expect(resultEasy.predictedFsrsIntervalDays, 36);
      expect(resultEasy.predictedFsrsIntervalDays, greaterThan(resultHard.predictedFsrsIntervalDays!));
    });

    test('Clamp Tests: retrievability [0,1] and interval [1,365]', () {
      final recordExtremeHigh = createRecord(stability: 1000.0, difficulty: 1.0);
      final resultHigh = usecase.predict(recordExtremeHigh, 1, now);
      
      // Interval would be 1000 * 10 / 5 = 2000, should clamp to 365
      expect(resultHigh.predictedFsrsIntervalDays, 365);
      expect(resultHigh.predictedRetrievability, lessThanOrEqualTo(1.0));

      final recordExtremeLow = createRecord(stability: -10.0, difficulty: 10.0);
      final resultLow = usecase.predict(recordExtremeLow, 1000, now);
      
      // Interval would be small/negative, should clamp to 1
      expect(resultLow.predictedFsrsIntervalDays, 1);
      expect(resultLow.predictedRetrievability, greaterThanOrEqualTo(0.0));
    });

    test('Repository Isolation: V3.2 values remain completely unchanged', () {
      final record = createRecord(
        stability: 50.0, 
        difficulty: 5.0,
        intervalDays: 14,
        easeFactor: 2.3,
        strengthLevel: 3,
      );
      const actualElapsedDays = 10;
      
      final result = usecase.predict(record, actualElapsedDays, now);

      expect(result.intervalDays, record.intervalDays, reason: 'Production interval mutated');
      expect(result.nextReviewDate, record.nextReviewDate, reason: 'Production due date mutated');
      expect(result.easeFactor, record.easeFactor, reason: 'Production ease mutated');
      expect(result.strengthLevel, record.strengthLevel, reason: 'Production strength mutated');
      
      expect(result.predictedFsrsIntervalDays, isNotNull);
      expect(result.predictedRetrievability, isNotNull);
      expect(result.predictedFsrsDueDate, isNotNull);
    });
  });
}
