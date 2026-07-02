import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/memorization_insights_aggregator.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/migration_readiness_usecase.dart';

void main() {
  late MemorizationInsightsAggregator aggregator;
  late DateTime now;

  setUp(() {
    aggregator = const MemorizationInsightsAggregator();
    now = DateTime(2026, 1, 1).toUtc();
  });

  AyahReviewRecord createRecord({
    int strengthLevel = 1,
    int totalReviews = 1,
    int lapses = 0,
    double difficulty = 5.0,
    double stability = 2.0,
    int? schedulerVsFsrsGapDays,
    double? schedulerVsFsrsRatio,
    int? predictedFsrsIntervalDays = 10,
  }) {
    return AyahReviewRecord(
      surahId: 1,
      ayahNumber: 1,
      strengthLevel: strengthLevel,
      intervalDays: 7,
      lastReviewedAt: now.subtract(const Duration(days: 1)),
      nextReviewDate: now.add(const Duration(days: 7)),
      totalReviews: totalReviews,
      lastRating: PerformanceRating.excellent,
      lapses: lapses,
      difficulty: difficulty,
      stability: stability,
      predictedFsrsIntervalDays: predictedFsrsIntervalDays,
      schedulerVsFsrsGapDays: schedulerVsFsrsGapDays,
      schedulerVsFsrsRatio: schedulerVsFsrsRatio,
      schedulerEarlierThanFsrs: schedulerVsFsrsGapDays != null ? schedulerVsFsrsGapDays > 0 : null,
    );
  }

  group('MemorizationInsightsAggregator', () {
    test('Empty list returns default zeroed report', () {
      final report = aggregator.generate([], now);
      
      expect(report.totalRecordsAnalyzed, 0);
      expect(report.totalAyahs, 0);
      expect(report.retentionScore, 0.0);
      expect(report.leechAyahs, 0);
      expect(report.averageDifficulty, 0.0);
      expect(report.averageStability, 0.0);
      expect(report.confidence, AnalyticsConfidence.low);
    });

    test('Aggregates insights across domains', () {
      final records = [
        createRecord(
          difficulty: 4.0,
          stability: 3.0,
          lapses: 0,
          schedulerVsFsrsGapDays: 5,
          schedulerVsFsrsRatio: 1.5,
        ),
        createRecord(
          difficulty: 6.0,
          stability: 1.0,
          lapses: 9, // Leech
          schedulerVsFsrsGapDays: -2,
          schedulerVsFsrsRatio: 0.8,
        ),
      ];

      final report = aggregator.generate(records, now);

      expect(report.totalRecordsAnalyzed, 2);
      expect(report.averageDifficulty, 5.0); // (4+6)/2
      expect(report.averageStability, 2.0); // (3+1)/2
      expect(report.leechAyahs, 1);
      expect(report.averageLapses, 9.0);
      expect(report.retentionScore, 1.0); // both have excellent last rating by default
      expect(report.averageGapDays, 1.5); // (5 + -2)/2
      expect(report.averageRatio, 1.15); // (1.5 + 0.8)/2
      expect(report.schedulerEarlierCount, 1); // first record has gap 5 > 0
      expect(report.fsrsEarlierCount, 1); // second record has gap -2 <= 0
      expect(report.confidence, AnalyticsConfidence.low); // 2 records < 100

      // V3.7 additions
      expect(report.strongAgreementCount, 2); // 5 and |-2| are both <= 7
      expect(report.moderateAgreementCount, 0);
      expect(report.majorDisagreementCount, 0);
      expect(report.fsrsAgreementScore, 1.0);
      expect(report.readinessScore, 1.0);
      expect(report.readinessLevel, MigrationReadinessLevel.insufficientData); // due to confidence low
    });

    test('Confidence indicator thresholds', () {
      final lowRecords = List.generate(99, (_) => createRecord(schedulerVsFsrsGapDays: 0, schedulerVsFsrsRatio: 1.0));
      final medRecords = List.generate(100, (_) => createRecord(schedulerVsFsrsGapDays: 0, schedulerVsFsrsRatio: 1.0));
      final highRecords = List.generate(1001, (_) => createRecord(schedulerVsFsrsGapDays: 0, schedulerVsFsrsRatio: 1.0));

      expect(aggregator.generate(lowRecords, now).confidence, AnalyticsConfidence.low);
      expect(aggregator.generate(medRecords, now).confidence, AnalyticsConfidence.medium);
      expect(aggregator.generate(highRecords, now).confidence, AnalyticsConfidence.high);
    });

    test('Isolates scheduler state entirely', () {
      final record = createRecord(lapses: 8, difficulty: 7.0, schedulerVsFsrsGapDays: 10, schedulerVsFsrsRatio: 2.0);
      final report = aggregator.generate([record], now);

      // Verify record itself is untouched (pure function check)
      expect(record.lapses, 8);
      expect(record.difficulty, 7.0);

      // Verify report reflects the insight
      expect(report.leechAyahs, 1);
      expect(report.averageGapDays, 10.0);
    });
  });
}
