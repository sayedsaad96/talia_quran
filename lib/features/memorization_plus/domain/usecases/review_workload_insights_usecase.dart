import '../entities/memorization_entities.dart';

class ReviewWorkloadInsightsResult {
  const ReviewWorkloadInsightsResult({
    required this.dueNow,
    required this.dueNext7Days,
    required this.dueNext30Days,
    required this.healthScore,
  });

  final int dueNow;
  final int dueNext7Days;
  final int dueNext30Days;
  final WorkloadHealth healthScore;
}

class ReviewWorkloadInsightsUsecase {
  const ReviewWorkloadInsightsUsecase();

  ReviewWorkloadInsightsResult analyze(List<AyahReviewRecord> records, DateTime now) {
    int dueNow = 0;
    int dueNext7Days = 0;
    int dueNext30Days = 0;

    final next7Days = now.add(const Duration(days: 7));
    final next30Days = now.add(const Duration(days: 30));

    for (final record in records) {
      if (record.strengthLevel == 0) continue;
      
      if (record.nextReviewDate.isBefore(now) || record.nextReviewDate.isAtSameMomentAs(now)) {
        dueNow++;
      }
      
      if (record.nextReviewDate.isBefore(next7Days)) {
        dueNext7Days++;
      }
      
      if (record.nextReviewDate.isBefore(next30Days)) {
        dueNext30Days++;
      }
    }

    WorkloadHealth health;
    if (dueNow > 100) {
      health = WorkloadHealth.critical;
    } else if (dueNow > 50 || dueNext7Days > 300) {
      health = WorkloadHealth.heavy;
    } else if (dueNow > 20 || dueNext7Days > 100) {
      health = WorkloadHealth.moderate;
    } else {
      health = WorkloadHealth.healthy;
    }

    return ReviewWorkloadInsightsResult(
      dueNow: dueNow,
      dueNext7Days: dueNext7Days,
      dueNext30Days: dueNext30Days,
      healthScore: health,
    );
  }
}
