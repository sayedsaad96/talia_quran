import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_achievement_store.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_achievements.dart';

void main() {
  var now = DateTime.utc(2026, 10, 8, 9);

  setUp(() {
    now = DateTime.utc(2026, 10, 8, 9);
    SharedPreferences.setMockInitialValues({});
  });

  Future<KidsAchievementStore> storeFor(String owner) async =>
      KidsAchievementStore(
        await SharedPreferences.getInstance(),
        FixedRecordOwnerProvider(owner),
        clock: () => now,
      );

  KidsAchievement find(List<KidsAchievement> all, KidsAchievementId id) =>
      all.singleWhere((a) => a.id == id);

  test('sync stores new unlocks with their first date', () async {
    final store = await storeFor('a');

    await store.sync(const KidsAchievementInputs(readPages: 10));
    now = DateTime.utc(2026, 10, 20);
    final later = await store.sync(const KidsAchievementInputs(readPages: 3));

    final pages10 = find(later, KidsAchievementId.pages10);
    expect(pages10.isUnlocked, isTrue);
    expect(pages10.unlockedAt, DateTime.utc(2026, 10, 8, 9));
    expect(store.unlocked().keys, contains('pages10'));
  });

  test('is scoped to the record owner', () async {
    await (await storeFor(
      'a',
    )).sync(const KidsAchievementInputs(memorizedAyahs: 1));

    final other = await storeFor('b');
    expect(other.unlocked(), isEmpty);
  });

  test('a corrupt stored value reads as nothing unlocked', () async {
    SharedPreferences.setMockInitialValues({'kids_achievements_a': 'oops'});
    final store = await storeFor('a');

    expect(store.unlocked(), isEmpty);
  });

  test(
    'keeps ids this build does not know when a new unlock is stored',
    () async {
      SharedPreferences.setMockInitialValues({
        'kids_achievements_a':
            '{"familyPractice":"2026-09-01T00:00:00.000Z","firstAyah":"2026-09-02T00:00:00.000Z"}',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = await storeFor('a');

      final all = await store.sync(const KidsAchievementInputs(readPages: 1));

      expect(find(all, KidsAchievementId.firstPage).isUnlocked, isTrue);
      expect(
        store.unlocked().keys,
        containsAll(['familyPractice', 'firstAyah', 'firstPage']),
      );
      // The stored text itself still holds the future id untouched.
      expect(
        prefs.getString('kids_achievements_a'),
        contains('familyPractice'),
      );
    },
  );

  test(
    'an unreadable value for a known id is replaced by a fresh unlock',
    () async {
      SharedPreferences.setMockInitialValues({
        'kids_achievements_a': '{"firstPage":"not-a-date","mystery":7}',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = await storeFor('a');

      await store.sync(const KidsAchievementInputs(readPages: 1));

      expect(store.unlocked()['firstPage'], DateTime.utc(2026, 10, 8, 9));
      // Even a value this build cannot interpret is carried along.
      expect(prefs.getString('kids_achievements_a'), contains('"mystery":7'));
    },
  );

  test('a sync with nothing new leaves the stored text unchanged', () async {
    const stored = '{"firstAyah":"2026-09-02T00:00:00.000Z","future":"x"}';
    SharedPreferences.setMockInitialValues({'kids_achievements_a': stored});
    final prefs = await SharedPreferences.getInstance();
    final store = await storeFor('a');

    await store.sync(const KidsAchievementInputs(memorizedAyahs: 1));

    expect(prefs.getString('kids_achievements_a'), stored);
  });
}
