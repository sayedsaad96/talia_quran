import '../entities/memorization_entities.dart';
import 'migration_readiness_usecase.dart';

class AdaptiveRecommendationsUsecase {
  const AdaptiveRecommendationsUsecase();

  /// Retention is a share of reviewed ayahs, so a handful of ayahs makes it
  /// noise: right after a first session it is 0% and raised a high-priority
  /// "action required" alert on Home for every new learner.
  static const minAyahsForRetentionSignal = 10;

  MemorizationRecommendationsReport generate(MemorizationInsightsReport report) {
    final List<MemorizationRecommendation> recommendations = [];

    // Review Backlog
    if (report.dueAyahs > 100) {
      recommendations.add(
        const MemorizationRecommendation(
          type: RecommendationType.reviewBacklog,
          priority: RecommendationPriority.critical,
        ),
      );
    }

    // Overload Risk
    if (report.workloadHealthScore == WorkloadHealth.critical ||
        report.workloadHealthScore == WorkloadHealth.heavy) {
      recommendations.add(
        const MemorizationRecommendation(
          type: RecommendationType.overloadRisk,
          priority: RecommendationPriority.high,
        ),
      );
    }

    // Leech Recovery
    if (report.totalAyahs > 0) {
      final leechPercentage = report.leechAyahs / report.totalAyahs;
      if (leechPercentage >= 0.1) {
        recommendations.add(
          const MemorizationRecommendation(
            type: RecommendationType.leechRecovery,
            priority: RecommendationPriority.high,
          ),
        );
      }
    }

    final hasRetentionSignal =
        report.totalAyahs >= minAyahsForRetentionSignal;

    // Retention Drop
    if (hasRetentionSignal && report.retentionScore < 0.70) {
      recommendations.add(
        const MemorizationRecommendation(
          type: RecommendationType.retentionDrop,
          priority: RecommendationPriority.high,
        ),
      );
    }

    // Retention Excellent
    if (hasRetentionSignal && report.retentionScore > 0.90) {
      recommendations.add(
        const MemorizationRecommendation(
          type: RecommendationType.retentionExcellent,
          priority: RecommendationPriority.medium,
        ),
      );
    }

    // FSRS Status
    if (report.readinessLevel == MigrationReadinessLevel.high) {
      recommendations.add(
        const MemorizationRecommendation(
          type: RecommendationType.fsrsReady,
          priority: RecommendationPriority.low,
        ),
      );
    } else if (report.readinessLevel == MigrationReadinessLevel.insufficientData) {
      recommendations.add(
        const MemorizationRecommendation(
          type: RecommendationType.fsrsNotReady,
          priority: RecommendationPriority.low,
        ),
      );
    }

    // Sort by priority descending
    recommendations.sort((a, b) => b.priority.weight.compareTo(a.priority.weight));

    return MemorizationRecommendationsReport(recommendations: recommendations);
  }
}
