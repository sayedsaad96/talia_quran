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
}
