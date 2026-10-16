import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/services/after_prayer_azkar_window.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DateTime at(int h, int m) => DateTime(2026, 10, 16, h, m);
  final times = {
    PrayerSlot.fajr: at(5, 0),
    PrayerSlot.dhuhr: at(12, 0),
    PrayerSlot.asr: at(15, 30),
    PrayerSlot.maghrib: at(18, 0),
    PrayerSlot.isha: at(19, 20),
  };

  test(
    'window opens at prayer+10, closes at +60, clipped before next prayer',
    () {
      final w = activeAfterPrayerWindow(todayTimes: times, now: at(12, 10));
      expect(w?.prayer, PrayerSlot.dhuhr);
      expect(w?.from, at(12, 10));
      expect(w?.until, at(13, 0));
      expect(
        activeAfterPrayerWindow(todayTimes: times, now: at(12, 59))?.prayer,
        PrayerSlot.dhuhr,
      );
      expect(
        activeAfterPrayerWindow(todayTimes: times, now: at(13, 0)),
        isNull,
      );
      final close = {...times, PrayerSlot.isha: at(18, 40)};
      final clipped = activeAfterPrayerWindow(
        todayTimes: close,
        now: at(18, 15),
      );
      expect(clipped?.prayer, PrayerSlot.maghrib);
      expect(clipped?.until, at(18, 40));
    },
  );

  test('before offset, between windows and before fajr are null; isha runs '
      'past midnight; custom offset honoured', () {
    expect(activeAfterPrayerWindow(todayTimes: times, now: at(12, 9)), isNull);
    expect(activeAfterPrayerWindow(todayTimes: times, now: at(14, 0)), isNull);
    expect(activeAfterPrayerWindow(todayTimes: times, now: at(4, 0)), isNull);
    final late = {...times, PrayerSlot.isha: at(23, 30)};
    final w = activeAfterPrayerWindow(
      todayTimes: late,
      now: DateTime(2026, 10, 17, 0, 15),
    );
    expect(w?.prayer, PrayerSlot.isha);
    expect(
      activeAfterPrayerWindow(
        todayTimes: times,
        now: at(12, 5),
        offsetMinutes: 5,
      )?.prayer,
      PrayerSlot.dhuhr,
    );
  });

  test('loadAfterPrayerAzkarIds from the real bundled asset returns the 4 '
      'approved ids', () async {
    final ids = await loadAfterPrayerAzkarIds(rootBundle);
    expect(ids, hasLength(4));
    expect(ids.toSet(), hasLength(4));
  });
}
