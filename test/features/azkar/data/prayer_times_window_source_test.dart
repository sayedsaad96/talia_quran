import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/azkar/data/datasources/prayer_times_window_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns null when prayer times are disabled', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final source = PrayerTimesWindowSource(PrayerTimesService(prefs));

    expect(await source.load(DateTime(2026, 9, 29, 10)), isNull);
  });

  test('returns Fajr before Asr for a configured city', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
      PrayerTimesService.cityIdKey: 'makkah',
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(
      prefs,
      now: () => DateTime.utc(2026, 9, 29, 7),
    );
    final source = PrayerTimesWindowSource(service);

    final window = await source.load(DateTime.utc(2026, 9, 29, 7));

    expect(window, isNotNull);
    expect(window!.isConsistent, isTrue);
  });
}
