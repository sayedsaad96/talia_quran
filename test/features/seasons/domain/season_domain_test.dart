import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/features/seasons/domain/iftar_countdown.dart';
import 'package:talia_quran/features/seasons/domain/season_card_selection.dart';
import 'package:talia_quran/features/seasons/domain/season_reminders.dart';
import 'package:talia_quran/features/seasons/domain/season_windows.dart';

/// Civil date whose Hijri date is ([year], [month], [day]) under [adj].
DateTime civilOf(int year, int month, int day, int adj) {
  final first = hijriMonthFirstCivilDay(year, month, adj);
  return DateTime(first.year, first.month, first.day + day - 1);
}

bool _all(SeasonId _) => true;

void main() {
  group('hijri windows', () {
    test(
      'civilOf round-trips through hijriOfCivil for adjustments -1/0/+1',
      () {
        for (final adj in [-1, 0, 1]) {
          final d = civilOf(1448, 12, 10, adj);
          final h = hijriOfCivil(d, adj);
          expect((h.year, h.month, h.day), (1448, 12, 10));
        }
      },
    );
  });

  group('selectSeasonCard', () {
    // (label, hijri y/m/d, expected id, expected stage)
    final cases = <(String, int, int, int, SeasonId, SeasonStage)>[
      ('Eid al-Fitr', 1448, 10, 1, SeasonId.eidFitr, SeasonStage.active),
      ('Eid al-Fitr day 3', 1448, 10, 3, SeasonId.eidFitr, SeasonStage.active),
      ('six of Shawwal', 1448, 10, 10, SeasonId.shawwalSix, SeasonStage.active),
      (
        'Dhul-Hijjah invite',
        1448,
        11,
        28,
        SeasonId.dhulHijjahTen,
        SeasonStage.invite,
      ),
      (
        'Dhul-Hijjah day 3',
        1448,
        12,
        3,
        SeasonId.dhulHijjahTen,
        SeasonStage.active,
      ),
      (
        'Dhul-Hijjah day 9',
        1448,
        12,
        9,
        SeasonId.dhulHijjahTen,
        SeasonStage.active,
      ),
      ('Eid al-Adha', 1448, 12, 10, SeasonId.eidAdha, SeasonStage.active),
      (
        'Eid al-Adha day 13',
        1448,
        12,
        13,
        SeasonId.eidAdha,
        SeasonStage.active,
      ),
      ('Hijri new year', 1449, 1, 2, SeasonId.hijriNewYear, SeasonStage.active),
      ('Ashura invite', 1449, 1, 7, SeasonId.ashura, SeasonStage.invite),
      ('Ashura day 9', 1449, 1, 9, SeasonId.ashura, SeasonStage.active),
      ('Ashura day 10', 1449, 1, 10, SeasonId.ashura, SeasonStage.active),
      ('Shaban prep', 1448, 8, 20, SeasonId.shabanPrep, SeasonStage.active),
      (
        'white days invite',
        1448,
        3,
        12,
        SeasonId.whiteDays,
        SeasonStage.invite,
      ),
      ('white days', 1448, 3, 14, SeasonId.whiteDays, SeasonStage.active),
    ];
    for (final adj in [-1, 0, 1]) {
      for (final (label, y, m, d, id, stage) in cases) {
        test('$label (adjustment $adj)', () {
          final s = selectSeasonCard(
            civilOf(y, m, d, adj),
            adjustmentDays: adj,
            isVisible: _all,
          );
          expect(s?.id, id);
          expect(s?.stage, stage);
        });
      }
    }

    test('a Friday outside every other season picks the Kahf card', () {
      final friday = DateTime(2027, 4, 16);
      expect(friday.weekday, DateTime.friday);
      final s = selectSeasonCard(friday, adjustmentDays: 0, isVisible: _all);
      expect(s?.id, SeasonId.friday);
    });

    test('a hidden season is skipped and the next one shows', () {
      final d = civilOf(1448, 12, 10, 0); // Eid al-Adha + Dhul-Hijjah days
      bool visible(SeasonId id) =>
          id != SeasonId.eidAdha && id != SeasonId.dhulHijjahTen;
      final s = selectSeasonCard(d, adjustmentDays: 0, isVisible: visible);
      expect(s?.id, isNot(SeasonId.eidAdha));
      expect(s?.id, isNot(SeasonId.dhulHijjahTen));
    });

    test('nothing is visible with every season off', () {
      expect(
        selectSeasonCard(
          civilOf(1448, 10, 1, 0),
          adjustmentDays: 0,
          isVisible: (_) => false,
        ),
        isNull,
      );
    });

    test('Ramadan is never chosen (it has its own card)', () {
      final s = selectSeasonCard(
        civilOf(1448, 9, 5, 0),
        adjustmentDays: 0,
        isVisible: _all,
      );
      expect(s?.id, isNot(SeasonId.ramadan));
    });

    test('the New Year invite leaves the home to the recap card', () {
      final s = selectSeasonCard(
        civilOf(1448, 12, 22, 0),
        adjustmentDays: 0,
        isVisible: _all,
      );
      expect(s?.id, isNot(SeasonId.hijriNewYear));
    });

    test('white days are not offered on 13 Dhul-Hijjah or in Ramadan', () {
      for (final (m, d) in [(12, 12), (12, 14), (9, 14)]) {
        final s = selectSeasonCard(
          civilOf(1448, m, d, 0),
          adjustmentDays: 0,
          isVisible: (id) => id == SeasonId.whiteDays,
        );
        expect(
          s?.id,
          m == 12 && d == 14 ? SeasonId.whiteDays : isNull,
          reason: '$m/$d',
        );
      }
    });

    test('the Eid and Dhul-Hijjah rows share a switch group', () {
      expect(
        seasonSwitchGroup(SeasonId.shawwalSix),
        contains(SeasonId.eidFitr),
      );
      expect(
        seasonSwitchGroup(SeasonId.eidAdha),
        contains(SeasonId.dhulHijjahTen),
      );
      expect(seasonSwitchGroup(SeasonId.friday), [SeasonId.friday]);
    });
  });

  group('season reminders', () {
    List<SeasonReminderSlot> slots(
      DateTime now, {
      bool Function(SeasonId)? v,
      int adj = 0,
    }) => upcomingSeasonReminderSlots(
      now,
      adjustmentDays: adj,
      isVisible: v ?? _all,
    );

    test('Arafah eve is 8 Dhul-Hijjah, for every adjustment', () {
      for (final adj in [-1, 0, 1]) {
        final day = civilOf(1448, 12, 8, adj);
        final found = slots(day, adj: adj);
        expect(found.first.kind, SeasonReminderKind.arafahEve, reason: '$adj');
        expect(found.first.date, day);
      }
    });

    test('Ashura eve is 8 Muharram', () {
      final day = civilOf(1449, 1, 8, 0);
      expect(
        slots(day).where((s) => s.date == day).single.kind,
        SeasonReminderKind.ashuraEve,
      );
    });

    test('white days eve is the 12th, never before Eid or in Ramadan', () {
      final ok = civilOf(1448, 3, 12, 0);
      expect(
        slots(ok).where((s) => s.date == ok).single.kind,
        SeasonReminderKind.whiteDaysEve,
      );
      // 12 Dhul-Hijjah: tomorrow is a day after Eid; 12 Ramadan: Ramadan.
      for (final (m, d) in [(12, 12), (9, 12)]) {
        final day = civilOf(1448, m, d, 0);
        final onDay = slots(day).where((s) => s.date == day);
        expect(
          onDay.where((s) => s.kind == SeasonReminderKind.whiteDaysEve),
          isEmpty,
          reason: '$m/$d',
        );
      }
    });

    test('at most one reminder per civil day, higher priority wins', () {
      // 8 Dhul-Hijjah that happens to be a Friday would still give one slot.
      final start = DateTime(2027, 1, 1);
      for (var k = 0; k < 400; k += 7) {
        final found = slots(DateTime(start.year, start.month, start.day + k));
        final dates = found.map((s) => s.date).toList();
        expect(dates.toSet().length, dates.length);
      }
      final fri = civilOf(1448, 12, 8, 0);
      final shifted = List.generate(
        14,
        (i) => DateTime(fri.year, fri.month, fri.day + i),
      );
      for (final d in shifted) {
        final onDay = slots(d).where((s) => s.date == d);
        expect(onDay.length, lessThanOrEqualTo(1));
      }
    });

    test('Sunday/Wednesday evening kind; Friday has no seasonal reminder', () {
      final fri = DateTime(2027, 2, 12);
      expect(fri.weekday, DateTime.friday);
      expect(
        slots(fri, v: (id) => id == SeasonId.friday).where((s) => s.date == fri),
        isEmpty,
      );
      // monThu off by default unless visible; visible on Sunday/Wednesday.
      final sun = DateTime(2027, 4, 18);
      expect(sun.weekday, DateTime.sunday);
      expect(
        slots(sun, v: (id) => id == SeasonId.monThu).first.kind,
        SeasonReminderKind.monThuEve,
      );
      expect(
        slots(
          sun,
          v: (id) => id == SeasonId.friday,
        ).where((s) => s.date == sun),
        isEmpty,
      );
      // Not on the eve of a Ramadan fast day.
      final ramadanSunday = DateTime(2027, 2, 14);
      expect(
        slots(
          ramadanSunday,
          v: (id) => id == SeasonId.monThu,
        ).where((s) => s.date == ramadanSunday),
        isEmpty,
      );
    });

    test('a hidden season gives no reminder', () {
      final day = civilOf(1448, 12, 8, 0);
      expect(
        slots(
          day,
          v: (id) => id != SeasonId.dhulHijjahTen,
        ).where((s) => s.kind == SeasonReminderKind.arafahEve),
        isEmpty,
      );
    });

    test('times: evening before Maghrib or 20:00', () {
      final day = civilOf(1448, 12, 8, 0);
      final slot = SeasonReminderSlot(SeasonReminderKind.arafahEve, day);
      final early = DateTime(day.year, day.month, day.day, 8);
      expect(
        seasonReminderTime(slot, now: early),
        DateTime(day.year, day.month, day.day, 20),
      );
      final maghrib = DateTime(day.year, day.month, day.day, 17, 40);
      expect(
        seasonReminderTime(slot, now: early, maghrib: maghrib),
        DateTime(day.year, day.month, day.day, 17, 10),
      );
      // Maghrib of another day is ignored.
      expect(
        seasonReminderTime(
          slot,
          now: early,
          maghrib: maghrib.add(const Duration(days: 1)),
        ),
        DateTime(day.year, day.month, day.day, 20),
      );
    });
  });

  group('iftarCountdownAt', () {
    final fajr = DateTime(2027, 2, 20, 5, 10);
    final maghrib = DateTime(2027, 2, 20, 17, 45);
    final fajrNext = DateTime(2027, 2, 21, 5, 9);

    IftarCountdown? at(DateTime now, {bool times = true}) => iftarCountdownAt(
      now,
      fajrToday: times ? fajr : null,
      maghribToday: times ? maghrib : null,
      fajrTomorrow: times ? fajrNext : null,
    );

    test('before Maghrib counts down to iftar', () {
      final c = at(DateTime(2027, 2, 20, 15, 30))!;
      expect(c.phase, FastPhase.untilIftar);
      expect(c.remaining, const Duration(hours: 2, minutes: 15));
    });

    test('after Maghrib shows when suhoor ends', () {
      final c = at(DateTime(2027, 2, 20, 18))!;
      expect(c.phase, FastPhase.untilSuhoorEnd);
      expect(c.fajr, fajrNext);
    });

    test('before Fajr still shows the same night Fajr', () {
      final c = at(DateTime(2027, 2, 20, 3))!;
      expect(c.phase, FastPhase.untilSuhoorEnd);
      expect(c.fajr, fajr);
    });

    test('after Maghrib on the last Ramadan day there is no suhoor', () {
      final c = iftarCountdownAt(
        DateTime(2027, 2, 20, 18),
        fajrToday: fajr,
        maghribToday: maghrib,
        fajrTomorrow: fajrNext,
        lastRamadanDay: true,
      );
      expect(c, isNull);
      // Before Maghrib the last day still counts down to iftar.
      final before = iftarCountdownAt(
        DateTime(2027, 2, 20, 15),
        fajrToday: fajr,
        maghribToday: maghrib,
        fajrTomorrow: fajrNext,
        lastRamadanDay: true,
      );
      expect(before!.phase, FastPhase.untilIftar);
    });

    test('no prayer times means nothing', () {
      expect(at(DateTime(2027, 2, 20, 12), times: false), isNull);
    });
  });
}
