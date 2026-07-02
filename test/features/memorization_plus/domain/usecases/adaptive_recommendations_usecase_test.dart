import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/adaptive_recommendations_usecase.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/migration_readiness_usecase.dart';

void main() {
  late AdaptiveRecommendationsUsecase usecase;

  setUp(() {
    usecase = const AdaptiveRecommendationsUsecase();
  });

  MemorizationInsightsReport createReport({
    int totalAyahs = 100,
    int dueAyahs = 0,
    int leechAyahs = 0,
    double retentionScore = 0.80,
    WorkloadHealth workloadHealthScore = WorkloadHealth.healthy,
    MigrationReadinessLevel readinessLevel = MigrationReadinessLevel.medium,
  }) {
    return MemorizationInsightsReport(
      totalRecordsAnalyzed: totalAyahs,
      totalAyahs: totalAyahs,
      dueAyahs: dueAyahs,
      leechAyahs: leechAyahs,
      averageLapses: 0.0,
      averageDifficulty: 0.0,
      averageStability: 0.0,
      averageGapDays: 0.0,
      averageRatio: 1.0,
      schedulerEarlierCount: 0,
      fsrsEarlierCount: 0,
      retentionScore: retentionScore,
      gapBuckets: const {},
      workloadHealthScore: workloadHealthScore,
      confidence: AnalyticsConfidence.medium,
      readinessLevel: readinessLevel,
    );
  }

  group('AdaptiveRecommendationsUsecase', () {
    test('Review Backlog Recommendation (dueAyahs > 100)', () {
      final report = createReport(dueAyahs: 101);
      final result = usecase.generate(report);
      
      expect(result.recommendations.length, 1);
      expect(result.recommendations.first.type, RecommendationType.reviewBacklog);
      expect(result.recommendations.first.priority, RecommendationPriority.critical);
    });

    test('Overload Risk Recommendation (critical or heavy)', () {
      final reportHeavy = createReport(workloadHealthScore: WorkloadHealth.heavy);
      final resultHeavy = usecase.generate(reportHeavy);
      expect(resultHeavy.recommendations.length, 1);
      expect(resultHeavy.recommendations.first.type, RecommendationType.overloadRisk);

      final reportCritical = createReport(workloadHealthScore: WorkloadHealth.critical);
      final resultCritical = usecase.generate(reportCritical);
      expect(resultCritical.recommendations.length, 1);
      expect(resultCritical.recommendations.first.type, RecommendationType.overloadRisk);
    });

    test('Leech Recovery Recommendation (>= 10%)', () {
      final report = createReport(totalAyahs: 100, leechAyahs: 10);
      final result = usecase.generate(report);
      expect(result.recommendations.length, 1);
      expect(result.recommendations.first.type, RecommendationType.leechRecovery);
      expect(result.recommendations.first.priority, RecommendationPriority.high);
    });

    test('Retention Drop Recommendation (< 70%)', () {
      final report = createReport(retentionScore: 0.69);
      final result = usecase.generate(report);
      expect(result.recommendations.length, 1);
      expect(result.recommendations.first.type, RecommendationType.retentionDrop);
    });

    test('Retention Excellent Recommendation (> 90%)', () {
      final report = createReport(retentionScore: 0.95);
      final result = usecase.generate(report);
      expect(result.recommendations.length, 1);
      expect(result.recommendations.first.type, RecommendationType.retentionExcellent);
      expect(result.recommendations.first.priority, RecommendationPriority.medium);
    });

    test('FSRS Readiness Recommendations', () {
      final reportReady = createReport(readinessLevel: MigrationReadinessLevel.high);
      final resultReady = usecase.generate(reportReady);
      expect(resultReady.recommendations.first.type, RecommendationType.fsrsReady);
      expect(resultReady.recommendations.first.priority, RecommendationPriority.low);

      final reportNotReady = createReport(readinessLevel: MigrationReadinessLevel.insufficientData);
      final resultNotReady = usecase.generate(reportNotReady);
      expect(resultNotReady.recommendations.first.type, RecommendationType.fsrsNotReady);
    });

    test('Multiple recommendations sort by priority', () {
      final report = createReport(
        dueAyahs: 150, // Backlog (Critical=4)
        leechAyahs: 20, // Leech (High=3)
        retentionScore: 0.95, // Excellent (Medium=2)
        readinessLevel: MigrationReadinessLevel.high, // Ready (Low=1)
      );

      final result = usecase.generate(report);
      
      expect(result.recommendations.length, 4);
      expect(result.recommendations[0].priority, RecommendationPriority.critical);
      expect(result.recommendations[1].priority, RecommendationPriority.high);
      expect(result.recommendations[2].priority, RecommendationPriority.medium);
      expect(result.recommendations[3].priority, RecommendationPriority.low);
    });
  });
}
