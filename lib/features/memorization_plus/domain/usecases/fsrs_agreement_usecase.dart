import '../entities/memorization_entities.dart';

class FsrsAgreementResult {
  const FsrsAgreementResult({
    required this.agreementScore,
    required this.totalRecords,
    required this.strongAgreementCount,
    required this.moderateAgreementCount,
    required this.majorDisagreementCount,
  });

  final double agreementScore;
  final int totalRecords;
  final int strongAgreementCount;
  final int moderateAgreementCount;
  final int majorDisagreementCount;

  double get agreementPercentage => agreementScore * 100;
}

class FsrsAgreementUsecase {
  const FsrsAgreementUsecase();

  FsrsAgreementResult analyze(List<AyahReviewRecord> records) {
    int validRecords = 0;
    int strong = 0;
    int moderate = 0;
    int major = 0;
    double totalScore = 0.0;

    for (final record in records) {
      if (record.predictedFsrsIntervalDays == null || record.schedulerVsFsrsGapDays == null) {
        continue;
      }

      validRecords++;
      final gap = record.schedulerVsFsrsGapDays!.abs();

      if (gap <= 7) {
        strong++;
        totalScore += 1.0;
      } else if (gap <= 30) {
        moderate++;
        totalScore += 0.6;
      } else {
        major++;
        totalScore += 0.0;
      }
    }

    final double score = validRecords == 0 ? 0.0 : totalScore / validRecords;

    return FsrsAgreementResult(
      agreementScore: score,
      totalRecords: validRecords,
      strongAgreementCount: strong,
      moderateAgreementCount: moderate,
      majorDisagreementCount: major,
    );
  }
}
