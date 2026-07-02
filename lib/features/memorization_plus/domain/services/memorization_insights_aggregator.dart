import '../entities/memorization_entities.dart';
import '../usecases/fsrs_agreement_usecase.dart';
import '../usecases/leech_analysis_usecase.dart';
import '../usecases/migration_readiness_usecase.dart';
import '../usecases/retention_insights_usecase.dart';
import '../usecases/review_workload_insights_usecase.dart';
import 'fsrs_analytics_service.dart';

class MemorizationInsightsAggregator {
  const MemorizationInsightsAggregator({
    this.retentionUsecase = const RetentionInsightsUsecase(),
    this.leechUsecase = const LeechAnalysisUsecase(),
    this.workloadUsecase = const ReviewWorkloadInsightsUsecase(),
    this.fsrsAnalyticsService = const FsrsAnalyticsService(),
    this.agreementUsecase = const FsrsAgreementUsecase(),
    this.migrationReadinessUsecase = const MigrationReadinessUsecase(),
  });

  final RetentionInsightsUsecase retentionUsecase;
  final LeechAnalysisUsecase leechUsecase;
  final ReviewWorkloadInsightsUsecase workloadUsecase;
  final FsrsAnalyticsService fsrsAnalyticsService;
  final FsrsAgreementUsecase agreementUsecase;
  final MigrationReadinessUsecase migrationReadinessUsecase;

  MemorizationInsightsReport generate(List<AyahReviewRecord> records, DateTime now) {
    final retentionScore = retentionUsecase.analyze(records);
    final leechResult = leechUsecase.analyze(records);
    final workloadResult = workloadUsecase.analyze(records, now);
    final fsrsReport = fsrsAnalyticsService.analyze(records);
    final agreementResult = agreementUsecase.analyze(records);

    AnalyticsConfidence confidence;
    if (fsrsReport.totalRecords < 100) {
      confidence = AnalyticsConfidence.low;
    } else if (fsrsReport.totalRecords <= 1000) {
      confidence = AnalyticsConfidence.medium;
    } else {
      confidence = AnalyticsConfidence.high;
    }

    final readinessReport = migrationReadinessUsecase.analyze(
      agreementScore: agreementResult.agreementScore,
      totalRecords: agreementResult.totalRecords,
      analyticsConfidence: confidence,
    );

    double avgDifficulty = 0.0;
    double avgStability = 0.0;
    int validFSRSRecords = 0;

    for (final r in records) {
      if (r.totalReviews > 0) {
        avgDifficulty += r.difficulty;
        avgStability += r.stability;
        validFSRSRecords++;
      }
    }

    if (validFSRSRecords > 0) {
      avgDifficulty /= validFSRSRecords;
      avgStability /= validFSRSRecords;
    }

    return MemorizationInsightsReport(
      totalRecordsAnalyzed: records.length,
      totalAyahs: records.length,
      dueAyahs: workloadResult.dueNow,
      leechAyahs: leechResult.totalLeeches,
      averageLapses: leechResult.averageLapses,
      averageDifficulty: avgDifficulty,
      averageStability: avgStability,
      averageGapDays: fsrsReport.averageGapDays,
      averageRatio: fsrsReport.averageRatio,
      schedulerEarlierCount: fsrsReport.schedulerEarlierCount,
      fsrsEarlierCount: fsrsReport.fsrsEarlierCount,
      retentionScore: retentionScore,
      gapBuckets: fsrsReport.gapDistribution,
      workloadHealthScore: workloadResult.healthScore,
      confidence: confidence,
      fsrsAgreementScore: agreementResult.agreementScore,
      strongAgreementCount: agreementResult.strongAgreementCount,
      moderateAgreementCount: agreementResult.moderateAgreementCount,
      majorDisagreementCount: agreementResult.majorDisagreementCount,
      readinessScore: readinessReport.readinessScore,
      readinessLevel: readinessReport.readinessLevel,
    );
  }
}
