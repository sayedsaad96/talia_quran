import '../entities/memorization_entities.dart';

class LeechAnalysisResult {
  const LeechAnalysisResult({
    required this.totalLeeches,
    required this.percentageOfLeeches,
    required this.averageLapses,
  });

  final int totalLeeches;
  final double percentageOfLeeches;
  final double averageLapses;
}

class LeechAnalysisUsecase {
  const LeechAnalysisUsecase();

  LeechAnalysisResult analyze(List<AyahReviewRecord> records) {
    int totalLeeches = 0;
    int totalLapsesInLeeches = 0;

    for (final record in records) {
      if (record.isLeech) {
        totalLeeches++;
        totalLapsesInLeeches += record.lapses;
      }
    }

    final double percentage = records.isEmpty ? 0.0 : totalLeeches / records.length;
    final double averageLapses = totalLeeches == 0 ? 0.0 : totalLapsesInLeeches / totalLeeches;

    return LeechAnalysisResult(
      totalLeeches: totalLeeches,
      percentageOfLeeches: percentage,
      averageLapses: averageLapses,
    );
  }
}
