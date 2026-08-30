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
      await _datasource.saveCustomPlan(
        CustomMemorizationPlanModel.fromEntity(plan),
      );
      await _prefs.setBool(PlanCloudDirtyKeys.customPlan, true);
      await _prefs.setString(
        PlanCloudDirtyKeys.customPlanLocalUpdatedAt,
        DateTime.now().toUtc().toIso8601String(),
      );
      // Clear the cached daily plan so that a stale surahId from a previous
      // session does not override the correct entry point (endSurahId) when
      // the user returns to the app after saving a new plan.
      try {
        await _datasource.clearDailyPlanCache();
      } catch (_) {
        // Non-critical: cache clearing failure should not block plan saving.
      }
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
