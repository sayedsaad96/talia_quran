import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const timezoneChannel = MethodChannel('flutter_timezone');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, (call) async {
          if (call.method == 'getLocalTimezone') return 'GMT+03:00';
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, null);
  });

  test(
    'configureLocalTimezone maps OEM offset IDs to tz-database Etc/GMT zones',
    () async {
      await TaliaNotificationService().configureLocalTimezone();

      // "GMT+03:00" is not an IANA ID but the offset is still meaningful:
      // map it to the (sign-inverted) Etc/GMT-3 instead of losing 3 hours.
      expect(tz.local.name, 'Etc/GMT-3');
    },
  );

  test(
    'city-zone prayer instants survive conversion to the device zone',
    () async {
      tz_data.initializeTimeZones();
      final london = tz.getLocation('Europe/London');
      final fajr = tz.TZDateTime(london, 2026, 6, 15, 2, 30);

      // Same conversion applied in schedulePrayerTimesReminders before
      // zonedSchedule: it must preserve the instant, never reinterpret the
      // wall clock in the device zone.
      final asDevice = tz.TZDateTime.from(fajr, tz.local);

      expect(asDevice.isAtSameMomentAs(fajr), isTrue);
      expect(asDevice.toUtc(), fajr.toUtc());
    },
  );

  test(
    'configureLocalTimezone provides a usable UTC fallback for an unknown device timezone',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(timezoneChannel, (call) async {
            if (call.method == 'getLocalTimezone') return 'Not/AZone';
            return null;
          });

      await TaliaNotificationService().configureLocalTimezone();

      expect(tz.local.name, 'Etc/UTC');
    },
  );
}
