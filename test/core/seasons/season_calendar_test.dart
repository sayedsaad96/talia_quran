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
  /// Civil date whose adjusted Hijri date is [hYear]/[hMonth]/[hDay].
  /// Anchors on day 1 of the month (conversion offsets are a day or two),
  /// then walks civil days forward, exactly the way the engine builds
  /// months. Bounded, so a target the calendar does not have throws instead
  /// of hanging.
  DateTime hijriDate(int hYear, int hMonth, int hDay, int adj) {
    final g = HijriCalendar().hijriToGregorian(hYear, hMonth, 1);
    var c = DateTime(g.year, g.month, g.day - adj);
    var located = false;
    for (var i = 0; i < 15 && !located; i++) {
      final h = HijriCalendar.fromDate(_d(c, adj));
      if (h.hMonth == hMonth && h.hDay == 1) {
        located = true;
      } else if (h.hMonth == hMonth) {
        c = _d(c, 1 - h.hDay);
      } else {
        c = _d(c, 1);
      }
    }
    if (!located) {
      throw StateError('no civil date maps to $hYear-$hMonth-01 (adj $adj)');
    }
    return _d(c, hDay - 1);
  }

  int monthLength(int hYear, int hMonth, int adj) => HijriCalendar.fromDate(
    _d(hijriDate(hYear, hMonth, 1, adj), adj),
  ).lengthOfMonth;

  bool hasSeason(DateTime now, SeasonId id, SeasonStage stage, {int adj = 0}) =>
      seasonsAt(
        now,
        adjustmentDays: adj,
      ).any((s) => s.id == id && s.stage == stage);

  ActiveSeason? seasonOf(DateTime now, SeasonId id, {int adj = 0}) =>
      seasonsAt(now, adjustmentDays: adj).where((s) => s.id == id).firstOrNull;

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
    expect(
      daysUntilLastTenEve(const RamadanInfo(phase: RamadanPhase.invite)),
      isNull,
    );
    expect(lastTenDayNumber(at(RamadanPhase.lastTen, 21)), 1);
    expect(lastTenDayNumber(at(RamadanPhase.lastTen, 29)), 9);
    expect(lastTenDayNumber(at(RamadanPhase.ramadan, 20)), isNull);
  });

  // ─── seasonsAt ────────────────────────────────────────────────────────────

  for (final adj in [-1, 0, 1]) {
    group('seasonsAt boundaries with adjustment $adj', () {
      test('shabanPrep covers 15 Shaaban to the end of the month', () {
        const y = 1448;
        final len = monthLength(y, 8, adj);
        expect(
          hasSeason(
            hijriDate(y, 8, 14, adj),
            SeasonId.shabanPrep,
            SeasonStage.active,
            adj: adj,
          ),
          isFalse,
        );
        expect(
          hasSeason(
            hijriDate(y, 8, 15, adj),
            SeasonId.shabanPrep,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 8, len, adj),
            SeasonId.shabanPrep,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
      });

      test('ramadan invites for exactly 7 days then runs the whole month', () {
        const y = 1448;
        final len = monthLength(y, 8, adj);
        expect(
          hasSeason(
            hijriDate(y, 8, len - 7, adj),
            SeasonId.ramadan,
            SeasonStage.invite,
            adj: adj,
          ),
          isFalse,
        );
        expect(
          hasSeason(
            hijriDate(y, 8, len - 6, adj),
            SeasonId.ramadan,
            SeasonStage.invite,
            adj: adj,
          ),
          isTrue,
        );
        final d1 = seasonOf(
          hijriDate(y, 9, 1, adj),
          SeasonId.ramadan,
          adj: adj,
        );
        expect(d1?.stage, SeasonStage.active);
        expect(d1?.day, 1);
        expect(d1?.hijriYear, y);
        final d21 = seasonOf(
          hijriDate(y, 9, 21, adj),
          SeasonId.ramadan,
          adj: adj,
        );
        expect(d21?.stage, SeasonStage.active);
        expect(d21?.day, 21);
        final last = seasonOf(
          hijriDate(y, 9, monthLength(y, 9, adj), adj),
          SeasonId.ramadan,
          adj: adj,
        );
        expect(last?.day, monthLength(y, 9, adj));
      });

      test('ramadan after, eidFitr and shawwalSix windows in Shawwal', () {
        const y = 1448;
        expect(
          hasSeason(
            hijriDate(y, 10, 1, adj),
            SeasonId.ramadan,
            SeasonStage.after,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 10, 7, adj),
            SeasonId.ramadan,
            SeasonStage.after,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 10, 8, adj),
            SeasonId.ramadan,
            SeasonStage.after,
            adj: adj,
          ),
          isFalse,
        );
        expect(
          hasSeason(
            hijriDate(y, 10, 3, adj),
            SeasonId.eidFitr,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 10, 4, adj),
            SeasonId.eidFitr,
            SeasonStage.active,
            adj: adj,
          ),
          isFalse,
        );
        expect(
          hasSeason(
            hijriDate(y, 10, 1, adj),
            SeasonId.shawwalSix,
            SeasonStage.active,
            adj: adj,
          ),
          isFalse,
        );
        expect(
          hasSeason(
            hijriDate(y, 10, 2, adj),
            SeasonId.shawwalSix,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
      });

      test('dhulHijjahTen invites 3 days then runs 1–10', () {
        const y = 1448;
        final qdahLen = monthLength(y, 11, adj);
        expect(
          hasSeason(
            hijriDate(y, 11, qdahLen - 3, adj),
            SeasonId.dhulHijjahTen,
            SeasonStage.invite,
            adj: adj,
          ),
          isFalse,
        );
        expect(
          hasSeason(
            hijriDate(y, 11, qdahLen - 2, adj),
            SeasonId.dhulHijjahTen,
            SeasonStage.invite,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 12, 1, adj),
            SeasonId.dhulHijjahTen,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 12, 10, adj),
            SeasonId.dhulHijjahTen,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 12, 11, adj),
            SeasonId.dhulHijjahTen,
            SeasonStage.active,
            adj: adj,
          ),
          isFalse,
        );
      });

      test('eidAdha covers 10–13 Dhul-Hijjah', () {
        const y = 1448;
        expect(
          hasSeason(
            hijriDate(y, 12, 9, adj),
            SeasonId.eidAdha,
            SeasonStage.active,
            adj: adj,
          ),
          isFalse,
        );
        expect(
          hasSeason(
            hijriDate(y, 12, 10, adj),
            SeasonId.eidAdha,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 12, 13, adj),
            SeasonId.eidAdha,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 12, 14, adj),
            SeasonId.eidAdha,
            SeasonStage.active,
            adj: adj,
          ),
          isFalse,
        );
      });

      test(
        'hijriNewYear invites from 20 Dhul-Hijjah then runs 1–7 Muharram',
        () {
          const y = 1448;
          expect(
            hasSeason(
              hijriDate(y, 12, 19, adj),
              SeasonId.hijriNewYear,
              SeasonStage.invite,
              adj: adj,
            ),
            isFalse,
          );
          final invite = seasonOf(
            hijriDate(y, 12, 20, adj),
            SeasonId.hijriNewYear,
            adj: adj,
          );
          expect(invite?.stage, SeasonStage.invite);
          expect(invite?.hijriYear, y + 1);
          final active = seasonOf(
            hijriDate(y + 1, 1, 1, adj),
            SeasonId.hijriNewYear,
            adj: adj,
          );
          expect(active?.stage, SeasonStage.active);
          expect(active?.hijriYear, y + 1);
          expect(
            hasSeason(
              hijriDate(y + 1, 1, 7, adj),
              SeasonId.hijriNewYear,
              SeasonStage.active,
              adj: adj,
            ),
            isTrue,
          );
          expect(
            hasSeason(
              hijriDate(y + 1, 1, 8, adj),
              SeasonId.hijriNewYear,
              SeasonStage.active,
              adj: adj,
            ),
            isFalse,
          );
        },
      );

      test('ashura invites 6–8 then runs 9–10 Muharram', () {
        const y = 1449;
        expect(
          hasSeason(
            hijriDate(y, 1, 5, adj),
            SeasonId.ashura,
            SeasonStage.invite,
            adj: adj,
          ),
          isFalse,
        );
        expect(
          hasSeason(
            hijriDate(y, 1, 6, adj),
            SeasonId.ashura,
            SeasonStage.invite,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 1, 8, adj),
            SeasonId.ashura,
            SeasonStage.invite,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 1, 9, adj),
            SeasonId.ashura,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 1, 10, adj),
            SeasonId.ashura,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            hijriDate(y, 1, 11, adj),
            SeasonId.ashura,
            SeasonStage.active,
            adj: adj,
          ),
          isFalse,
        );
      });

      test('whiteDays invite on the 12th and run 13–15 of every month', () {
        const y = 1448;
        for (final month in [3, 6, 9, 12]) {
          expect(
            hasSeason(
              hijriDate(y, month, 12, adj),
              SeasonId.whiteDays,
              SeasonStage.invite,
              adj: adj,
            ),
            isTrue,
          );
          expect(
            hasSeason(
              hijriDate(y, month, 11, adj),
              SeasonId.whiteDays,
              SeasonStage.invite,
              adj: adj,
            ),
            isFalse,
          );
          expect(
            hasSeason(
              hijriDate(y, month, 13, adj),
              SeasonId.whiteDays,
              SeasonStage.active,
              adj: adj,
            ),
            isTrue,
          );
          expect(
            hasSeason(
              hijriDate(y, month, 15, adj),
              SeasonId.whiteDays,
              SeasonStage.active,
              adj: adj,
            ),
            isTrue,
          );
          expect(
            hasSeason(
              hijriDate(y, month, 16, adj),
              SeasonId.whiteDays,
              SeasonStage.active,
              adj: adj,
            ),
            isFalse,
          );
        }
      });

      test('civil weekdays follow the civil date', () {
        // 2026-10-30 is a Friday, 2026-10-26 a Monday, 2026-10-29 a Thursday.
        expect(
          hasSeason(
            DateTime(2026, 10, 30, 9),
            SeasonId.friday,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            DateTime(2026, 10, 26, 9),
            SeasonId.monThu,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            DateTime(2026, 10, 29, 9),
            SeasonId.monThu,
            SeasonStage.active,
            adj: adj,
          ),
          isTrue,
        );
        expect(
          hasSeason(
            DateTime(2026, 10, 27, 9),
            SeasonId.monThu,
            SeasonStage.active,
            adj: adj,
          ),
          isFalse,
        );
        expect(
          hasSeason(
            DateTime(2026, 10, 30, 9),
            SeasonId.monThu,
            SeasonStage.active,
            adj: adj,
          ),
          isFalse,
        );
      });

      test('seasonsAt agrees with ramadanInfoAt across a full year sweep', () {
        final start = hijriDate(1447, 9, 1, adj);
        for (var i = 0; i < 400; i++) {
          final now = _d(start, i);
          final ramadan = seasonOf(now, SeasonId.ramadan, adj: adj);
          final phase = ramadanInfoAt(now, adjustmentDays: adj).phase;
          expect(ramadan?.stage, switch (phase) {
            RamadanPhase.invite => SeasonStage.invite,
            RamadanPhase.ramadan || RamadanPhase.lastTen => SeasonStage.active,
            RamadanPhase.afterEid => SeasonStage.after,
            RamadanPhase.none => null,
          }, reason: 'day $i (${now.year}-${now.month}-${now.day})');
        }
      });
    });
  }

  test('ramadan length 29 and 30 years both close on their last day', () {
    var saw29 = false;
    var saw30 = false;
    for (var y = 1446; y <= 1452; y++) {
      final len = monthLength(y, 9, 0);
      final last = seasonOf(hijriDate(y, 9, len, 0), SeasonId.ramadan);
      expect(last?.stage, SeasonStage.active);
      expect(last?.day, len);
      expect(
        hasSeason(
          _d(hijriDate(y, 9, len, 0), 1),
          SeasonId.ramadan,
          SeasonStage.active,
        ),
        isFalse,
      );
      expect(
        hasSeason(
          _d(hijriDate(y, 9, len, 0), 1),
          SeasonId.eidFitr,
          SeasonStage.active,
        ),
        isTrue,
      );
      if (len == 29) saw29 = true;
      if (len == 30) saw30 = true;
    }
    expect(saw29, isTrue, reason: 'the sweep must cover a 29-day Ramadan');
    expect(saw30, isTrue, reason: 'the sweep must cover a 30-day Ramadan');
  });
}
