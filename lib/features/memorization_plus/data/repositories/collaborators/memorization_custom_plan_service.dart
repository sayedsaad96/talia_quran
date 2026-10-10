import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/error/app_failure.dart';
import '../../../../../core/memorization/plan_cloud_dirty_keys.dart';
import '../../../domain/entities/memorization_entities.dart';
import '../../datasources/memorization_plus_local_datasource.dart';
import '../../models/memorization_models.dart';

/// Custom memorization plan domain: read, save and delete the user's custom
/// plan. Saving also clears the daily-plan cache so a stale entry point never
/// overrides the freshly configured range.
class MemorizationCustomPlanService {
  MemorizationCustomPlanService(this._datasource, this._prefs);

  final MemorizationPlusLocalDatasource _datasource;
  final SharedPreferences _prefs;

  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async {
    try {
      final plan = await _datasource.getCustomPlan();
      return Right(plan);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, void>> saveCustomPlan(
    CustomMemorizationPlan plan,
  ) async {
    try {
      // Invalidate before replacing the plan. If invalidation cannot be
      // persisted, do not report a successful save while an old daily plan
      // can still launch under the new settings.
      await _datasource.clearDailyPlanCache();
      await _datasource.saveCustomPlan(
        CustomMemorizationPlanModel.fromEntity(plan),
      );
      await _prefs.setBool(PlanCloudDirtyKeys.customPlan, true);
      await _prefs.setString(
        PlanCloudDirtyKeys.customPlanLocalUpdatedAt,
        DateTime.now().toUtc().toIso8601String(),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  Future<Either<Failure, void>> deleteCustomPlan() async {
    try {
      await _datasource.deleteCustomPlan();
      await _prefs.setBool(PlanCloudDirtyKeys.customPlan, true);
      await _prefs.setString(
        PlanCloudDirtyKeys.customPlanLocalUpdatedAt,
        DateTime.now().toUtc().toIso8601String(),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }
}
