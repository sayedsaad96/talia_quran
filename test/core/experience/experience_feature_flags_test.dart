import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/experience/rollout_manifest.dart';

void main() {
  test('missing / non-bool / throwing read -> false', () async {
    expect(
      const ExperienceFlags(_null).isEnabled(ExperienceFeature.trustCenter),
      isFalse,
    );
    expect(
      ExperienceFlags(
        (_) => throw StateError('boom'),
      ).isEnabled(ExperienceFeature.trustCenter),
      isFalse,
    );
    SharedPreferences.setMockInitialValues({
      ExperienceFeature.trustCenter.storageKey: 'yes',
      ExperienceFeature.readerRepeat.storageKey: true,
    });
    final flags = ExperienceFlags.fromPreferences(
      await SharedPreferences.getInstance(),
    );
    expect(flags.isEnabled(ExperienceFeature.trustCenter), isFalse);
    expect(flags.isEnabled(ExperienceFeature.readerRepeat), isTrue);
    // Missing values fall back to the shipped rollout default.
    expect(
      flags.isEnabled(ExperienceFeature.strengthOverlay),
      RolloutManifest.defaultFor(ExperienceFeature.strengthOverlay.storageKey),
    );
  });

  test('storage keys are experience_flag_<name> and unique', () {
    final keys = ExperienceFeature.values.map((f) => f.storageKey).toList();
    expect(keys.toSet().length, keys.length);
    for (final f in ExperienceFeature.values) {
      expect(f.storageKey, 'experience_flag_${f.name}');
    }
    expect(ExperienceFeature.values.length, 17);
  });
}

bool? _null(String key) => null;
