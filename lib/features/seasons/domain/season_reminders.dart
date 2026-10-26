import '../../../core/seasons/season_calendar.dart';
import 'season_card_selection.dart';
import 'season_windows.dart';

/// One-off neutral seasonal reminders, in priority order. At most one per
/// civil day; the text is plain UI copy (no azkar, no virtue claims).
enum SeasonReminderKind {
  arafahEve,
  ashuraEve,
  whiteDaysEve,
  monThuEve,
}

/// The season switch a reminder needs on.
SeasonId seasonOfReminder(SeasonReminderKind kind) => switch (kind) {
  SeasonReminderKind.arafahEve => SeasonId.dhulHijjahTen,
  SeasonReminderKind.ashuraEve => SeasonId.ashura,
  SeasonReminderKind.whiteDaysEve => SeasonId.whiteDays,
  SeasonReminderKind.monThuEve => SeasonId.monThu,
};

class SeasonReminderSlot {
  const SeasonReminderSlot(this.kind, this.date);

  final SeasonReminderKind kind;

  /// Civil date the reminder fires on (no time component).
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is SeasonReminderSlot && other.kind == kind && other.date == date;

  @override
  int get hashCode => Object.hash(kind, date);

  @override
  String toString() => 'SeasonReminderSlot($kind, $date)';
}

/// Reminders go out this many days ahead at most.
const int seasonReminderHorizonDays = 7;

/// Evening reminders arrive this long before Maghrib, or at the fallback
/// time when prayer times are unknown.
const Duration seasonReminderEveningLead = Duration(minutes: 30);
const int seasonReminderEveningFallbackHour = 20;

/// Whether the reminder is timed from Maghrib when it is known.
bool seasonReminderUsesMaghrib(SeasonReminderKind kind) =>
    kind == SeasonReminderKind.arafahEve ||
    kind == SeasonReminderKind.ashuraEve ||
    kind == SeasonReminderKind.whiteDaysEve;

/// The next reminders from [now], one per civil day at most (the highest
/// priority wins the day), for the seasons [isVisible] allows. Pure.
List<SeasonReminderSlot> upcomingSeasonReminderSlots(
  DateTime now, {
  required int adjustmentDays,
  required bool Function(SeasonId id) isVisible,
  int horizonDays = seasonReminderHorizonDays,
}) {
  final out = <SeasonReminderSlot>[];
  for (var k = 0; k < horizonDays; k++) {
    final day = DateTime(now.year, now.month, now.day + k);
    final tomorrow = DateTime(day.year, day.month, day.day + 1);
    final ({int year, int month, int day}) today;
    final ({int year, int month, int day}) next;
    try {
      today = hijriOfCivil(day, adjustmentDays);
      next = hijriOfCivil(tomorrow, adjustmentDays);
    } catch (_) {
      continue;
    }
    SeasonReminderKind? kind;
    if (today.month == 12 &&
        today.day == 8 &&
        isVisible(SeasonId.dhulHijjahTen)) {
      kind = SeasonReminderKind.arafahEve;
    } else if (today.month == 1 &&
        today.day == 8 &&
        isVisible(SeasonId.ashura)) {
      kind = SeasonReminderKind.ashuraEve;
    } else if (next.day == 13 &&
        !isFastingNotOffered(next.month, next.day) &&
        isVisible(SeasonId.whiteDays)) {
      kind = SeasonReminderKind.whiteDaysEve;
    } else if ((day.weekday == DateTime.sunday ||
            day.weekday == DateTime.wednesday) &&
        !isFastingNotOffered(next.month, next.day) &&
        isVisible(SeasonId.monThu)) {
      kind = SeasonReminderKind.monThuEve;
    }
    if (kind != null) out.add(SeasonReminderSlot(kind, day));
  }
  return out;
}

/// When [slot] fires: evening reminders
/// [seasonReminderEveningLead] before [maghrib] (a time on another date is
/// ignored) or at the fallback hour. Null when that moment is not after [now].
DateTime? seasonReminderTime(
  SeasonReminderSlot slot, {
  required DateTime now,
  DateTime? maghrib,
}) {
  final d = slot.date;
  final local = maghrib?.toLocal();
  final sameDay =
      local != null &&
      seasonReminderUsesMaghrib(slot.kind) &&
      local.year == d.year &&
      local.month == d.month &&
      local.day == d.day;
  final at = sameDay
      ? local.subtract(seasonReminderEveningLead)
      : DateTime(d.year, d.month, d.day, seasonReminderEveningFallbackHour);
  return at.isAfter(now) ? at : null;
}
