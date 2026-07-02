import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/fsrs_agreement_usecase.dart';

void main() {
  late FsrsAgreementUsecase usecase;
  late DateTime now;

  setUp(() {
    usecase = const FsrsAgreementUsecase();
    now = DateTime(2026, 1, 1).toUtc();
  });

  AyahReviewRecord createRecord({
    int? predictedFsrsIntervalDays = 10,
    int? schedulerVsFsrsGapDays = 0,
  }) {
    return AyahReviewRecord(
      surahId: 1,
      ayahNumber: 1,
      strengthLevel: 1,
      intervalDays: 1,
      lastReviewedAt: now,
      nextReviewDate: now,
      totalReviews: 1,
      lastRating: PerformanceRating.excellent,
      predictedFsrsIntervalDays: predictedFsrsIntervalDays,
      schedulerVsFsrsGapDays: schedulerVsFsrsGapDays,
    );
  }

  group('FsrsAgreementUsecase', () {
    test('Empty list returns default zeroed result', () {
      final result = usecase.analyze([]);
      expect(result.totalRecords, 0);
      expect(result.agreementScore, 0.0);
      expect(result.agreementPercentage, 0.0);
      expect(result.strongAgreementCount, 0);
      expect(result.moderateAgreementCount, 0);
      expect(result.majorDisagreementCount, 0);
    });

    test('Skips records with missing prediction fields', () {
      final records = [
        createRecord(predictedFsrsIntervalDays: null, schedulerVsFsrsGapDays: 10),
        createRecord(predictedFsrsIntervalDays: 10, schedulerVsFsrsGapDays: null),
        createRecord(predictedFsrsIntervalDays: null, schedulerVsFsrsGapDays: null),
      ];

      final result = usecase.analyze(records);
      expect(result.totalRecords, 0);
      expect(result.agreementScore, 0.0);
    });

    test('Strong Agreement (gap <= 7)', () {
      final records = [
        createRecord(schedulerVsFsrsGapDays: 0),
        createRecord(schedulerVsFsrsGapDays: 7),
        createRecord(schedulerVsFsrsGapDays: -7), // abs() should catch this
      ];

      final result = usecase.analyze(records);
      expect(result.totalRecords, 3);
      expect(result.strongAgreementCount, 3);
      expect(result.agreementScore, 1.0); // (1 + 1 + 1) / 3
      expect(result.agreementPercentage, 100.0);
    });

    test('Moderate Agreement (8 <= gap <= 30)', () {
      final records = [
        createRecord(schedulerVsFsrsGapDays: 8),
        createRecord(schedulerVsFsrsGapDays: -15),
        createRecord(schedulerVsFsrsGapDays: 30),
      ];

      final result = usecase.analyze(records);
      expect(result.totalRecords, 3);
      expect(result.moderateAgreementCount, 3);
      expect(result.agreementScore, closeTo(0.6, 0.0001)); // (0.6 + 0.6 + 0.6) / 3
    });

    test('Major Disagreement (gap > 30)', () {
      final records = [
        createRecord(schedulerVsFsrsGapDays: 31),
        createRecord(schedulerVsFsrsGapDays: -60),
      ];

      final result = usecase.analyze(records);
      expect(result.totalRecords, 2);
      expect(result.majorDisagreementCount, 2);
      expect(result.agreementScore, 0.0);
    });

    test('Mixed dataset aggregation', () {
      final records = [
        createRecord(schedulerVsFsrsGapDays: 3),   // Strong (1.0)
        createRecord(schedulerVsFsrsGapDays: 15),  // Moderate (0.6)
        createRecord(schedulerVsFsrsGapDays: -60), // Major (0.0)
      ];

      final result = usecase.analyze(records);
      expect(result.totalRecords, 3);
      expect(result.strongAgreementCount, 1);
      expect(result.moderateAgreementCount, 1);
      expect(result.majorDisagreementCount, 1);
      
      const expectedScore = (1.0 + 0.6 + 0.0) / 3;
      expect(result.agreementScore, closeTo(expectedScore, 0.0001));
      expect(result.agreementPercentage, closeTo(expectedScore * 100, 0.01));
    });
  });
}
