import '../entities/memorization_entities.dart';

class FsrsAnalyticsReport {
  const FsrsAnalyticsReport({
    required this.totalRecords,
    required this.averageGapDays,
    required this.averageRatio,
    required this.schedulerEarlierCount,
    required this.fsrsEarlierCount,
    required this.gapDistribution,
  });

  final int totalRecords;
  final double averageGapDays;
  final double averageRatio;
  final int schedulerEarlierCount;
  final int fsrsEarlierCount;
  final Map<String, int> gapDistribution;
}

class FsrsAnalyticsService {
  const FsrsAnalyticsService();

  FsrsAnalyticsReport analyze(List<AyahReviewRecord> records) {
    if (records.isEmpty) {
      return const FsrsAnalyticsReport(
        totalRecords: 0,
        averageGapDays: 0.0,
        averageRatio: 0.0,
        schedulerEarlierCount: 0,
        fsrsEarlierCount: 0,
        gapDistribution: {
          '<-90': 0,
          '-90..-31': 0,
          '-30..-8': 0,
          '-7..7': 0,
          '8..30': 0,
          '31..90': 0,
          '91+': 0,
        },
      );
    }

    int totalGap = 0;
    double totalRatio = 0.0;
    int schedulerEarlier = 0;
    int fsrsEarlier = 0;

    final distribution = {
      '<-90': 0,
      '-90..-31': 0,
      '-30..-8': 0,
      '-7..7': 0,
      '8..30': 0,
      '31..90': 0,
      '91+': 0,
    };

    int validRecords = 0;

    for (final record in records) {
      if (record.schedulerVsFsrsGapDays == null ||
          record.schedulerVsFsrsRatio == null) {
        continue;
      }

      validRecords++;
      final gap = record.schedulerVsFsrsGapDays!;
      
      totalGap += gap;
      totalRatio += record.schedulerVsFsrsRatio!;
      
      if (record.schedulerEarlierThanFsrs == true) {
        schedulerEarlier++;
      } else if (record.schedulerEarlierThanFsrs == false) {
        fsrsEarlier++;
      }

      if (gap < -90) {
        distribution['<-90'] = distribution['<-90']! + 1;
      } else if (gap >= -90 && gap <= -31) {
        distribution['-90..-31'] = distribution['-90..-31']! + 1;
      } else if (gap >= -30 && gap <= -8) {
        distribution['-30..-8'] = distribution['-30..-8']! + 1;
      } else if (gap >= -7 && gap <= 7) {
        distribution['-7..7'] = distribution['-7..7']! + 1;
      } else if (gap >= 8 && gap <= 30) {
        distribution['8..30'] = distribution['8..30']! + 1;
      } else if (gap >= 31 && gap <= 90) {
        distribution['31..90'] = distribution['31..90']! + 1;
      } else {
        distribution['91+'] = distribution['91+']! + 1;
      }
    }

    if (validRecords == 0) {
       return const FsrsAnalyticsReport(
        totalRecords: 0,
        averageGapDays: 0.0,
        averageRatio: 0.0,
        schedulerEarlierCount: 0,
        fsrsEarlierCount: 0,
        gapDistribution: {
          '<-90': 0,
          '-90..-31': 0,
          '-30..-8': 0,
          '-7..7': 0,
          '8..30': 0,
          '31..90': 0,
          '91+': 0,
        },
      );
    }

    return FsrsAnalyticsReport(
      totalRecords: validRecords,
      averageGapDays: totalGap / validRecords,
      averageRatio: totalRatio / validRecords,
      schedulerEarlierCount: schedulerEarlier,
      fsrsEarlierCount: fsrsEarlier,
      gapDistribution: distribution,
    );
  }
}
