import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan_template.dart';

RamadanInfo info(DateTime first, int length, RamadanPhase phase) => RamadanInfo(
  phase: phase,
  monthLength: length,
  firstDay: first,
  lastDay: DateTime(first.year, first.month, first.day + length - 1),
);

void main() {
  final first = DateTime(2027, 2, 8);

  test('30-day month from day 1: oneInMonth pagesPerDay 21, days 30', () {
    final p = paramsFor(
      RamadanKhatmahTemplate.oneInMonth,
      info(first, 30, RamadanPhase.ramadan),
      first,
    );
    expect(p.targetDays, 30);
    expect(p.pagesPerDay, 21);
    expect(p.wirdUnit, KhatmahWirdUnit.juz);
    expect(p.portionsPerDay, 1);
  });

  test('29-day month: days 29, ends on the last Ramadan day', () {
    final i = info(first, 29, RamadanPhase.ramadan);
    final p = paramsFor(RamadanKhatmahTemplate.oneInMonth, i, first);
    expect(p.targetDays, 29);
    expect(p.pagesPerDay, 21);
    final end = DateTime(first.year, first.month, first.day + p.targetDays - 1);
    expect(end, i.lastDay);
  });

  test('starting on day 10 of a 30-day month: days 21', () {
    final today = DateTime(2027, 2, 17);
    final p = paramsFor(
      RamadanKhatmahTemplate.oneInMonth,
      info(first, 30, RamadanPhase.ramadan),
      today,
    );
    expect(p.targetDays, 21);
    expect(p.pagesPerDay, 29);
  });

  test('invite phase uses the full month length', () {
    final p = paramsFor(
      RamadanKhatmahTemplate.oneInMonth,
      info(first, 30, RamadanPhase.invite),
      DateTime(2027, 2, 5),
    );
    expect(p.targetDays, 30);
  });

  test('twoInMonth: days ceil(n/2)', () {
    final p = paramsFor(
      RamadanKhatmahTemplate.twoInMonth,
      info(first, 29, RamadanPhase.ramadan),
      first,
    );
    expect(p.targetDays, 15);
    expect(p.pagesPerDay, 41);
    expect(p.wirdUnit, KhatmahWirdUnit.pages);
  });

  test('splitByPrayers has 5 portions per day', () {
    final p = paramsFor(
      RamadanKhatmahTemplate.splitByPrayers,
      info(first, 30, RamadanPhase.ramadan),
      first,
    );
    expect(p.portionsPerDay, 5);
    expect(p.pagesPerDay, 21);
  });

  test('last day is never below 1 day', () {
    final i = info(first, 30, RamadanPhase.lastTen);
    expect(ramadanDaysRemaining(i, DateTime(2027, 3, 20)), 1);
  });

  test(
    'splitByPrayers portions cover the daily range exactly with no gaps',
    () {
      for (final range in [(1, 21), (22, 42), (5, 7), (100, 100), (1, 5)]) {
        final parts = splitPagesIntoPortions(range.$1, range.$2, 5);
        expect(parts.first.from, range.$1);
        expect(parts.last.to, range.$2);
        for (var i = 1; i < parts.length; i++) {
          expect(parts[i].from, parts[i - 1].to + 1);
        }
        expect(parts.length, lessThanOrEqualTo(5));
      }
      expect(splitPagesIntoPortions(1, 21, 5).map((p) => p.to - p.from + 1), [
        5,
        4,
        4,
        4,
        4,
      ]);
    },
  );
}
