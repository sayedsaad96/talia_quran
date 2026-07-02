import '../entities/memorization_insights_report.dart';

enum MigrationReadinessLevel {
  insufficientData,
  low,
  medium,
  high,
}

class MigrationReadinessReport {
  const MigrationReadinessReport({
    required this.readinessScore,
    required this.readinessLevel,
  });

  final double readinessScore;
  final MigrationReadinessLevel readinessLevel;
}

class MigrationReadinessUsecase {
  const MigrationReadinessUsecase();

  MigrationReadinessReport analyze({
    required double agreementScore,
    required int totalRecords,
    required AnalyticsConfidence analyticsConfidence,
  }) {
    if (totalRecords < 100 || analyticsConfidence == AnalyticsConfidence.low) {
      return MigrationReadinessReport(
        readinessScore: agreementScore,
        readinessLevel: MigrationReadinessLevel.insufficientData,
      );
    }

    MigrationReadinessLevel level;
    if (agreementScore >= 0.85) {
      level = MigrationReadinessLevel.high;
    } else if (agreementScore >= 0.70) {
      level = MigrationReadinessLevel.medium;
    } else {
      level = MigrationReadinessLevel.low;
    }

    return MigrationReadinessReport(
      readinessScore: agreementScore,
      readinessLevel: level,
    );
  }
}
