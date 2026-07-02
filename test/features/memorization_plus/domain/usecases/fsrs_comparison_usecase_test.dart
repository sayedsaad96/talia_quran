import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';

void main() {
  late FsrsComparisonUsecase usecase;
  late DateTime now;

  setUp(() {
    usecase = const FsrsComparisonUsecase();
    now = DateTime(2026, 1, 1).toUtc();
  });

  AyahReviewRecord createRecord({
    int intervalDays = 7,
    int? predictedFsrsIntervalDays,
    double easeFactor = 2.5,
    int strengthLevel = 0,
  }) {
    return AyahReviewRecord(
      surahId: 1,
      ayahNumber: 1,
      strengthLevel: strengthLevel,
      intervalDays: intervalDays,
      lastReviewedAt: now.subtract(const Duration(days: 5)),
      nextReviewDate: now.add(Duration(days: intervalDays)),
      totalReviews: 1,
      lastRating: PerformanceRating.excellent,
      predictedFsrsIntervalDays: predictedFsrsIntervalDays,
      easeFactor: easeFactor,
    );
  }

  group('FsrsComparisonUsecase (V3.5 Analytics)', () {
    test('Positive gap: FSRS predicts longer interval', () {
      final record = createRecord(intervalDays: 30, predictedFsrsIntervalDays: 90);
      final result = usecase.compare(record);

      expect(result.schedulerVsFsrsGapDays, 60);
      expect(result.schedulerVsFsrsRatio, 3.0);
      expect(result.schedulerEarlierThanFsrs, true);
    });

    test('Negative gap: FSRS predicts shorter interval', () {
      final record = createRecord(intervalDays: 120, predictedFsrsIntervalDays: 80);
      final result = usecase.compare(record);

      expect(result.schedulerVsFsrsGapDays, -40);
      expect(result.schedulerVsFsrsRatio, 80 / 120);
      expect(result.schedulerEarlierThanFsrs, false);
    });

    test('Zero gap: Intervals match exactly', () {
      final record = createRecord(intervalDays: 14, predictedFsrsIntervalDays: 14);
      final result = usecase.compare(record);

      expect(result.schedulerVsFsrsGapDays, 0);
      expect(result.schedulerVsFsrsRatio, 1.0);
      expect(result.schedulerEarlierThanFsrs, false);
    });

    test('Null prediction falls back to interval 1 for comparison', () {
      final record = createRecord(intervalDays: 7, predictedFsrsIntervalDays: null);
      final result = usecase.compare(record);

      // Null prediction uses 1
      expect(result.schedulerVsFsrsGapDays, 1 - 7);
      expect(result.schedulerVsFsrsRatio, 1 / 7);
      expect(result.schedulerEarlierThanFsrs, false);
    });

    test('Ratio clamping protects against extreme values', () {
      // Very large ratio
      final largeRecord = createRecord(intervalDays: 1, predictedFsrsIntervalDays: 200);
      final resultLarge = usecase.compare(largeRecord);
      expect(resultLarge.schedulerVsFsrsRatio, 100.0);

      // Negative ratio theoretically not possible since intervals are positive, but clamp covers it
      final negativeRecord = createRecord(intervalDays: 10, predictedFsrsIntervalDays: -5);
      final resultNegative = usecase.compare(negativeRecord);
      expect(resultNegative.schedulerVsFsrsRatio, 0.0);
    });

    test('Safe division when intervalDays is zero', () {
      final record = createRecord(intervalDays: 0, predictedFsrsIntervalDays: 5);
      final result = usecase.compare(record);

      // Denominator should be max(0, 1) = 1
      expect(result.schedulerVsFsrsRatio, 5.0);
      expect(result.schedulerVsFsrsGapDays, 5);
      expect(result.schedulerEarlierThanFsrs, true);
    });

    test('Repository Isolation: V3.2 core fields never change', () {
      final record = createRecord(intervalDays: 15, predictedFsrsIntervalDays: 25);
      final result = usecase.compare(record);

      expect(result.intervalDays, 15);
      expect(result.nextReviewDate, record.nextReviewDate);
      expect(result.easeFactor, 2.5);
      expect(result.strengthLevel, 0);
      expect(result.totalReviews, 1);
    });
  });
}
