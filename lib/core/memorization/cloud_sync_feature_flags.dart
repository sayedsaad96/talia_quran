/// Feature flags for cloud production sync (Sprint 2 — B6).
///
/// [productionPullKey] defaults to false so existing installs keep push-only
/// behavior until staging validates pull + merge.
class CloudSyncFeatureFlags {
  CloudSyncFeatureFlags._();

  static const productionPullKey = 'use_cloud_production_pull';

  static bool isProductionPullEnabled({
    required bool Function(String key) readBool,
  }) =>
      readBool(productionPullKey);
}
