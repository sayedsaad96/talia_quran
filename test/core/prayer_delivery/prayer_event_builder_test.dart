import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_event_builder.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PrayerTimesService> service(DateTime now) async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
      PrayerTimesService.cityIdKey: 'london',
      PrayerTimesService.methodKey: 'muslim_world_league',
      PrayerTimesService.methodManualKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    return PrayerTimesService(prefs, now: () => now);
  }

  test('builds 7-day events with the city IANA timezone, never the device',
      () async {
    final prayerService = await service(DateTime.utc(2026, 7, 15, 3));

    final events = await PrayerEventBuilder.build(
      prayerService: prayerService,
      now: DateTime.utc(2026, 7, 15, 3),
      prayerFilter: const {
        'fajr': true,
        'dhuhr': true,
        'asr': true,
        'maghrib': true,
        'isha': true,
      },
      adhanEnabled: true,
    );

    expect(events, isNotEmpty);
    expect(events.length, lessThanOrEqualTo(35));
    for (final event in events) {
      expect(event.timezoneId, 'Europe/London');
      expect(event.adhanEnabled, isTrue);
      expect(event.notificationEnabled, isTrue);
      expect(event.scheduledAtUtc.isAfter(DateTime.utc(2026, 7, 15, 3)), isTrue,
          reason: 'past occurrences are skipped');
      expect(event.localPrayerTime, matches(RegExp(r'^\d{2}:\d{2}$')));
    }
    // Event ids are unique (one per occurrence).
    expect(events.map((e) => e.eventId).toSet().length, events.length);
  });

  test('respects per-prayer filters', () async {
    final prayerService = await service(DateTime.utc(2026, 7, 15, 3));

    final events = await PrayerEventBuilder.build(
      prayerService: prayerService,
      now: DateTime.utc(2026, 7, 15, 3),
      prayerFilter: const {
        'fajr': false,
        'dhuhr': true,
        'asr': true,
        'maghrib': true,
        'isha': true,
      },
      adhanEnabled: false,
    );

    expect(events.where((e) => e.prayerKey == 'fajr'), isEmpty);
    expect(events.where((e) => e.prayerKey == 'dhuhr'), isNotEmpty);
    expect(events.every((e) => e.adhanEnabled, ), isFalse);
  });

  test('alarm request codes stay inside the frozen V2 namespace', () async {
    final prayerService = await service(DateTime.utc(2026, 7, 15, 3));

    final events = await PrayerEventBuilder.build(
      prayerService: prayerService,
      now: DateTime.utc(2026, 7, 15, 3),
      prayerFilter: const {
        'fajr': true,
        'dhuhr': true,
        'asr': true,
        'maghrib': true,
        'isha': true,
      },
      adhanEnabled: false,
    );

    for (final event in events) {
      expect(event.alarmRequestCode, inInclusiveRange(2200, 2499));
    }
  });
}