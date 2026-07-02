import '../entities/memorization_entities.dart';

class RetentionInsightsUsecase {
  const RetentionInsightsUsecase();

  double analyze(List<AyahReviewRecord> records) {
    int totalReviewedAyahs = 0;
    int excellentAyahs = 0;

    for (final record in records) {
      if (record.totalReviews > 0) {
        totalReviewedAyahs++;
        if (record.lastRating == PerformanceRating.excellent) {
          excellentAyahs++;
        }
      }
    }

    if (totalReviewedAyahs == 0) return 0.0;

    return excellentAyahs / totalReviewedAyahs;
  }
}
