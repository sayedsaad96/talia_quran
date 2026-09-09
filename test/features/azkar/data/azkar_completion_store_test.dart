import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_completion_store.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';

void main() {
  test('counts and completion are day-scoped', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime(2026, 9, 8);
    final store = AzkarCompletionStore(prefs, now: () => today);

    expect(store.isToday(AzkarCategory.morning, today), isFalse);
    await store.setCount(
      category: AzkarCategory.morning,
      zikrId: 'a',
      count: 3,
      date: today,
    );
    expect(store.countFor(AzkarCategory.morning, 'a', today), 3);
    expect(
      store.isCompleteFromSessions(
        category: AzkarCategory.morning,
        items: const [
          Zikr(
            id: 'a',
            text: 'x',
            transliteration: 'x',
            translation: 'x',
            totalCount: 3,
            category: AzkarCategory.morning,
          ),
        ],
        date: today,
      ),
      isTrue,
    );
  });

  test('starting a new day clears counters left by the previous day', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var currentDate = DateTime(2026, 9, 8);
    final store = AzkarCompletionStore(prefs, now: () => currentDate);

    await store.setCount(
      category: AzkarCategory.morning,
      zikrId: 'first',
      count: 1,
    );
    await store.setCount(
      category: AzkarCategory.morning,
      zikrId: 'second',
      count: 1,
    );
    await store.setAllDone(AzkarCategory.morning, true);

    currentDate = DateTime(2026, 9, 9);
    await store.setCount(
      category: AzkarCategory.morning,
      zikrId: 'first',
      count: 1,
    );

    expect(store.countFor(AzkarCategory.morning, 'first'), 1);
    expect(store.countFor(AzkarCategory.morning, 'second'), 0);
    expect(store.isCategoryComplete(AzkarCategory.morning), isFalse);
  });
}
