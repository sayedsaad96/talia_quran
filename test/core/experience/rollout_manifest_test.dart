import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/experience/rollout_manifest.dart';
import 'package:talia_quran/core/memorization/kids_enrichment_feature_flags.dart';
import 'package:talia_quran/core/memorization/kids_hifz_feature_flags.dart';
import 'package:talia_quran/features/adult_journey/adult_journey_feature_flags.dart';

void main() {
  final allKeys = [
    for (final f in ExperienceFeature.values) f.storageKey,
    for (final f in KidsEnrichmentFeature.values) f.storageKey,
    for (final f in AdultJourneyFeature.values) f.storageKey,
    KidsHifzFeatureFlags.enabledKey,
    KidsHifzFeatureFlags.quranJourneyKey,
  ];

  test('every flag has exactly one entry and nothing else is listed', () {
    final keys = RolloutManifest.entries.map((e) => e.key).toList();
    expect(keys.toSet(), allKeys.toSet());
    expect(keys.length, keys.toSet().length);
  });

  test('every on entry cites a section of rollout-evidence.md; every off '
      'entry gives a reason', () {
    final doc = File('docs/release/rollout-evidence.md').readAsStringSync();
    for (final entry in RolloutManifest.entries) {
      if (entry.stage == RolloutStage.on) {
        expect(entry.evidence, isNotNull, reason: entry.key);
        expect(doc, contains('## ${entry.evidence}'), reason: entry.key);
      } else {
        expect(entry.reason, isNotEmpty, reason: entry.key);
        expect(
          doc,
          contains('`${entry.key.split('_').last}`'),
          reason: entry.key,
        );
      }
    }
  });

  test('requirements exist and no on entry depends on an off one', () {
    for (final entry in RolloutManifest.entries) {
      for (final required in entry.requires) {
        final dependency = RolloutManifest.entryFor(required);
        expect(dependency, isNotNull, reason: '${entry.key} -> $required');
        if (entry.stage == RolloutStage.on) {
          expect(dependency!.stage, RolloutStage.on, reason: entry.key);
        }
      }
    }
  });

  test('unknown keys default off', () {
    expect(RolloutManifest.defaultFor('experience_flag_unknown'), isFalse);
  });

  group('reading through the flag families', () {
    Future<SharedPreferences> prefs(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      return SharedPreferences.getInstance();
    }

    test('no stored value: the shipped default', () async {
      final p = await prefs({});
      final experience = ExperienceFlags.fromPreferences(p);
      expect(experience.isEnabled(ExperienceFeature.strengthOverlay), isTrue);
      expect(
        experience.isEnabled(ExperienceFeature.similarAyahTrainer),
        isTrue,
      );
      expect(
        KidsEnrichmentFlags.fromPreferences(
          p,
        ).isEnabled(KidsEnrichmentFeature.learningGames),
        isTrue,
      );
      expect(
        AdultJourneyFlags.fromPreferences(
          p,
        ).isEnabled(AdultJourneyFeature.todayBudget),
        isTrue,
      );
      expect(KidsHifzFeatureFlags.isEnabled(p), isTrue);
      expect(KidsHifzFeatureFlags.isQuranJourneyEnabled(p), isTrue);
    });

    test('a stored value always wins over the default', () async {
      final p = await prefs({
        ExperienceFeature.strengthOverlay.storageKey: false,
        ExperienceFeature.similarAyahTrainer.storageKey: false,
      });
      final experience = ExperienceFlags.fromPreferences(p);
      expect(experience.isEnabled(ExperienceFeature.strengthOverlay), isFalse);
      expect(
        experience.isEnabled(ExperienceFeature.similarAyahTrainer),
        isFalse,
      );
    });

    test('a stored dependency off still turns its dependents off', () async {
      final p = await prefs({
        AdultJourneyFeature.personalization.storageKey: false,
      });
      expect(
        AdultJourneyFlags.fromPreferences(
          p,
        ).isEnabled(AdultJourneyFeature.todayBudget),
        isFalse,
      );
    });

    test('a value of the wrong type reads as off', () async {
      final p = await prefs({
        ExperienceFeature.strengthOverlay.storageKey: 'yes',
      });
      expect(
        ExperienceFlags.fromPreferences(
          p,
        ).isEnabled(ExperienceFeature.strengthOverlay),
        isFalse,
      );
    });

    test('the plain constructor keeps "missing means off"', () {
      const flags = ExperienceFlags(_alwaysMissing);
      expect(flags.isEnabled(ExperienceFeature.strengthOverlay), isFalse);
    });
  });
}

bool? _alwaysMissing(String _) => null;
