import 'package:isar/isar.dart';

import '../../../streak/data/models/daily_activity_isar.dart';
import '../../domain/repositories/heatmap_repository.dart';
import '../../domain/usecases/get_activity_heatmap_usecase.dart';

class HeatmapRepositoryImpl implements HeatmapRepository {
  final Isar _isar;

  const HeatmapRepositoryImpl(this._isar);

  @override
  Future<ActivityHeatmapData> getHeatmapData() async {
    try {
      final now = DateTime.now();
      final fallbackStartDate = now.subtract(
        const Duration(days: GetActivityHeatmapUsecase.historyDays ~/ 2),
      );
      final oldestVisibleDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: GetActivityHeatmapUsecase.historyDays));
      final oldestVisibleDayKey = _dayKey(oldestVisibleDay);
      final dailyRecords = await _isar.dailyActivityIsars
          .where()
          .dayKeyGreaterThan(oldestVisibleDayKey - 1)
          .findAll();

      final map = <String, int>{};
      DateTime? earliestDate;

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
          const Duration(days: GetActivityHeatmapUsecase.historyDays ~/ 2),
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
