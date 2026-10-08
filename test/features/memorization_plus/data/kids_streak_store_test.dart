import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_streak_store.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  var now = DateTime(2026, 10, 2, 9);

  setUp(() {
    now = DateTime(2026, 10, 2, 9);
    SharedPreferences.setMockInitialValues({});
  });

  Future<KidsStreakStore> storeFor(
    String owner, {
    Future<KidsStreakSeed?> Function()? legacySeed,
    Future<void> Function()? onRecorded,
  }) async => KidsStreakStore(
    await SharedPreferences.getInstance(),
    FixedRecordOwnerProvider(owner),
    clock: () => now,
    legacySeed: legacySeed,
    onRecorded: onRecorded,
  );

  test('starts empty', () async {
    final store = await storeFor('a');

    expect(
      await store.getStreak(),
      const StreakEntity(currentStreak: 0, longestStreak: 0),
    );
    expect(await store.getActivityMap(), isEmpty);
  });

  test('activity on consecutive days grows the streak', () async {
    final store = await storeFor('a');

    await store.recordActivity();
    await store.recordActivity();
    now = DateTime(2026, 10, 3, 20);
    await store.recordActivity();

    final streak = await store.getStreak();
    expect(streak.currentStreak, 2);
    expect(streak.longestStreak, 2);
    expect(streak.lastActivityDate, DateTime.utc(2026, 10, 3));
    expect(await store.getActivityMap(), {'2026-10-02': 2, '2026-10-03': 1});
  });

  test('a two-day gap restarts the streak', () async {
    final store = await storeFor('a');
    await store.recordActivity();
    now = DateTime(2026, 10, 3, 9);
    await store.recordActivity();
    now = DateTime(2026, 10, 7, 9);
    await store.recordActivity();

    final streak = await store.getStreak();
    expect(streak.currentStreak, 1);
    expect(streak.longestStreak, 2);
  });

  test('is scoped to the record owner', () async {
    await (await storeFor('a')).recordActivity();

    final other = await storeFor('b');
    expect((await other.getStreak()).currentStreak, 0);
  });

  test('the activity map keeps only the requested days', () async {
    final store = await storeFor('a');
    now = DateTime(2026, 9, 1, 9);
    await store.recordActivity();
    now = DateTime(2026, 10, 2, 9);
    await store.recordActivity();

    expect(await store.getActivityMap(days: 30), {'2026-10-02': 1});
  });

  test('seeds once from the legacy shared streak', () async {
    var seedCalls = 0;
    final store = await storeFor(
      'a',
      legacySeed: () async {
        seedCalls++;
        return KidsStreakSeed(
          streak: StreakEntity(
            currentStreak: 5,
            longestStreak: 9,
            lastActivityDate: DateTime.utc(2026, 10, 1),
          ),
          activityByDay: const {'2026-10-01': 3},
        );
      },
    );

    expect((await store.getStreak()).currentStreak, 5);
    await store.recordActivity();

    final streak = await store.getStreak();
    expect(streak.currentStreak, 6);
    expect(streak.longestStreak, 9);
    expect(await store.getActivityMap(), {'2026-10-01': 3, '2026-10-02': 1});
    expect(seedCalls, 1);
  });

  test('a null legacy seed starts empty', () async {
    final store = await storeFor('a', legacySeed: () async => null);

    await store.recordActivity();

    expect((await store.getStreak()).currentStreak, 1);
  });

  test('notifies after each recorded activity', () async {
    var notified = 0;
    final store = await storeFor('a', onRecorded: () async => notified++);

    await store.recordActivity();

    expect(notified, 1);
  });
}
