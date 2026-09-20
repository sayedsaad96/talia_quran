import 'package:flutter_test/flutter_test.dart';

import 'package:talia_quran/core/services/streak_mercy_policy.dart';

/// Pure-Dart tests for the "يوم الرحمة" (Mercy Day) streak grace policy.
///
/// Mercy re-lights a broken streak when the user missed exactly one day, at
/// most once per cooldown window (default: one week).
void main() {
  const policy = StreakMercyPolicy();
  final today = DateTime(2025, 6, 15);

  group('StreakMercyPolicy — qualifying gap', () {
    test('grants mercy when exactly one day was missed', () {
      expect(
        policy.allowsMercy(missedDays: 1, lastMercyDate: null, today: today),
        isTrue,
      );
    });

    test('does not grant mercy on the same day', () {
      expect(
        policy.allowsMercy(missedDays: 0, lastMercyDate: null, today: today),
        isFalse,
      );
    });

    test('does not grant mercy after two or more missed days', () {
      expect(
        policy.allowsMercy(missedDays: 2, lastMercyDate: null, today: today),
        isFalse,
        reason: 'Longer absences reset the streak — mercy covers one day only',
      );
      expect(
        policy.allowsMercy(missedDays: 5, lastMercyDate: null, today: today),
        isFalse,
      );
    });
  });

  group('StreakMercyPolicy — weekly cooldown', () {
    test('grants mercy on first use (no previous mercy date)', () {
      expect(
        policy.allowsMercy(missedDays: 1, lastMercyDate: null, today: today),
        isTrue,
      );
    });

    test('blocks mercy within the cooldown window', () {
      final sixDaysAgo = today.subtract(const Duration(days: 6));
      expect(
        policy.allowsMercy(
          missedDays: 1,
          lastMercyDate: sixDaysAgo,
          today: today,
        ),
        isFalse,
        reason: 'Mercy is a weekly gift, not a daily loophole',
      );
    });

    test('grants mercy again after the cooldown elapses', () {
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      expect(
        policy.allowsMercy(
          missedDays: 1,
          lastMercyDate: sevenDaysAgo,
          today: today,
        ),
        isTrue,
      );
    });

    test('normalizes time-of-day when checking the cooldown', () {
      // Mercy granted at 23:59 seven days earlier must count as a full week.
      final lateNight = DateTime(2025, 6, 8, 23, 59);
      expect(
        policy.allowsMercy(
          missedDays: 1,
          lastMercyDate: lateNight,
          today: today,
        ),
        isTrue,
      );
    });
  });

  group('StreakMercyPolicy — custom cooldown', () {
    test('honors a custom cooldown window', () {
      const strict = StreakMercyPolicy(cooldownDays: 14);
      final tenDaysAgo = today.subtract(const Duration(days: 10));
      expect(
        strict.allowsMercy(
          missedDays: 1,
          lastMercyDate: tenDaysAgo,
          today: today,
        ),
        isFalse,
      );
      final fourteenDaysAgo = today.subtract(const Duration(days: 14));
      expect(
        strict.allowsMercy(
          missedDays: 1,
          lastMercyDate: fourteenDaysAgo,
          today: today,
        ),
        isTrue,
      );
    });
  });
}
