part of 'memorization_plus_local_datasource.dart';

/// Daily-plan cache and custom-memorization-plan storage.
mixin MemorizationPlansStorageMixin on MemorizationLocalStorageMixin {
  Future<DailyPlanModel?> getCachedDailyPlan() async {
    final raw = _prefs.getString(
      MemorizationPlusLocalDatasourceImpl._kDailyPlan,
    );
    if (raw == null) return null;
    return _tryParse(raw, DailyPlanModel.fromJson);
  }

  Future<void> saveDailyPlan(DailyPlanModel plan) => _setStringOrThrow(
    MemorizationPlusLocalDatasourceImpl._kDailyPlan,
    jsonEncode(plan.toJson()),
  );

  Future<void> clearDailyPlanCache() async =>
      _prefs.remove(MemorizationPlusLocalDatasourceImpl._kDailyPlan);

  @override
  Future<CustomMemorizationPlanModel?> getCustomPlan() async {
    final raw = _prefs.getString(
      MemorizationPlusLocalDatasourceImpl._kCustomPlan,
    );
    if (raw == null) return null;
    return _tryParse(raw, CustomMemorizationPlanModel.fromJson);
  }

  Future<void> saveCustomPlan(CustomMemorizationPlanModel plan) =>
      _setStringOrThrow(
        MemorizationPlusLocalDatasourceImpl._kCustomPlan,
        jsonEncode(plan.toJson()),
      );

  Future<void> deleteCustomPlan() =>
      _removeOrThrow(MemorizationPlusLocalDatasourceImpl._kCustomPlan);
}
