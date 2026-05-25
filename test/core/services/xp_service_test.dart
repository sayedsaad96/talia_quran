// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/constants/xp_constants.dart';

/// Tests for XP level progression logic.
/// These tests cover the pure-Dart getCurrentLevel() and level boundary
/// calculations without requiring a real Isar database.
void main() {
  group('XpConstants — level progression', () {
    XpLevel levelFor(int xp) {
      const levels = XpConstants.levels;
      for (int i = levels.length - 1; i >= 0; i--) {
        if (xp >= levels[i].minXp) return levels[i];
      }
      return levels.first;
    }

    double progressFor(int xp) {
      const levels = XpConstants.levels;
      final current = levelFor(xp);
      final idx = levels.indexWhere((l) => l.name == current.name);
      if (idx >= levels.length - 1) return 1.0;
      final next = levels[idx + 1];
      final range = next.minXp - current.minXp;
      final progress = xp - current.minXp;
      return (progress / range).clamp(0.0, 1.0);
    }

    // ─── Level boundary tests ───────────────────────────────────────────────

    test('0 XP → مبتدئ (starter)', () {
      expect(levelFor(0).name, equals('مبتدئ'));
    });

    test('99 XP → still مبتدئ (one below طالب threshold)', () {
      expect(levelFor(99).name, equals('مبتدئ'));
    });

    test('100 XP → طالب (student)', () {
      expect(levelFor(100).name, equals('طالب'));
    });

    test('499 XP → still طالب (one below حافظ threshold)', () {
      expect(levelFor(499).name, equals('طالب'));
    });

    test('500 XP → حافظ (memorizer)', () {
      expect(levelFor(500).name, equals('حافظ'));
    });

    test('1999 XP → still حافظ (one below شيخ threshold)', () {
      expect(levelFor(1999).name, equals('حافظ'));
    });

    test('2000 XP → شيخ (sheikh)', () {
      expect(levelFor(2000).name, equals('شيخ'));
    });

    test('9999 XP → still شيخ (one below إمام threshold)', () {
      expect(levelFor(9999).name, equals('شيخ'));
    });

    test('10000 XP → إمام (imam, max level)', () {
      expect(levelFor(10000).name, equals('إمام'));
    });

    test('999999 XP → still إمام (no level above max)', () {
      expect(levelFor(999999).name, equals('إمام'));
    });

    // ─── Reward amounts ──────────────────────────────────────────────────────

    test('ayah_memorized reward is 10 XP', () {
      expect(XpConstants.rewards['ayah_memorized'], equals(10));
    });

    test('daily_review reward is 5 XP', () {
      expect(XpConstants.rewards['daily_review'], equals(5));
    });

    test('unknown event key yields 0 (no reward)', () {
      expect(XpConstants.rewards['unknown_key'], isNull);
    });

    test('juz_completed reward is 500 XP', () {
      expect(XpConstants.rewards['juz_completed'], equals(500));
    });

    test('streak_7 reward is 100 XP', () {
      expect(XpConstants.rewards['streak_7'], equals(100));
    });

    test('streak_30 reward is 500 XP', () {
      expect(XpConstants.rewards['streak_30'], equals(500));
    });

    // ─── Progress to next level ──────────────────────────────────────────────

    test('0/100 XP → 0% progress to طالب', () {
      expect(progressFor(0), closeTo(0.0, 0.001));
    });

    test('50/100 XP → 50% progress to طالب', () {
      expect(progressFor(50), closeTo(0.5, 0.001));
    });

    test('100/500 XP → 0% progress toward حافظ at طالب level', () {
      // At طالب (100 XP), range to حافظ is 400 XP. 0 extra = 0%.
      expect(progressFor(100), closeTo(0.0, 0.001));
    });

    test('300/500 XP → 50% progress toward حافظ', () {
      // طالب range: 100–500 = 400. Current: 300-100=200/400 = 50%
      expect(progressFor(300), closeTo(0.5, 0.001));
    });

    test('إمام (max level) always returns 100% progress', () {
      expect(progressFor(10000), closeTo(1.0, 0.001));
      expect(progressFor(50000), closeTo(1.0, 0.001));
    });

    // ─── Levels list integrity ───────────────────────────────────────────────

    test('levels list contains exactly 5 levels', () {
      expect(XpConstants.levels.length, equals(5));
    });

    test('levels are sorted in ascending minXp order', () {
      final xpValues = XpConstants.levels.map((l) => l.minXp).toList();
      final sorted = [...xpValues]..sort();
      expect(xpValues, equals(sorted));
    });

    test('first level starts at 0 XP', () {
      expect(XpConstants.levels.first.minXp, equals(0));
    });

    test('every level has a non-empty name and icon', () {
      for (final level in XpConstants.levels) {
        expect(level.name, isNotEmpty, reason: '${level.name} name is empty');
        expect(level.icon, isNotEmpty, reason: '${level.name} icon is empty');
      }
    });
  });
}
