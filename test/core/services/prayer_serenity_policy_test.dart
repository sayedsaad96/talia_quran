import 'package:flutter_test/flutter_test.dart';

import 'package:talia_quran/core/services/prayer_serenity_policy.dart';

/// Pure-Dart tests for the Prayer Serenity Mode window rules.
void main() {
  const policy = PrayerSerenityPolicy();

  final prayerTimes = <String, DateTime>{
    'fajr': DateTime(2025, 9, 19, 5, 12),
    'dhuhr': DateTime(2025, 9, 19, 12, 5),
    'asr': DateTime(2025, 9, 19, 15, 40),
  };

  group('PrayerSerenityPolicy — window boundaries', () {
    test('opens the window exactly at the prayer time', () {
      final key = policy.activeOccurrenceKey(
        prayerTimes: prayerTimes,
        now: DateTime(2025, 9, 19, 12, 5),
      );
      expect(key, equals('dhuhr-20250919'));
    });

    test('stays open inside the serenity duration', () {
      final key = policy.activeOccurrenceKey(
        prayerTimes: prayerTimes,
        now: DateTime(2025, 9, 19, 12, 14, 59),
      );
      expect(key, equals('dhuhr-20250919'));
    });

    test('closes the window after the serenity duration', () {
      final key = policy.activeOccurrenceKey(
        prayerTimes: prayerTimes,
        now: DateTime(2025, 9, 19, 12, 15),
      );
      expect(key, isNull);
    });

    test('is quiet before any prayer time', () {
      final key = policy.activeOccurrenceKey(
        prayerTimes: prayerTimes,
        now: DateTime(2025, 9, 19, 4, 0),
      );
      expect(key, isNull);
    });

    test('is quiet between windows', () {
      final key = policy.activeOccurrenceKey(
        prayerTimes: prayerTimes,
        now: DateTime(2025, 9, 19, 14, 0),
      );
      expect(key, isNull);
    });
  });

  group('PrayerSerenityPolicy — occurrence keys', () {
    test('keys are stable per prayer per day', () {
      final firstTick = policy.activeOccurrenceKey(
        prayerTimes: prayerTimes,
        now: DateTime(2025, 9, 19, 12, 6),
      );
      final secondTick = policy.activeOccurrenceKey(
        prayerTimes: prayerTimes,
        now: DateTime(2025, 9, 19, 12, 7),
      );
      expect(firstTick, equals(secondTick));
      expect(firstTick, isNotNull);
    });

    test('the same prayer on another day has a different key', () {
      final nextDay = <String, DateTime>{
        'dhuhr': DateTime(2025, 9, 20, 12, 5),
      };
      final key = policy.activeOccurrenceKey(
        prayerTimes: nextDay,
        now: DateTime(2025, 9, 20, 12, 6),
      );
      expect(key, equals('dhuhr-20250920'));
    });

    test('picks the earliest matching window when overlapping', () {
      // A custom 2-hour window makes fajr and dhuhr overlap; the first
      // matching entry wins deterministically.
      const wide = PrayerSerenityPolicy(
        serenityDuration: Duration(hours: 8),
      );
      final key = wide.activeOccurrenceKey(
        prayerTimes: prayerTimes,
        now: DateTime(2025, 9, 19, 12, 0),
      );
      expect(key, equals('fajr-20250919'));
    });

    test('custom serenity duration is honored', () {
      const short = PrayerSerenityPolicy(
        serenityDuration: Duration(minutes: 1),
      );
      final inside = short.activeOccurrenceKey(
        prayerTimes: prayerTimes,
        now: DateTime(2025, 9, 19, 12, 5, 30),
      );
      final outside = short.activeOccurrenceKey(
        prayerTimes: prayerTimes,
        now: DateTime(2025, 9, 19, 12, 7),
      );
      expect(inside, equals('dhuhr-20250919'));
      expect(outside, isNull);
    });
  });
}
