import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/memorization/cloud_sync_feature_flags.dart';

void main() {
  test('production pull is enabled by default', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(
      CloudSyncFeatureFlags.isProductionPullEnabled(prefs),
      isTrue,
    );
  });

  test('production pull can be opted out via prefs', () async {
    SharedPreferences.setMockInitialValues({
      CloudSyncFeatureFlags.productionPullKey: false,
    });
    final prefs = await SharedPreferences.getInstance();

    expect(
      CloudSyncFeatureFlags.isProductionPullEnabled(prefs),
      isFalse,
    );
  });

  test('review evidence transport is disabled until explicitly enabled', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(CloudSyncFeatureFlags.isReviewEvidenceTransportEnabled(prefs), isFalse);

    SharedPreferences.setMockInitialValues({
      CloudSyncFeatureFlags.reviewEvidenceTransportKey: true,
    });
    final enabledPrefs = await SharedPreferences.getInstance();
    expect(
      CloudSyncFeatureFlags.isReviewEvidenceTransportEnabled(enabledPrefs),
      isTrue,
    );
  });
}
