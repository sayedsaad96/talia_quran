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
          title: 'Clear Review Backlog',
          description: 'You have many due ayahs. Focus on clearing them before memorizing new content.',
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
          title: 'Reduce New Memorization',
          description: 'Your workload is heavy. Focus on retaining what you have instead of adding new ayahs.',
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
            title: 'Focus on Weak Ayahs',
            description: 'Many of your ayahs are difficult to retain. Focus on reviewing them thoroughly.',
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
          title: 'Increase Review Frequency',
          description: 'Your retention rate is dropping. Consider reviewing more frequently.',
        ),
      );
    }

    // Retention Excellent
    if (report.retentionScore > 0.90) {
      recommendations.add(
        const MemorizationRecommendation(
          type: RecommendationType.retentionExcellent,
          priority: RecommendationPriority.medium,
          title: 'Excellent Retention',
          description: 'Your current review strategy is working perfectly. Keep it up!',
        ),
      );
    }

    // FSRS Status
    if (report.readinessLevel == MigrationReadinessLevel.high) {
      recommendations.add(
        const MemorizationRecommendation(
          type: RecommendationType.fsrsReady,
          priority: RecommendationPriority.low,
          title: 'FSRS Migration Ready',
          description: 'Sufficient data has been collected to evaluate an advanced scheduling algorithm in the future.',
        ),
      );
    } else if (report.readinessLevel == MigrationReadinessLevel.insufficientData) {
      recommendations.add(
        const MemorizationRecommendation(
          type: RecommendationType.fsrsNotReady,
          priority: RecommendationPriority.low,
          title: 'Keep Reviewing',
          description: 'Continue using the app normally while we collect more learning data.',
        ),
      );
    }

    // Sort by priority descending
    recommendations.sort((a, b) => b.priority.weight.compareTo(a.priority.weight));

    return MemorizationRecommendationsReport(recommendations: recommendations);
  }
}
