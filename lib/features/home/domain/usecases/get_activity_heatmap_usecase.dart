import 'package:isar/isar.dart';

import '../../../hifz/data/models/isar_ayah_progress.dart';
import '../../../streak/data/models/daily_activity_isar.dart';

/// Result object for the activity heatmap widget.
class ActivityHeatmapData {
  const ActivityHeatmapData({
    required this.countsByDay,
    required this.startDate,
  });

  /// Map of 'YYYY-MM-DD' → activity count.
  final Map<String, int> countsByDay;

  /// Earliest date with any activity — used as the heatmap start anchor.
  final DateTime startDate;
}

/// Aggregates Hifz review dates and daily activity records into a single
/// heatmap data object.
///
/// Keeping this logic out of the cubit removes the direct Isar dependency
/// from the presentation layer and makes the aggregation unit-testable.
class GetActivityHeatmapUsecase {
  const GetActivityHeatmapUsecase(this._isar);

  static const int historyDays = 730;

  final Isar _isar;

  Future<ActivityHeatmapData> call() async {
    try {
      final now = DateTime.now();
      final fallbackStartDate = now.subtract(
        const Duration(days: historyDays ~/ 2),
      );
      final oldestVisibleDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: historyDays));
      final oldestVisibleDayKey = _dayKey(oldestVisibleDay);
      final allProgress = await _isar.isarAyahProgress.where().findAll();
      final dailyRecords = await _isar.dailyActivityIsars
          .where()
          .dayKeyGreaterThan(oldestVisibleDayKey - 1)
          .findAll();

      final map = <String, int>{};
      DateTime? earliestDate;

      for (final progress in allProgress) {
        final date = progress.lastReviewDate;
        if (date.isBefore(oldestVisibleDay)) continue;
        if (earliestDate == null || date.isBefore(earliestDate)) {
          earliestDate = date;
        }
        final key = _dateKey(date);
        map[key] = (map[key] ?? 0) + 1;
      }

      for (final record in dailyRecords) {
        final recordDate = _dateFromDayKey(record.dayKey);
        if (earliestDate == null || recordDate.isBefore(earliestDate)) {
          earliestDate = recordDate;
        }
        final key = _dateKey(recordDate);
        final existing = map[key] ?? 0;
        if (record.activityCount > existing) {
          map[key] = record.activityCount;
        }
      }

      return ActivityHeatmapData(
        countsByDay: map,
        startDate: earliestDate ?? fallbackStartDate,
      );
    } catch (_) {
      return ActivityHeatmapData(
        countsByDay: const {},
        startDate: DateTime.now().subtract(
          const Duration(days: historyDays ~/ 2),
        ),
      );
    }
  }

  int _dayKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

  DateTime _dateFromDayKey(int dayKey) {
    final year = dayKey ~/ 10000;
    final month = (dayKey % 10000) ~/ 100;
    final day = dayKey % 100;
    return DateTime(year, month, day);
  }

  String _dateKey(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
