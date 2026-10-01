import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/azkar/data/datasources/smart_wird_progress_store.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_time_context.dart';

void main() {
  late SharedPreferences prefs;
  late SmartWirdProgressStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = SmartWirdProgressStore(prefs);
  });

  test('active session starts null, saves, and resumes with same counts', () async {
    expect(store.activeSession(), isNull);

    await store.saveActiveSession(
      SmartWirdSession(
        dayPart: AzkarDayPart.afterFajr,
        counts: {'m-1': 2, 'g-1': 1},
        updatedAt: DateTime(2026, 9, 25, 9),
      ),
    );

    final resumed = store.activeSession();
    expect(resumed, isNotNull);
    expect(resumed!.dayPart, AzkarDayPart.afterFajr);
    expect(resumed.counts, {'m-1': 2, 'g-1': 1});
  });

  test('clearActiveSession removes today\'s resume point', () async {
    await store.saveActiveSession(
      SmartWirdSession(
        dayPart: AzkarDayPart.afterFajr,
        counts: {'m-1': 1},
        updatedAt: DateTime(2026, 9, 25, 9),
      ),
    );
    await store.clearActiveSession();
    expect(store.activeSession(), isNull);
  });

  test('recordCompletion appends to the rolling history', () async {
    await store.recordCompletion(
      dayPart: AzkarDayPart.afterFajr,
      itemIds: ['m-1', 'g-1'],
      date: DateTime(2026, 9, 25, 9),
    );
    await store.recordCompletion(
      dayPart: AzkarDayPart.evening,
      itemIds: ['e-1'],
      date: DateTime(2026, 9, 25, 18),
    );

    final history = store.completionHistory();
    expect(history, hasLength(2));
    expect(history.first.isBefore(history.last), isTrue);
  });

  test('history is capped at maxHistory entries', () async {
    // A fixed clock: the history window is relative to now, so with the real
    // clock this test began failing once September 1 fell out of the window.
    final store = SmartWirdProgressStore(
      prefs,
      now: () => DateTime(2026, 9, 21),
    );
    for (var i = 0; i < SmartWirdProgressStore.maxHistory + 5; i++) {
      await store.recordCompletion(
        dayPart: AzkarDayPart.afterFajr,
        itemIds: const ['m-1'],
        date: DateTime(2026, 9, 1 + (i % 20), 9 + (i % 3), i),
      );
    }
    expect(
      store.completionHistory().length,
      SmartWirdProgressStore.maxHistory,
    );
  });

  test('corrupt persisted payloads fail closed to empty state', () async {
    await prefs.setString(
      '${SmartWirdProgressStore.activeKeyPrefix}2026-9-25',
      'not-json{',
    );
    expect(store.activeSession(DateTime(2026, 9, 25)), isNull);
  });

  group('SmartWirdSession period', () {
    test('round-trips the period', () {
      final session = SmartWirdSession(
        dayPart: AzkarDayPart.afterFajr,
        period: AzkarPeriod.morning,
        counts: const {'m-1': 1},
        updatedAt: DateTime(2026, 9, 25, 9),
      );

      final restored = SmartWirdSession.fromJson(session.toJson());

      expect(restored.period, AzkarPeriod.morning);
    });

    test('a legacy session without a period loads with a null period', () {
      final restored = SmartWirdSession.fromJson({
        'dayPart': 'afterFajr',
        'counts': {'m-1': 1},
        'updatedAt': DateTime(2026, 9, 25, 9).millisecondsSinceEpoch,
      });

      expect(restored.period, isNull);
      expect(restored.dayPart, AzkarDayPart.afterFajr);
    });

    test('an unknown period name loads as null instead of throwing', () {
      final restored = SmartWirdSession.fromJson({
        'dayPart': 'morning',
        'period': 'midday',
        'counts': const <String, dynamic>{},
        'updatedAt': 0,
      });

      expect(restored.period, isNull);
    });
  });
}
