import 'package:hijri/hijri_calendar.dart';

import '../entities/ayah_of_day.dart';

class DailyAyahHijriDate {
  const DailyAyahHijriDate({required this.month, required this.day});

  final int month;
  final int day;
}

typedef DailyAyahHijriDateFor = DailyAyahHijriDate? Function(DateTime date);

/// Resolves the single highest-priority reason for today's daily ayah.
///
/// Hijri dates are used only to choose a theme; the local Gregorian day still
/// controls deterministic rotation within that theme.
class DailyAyahContextResolver {
  const DailyAyahContextResolver({this.hijriDateFor});

  final DailyAyahHijriDateFor? hijriDateFor;

  DailyAyahContext resolve({
    required DateTime date,
    String? userGoal,
  }) {
    final hijri = _hijriDateFor(date);
    final seasonal = hijri == null ? null : _seasonalContext(hijri);
    if (seasonal != null) return seasonal;
    if (date.weekday == DateTime.friday) return DailyAyahContext.friday;
    return _goalContext(userGoal) ?? DailyAyahContext.general;
  }

  DailyAyahHijriDate? _hijriDateFor(DateTime date) {
    if (hijriDateFor != null) return hijriDateFor!(date);
    try {
      final hijri = HijriCalendar.fromDate(date);
      return DailyAyahHijriDate(month: hijri.hMonth, day: hijri.hDay);
    } catch (_) {
      return null;
    }
  }

  DailyAyahContext? _seasonalContext(DailyAyahHijriDate hijri) {
    if (hijri.month == 12 && hijri.day == 9) {
      return DailyAyahContext.arafah;
    }
    if (hijri.month == 12 && hijri.day == 10) {
      return DailyAyahContext.eidAlAdha;
    }
    if (hijri.month == 12 && hijri.day >= 1 && hijri.day <= 13) {
      return DailyAyahContext.dhulHijjah;
    }
    if (hijri.month == 9 && hijri.day == 1) {
      return DailyAyahContext.ramadanStart;
    }
    if (hijri.month == 9 && hijri.day >= 21) {
      return DailyAyahContext.lastTenNights;
    }
    if (hijri.month == 9) return DailyAyahContext.ramadan;
    return null;
  }

  DailyAyahContext? _goalContext(String? userGoal) => switch (userGoal) {
    'reading' => DailyAyahContext.reading,
    'memorization' => DailyAyahContext.memorization,
    'smart_review' => DailyAyahContext.smartReview,
    'azkar' => DailyAyahContext.azkar,
    'child_journey' => DailyAyahContext.childJourney,
    _ => null,
  };
}
