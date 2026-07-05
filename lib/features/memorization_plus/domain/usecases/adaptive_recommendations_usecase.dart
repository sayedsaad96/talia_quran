import '../entities/memorization_entities.dart';
import 'migration_readiness_usecase.dart';

class AdaptiveRecommendationsUsecase {
  const AdaptiveRecommendationsUsecase();

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

    // Retention Drop
    if (report.retentionScore < 0.70) {
      recommendations.add(
        const MemorizationRecommendation(
          type: RecommendationType.retentionDrop,
          priority: RecommendationPriority.high,
        ),
      );
    }

    // Retention Excellent
    if (report.retentionScore > 0.90) {
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
