import 'package:equatable/equatable.dart';
import 'package:hijri/hijri_calendar.dart';

enum RamadanPhase { none, invite, ramadan, lastTen, afterEid }

/// Ramadan season snapshot for a civil date.
///
/// [day] is the Hijri day of Ramadan (only during ramadan/lastTen).
/// [monthLength] is the Ramadan length (29/30) from the Hijri calendar, or 0
/// when [phase] is [RamadanPhase.none]. [firstDay]/[lastDay] are local civil
/// dates (no time component) of the relevant Ramadan, null for none.
final class RamadanInfo extends Equatable {
  const RamadanInfo({
    required this.phase,
    this.day,
    this.monthLength = 0,
    this.firstDay,
    this.lastDay,
  });

  final RamadanPhase phase;
  final int? day;
  final int monthLength;
  final DateTime? firstDay;
  final DateTime? lastDay;

  @override
  List<Object?> get props => [phase, day, monthLength, firstDay, lastDay];
}

const int _inviteDays = 7;
const int _afterEidDays = 7;

DateTime _civil(DateTime d, int offsetDays) =>
    DateTime(d.year, d.month, d.day + offsetDays);

/// Mirrors home_occasion_service.dart: Hijri date of (civil date + adjustment).
HijriCalendar _hijriOf(DateTime civil, int adjustmentDays) =>
    HijriCalendar.fromDate(_civil(civil, adjustmentDays));

RamadanInfo ramadanInfoAt(DateTime now, {required int adjustmentDays}) {
  try {
    final today = _civil(now, 0);
    final h = _hijriOf(today, adjustmentDays);
    if (h.hMonth == 9) {
      final length = h.lengthOfMonth;
      final first = _civil(today, -(h.hDay - 1));
      return RamadanInfo(
        phase: h.hDay >= 21 ? RamadanPhase.lastTen : RamadanPhase.ramadan,
        day: h.hDay,
        monthLength: length,
        firstDay: first,
        lastDay: _civil(first, length - 1),
      );
    }
    if (h.hMonth == 10 && h.hDay <= _afterEidDays) {
      final last = _civil(today, -h.hDay);
      final length = _hijriOf(last, adjustmentDays).lengthOfMonth;
      return RamadanInfo(
        phase: RamadanPhase.afterEid,
        monthLength: length,
        firstDay: _civil(last, -(length - 1)),
        lastDay: last,
      );
    }
    if (h.hMonth == 8) {
      for (var k = 1; k <= _inviteDays; k++) {
        final probe = _hijriOf(_civil(today, k), adjustmentDays);
        if (probe.hMonth == 9) {
          final length = probe.lengthOfMonth;
          final first = _civil(today, k);
          return RamadanInfo(
            phase: RamadanPhase.invite,
            monthLength: length,
            firstDay: first,
            lastDay: _civil(first, length - 1),
          );
        }
      }
    }
  } catch (_) {}
  return const RamadanInfo(phase: RamadanPhase.none);
}

/// Ramadan day whose evening begins the last ten nights (night 21 starts at
/// Maghrib of day 20).
const int lastTenEveDay = 20;

// ─── General season engine ──────────────────────────────────────────────────

/// Fixed-date religious seasons and recurring occasions. One switch in the
/// seasons settings page maps to one id (the Eid al-Fitr row also drives
/// [shawwalSix], and the Dhul-Hijjah row also drives [eidAdha]).
enum SeasonId {
  shabanPrep,
  ramadan,
  eidFitr,
  shawwalSix,
  dhulHijjahTen,
  eidAdha,
  hijriNewYear,
  ashura,
  friday,
  whiteDays,
  monThu,
}

/// Where a date sits inside a season's window.
enum SeasonStage { invite, active, after }

/// One season active (in any stage) on a civil date.
///
/// [day] is the Hijri day of month while the window runs inside one Hijri
/// month (Ramadan day, Shawwal day, …), null for invite days and civil
/// weekdays. [hijriYear] is the Hijri year the season belongs to — the
/// upcoming one during an invite (Muharram of year X+1 for a New Year invite
/// that runs at the end of Dhul-Hijjah X) — and null for the civil weekday
/// seasons.
final class ActiveSeason extends Equatable {
  const ActiveSeason({
    required this.id,
    required this.stage,
    this.hijriYear,
    this.day,
  });

  final SeasonId id;
  final SeasonStage stage;
  final int? hijriYear;
  final int? day;

  @override
  List<Object?> get props => [id, stage, hijriYear, day];
}

