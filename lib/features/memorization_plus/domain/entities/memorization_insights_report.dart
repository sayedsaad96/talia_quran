import '../usecases/migration_readiness_usecase.dart';

enum WorkloadHealth {
  healthy,
  moderate,
  heavy,
  critical,
}

enum AnalyticsConfidence {
  low,
  medium,
  high,
}

class MemorizationInsightsReport {
  const MemorizationInsightsReport({
    required this.totalRecordsAnalyzed,
    required this.totalAyahs,
    required this.dueAyahs,
    required this.leechAyahs,
    required this.averageLapses,
    required this.averageDifficulty,
    required this.averageStability,
    required this.averageGapDays,
    required this.averageRatio,
    required this.schedulerEarlierCount,
    required this.fsrsEarlierCount,
    required this.retentionScore,
    required this.gapBuckets,
    required this.workloadHealthScore,
    required this.confidence,
    this.fsrsAgreementScore,
    this.strongAgreementCount,
    this.moderateAgreementCount,
    this.majorDisagreementCount,
    this.readinessScore,
    this.readinessLevel,
  });

  final int totalRecordsAnalyzed;
  final int totalAyahs;
  final int dueAyahs;
  final int leechAyahs;

  final double averageLapses;
  final double averageDifficulty;
  final double averageStability;

  final double averageGapDays;
  final double averageRatio;

  final int schedulerEarlierCount;
  final int fsrsEarlierCount;

  final double retentionScore;

  final Map<String, int> gapBuckets;

  final WorkloadHealth workloadHealthScore;
  final AnalyticsConfidence confidence;

  /// FSRS vs Scheduler Agreement
  final double? fsrsAgreementScore;
  final int? strongAgreementCount;
  final int? moderateAgreementCount;
  final int? majorDisagreementCount;

  /// Migration Readiness
  final double? readinessScore;
  final MigrationReadinessLevel? readinessLevel;
}
