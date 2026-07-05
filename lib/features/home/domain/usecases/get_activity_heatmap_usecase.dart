import '../repositories/heatmap_repository.dart';

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
  const GetActivityHeatmapUsecase(this._repository);

  static const int historyDays = 730;

  final HeatmapRepository _repository;

  Future<ActivityHeatmapData> call() async {
    return _repository.getHeatmapData();
  }
}
