import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/notifications/prayer_companion_notification_intent.dart';

void main() {
  final asr = PrayerOccurrence(
    ownerId: 'local-guardian',
    localDate: DateTime(2026, 9, 20),
    prayerKey: PrayerKey.asr,
    scheduledAt: DateTime(2026, 9, 20, 15, 32),
  );

  group('encode/tryParse round trip', () {
    test('intent round-trips occurrence metadata only', () {
      final source = PrayerCompanionNotificationIntent(
        occurrence: asr,
        kind: PrayerCompanionNotificationKind.checkIn,
      );

      final encoded = source.encode();
      final decoded = PrayerCompanionNotificationIntent.tryParse(encoded);

      expect(decoded, source);
      // Metadata only: never localized copy, never a route path.
      expect(encoded, isNot(contains('صليت')));
      expect(encoded, isNot(contains('Did you pray')));
      expect(encoded, isNot(contains('/')));
      expect(
        encoded,
        startsWith('${PrayerCompanionNotificationIntent.version}|'),
      );
    });

    test('round-trips every kind and prayer key', () {
      for (final kind in PrayerCompanionNotificationKind.values) {
        for (final prayerKey in PrayerKey.values) {
          final source = PrayerCompanionNotificationIntent(
            occurrence: PrayerOccurrence(
              ownerId: 'owner-1',
              localDate: DateTime(2026, 1, 5),
              prayerKey: prayerKey,
              scheduledAt: DateTime(2026, 1, 5, 6, 10),
            ),
            kind: kind,
          );
          expect(
            PrayerCompanionNotificationIntent.tryParse(source.encode()),
            source,
          );
        }
      }
    });

    test('owner ids containing the separator survive the round trip', () {
      final source = PrayerCompanionNotificationIntent(
        occurrence: PrayerOccurrence(
          ownerId: 'supabase|user-42',
          localDate: DateTime(2026, 12, 31),
          prayerKey: PrayerKey.fajr,
          scheduledAt: DateTime(2026, 12, 31, 5, 45),
        ),
        kind: PrayerCompanionNotificationKind.followUp,
      );

      expect(
        PrayerCompanionNotificationIntent.tryParse(source.encode()),
        source,
      );
    });
  });

  group('tryParse strict validation', () {
    test('returns null for null, empty, garbage, or route payloads', () {
      expect(PrayerCompanionNotificationIntent.tryParse(null), isNull);
      expect(PrayerCompanionNotificationIntent.tryParse(''), isNull);
      expect(
        PrayerCompanionNotificationIntent.tryParse('not a payload'),
        isNull,
      );
      expect(PrayerCompanionNotificationIntent.tryParse('/'), isNull);
      expect(
        PrayerCompanionNotificationIntent.tryParse('/memorization'),
        isNull,
      );
    });

    test('returns null for old or future payload versions', () {
      expect(
        PrayerCompanionNotificationIntent.tryParse(
          'pc0|owner|2026-09-20|asr|1726820400000|checkIn',
        ),
        isNull,
      );
      expect(
        PrayerCompanionNotificationIntent.tryParse(
          'pc2|owner|2026-09-20|asr|1726820400000|checkIn',
        ),
        isNull,
      );
    });

    test('returns null when any field is missing or malformed', () {
      // Missing kind.
      expect(
        PrayerCompanionNotificationIntent.tryParse(
          'pc1|owner|2026-09-20|asr|1726820400000',
        ),
        isNull,
      );
      // Extra field.
      expect(
        PrayerCompanionNotificationIntent.tryParse(
          'pc1|owner|2026-09-20|asr|1726820400000|checkIn|extra',
        ),
        isNull,
      );
      // Empty owner.
      expect(
        PrayerCompanionNotificationIntent.tryParse(
          'pc1||2026-09-20|asr|1726820400000|checkIn',
        ),
        isNull,
      );
      // Malformed dates.
      expect(
        PrayerCompanionNotificationIntent.tryParse(
          'pc1|owner|2026-9-20|asr|1726820400000|checkIn',
        ),
        isNull,
      );
      expect(
        PrayerCompanionNotificationIntent.tryParse(
          'pc1|owner|not-a-date|asr|1726820400000|checkIn',
        ),
        isNull,
      );
      // Unknown prayer key.
      expect(
        PrayerCompanionNotificationIntent.tryParse(
          'pc1|owner|2026-09-20|sunrise|1726820400000|checkIn',
        ),
        isNull,
      );
      // Non-numeric scheduled-at.
      expect(
        PrayerCompanionNotificationIntent.tryParse(
          'pc1|owner|2026-09-20|asr|soon|checkIn',
        ),
        isNull,
      );
      // Unknown kind.
      expect(
        PrayerCompanionNotificationIntent.tryParse(
          'pc1|owner|2026-09-20|asr|1726820400000|reminder',
        ),
        isNull,
      );
    });

    test('never throws on hostile input', () {
      expect(
        () => PrayerCompanionNotificationIntent.tryParse('pc1|||||'),
        returnsNormally,
      );
      expect(
        () => PrayerCompanionNotificationIntent.tryParse('%7C%7C%7C'),
        returnsNormally,
      );
    });
  });
}
