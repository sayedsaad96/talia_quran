import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_scheduled_event.dart';

PrayerScheduledEvent _event() => PrayerScheduledEvent(
      eventId: '2026-09-21_fajr',
      prayerKey: 'fajr',
      scheduledAtUtc: DateTime.utc(2026, 9, 20, 21, 12),
      localPrayerTime: '00:12',
      timezoneId: 'Africa/Cairo',
      notificationEnabled: true,
      adhanEnabled: true,
      payload: const {'source': 'test'},
    );

void main() {
  group('PrayerScheduledEvent', () {
    test('toMap/fromMap round-trips every field', () {
      final event = _event();

      final restored = PrayerScheduledEvent.fromMap(event.toMap());

      expect(restored, event);
      expect(restored.scheduledAtUtc.isUtc, isTrue);
      expect(restored.payload, {'source': 'test'});
    });

    test('fromMap tolerates a locally-stored timestamp without Z', () {
      final map = _event().toMap()..['scheduledAtUtc'] = '2026-09-20T21:12:00';

      final restored = PrayerScheduledEvent.fromMap(map);

      expect(
        restored.scheduledAtUtc,
        DateTime.utc(2026, 9, 20, 21, 12),
      );
    });

    test('fromMap applies documented defaults for missing flags', () {
      final map = _event().toMap()
        ..remove('notificationEnabled')
        ..remove('adhanEnabled')
        ..remove('soundProfile')
        ..remove('payload');

      final restored = PrayerScheduledEvent.fromMap(map);

      expect(restored.notificationEnabled, isTrue);
      expect(restored.adhanEnabled, isFalse);
      expect(restored.soundProfile, 'default');
      expect(restored.payload, isEmpty);
    });

    test('buildEventId is deterministic and zero-padded', () {
      final id = PrayerScheduledEvent.buildEventId(
        DateTime(2026, 3, 5),
        'dhuhr',
      );

      expect(id, '2026-03-05_dhuhr');
      expect(
        PrayerScheduledEvent.buildEventId(DateTime(2026, 3, 5), 'dhuhr'),
        id,
      );
    });
  });

  group('PrayerAlarmIdentity', () {
    test('request codes stay inside the frozen 2200-2499 V2 namespace', () {
      final base = DateTime.utc(2026, 9, 20);
      for (var day = 0; day < 90; day++) {
        for (final key in PrayerAlarmIdentity.prayerOrder) {
          final code = PrayerAlarmIdentity.requestCodeFor(
            base.add(Duration(days: day)),
            key,
          );
          expect(code, inInclusiveRange(2200, 2499),
              reason: 'day=$day key=$key');
        }
      }
    });

    test('never collides with legacy FLN (2000-2039) or companion (2100-2134)',
        () {
      final code = PrayerAlarmIdentity.requestCodeFor(
        DateTime.utc(2026, 9, 20),
        'isha',
      );
      expect(code, isNot(inInclusiveRange(2000, 2039)));
      expect(code, isNot(inInclusiveRange(2100, 2134)));
      expect(code >= 2200, isTrue);
    });

    test('is deterministic for the same occurrence', () {
      final a = PrayerAlarmIdentity.requestCodeFor(
        DateTime.utc(2026, 9, 21),
        'maghrib',
      );
      final b = PrayerAlarmIdentity.requestCodeFor(
        DateTime(2026, 9, 21, 23, 59), // local variant, same calendar day
        'maghrib',
      );

      expect(a, b);
    });

    test('distinct prayers on the same day get distinct codes', () {
      final day = DateTime.utc(2026, 9, 21);
      final codes = PrayerAlarmIdentity.prayerOrder
          .map((key) => PrayerAlarmIdentity.requestCodeFor(day, key))
          .toSet();

      expect(codes.length, PrayerAlarmIdentity.prayerOrder.length);
    });

    test('unknown prayer key still produces a valid in-range code', () {
      final code = PrayerAlarmIdentity.requestCodeFor(
        DateTime.utc(2026, 9, 21),
        'taraweeh',
      );

      expect(code, inInclusiveRange(2200, 2499));
    });

    test('matches the native Kotlin identity for a pinned occurrence', () {
      // Pinned cross-language contract: PrayerAlarmIdentityTest.kt asserts
      // the same value for 2026-09-21/fajr (UTC epoch day 20717).
      expect(
        PrayerAlarmIdentity.requestCodeFor(DateTime.utc(2026, 9, 21), 'fajr'),
        2200 + (20717 % 60) * 5,
      );
    });
  });
}