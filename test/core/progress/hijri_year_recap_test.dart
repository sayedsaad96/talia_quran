import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:talia_quran/core/progress/hijri_year_recap.dart';

DateTime _civilForHijri(int year, int month, int day, int adjustment) {
  final g = HijriCalendar().hijriToGregorian(year, month, day);
  var civil = DateTime(g.year, g.month, g.day - adjustment);
  for (var attempt = 0; attempt < 8; attempt++) {
    final h = HijriCalendar.fromDate(
      DateTime(civil.year, civil.month, civil.day + adjustment),
    );
    if (h.hYear == year && h.hMonth == month && h.hDay == day) return civil;
    final before = h.hYear < year ||
        (h.hYear == year &&
            (h.hMonth < month || (h.hMonth == month && h.hDay < day)));
    civil = DateTime(civil.year, civil.month, civil.day + (before ? 1 : -1));
  }
  throw StateError('No test boundary');
}

HijriYearRecap _recap({
  required DateTime now,
  int adjustment = 0,
  Iterable<DateTime> completions = const [],
  Iterable<HijriYearRecapReview> reviews = const [],
  int longest = 0,
  Map<String, int> activity = const {},
}) => HijriYearRecapCalculator.calculate(HijriYearRecapInput(
  now: now,
  hijriAdjustmentDays: adjustment,
  khatmahCompletionDates: completions,
  reviews: reviews,
  lifetimeLongestStreak: longest,
  activityByDay: activity,
));

String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  test('keeps the card window separate and uses the prior year in Muharram', () {
    for (final adjustment in [-2, 0, 2]) {
      final dhu20 = _civilForHijri(1448, 12, 20, adjustment);
      final atStart = _recap(now: dhu20, adjustment: adjustment);
      expect(atStart.hijriYear, 1448);
      expect(atStart.isVisible, isTrue);
      expect(atStart.visibilityStartDate, dhu20);
      final muh10 = _civilForHijri(1449, 1, 10, adjustment);
      final atEnd = _recap(now: muh10, adjustment: adjustment);
      expect(atEnd.hijriYear, 1448);
      expect(atEnd.visibilityEndDate, muh10);
      expect(
        _recap(
          now: DateTime(muh10.year, muh10.month, muh10.day + 1),
          adjustment: adjustment,
        ).isVisible,
        isFalse,
      );
    }
  });

  test('counts the full annual range and only positive activity', () {
    final seed = _recap(now: _civilForHijri(1448, 12, 20, 0));
    final start = seed.yearStartDate;
    final next = seed.yearEndExclusiveDate;
    final end = DateTime(next.year, next.month, next.day - 1);
    final middle = _civilForHijri(1448, 6, 1, 0);
    final recap = _recap(
      now: seed.visibilityStartDate,
      completions: [start, middle, end, next],
      reviews: [
        HijriYearRecapReview(isCurrentlyMemorized: true, lastReviewedAt: middle),
        HijriYearRecapReview(isCurrentlyMemorized: true, lastReviewedAt: next),
      ],
      longest: 42,
      activity: {
        _key(start): 3,
        _key(middle): 4,
        _key(end): 1,
        _key(next): 5,
        _key(DateTime(middle.year, middle.month, middle.day + 1)): 0,
        _key(DateTime(middle.year, middle.month, middle.day + 2)): -1,
        'not-a-date': 8,
      },
    );
    expect(recap.completedKhatmahs, 3);
    expect(recap.approximateMemorizedAyahs, 1);
    expect(recap.lifetimeLongestStreak, 42);
    expect(recap.activityByDay.values, unorderedEquals([3, 4, 1]));
  });

  test('returns zeros for empty data', () {
    final recap = _recap(now: _civilForHijri(1448, 12, 20, 0));
    expect(recap.completedKhatmahs, 0);
    expect(recap.approximateMemorizedAyahs, 0);
    expect(recap.lifetimeLongestStreak, 0);
    expect(recap.activityByDay, isEmpty);
  });
}
