// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

/// Pure-Dart tests for streak business logic.
///
/// These tests validate the streak domain rules without an Isar database.
/// They work by exercising the streak calculation rules in isolation —
/// the same rules implemented in StreakService.recordActivity().
///
/// Full integration tests (with a real Isar in-memory db) should be
/// added once the project moves from Isar v3 to a version compatible
/// with the latest test tooling.
void main() {
  // ─── Helper: simulate streak state machine ──────────────────────────────
  //
  // Mirrors the logic in StreakService.recordActivity() so we can unit-test
  // the streak rules without touching Isar.

  int simulateStreak({
    required DateTime? lastActivityDate,
    required int currentStreak,
    required DateTime today,
  }) {
    if (lastActivityDate == null) return 1;

    final lastNorm = DateTime.utc(
      lastActivityDate.year,
      lastActivityDate.month,
      lastActivityDate.day,
    );
    final todayNorm = DateTime.utc(today.year, today.month, today.day);

    if (lastNorm == todayNorm) return currentStreak; // same day
    final yesterday = todayNorm.subtract(const Duration(days: 1));
    if (lastNorm == yesterday) return currentStreak + 1; // consecutive
    return 1; // broken
  }

  // ─── Same-day ────────────────────────────────────────────────────────────

  group('Same-day activity', () {
    final base = DateTime.utc(2025, 6, 15);

    test('does not increment streak', () {
      final result = simulateStreak(
        lastActivityDate: base,
        currentStreak: 5,
        today: base,
      );
      expect(result, equals(5));
    });

    test('handles midnight boundary (same UTC day)', () {
      final lastActivity = DateTime.utc(2025, 6, 15, 0, 0, 0);
      final laterSameDay = DateTime.utc(2025, 6, 15, 23, 59, 59);
      final result = simulateStreak(
        lastActivityDate: lastActivity,
        currentStreak: 3,
        today: laterSameDay,
      );
      expect(result, equals(3));
    });
  });

  // ─── Consecutive-day ─────────────────────────────────────────────────────

  group('Consecutive-day activity', () {
    test('increments streak from 1 to 2', () {
      final yesterday = DateTime.utc(2025, 6, 14);
      final today = DateTime.utc(2025, 6, 15);
      final result = simulateStreak(
        lastActivityDate: yesterday,
        currentStreak: 1,
        today: today,
      );
      expect(result, equals(2));
    });

    test('increments a long streak from 29 to 30', () {
      final yesterday = DateTime.utc(2025, 6, 14);
      final today = DateTime.utc(2025, 6, 15);
      final result = simulateStreak(
        lastActivityDate: yesterday,
        currentStreak: 29,
        today: today,
      );
      expect(result, equals(30));
    });

    test('handles month boundary (e.g. June 30 → July 1)', () {
      final lastDay = DateTime.utc(2025, 6, 30);
      final nextMonth = DateTime.utc(2025, 7, 1);
      final result = simulateStreak(
        lastActivityDate: lastDay,
        currentStreak: 10,
        today: nextMonth,
      );
      expect(result, equals(11));
    });

    test('handles year boundary (Dec 31 → Jan 1)', () {
      final dec31 = DateTime.utc(2024, 12, 31);
      final jan1 = DateTime.utc(2025, 1, 1);
      final result = simulateStreak(
        lastActivityDate: dec31,
        currentStreak: 100,
        today: jan1,
      );
      expect(result, equals(101));
    });
  });

  // ─── Broken streak ───────────────────────────────────────────────────────

  group('Broken streak', () {
    test('resets to 1 after a 1-day gap', () {
      final twoDaysAgo = DateTime.utc(2025, 6, 13);
      final today = DateTime.utc(2025, 6, 15);
      final result = simulateStreak(
        lastActivityDate: twoDaysAgo,
        currentStreak: 7,
        today: today,
      );
      expect(result, equals(1));
    });

    test('resets to 1 after a long absence', () {
      final monthAgo = DateTime.utc(2025, 5, 15);
      final today = DateTime.utc(2025, 6, 15);
      final result = simulateStreak(
        lastActivityDate: monthAgo,
        currentStreak: 365,
        today: today,
      );
      expect(result, equals(1));
    });

    test('resets to 1 after exactly 2-day gap', () {
      final threeDaysAgo = DateTime.utc(2025, 6, 12);
      final today = DateTime.utc(2025, 6, 15);
      final result = simulateStreak(
        lastActivityDate: threeDaysAgo,
        currentStreak: 14,
        today: today,
      );
      expect(result, equals(1));
    });
  });

  // ─── First-time activity ─────────────────────────────────────────────────

  group('First-time activity (no previous date)', () {
    test('starts streak at 1', () {
      final result = simulateStreak(
        lastActivityDate: null,
        currentStreak: 0,
        today: DateTime.utc(2025, 6, 15),
      );
      expect(result, equals(1));
    });
  });

  // ─── UTC normalization ───────────────────────────────────────────────────

  group('UTC normalization', () {
    test('local time near midnight does not bleed into next UTC day', () {
      // A user in UTC+3 at 11 PM is still on UTC 8 PM the same day.
      // The StreakService normalizes to UTC, so this should be the same UTC day.
      final utcSameDay1 = DateTime.utc(2025, 6, 15, 20, 0, 0); // UTC 8 PM
      final utcSameDay2 = DateTime.utc(2025, 6, 15, 22, 0, 0); // UTC 10 PM
      final result = simulateStreak(
        lastActivityDate: utcSameDay1,
        currentStreak: 5,
        today: utcSameDay2,
      );
      expect(result, equals(5), reason: 'Same UTC day should not increment');
    });

    test('activity after midnight UTC is a new day', () {
      final endOfDay = DateTime.utc(2025, 6, 15, 23, 59, 59);
      final nextDay = DateTime.utc(2025, 6, 16, 0, 0, 1);
      final result = simulateStreak(
        lastActivityDate: endOfDay,
        currentStreak: 5,
        today: nextDay,
      );
      expect(result, equals(6), reason: 'New UTC day should increment streak');
    });
  });

  // ─── StreakEntity domain model ────────────────────────────────────────────

  group('StreakEntity', () {
    test('default constructor creates zero-streak entity', () {
      const entity = StreakEntity(currentStreak: 0, longestStreak: 0);
      expect(entity.currentStreak, equals(0));
      expect(entity.longestStreak, equals(0));
      expect(entity.lastActivityDate, isNull);
      expect(entity.freezesAvailable, equals(0));
    });

    test('entity with data preserves all fields', () {
      final date = DateTime.utc(2025, 6, 15);
      final entity = StreakEntity(
        currentStreak: 30,
        longestStreak: 45,
        lastActivityDate: date,
        freezesAvailable: 2,
      );
      expect(entity.currentStreak, equals(30));
      expect(entity.longestStreak, equals(45));
      expect(entity.lastActivityDate, equals(date));
      expect(entity.freezesAvailable, equals(2));
    });
  });
}
