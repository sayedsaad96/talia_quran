import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_home_window.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';

void main() {
  final times = {
    for (final prayer in PrayerKey.values)
      prayer: DateTime(2026, 10, 20, 4 + prayer.index * 3),
  };
  test('fallback window includes its start and excludes prayer start', () {
    final prayerAt = times[PrayerKey.dhuhr]!;
    for (final minutes in [16, 15, 1, 0]) {
      final result = prayerReviewHomeOccurrence(
        ownerId: 'owner',
        times: times,
        now: prayerAt.subtract(Duration(minutes: minutes)),
        preparationNotificationsEnabled: false,
        preparationMinutes: 0,
      );
      if (minutes == 15 || minutes == 1) {
        expect(result?.prayerKey, PrayerKey.dhuhr);
        expect(result?.scheduledAt, prayerAt);
        expect(result?.ownerId, 'owner');
      } else {
        expect(result, isNull);
      }
    }
  });
  test('enabled preparation and incomplete prayer times hide the card', () {
    final now = times[PrayerKey.dhuhr]!.subtract(const Duration(minutes: 1));
    expect(
      prayerReviewHomeOccurrence(
        ownerId: 'owner',
        times: times,
        now: now,
        preparationNotificationsEnabled: true,
        preparationMinutes: 5,
      ),
      isNull,
    );
    expect(
      prayerReviewHomeOccurrence(
        ownerId: 'owner',
        times: {},
        now: now,
        preparationNotificationsEnabled: false,
        preparationMinutes: 0,
      ),
      isNull,
    );
  });
}
