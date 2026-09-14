import 'package:shared_preferences/shared_preferences.dart';

/// Feature flags for cloud production sync (Sprint 2 — B6).
class CloudSyncFeatureFlags {
  CloudSyncFeatureFlags._();

  static const productionPullKey = 'use_cloud_production_pull';
  static const reviewEvidenceTransportKey = 'use_review_evidence_transport';

  /// Production SRS pull is enabled by default. Set
  /// [productionPullKey] to `false` in SharedPreferences to opt out.
  static bool isProductionPullEnabled(SharedPreferences prefs) =>
      prefs.getBool(productionPullKey) ?? true;

  /// The immutable evidence ledger remains opt-in until its runtime release
  /// gate has completed. Projection sync is intentionally unaffected.
  static bool isReviewEvidenceTransportEnabled(SharedPreferences prefs) =>
      prefs.getBool(reviewEvidenceTransportKey) ?? false;
}
