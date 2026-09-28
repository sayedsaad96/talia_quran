import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/streak_day.dart';

void main() {
  group('StreakDay.of (C4)', () {
    test('uses the learner\'s local calendar day, not the UTC day', () {
      // 01:30 local on the 28th: after local midnight, whatever the offset.
      final afterLocalMidnight = DateTime(2026, 9, 28, 1, 30);

      expect(StreakDay.of(afterLocalMidnight), DateTime.utc(2026, 9, 28));
    });

    test('a stored day keeps its calendar fields in any time zone', () {
      expect(
        StreakDay.stored(DateTime.utc(2026, 9, 28)),
        DateTime.utc(2026, 9, 28),
      );
    });
  });

  group('StreakDay.transition', () {
    final today = DateTime.utc(2026, 9, 28);

    test('first activity starts a streak of one', () {
      final next = StreakDay.transition(
        currentStreak: 0,
        longestStreak: 0,
        lastDay: null,
        lastMercyDay: null,
        today: today,
      );
      expect(next.currentStreak, 1);
      expect(next.longestStreak, 1);
      expect(next.isNewDay, isTrue);
    });

    test('same day keeps the streak', () {
      final next = StreakDay.transition(
        currentStreak: 4,
        longestStreak: 9,
        lastDay: today,
        lastMercyDay: null,
        today: today,
      );
      expect(next.isNewDay, isFalse);
      expect(next.currentStreak, 4);
    });

    test('consecutive day extends and may set a record', () {
      final next = StreakDay.transition(
        currentStreak: 9,
        longestStreak: 9,
        lastDay: DateTime.utc(2026, 9, 27),
        lastMercyDay: null,
        today: today,
      );
      expect(next.currentStreak, 10);
      expect(next.longestStreak, 10);
      expect(next.isNewRecord, isTrue);
    });

    test('one missed day is forgiven by the mercy rule', () {
      final next = StreakDay.transition(
        currentStreak: 5,
        longestStreak: 5,
        lastDay: DateTime.utc(2026, 9, 26),
        lastMercyDay: null,
        today: today,
      );
      expect(next.currentStreak, 6);
      expect(next.mercyApplied, isTrue);
      expect(next.lastMercyDay, today);
    });

    test('a longer gap resets the streak', () {
      final next = StreakDay.transition(
        currentStreak: 5,
        longestStreak: 5,
        lastDay: DateTime.utc(2026, 9, 20),
        lastMercyDay: null,
        today: today,
      );
      expect(next.currentStreak, 1);
      expect(next.longestStreak, 5);
      expect(next.mercyApplied, isFalse);
    });
  });
}
