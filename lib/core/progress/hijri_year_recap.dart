import 'dart:collection';

import 'package:hijri/hijri_calendar.dart';

/// A review row reduced to the only facts the annual recap can prove.
///
/// The recap deliberately counts ayahs that are currently memorized and were
/// last reviewed during the selected Hijri year. It cannot determine when an
/// ayah first became memorized because that transition is not retained.
final class HijriYearRecapReview {
  const HijriYearRecapReview({
    required this.isCurrentlyMemorized,
    required this.lastReviewedAt,
  });

  final bool isCurrentlyMemorized;
  final DateTime lastReviewedAt;
}

/// Explicit, storage-independent inputs for [HijriYearRecapCalculator].
final class HijriYearRecapInput {
  const HijriYearRecapInput({
    required this.now,
    required this.hijriAdjustmentDays,
    required this.khatmahCompletionDates,
    required this.reviews,
    required this.lifetimeLongestStreak,
    required this.activityByDay,
  });

  final DateTime now;
  final int hijriAdjustmentDays;
  final Iterable<DateTime> khatmahCompletionDates;
  final Iterable<HijriYearRecapReview> reviews;

  /// This is a lifetime maximum supplied by the streak service, not an annual
  /// maximum reconstructed from activity rows.
  final int lifetimeLongestStreak;

  /// Local civil `YYYY-MM-DD` keys from `StreakService.getActivityMap`.
  final Map<String, int> activityByDay;
}

/// A pure, date-bounded Hijri annual recap.
final class HijriYearRecap {
  HijriYearRecap({
    required this.hijriYear,
    required this.yearStartDate,
    required this.yearEndExclusiveDate,
    required this.visibilityStartDate,
    required this.visibilityEndDate,
    required this.isVisible,
    required this.completedKhatmahs,
    required this.approximateMemorizedAyahs,
    required this.lifetimeLongestStreak,
    required Map<String, int> activityByDay,
  }) : activityByDay = UnmodifiableMapView(Map.of(activityByDay));

  final int hijriYear;

  /// Inclusive local civil start of this Hijri year (1 Muharram).
  final DateTime yearStartDate;

  /// Exclusive local civil end of this Hijri year (next 1 Muharram).
  final DateTime yearEndExclusiveDate;

  /// Inclusive local civil card window: 20 Dhu al-Hijjah through 10 Muharram.
  final DateTime visibilityStartDate;
  final DateTime visibilityEndDate;
  final bool isVisible;
  final int completedKhatmahs;

  /// Currently memorized ayahs whose last review falls within the year.
  final int approximateMemorizedAyahs;
  final int lifetimeLongestStreak;
  final Map<String, int> activityByDay;
}

abstract final class HijriYearRecapCalculator {
  static const _minimumAdjustmentDays = -2;
  static const _maximumAdjustmentDays = 2;

  static HijriYearRecap calculate(HijriYearRecapInput input) {
    final adjustment = input.hijriAdjustmentDays
        .clamp(_minimumAdjustmentDays, _maximumAdjustmentDays)
        .toInt();
    final today = _dateOnly(input.now);
    final hijriToday = HijriCalendar.fromDate(_addDays(today, adjustment));
    final isMuharramWindow = hijriToday.hMonth == 1 && hijriToday.hDay <= 10;
    final recapYear = isMuharramWindow
        ? hijriToday.hYear - 1
        : hijriToday.hYear;
    final yearStart = _civilForHijri(recapYear, 1, 1, adjustment);
    final yearEndExclusive = _civilForHijri(recapYear + 1, 1, 1, adjustment);
    final visibilityStart = _civilForHijri(recapYear, 12, 20, adjustment);
    final visibilityEnd = _civilForHijri(recapYear + 1, 1, 10, adjustment);
    final isVisible =
        (hijriToday.hMonth == 12 && hijriToday.hDay >= 20) || isMuharramWindow;

    return _assemble(
      input,
      recapYear,
      yearStart,
      yearEndExclusive,
      visibilityStart,
      visibilityEnd,
      isVisible,
    );
  }

  static HijriYearRecap _assemble(
    HijriYearRecapInput input,
    int year,
    DateTime start,
    DateTime end,
    DateTime visibilityStart,
    DateTime visibilityEnd,
    bool visible,
  ) => HijriYearRecap(
    hijriYear: year,
    yearStartDate: start,
    yearEndExclusiveDate: end,
    visibilityStartDate: visibilityStart,
    visibilityEndDate: visibilityEnd,
    isVisible: visible,
    completedKhatmahs: input.khatmahCompletionDates
        .where((date) => _isInYear(_dateOnly(date), start, end))
        .length,
    approximateMemorizedAyahs: _memorizedCount(input, start, end),
    lifetimeLongestStreak: input.lifetimeLongestStreak < 0
        ? 0
        : input.lifetimeLongestStreak,
    activityByDay: _activity(input.activityByDay, start, end),
  );

  static int _memorizedCount(
    HijriYearRecapInput input,
    DateTime start,
    DateTime end,
  ) => input.reviews
      .where(
        (review) =>
            review.isCurrentlyMemorized &&
            _isInYear(_dateOnly(review.lastReviewedAt), start, end),
      )
      .length;

  static Map<String, int> _activity(
    Map<String, int> activity,
    DateTime start,
    DateTime end,
  ) => {
    for (final entry in activity.entries)
      if (entry.value > 0 && _isInYear(_parseDay(entry.key), start, end))
        entry.key: entry.value,
  };

  static DateTime _civilForHijri(int year, int month, int day, int adjustment) {
    final converted = HijriCalendar().hijriToGregorian(year, month, day);
    var civil = DateTime(
      converted.year,
      converted.month,
      converted.day - adjustment,
    );
    for (var attempt = 0; attempt < 8; attempt++) {
      final hijri = HijriCalendar.fromDate(_addDays(civil, adjustment));
      if (hijri.hYear == year && hijri.hMonth == month && hijri.hDay == day) {
        return civil;
      }
      civil = _addDays(
        civil,
        hijri.hYear < year ||
                (hijri.hYear == year &&
                    (hijri.hMonth < month ||
                        (hijri.hMonth == month && hijri.hDay < day)))
            ? 1
            : -1,
      );
    }
    throw StateError('Unable to resolve Hijri recap boundary');
  }

  static DateTime? _parseDay(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day
        ? parsed
        : null;
  }

  static bool _isInYear(
    DateTime? date,
    DateTime start,
    DateTime endExclusive,
  ) => date != null && !date.isBefore(start) && date.isBefore(endExclusive);

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime _addDays(DateTime value, int days) =>
      DateTime(value.year, value.month, value.day + days);
}
