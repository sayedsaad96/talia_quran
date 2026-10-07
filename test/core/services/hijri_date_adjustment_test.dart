import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/hijri_date_adjustment.dart';
import 'package:talia_quran/features/home/domain/services/daily_ayah_context_resolver.dart';
import 'package:talia_quran/features/home/domain/services/home_occasion_service.dart';

void main() {
  test('defaults to zero, persists, and clamps to +/- 2 days', () async {
    SharedPreferences.setMockInitialValues({});
    final adjustment = HijriDateAdjustment(
      await SharedPreferences.getInstance(),
    );

    expect(adjustment.days, 0);
    await adjustment.setDays(1);
    expect(adjustment.days, 1);
    await adjustment.setDays(5);
    expect(adjustment.days, 2);
    await adjustment.setDays(-9);
    expect(adjustment.days, -2);
  });

  test('home occasion with +1 equals the next day without adjustment', () {
    final day = DateTime(2027, 2, 6, 10);
    final shifted = HomeOccasionService(
      now: () => day,
      hijriOffsetDays: () => 1,
    ).current(isArabic: true);
    final nextDay = HomeOccasionService(
      now: () => day.add(const Duration(days: 1)),
    ).current(isArabic: true);

    expect(shifted.hijriLabel, nextDay.hijriLabel);
    // The Gregorian label and the Friday check stay on the real date.
    expect(
      shifted.gregorianLabel,
      HomeOccasionService(
        now: () => day,
      ).current(isArabic: true).gregorianLabel,
    );
  });

  test('daily ayah context with -1 equals the previous day', () {
    // Scan a full year so seasonal contexts (Ramadan, Dhul Hijjah) are hit.
    // Fridays are checked on the real date, so skip days next to them.
    var compared = 0;
    for (var i = 0; i < 366; i++) {
      final date = DateTime(2027, 1, 1).add(Duration(days: i));
      final previous = date.subtract(const Duration(days: 1));
      if (date.weekday == DateTime.friday ||
          previous.weekday == DateTime.friday) {
        continue;
      }
      expect(
        DailyAyahContextResolver(hijriOffsetDays: () => -1).resolve(date: date),
        const DailyAyahContextResolver().resolve(date: previous),
        reason: '$date',
      );
      compared++;
    }
    expect(compared, greaterThan(250));
  });
}
