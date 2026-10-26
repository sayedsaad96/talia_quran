import 'package:hijri/hijri_calendar.dart';

/// Civil first day of Hijri [month] of [year] for a user whose Hijri date is
/// the civil date plus [adjustmentDays] (the convention of `seasonsAt`).
DateTime hijriMonthFirstCivilDay(int year, int month, int adjustmentDays) {
  final g = HijriCalendar().hijriToGregorian(year, month, 1);
  return DateTime(g.year, g.month, g.day - adjustmentDays);
}

/// Hijri (year, month, day) of a civil date under [adjustmentDays].
({int year, int month, int day}) hijriOfCivil(
  DateTime civil,
  int adjustmentDays,
) {
  final h = HijriCalendar.fromDate(
    DateTime(civil.year, civil.month, civil.day + adjustmentDays),
  );
  return (year: h.hYear, month: h.hMonth, day: h.hDay);
}

/// Inclusive civil range of Ramadan of Hijri [year].
({DateTime first, DateTime last}) ramadanCivilRange(
  int year,
  int adjustmentDays,
) {
  final first = hijriMonthFirstCivilDay(year, 9, adjustmentDays);
  final length = HijriCalendar().getDaysInMonth(year, 9);
  return (
    first: first,
    last: DateTime(first.year, first.month, first.day + length - 1),
  );
}
