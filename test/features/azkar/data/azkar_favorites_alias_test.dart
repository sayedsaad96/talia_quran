import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_alias_registry.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_preferences_store.dart';

void main() {
  late AzkarAliasRegistry registry;

  setUp(() {
    registry = AzkarAliasRegistry()
      ..record({
        'dq1': {'dua_quran_1'},
      });
  });

  Future<AzkarPreferencesStore> storeWith(List<String> saved) async {
    SharedPreferences.setMockInitialValues({'azkar_favorite_duas': saved});
    final prefs = await SharedPreferences.getInstance();
    return AzkarPreferencesStore(prefs, registry);
  }

  test(
    'a favorite saved on the hidden copy shows on the visible copy',
    () async {
      final store = await storeWith(['dua_quran_1']);

      expect(store.isFavorite('dq1'), isTrue);
    },
  );

  test('toggling the visible copy clears every copy', () async {
    final store = await storeWith(['dua_quran_1', 'dq1']);

    final nowFavorite = await store.toggleFavorite('dq1');

    expect(nowFavorite, isFalse);
    expect(store.getFavoriteDuaIds(), isEmpty);
  });

  test('adding a favorite stores only the visible id', () async {
    final store = await storeWith([]);

    final nowFavorite = await store.toggleFavorite('dq1');

    expect(nowFavorite, isTrue);
    expect(store.getFavoriteDuaIds(), {'dq1'});
  });

  test('a record without aliases behaves as before', () async {
    final store = await storeWith(['dp3']);

    expect(store.isFavorite('dp3'), isTrue);
    expect(await store.toggleFavorite('dp3'), isFalse);
    expect(store.isFavorite('dp3'), isFalse);
  });

  test('works without a registry', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AzkarPreferencesStore(prefs);

    expect(await store.toggleFavorite('x'), isTrue);
    expect(store.isFavorite('x'), isTrue);
  });
}
