import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';

DateTime _d(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Civil date whose adjusted Hijri date is 1 Ramadan [hYear].
DateTime _firstRamadan(int hYear, int adj) {
  final g = HijriCalendar().hijriToGregorian(hYear, 9, 1);
  var c = DateTime(g.year, g.month, g.day - adj);
  // Normalise against fromDate in case of conversion offsets.
  while (HijriCalendar.fromDate(_d(c, adj)).hMonth == 9 &&
      HijriCalendar.fromDate(_d(c, adj)).hDay > 1) {
    c = _d(c, -1);
  }
  while (!(HijriCalendar.fromDate(_d(c, adj)).hMonth == 9 &&
      HijriCalendar.fromDate(_d(c, adj)).hDay == 1)) {
    c = _d(c, 1);
  }
  return c;
}

void main() {
  for (final adj in [0, 1]) {
    test('phases across Ramadan 1448 with adjustment $adj', () {
      final first = _firstRamadan(1448, adj);
      final len = HijriCalendar.fromDate(_d(first, adj)).lengthOfMonth;
      expect(len, anyOf(29, 30));

      expect(
        ramadanInfoAt(_d(first, -30), adjustmentDays: adj).phase,
        RamadanPhase.none,
      );
      expect(
        ramadanInfoAt(_d(first, -8), adjustmentDays: adj).phase,
        RamadanPhase.none,
      );
      expect(
        ramadanInfoAt(_d(first, -7), adjustmentDays: adj).phase,
        RamadanPhase.invite,
      );
      expect(
        ramadanInfoAt(_d(first, -1), adjustmentDays: adj).phase,
        RamadanPhase.invite,
      );
      final d1 = ramadanInfoAt(first, adjustmentDays: adj);
      expect(d1.phase, RamadanPhase.ramadan);
      expect(d1.day, 1);
      expect(
        ramadanInfoAt(_d(first, 19), adjustmentDays: adj).phase,
        RamadanPhase.ramadan,
      );
      final d21 = ramadanInfoAt(_d(first, 20), adjustmentDays: adj);
      expect(d21.phase, RamadanPhase.lastTen);
      expect(d21.day, 21);
      final lastDay = ramadanInfoAt(_d(first, len - 1), adjustmentDays: adj);
      expect(lastDay.phase, RamadanPhase.lastTen);
      expect(lastDay.day, len);
      final eid = ramadanInfoAt(_d(first, len), adjustmentDays: adj);
      expect(eid.phase, RamadanPhase.afterEid);
      expect(
        ramadanInfoAt(_d(first, len + 6), adjustmentDays: adj).phase,
        RamadanPhase.afterEid,
      );
      expect(
        ramadanInfoAt(_d(first, len + 7), adjustmentDays: adj).phase,
        RamadanPhase.none,
      );
    });
  }

  test('monthLength from calendar; lastDay = firstDay + length - 1', () {
    final seen = <int>{};
    for (var y = 1446; y <= 1452; y++) {
      final first = _firstRamadan(y, 0);
      final len = HijriCalendar.fromDate(first).lengthOfMonth;
      seen.add(len);
      for (final probe in [
        _d(first, -3),
        _d(first, 5),
        _d(first, len - 1),
        _d(first, len + 2),
      ]) {
        final info = ramadanInfoAt(probe, adjustmentDays: 0);
        expect(info.monthLength, len);
        expect(info.firstDay, first);
        expect(info.lastDay, _d(first, len - 1));
        expect(info.firstDay!.hour, 0);
        expect(info.lastDay!.isUtc, isFalse);
      }
    }
    expect(seen.every((l) => l == 29 || l == 30), isTrue);
  });

  test('adjustment shifts the phase boundary by the offset', () {
    final first0 = _firstRamadan(1448, 0);
    final first1 = _firstRamadan(1448, 1);
    expect(first1, _d(first0, -1));
    expect(ramadanInfoAt(first0, adjustmentDays: 0).day, 1);
    expect(ramadanInfoAt(first0, adjustmentDays: 1).day, 2);
    expect(ramadanInfoAt(_d(first0, -1), adjustmentDays: 1).day, 1);
    expect(
      ramadanInfoAt(_d(first0, -1), adjustmentDays: 0).phase,
      RamadanPhase.invite,
    );
  });

  test('time of day is ignored', () {
    final first = _firstRamadan(1448, 0);
    final a = ramadanInfoAt(
      DateTime(first.year, first.month, first.day, 23, 59),
      adjustmentDays: 0,
    );
    expect(a.day, 1);
  });

  test('last-ten countdown and day number follow the Ramadan day', () {
    RamadanInfo at(RamadanPhase phase, int day) =>
        RamadanInfo(phase: phase, day: day, monthLength: 30);
    expect(daysUntilLastTenEve(at(RamadanPhase.ramadan, 1)), 19);
    expect(daysUntilLastTenEve(at(RamadanPhase.ramadan, 19)), 1);
    expect(daysUntilLastTenEve(at(RamadanPhase.ramadan, 20)), 0);
    expect(daysUntilLastTenEve(at(RamadanPhase.lastTen, 21)), isNull);
    expect(daysUntilLastTenEve(const RamadanInfo(phase: RamadanPhase.invite)),
        isNull);
    expect(lastTenDayNumber(at(RamadanPhase.lastTen, 21)), 1);
    expect(lastTenDayNumber(at(RamadanPhase.lastTen, 29)), 9);
    expect(lastTenDayNumber(at(RamadanPhase.ramadan, 20)), isNull);
  });
}
