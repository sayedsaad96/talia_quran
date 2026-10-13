import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/adult_journey/adult_journey_feature_flags.dart';

AdultJourneyFlags _flags(Map<String, Object?> values) =>
    AdultJourneyFlags((key) => values[key] as bool?);

void main() {
  const p = 'adult_journey_flag_personalization';
  const t = 'adult_journey_flag_todayBudget';
  const g = 'adult_journey_flag_gentleReturn';

  test('everything is off by default', () {
    final flags = _flags({});
    for (final feature in AdultJourneyFeature.values) {
      expect(flags.isEnabled(feature), isFalse);
    }
    expect(flags.gentleReturnTimeActionsEnabled, isFalse);
  });

  test('personalization off disables the whole package', () {
    final flags = _flags({t: true, g: true});
    expect(flags.isEnabled(AdultJourneyFeature.todayBudget), isFalse);
    expect(flags.isEnabled(AdultJourneyFeature.gentleReturn), isFalse);
  });

  test('gentle return time actions also need the today budget', () {
    expect(_flags({p: true, g: true}).gentleReturnTimeActionsEnabled, isFalse);
    expect(
      _flags({p: true, g: true, t: true}).gentleReturnTimeActionsEnabled,
      isTrue,
    );
  });

  test('a read failure counts as off', () {
    final flags = AdultJourneyFlags((_) => throw StateError('prefs'));
    expect(flags.isEnabled(AdultJourneyFeature.personalization), isFalse);
  });

  test('rollout keys stay outside the account-owned prefix', () {
    for (final feature in AdultJourneyFeature.values) {
      expect(feature.storageKey.startsWith('adult_journey_v1_'), isFalse);
    }
  });
}
