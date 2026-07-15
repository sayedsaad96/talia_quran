import 'package:shared_preferences/shared_preferences.dart';

/// Feature flags for cloud production sync (Sprint 2 — B6).
class CloudSyncFeatureFlags {
  CloudSyncFeatureFlags._();

  static const productionPullKey = 'use_cloud_production_pull';

  /// Production SRS pull is enabled by default. Set
  /// [productionPullKey] to `false` in SharedPreferences to opt out.
  static bool isProductionPullEnabled(SharedPreferences prefs) =>
      prefs.getBool(productionPullKey) ?? true;
}
