import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/memorization/kids_hifz_feature_flags.dart';
import 'package:talia_quran/features/settings/presentation/pages/labs_flags_page.dart';

void main() {
  testWidgets('every toggle asks for a notification refresh', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LabsFlagsPage(prefs: prefs, onFlagChanged: (_) => refreshes++),
      ),
    );
    final key = ExperienceFeature.forgettingForecast.storageKey;
    final tile = find.byKey(ValueKey('labs_flag_$key'));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(tile);
    await tester.pump();
    await tester.tap(tile);
    await tester.pump();
    // On by default, so two taps end back on.
    expect(prefs.getBool(key), isTrue);
    expect(refreshes, 2);
  });

  testWidgets(
    'labs page lists every family and toggling writes the exact key',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(MaterialApp(home: LabsFlagsPage(prefs: prefs)));

      for (final title in [
        'KidsEnrichmentFeature',
        'AdultJourneyFeature',
        'KidsHifzFeatureFlags',
        'ExperienceFeature',
      ]) {
        expect(find.text(title), findsOneWidget);
      }

      Future<void> toggle(String key) async {
        final tile = find.byKey(ValueKey('labs_flag_$key'));
        await tester.scrollUntilVisible(
          tile,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(tile);
        await tester.pump();
      }

      // Shipped on by default, so the first tap stores off.
      await toggle('kids_enrichment_homeMissionTemplates');
      expect(prefs.getBool('kids_enrichment_homeMissionTemplates'), isFalse);

      // The Quran journey is on by default, so the switch starts on.
      final journeyTile = tester.widget<SwitchListTile>(
        find.byKey(
          const ValueKey('labs_flag_${KidsHifzFeatureFlags.quranJourneyKey}'),
        ),
      );
      expect(journeyTile.value, isTrue);
      await toggle(KidsHifzFeatureFlags.quranJourneyKey);
      expect(prefs.getBool(KidsHifzFeatureFlags.quranJourneyKey), isFalse);

      await toggle(ExperienceFeature.strengthOverlay.storageKey);
      expect(prefs.getBool('experience_flag_strengthOverlay'), isFalse);

      await toggle(ExperienceFeature.strengthOverlay.storageKey);
      expect(prefs.getBool('experience_flag_strengthOverlay'), isTrue);
    },
  );

  testWidgets('shows the default, marks a local change and resets it', (
    tester,
  ) async {
    final key = ExperienceFeature.similarAyahTrainer.storageKey;
    SharedPreferences.setMockInitialValues({key: true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MaterialApp(home: LabsFlagsPage(prefs: prefs, onFlagChanged: (_) {})),
    );
    final tile = find.byKey(ValueKey('labs_flag_$key'));
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('default: off · changed locally'), findsOne);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(find.byKey(ValueKey('labs_reset_$key')));
    await tester.pump();
    expect(prefs.containsKey(key), isFalse);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    expect(find.byKey(ValueKey('labs_reset_$key')), findsNothing);
  });
}
