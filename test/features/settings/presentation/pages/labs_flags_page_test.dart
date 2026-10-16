import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/memorization/kids_hifz_feature_flags.dart';
import 'package:talia_quran/features/settings/presentation/pages/labs_flags_page.dart';

void main() {
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

      await toggle('kids_enrichment_homeMissionTemplates');
      expect(prefs.getBool('kids_enrichment_homeMissionTemplates'), isTrue);

      await toggle(KidsHifzFeatureFlags.quranJourneyKey);
      expect(prefs.getBool(KidsHifzFeatureFlags.quranJourneyKey), isTrue);

      await toggle(ExperienceFeature.strengthOverlay.storageKey);
      expect(prefs.getBool('experience_flag_strengthOverlay'), isTrue);

      await toggle(ExperienceFeature.strengthOverlay.storageKey);
      expect(prefs.getBool('experience_flag_strengthOverlay'), isFalse);
    },
  );
}
