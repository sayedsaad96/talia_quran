import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/memorization/kids_enrichment_feature_flags.dart';
import 'package:talia_quran/core/memorization/kids_hifz_feature_flags.dart';

void main() {
  late SharedPreferences prefs;

  Future<void> seed(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
  }

  test('missingFlagIsOff', () async {
    await seed({});
    final flags = KidsEnrichmentFlags.fromPreferences(prefs);
    for (final feature in KidsEnrichmentFeature.values) {
      expect(flags.isEnabled(feature), isFalse, reason: feature.name);
    }
  });

  test('roadmap flags are appended in order and off by default', () async {
    expect(KidsEnrichmentFeature.values.map((e) => e.name).toList(), [
      'homeMissionTemplates',
      'effortAchievements',
      'weeklyCoaching',
      'familyPractice',
      'learningLessons',
      'spokenGuidance',
      'supportProfile',
      'supportActions',
      'learningGames',
      'worldGrowth',
      'weeklyPack',
      'recitationPortfolio',
      'guardianCertificates',
      'bedtimeListening',
      'guardianPromise',
      'guardianRecitation',
      'guardianMilestones',
      'monthlyReport',
      'remotePlan',
      'remotePromise',
      'encouragements',
    ]);
    await seed({});
    final flags = KidsEnrichmentFlags.fromPreferences(prefs);
    for (final name in [
      'guardianCertificates',
      'bedtimeListening',
      'guardianPromise',
      'guardianRecitation',
      'guardianMilestones',
      'monthlyReport',
      'remotePlan',
      'remotePromise',
      'encouragements',
    ]) {
      final feature = KidsEnrichmentFeature.values.firstWhere(
        (e) => e.name == name,
      );
      expect(feature.storageKey, 'kids_enrichment_$name');
      expect(flags.isEnabled(feature), isFalse, reason: name);
    }
  });

  test('a flag turns on only its own feature', () async {
    await seed({KidsEnrichmentFeature.homeMissionTemplates.storageKey: true});
    final flags = KidsEnrichmentFlags.fromPreferences(prefs);
    expect(flags.isEnabled(KidsEnrichmentFeature.homeMissionTemplates), isTrue);
    for (final feature in KidsEnrichmentFeature.values.where(
      (f) => f != KidsEnrichmentFeature.homeMissionTemplates,
    )) {
      expect(flags.isEnabled(feature), isFalse, reason: feature.name);
    }
  });

  test('a mistyped or unreadable value counts as off', () async {
    await seed({KidsEnrichmentFeature.weeklyCoaching.storageKey: 'true'});
    expect(
      KidsEnrichmentFlags.fromPreferences(
        prefs,
      ).isEnabled(KidsEnrichmentFeature.weeklyCoaching),
      isFalse,
    );
    expect(
      KidsEnrichmentFlags(
        (_) => throw StateError('storage unavailable'),
      ).isEnabled(KidsEnrichmentFeature.weeklyCoaching),
      isFalse,
    );
  });

  test('disablingOneFeatureDoesNotDisableKidsPath', () async {
    await seed({
      KidsHifzFeatureFlags.enabledKey: true,
      KidsEnrichmentFeature.effortAchievements.storageKey: false,
    });
    expect(KidsHifzFeatureFlags.isEnabled(prefs), isTrue);
    expect(
      KidsEnrichmentFlags.fromPreferences(
        prefs,
      ).isEnabled(KidsEnrichmentFeature.effortAchievements),
      isFalse,
    );
  });

  test('storage keys are unique and never collide with the kids V2 key', () {
    final keys = KidsEnrichmentFeature.values.map((f) => f.storageKey).toList();
    expect(keys.toSet().length, keys.length);
    expect(keys, isNot(contains(KidsHifzFeatureFlags.enabledKey)));
  });

  test('keys are not account-owned, so an account switch keeps them', () {
    for (final feature in KidsEnrichmentFeature.values) {
      final key = feature.storageKey;
      expect(AccountDataReset.clearedPreferenceKeys, isNot(contains(key)));
      expect(
        AccountDataReset.clearedPreferencePrefixes.any(key.startsWith),
        isFalse,
        reason: '$key would be wiped on account switch',
      );
    }
  });
}
