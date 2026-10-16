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
