import '../usecases/get_activity_heatmap_usecase.dart';

abstract class HeatmapRepository {
  Future<ActivityHeatmapData> getHeatmapData();
}
