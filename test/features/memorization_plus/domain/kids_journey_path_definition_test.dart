import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/memorization/kids_hifz_feature_flags.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';

void main() {
  test('adventure keeps the existing path verbatim', () {
    expect(
      KidsJourneyPathDefinition.adventure.surahIds,
      KidsJourneyPath.surahIds,
    );
    expect(
      KidsJourneyPathId.juzAmmaAdventure.storageValue,
      'fatiha_then_juz_amma',
    );
    expect(KidsJourneyPathDefinition.adventure.nextAfter(78), isNull);
    expect(KidsJourneyPathDefinition.adventure.locksAhead, isTrue);
  });
  test('quranFromNas: Fatiha, then 114 down to 2', () {
    final p = KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas);
    expect(p.surahIds.length, 114);
    expect(p.surahIds.take(3), [1, 114, 113]);
    expect(p.surahIds.last, 2);
    expect(p.nextAfter(1), 114);
    expect(p.nextAfter(3), 2);
    expect(p.nextAfter(2), isNull);
    expect(p.locksAhead, isFalse);
    expect(p.isQuranJourney, isTrue);
  });
  test('quranFromFatiha: 1..114', () {
    final p = KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromFatiha);
    expect(p.surahIds, List.generate(114, (i) => i + 1));
    expect(p.nextAfter(113), 114);
    expect(p.nextAfter(114), isNull);
    expect(p.contains(2), isTrue);
  });
  test('parse falls back to the adventure', () {
    for (final raw in [null, '', 'x', 'QURAN_FROM_NAS']) {
      expect(KidsJourneyPathId.parse(raw), KidsJourneyPathId.juzAmmaAdventure);
    }
    expect(
      KidsJourneyPathId.parse('quran_from_nas'),
      KidsJourneyPathId.quranFromNas,
    );
  });
  test('flag off forces the adventure', () {
    expect(
      resolveKidsJourneyPath(
        storedPathId: 'quran_from_nas',
        quranJourneyEnabled: false,
      ).id,
      KidsJourneyPathId.juzAmmaAdventure,
    );
    expect(
      resolveKidsJourneyPath(
        storedPathId: 'quran_from_nas',
        quranJourneyEnabled: true,
      ).id,
      KidsJourneyPathId.quranFromNas,
    );
  });
  test('nextAfter for a surah outside the path is null', () {
    expect(KidsJourneyPathDefinition.adventure.nextAfter(50), isNull);
  });
  test('quran journey flag defaults to false', () async {
    SharedPreferences.setMockInitialValues({});
    var prefs = await SharedPreferences.getInstance();
    expect(KidsHifzFeatureFlags.isQuranJourneyEnabled(prefs), isFalse);
    SharedPreferences.setMockInitialValues({
      'kids_quran_journey_enabled': true,
    });
    prefs = await SharedPreferences.getInstance();
    expect(KidsHifzFeatureFlags.isQuranJourneyEnabled(prefs), isTrue);
  });
}
