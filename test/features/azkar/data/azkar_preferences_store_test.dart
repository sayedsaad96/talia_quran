import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late AzkarPreferencesStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = AzkarPreferencesStore(prefs);
  });

  group('AzkarPreferencesStore', () {
    test('provides sensible default preferences', () {
      expect(store.getFavoriteDuaIds(), isEmpty);
      expect(store.isFavorite('dq1'), isFalse);
      expect(store.favoritesListenable.value, isEmpty);

      expect(store.getAutoAdvance(), isTrue);
      expect(store.autoAdvanceListenable.value, isTrue);

      expect(store.getFontScale(), equals(1.0));
      expect(store.fontScaleListenable.value, equals(1.0));

      expect(store.getLastTasbeehTarget(), equals(33));
    });

    test('toggling favorite persistently adds and removes ID and notifies listeners', () async {
      var notifiedFavorites = <String>{};
      store.favoritesListenable.addListener(() {
        notifiedFavorites = store.favoritesListenable.value;
      });

      final added = await store.toggleFavorite('dq1');
      expect(added, isTrue);
      expect(store.isFavorite('dq1'), isTrue);
      expect(store.getFavoriteDuaIds(), contains('dq1'));
      expect(notifiedFavorites, contains('dq1'));

      final addedSecond = await store.toggleFavorite('dp2');
      expect(addedSecond, isTrue);
      expect(store.getFavoriteDuaIds(), containsAll(['dq1', 'dp2']));

      final removed = await store.toggleFavorite('dq1');
      expect(removed, isFalse);
      expect(store.isFavorite('dq1'), isFalse);
      expect(store.getFavoriteDuaIds(), isNot(contains('dq1')));
      expect(store.getFavoriteDuaIds(), contains('dp2'));
    });

    test('setAutoAdvance persists setting and updates listenable', () async {
      var autoAdvanceValue = true;
      store.autoAdvanceListenable.addListener(() {
        autoAdvanceValue = store.autoAdvanceListenable.value;
      });

      await store.setAutoAdvance(false);
      expect(store.getAutoAdvance(), isFalse);
      expect(autoAdvanceValue, isFalse);

      await store.setAutoAdvance(true);
      expect(store.getAutoAdvance(), isTrue);
      expect(autoAdvanceValue, isTrue);
    });

    test('setFontScale persists setting and updates listenable', () async {
      var scale = 1.0;
      store.fontScaleListenable.addListener(() {
        scale = store.fontScaleListenable.value;
      });

      await store.setFontScale(1.25);
      expect(store.getFontScale(), equals(1.25));
      expect(scale, equals(1.25));
    });

    test('setLastTasbeehTarget persists target', () async {
      await store.setLastTasbeehTarget(100);
      expect(store.getLastTasbeehTarget(), equals(100));

      await store.setLastTasbeehTarget(0);
      expect(store.getLastTasbeehTarget(), equals(0));
    });

    test('restores previously persisted preferences on new store instance', () async {
      await store.toggleFavorite('dq1');
      await store.setAutoAdvance(false);
      await store.setFontScale(0.85);
      await store.setLastTasbeehTarget(100);

      final restoredStore = AzkarPreferencesStore(prefs);
      expect(restoredStore.isFavorite('dq1'), isTrue);
      expect(restoredStore.getFavoriteDuaIds(), contains('dq1'));
      expect(restoredStore.getAutoAdvance(), isFalse);
      expect(restoredStore.getFontScale(), equals(0.85));
      expect(restoredStore.getLastTasbeehTarget(), equals(100));
    });
  });
}
