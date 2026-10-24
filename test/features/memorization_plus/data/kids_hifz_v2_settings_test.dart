import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/kids_hifz_feature_flags.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';

void main() {
  Future<MemorizationPlusLocalDatasourceImpl> datasource(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    return MemorizationPlusLocalDatasourceImpl(
      await SharedPreferences.getInstance(),
      owner: const FixedRecordOwnerProvider('owner'),
    );
  }

  test('settings report the effective kids V2 switch, not a stale copy', () async {
    // No stored switch: the shipped default (on) applies, even though the
    // saved settings JSON still carries the old false.
    final ds = await datasource({});
    await ds.saveParentSettings(
      const ParentSettingsModel(reminderHour: 7),
    );
    final settings = await ds.getParentSettings();
    expect(settings.kidsHifzV2Enabled, isTrue);
    expect(settings.reminderHour, 7);
  });

  test('a stored off switch is reported as off', () async {
    final ds = await datasource({KidsHifzFeatureFlags.enabledKey: false});
    expect((await ds.getParentSettings()).kidsHifzV2Enabled, isFalse);
  });
}