/// Every season whose window covers [now], on the Hijri date the user's
/// [adjustmentDays] produces. Pure; dates at any time of day share a result.
/// A Hijri conversion failure still yields the civil weekday seasons.
List<ActiveSeason> seasonsAt(DateTime now, {required int adjustmentDays}) {
  final out = <ActiveSeason>[];
  final isFriday = now.weekday == DateTime.friday;
  final isMonOrThu =
      now.weekday == DateTime.monday || now.weekday == DateTime.thursday;
  try {
    final h = _hijriOf(_civil(now, 0), adjustmentDays);
    final month = h.hMonth;
    final day = h.hDay;
    final year = h.hYear;
    final remaining = h.lengthOfMonth - day;

    if (month == 8) {
      if (day >= 15) {
        out.add(
          ActiveSeason(
            id: SeasonId.shabanPrep,
            stage: SeasonStage.active,
            hijriYear: year,
            day: day,
          ),
        );
      }
      if (remaining < _inviteDays) {
        out.add(
          ActiveSeason(
            id: SeasonId.ramadan,
            stage: SeasonStage.invite,
            hijriYear: year,
          ),
        );
      }
    } else if (month == 9) {
      out.add(
        ActiveSeason(
          id: SeasonId.ramadan,
          stage: SeasonStage.active,
          hijriYear: year,
          day: day,
        ),
      );
    } else if (month == 10) {
      if (day <= _afterEidDays) {
        out.add(
          ActiveSeason(
            id: SeasonId.ramadan,
            stage: SeasonStage.after,
            hijriYear: year,
          ),
        );
      }
      if (day <= 3) {
        out.add(
          ActiveSeason(
            id: SeasonId.eidFitr,
            stage: SeasonStage.active,
            hijriYear: year,
            day: day,
          ),
        );
      }
      if (day >= 2) {
        out.add(
          ActiveSeason(
            id: SeasonId.shawwalSix,
            stage: SeasonStage.active,
            hijriYear: year,
            day: day,
          ),
        );
      }
    } else if (month == 11) {
      if (remaining < 3) {
        out.add(
          ActiveSeason(
            id: SeasonId.dhulHijjahTen,
            stage: SeasonStage.invite,
            hijriYear: year,
          ),
        );
      }
    } else if (month == 12) {
      if (day <= 10) {
        out.add(
          ActiveSeason(
            id: SeasonId.dhulHijjahTen,
            stage: SeasonStage.active,
            hijriYear: year,
            day: day,
          ),
        );
      }
      if (day >= 10 && day <= 13) {
        out.add(
          ActiveSeason(
            id: SeasonId.eidAdha,
            stage: SeasonStage.active,
            hijriYear: year,
            day: day,
          ),
        );
      }
      if (day >= 20) {
        out.add(
          ActiveSeason(
            id: SeasonId.hijriNewYear,
            stage: SeasonStage.invite,
            hijriYear: year + 1,
          ),
        );
      }
    } else if (month == 1) {
      if (day <= 7) {
        out.add(
          ActiveSeason(
            id: SeasonId.hijriNewYear,
            stage: SeasonStage.active,
            hijriYear: year,
            day: day,
          ),
        );
      }
      if (day >= 6 && day <= 8) {
        out.add(
          ActiveSeason(
            id: SeasonId.ashura,
            stage: SeasonStage.invite,
            hijriYear: year,
          ),
        );
      }
      if (day >= 9 && day <= 10) {
        out.add(
          ActiveSeason(
            id: SeasonId.ashura,
            stage: SeasonStage.active,
            hijriYear: year,
            day: day,
          ),
        );
      }
    }
    if (day >= 13 && day <= 15) {
      out.add(
        ActiveSeason(
          id: SeasonId.whiteDays,
          stage: SeasonStage.active,
          hijriYear: year,
          day: day,
        ),
      );
    } else if (day == 12) {
      out.add(
        ActiveSeason(
          id: SeasonId.whiteDays,
          stage: SeasonStage.invite,
          hijriYear: year,
        ),
      );
    }
  } catch (_) {
    // Civil weekday seasons still apply below.
  }
  if (isFriday) {
    out.add(const ActiveSeason(id: SeasonId.friday, stage: SeasonStage.active));
  }
  if (isMonOrThu) {
    out.add(const ActiveSeason(id: SeasonId.monThu, stage: SeasonStage.active));
  }
  return out;
}

/// Days from [now] until [id] is first active, probing at most [maxDays]
/// ahead; null when it does not turn active within that horizon. Drives the
/// seasons settings subtitle («Ramadan in 12 days»).
int? daysUntilSeasonActive(
  SeasonId id,
  DateTime now, {
  required int adjustmentDays,
  int maxDays = 60,
}) {
  for (var k = 0; k <= maxDays; k++) {
    final probe = seasonsAt(
      DateTime(now.year, now.month, now.day + k),
      adjustmentDays: adjustmentDays,
    );
    if (probe.any((s) => s.id == id && s.stage == SeasonStage.active)) return k;
  }
  return null;
}

/// Days from today until the evening the last ten nights begin: 0 on day 20
/// itself, null outside Ramadan days 1–20.
int? daysUntilLastTenEve(RamadanInfo info) {
  final day = info.day;
  if (info.phase != RamadanPhase.ramadan || day == null || day < 1) return null;
  if (day > lastTenEveDay) return null;
  return lastTenEveDay - day;
}

/// 1-based day within the last ten (day 21 is 1), or null outside them.
int? lastTenDayNumber(RamadanInfo info) {
  final day = info.day;
  if (info.phase != RamadanPhase.lastTen || day == null) return null;
  return day - lastTenEveDay;
}
