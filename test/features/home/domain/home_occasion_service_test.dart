import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/features/home/domain/services/home_occasion_service.dart';

void main() {
  test(
    'current() returns Hijri context for September 2026 without throwing',
    () {
      final service = HomeOccasionService(now: () => DateTime(2026, 9, 8, 10));
      final context = service.current(isArabic: true);
      expect(context.greetingPeriod, 'morning');
      expect(context.gregorianLabel, '8 / 9 / 2026');
      expect(context.hijriLabel, isNotEmpty);
    },
  );

  test('Friday is surfaced even if Hijri conversion fails', () {
    final service = HomeOccasionService(now: () => DateTime(2026, 9, 11, 8));
    final context = service.current(isArabic: false);
    expect(context.occasion, HomeOccasion.friday);
  });

  // 2027-02-08 is 1 Ramadan 1448 (the fixture the Ramadan card tests use).
  test('Ramadan days 1–20 surface ramadan', () {
    final service = HomeOccasionService(now: () => DateTime(2027, 2, 20, 10));
    expect(service.current(isArabic: true).occasion, HomeOccasion.ramadan);
  });

  test('Ramadan day 21 surfaces the last ten nights', () {
    final service = HomeOccasionService(now: () => DateTime(2027, 2, 28, 10));
    expect(
      service.current(isArabic: true).occasion,
      HomeOccasion.lastTenNights,
    );
  });

  test('a Friday inside Ramadan still surfaces Ramadan first', () {
    // 2027-02-26 is a Friday inside Ramadan 1448.
    final service = HomeOccasionService(now: () => DateTime(2027, 2, 26, 10));
    expect(DateTime(2027, 2, 26).weekday, DateTime.friday);
    expect(service.current(isArabic: true).occasion, HomeOccasion.ramadan);
  });

  test('the occasion agrees with seasonsAt across a full year sweep', () {
    for (var i = 0; i < 500; i++) {
      final day = DateTime(2026, 1, 1).add(Duration(days: i));
      final withClock = HomeOccasionService(now: () => day);
      final occasion = withClock.current(isArabic: false).occasion;
      final ramadan = seasonsAt(
        day,
        adjustmentDays: 0,
      ).where((s) => s.id == SeasonId.ramadan).firstOrNull;
      expect(occasion, switch (ramadan?.stage) {
        SeasonStage.active when (ramadan!.day ?? 0) >= 21 =>
          HomeOccasion.lastTenNights,
        SeasonStage.active => HomeOccasion.ramadan,
        _ when day.weekday == DateTime.friday => HomeOccasion.friday,
        _ => HomeOccasion.none,
      }, reason: day.toIso8601String());
    }
  });
}
