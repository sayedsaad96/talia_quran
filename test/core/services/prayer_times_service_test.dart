import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('disabled service returns null', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: false,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(prefs);
    final snapshot = await service.current(isArabic: true);
    expect(snapshot, isNull);
  });

  test('exposes all six computed times in canonical order', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(
      prefs,
      now: () => DateTime(2026, 9, 12, 12),
    );
    final snapshot = await service.current(isArabic: true);

    expect(snapshot, isNotNull);
    final times = [
      snapshot!.fajr!,
      snapshot.sunrise!,
      snapshot.dhuhr!,
      snapshot.asr!,
      snapshot.maghrib!,
      snapshot.isha!,
    ];
    expect(
      times,
      orderedEquals([...times]..sort()),
      reason: 'fajr < sunrise < dhuhr < asr < maghrib < isha',
    );
    for (final t in times) {
      expect(
        DateTime(t.year, t.month, t.day),
        DateTime(2026, 9, 12),
        reason: 'all six times on the computation date',
      );
    }
    expect(snapshot.nextName, anyOf('dhuhr', 'asr'));
    expect(snapshot.minutesUntil, greaterThan(0));
  });

  test('next-prayer wraps to tomorrow fajr after isha', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(
      prefs,
      now: () => DateTime(2026, 9, 12, 23),
    );
    final snapshot = await service.current(isArabic: true);

    expect(snapshot, isNotNull);
    expect(snapshot!.nextName, 'fajr');
    expect(snapshot.nextTime.isAfter(snapshot.isha!), isTrue);
    expect(snapshot.minutesUntil, greaterThan(0));
  });
}
