enum RecommendationPriority {
  low,
  medium,
  high,
  critical,
}

extension RecommendationPriorityExt on RecommendationPriority {
  int get weight {
    switch (this) {
      case RecommendationPriority.critical:
        return 4;
      case RecommendationPriority.high:
        return 3;
      case RecommendationPriority.medium:
        return 2;
      case RecommendationPriority.low:
        return 1;
    }
  }
}

enum RecommendationType {
  leechRecovery,
  overloadRisk,
  retentionDrop,
  retentionExcellent,
  fsrsReady,
  fsrsNotReady,
  reviewBacklog,
}

class MemorizationRecommendation {
  const MemorizationRecommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
  });

  final RecommendationType type;
  final RecommendationPriority priority;
  final String title;
  final String description;
}

class MemorizationRecommendationsReport {
  const MemorizationRecommendationsReport({
    required this.recommendations,
  });

  final List<MemorizationRecommendation> recommendations;
}
