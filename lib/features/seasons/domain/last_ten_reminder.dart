import '../../../core/seasons/season_calendar.dart';

/// Device-level opt-in for the one-off "the last ten nights begin tonight"
/// reminder. Off unless the user turns it on from the Ramadan card.
const String lastTenReminderPreferenceKey = 'notifications_ramadan_last_ten';

/// Lead time before Maghrib, so the reminder arrives before the night starts.
const Duration lastTenReminderLead = Duration(minutes: 30);

/// Used when the prayer times for that day are unknown (no city chosen).
const int lastTenReminderFallbackHour = 17;
const int lastTenReminderFallbackMinute = 30;

/// Civil date of Ramadan day [lastTenEveDay], whose evening begins the last
/// ten nights. Null outside the invite phase and Ramadan days 1–20.
DateTime? lastTenEveDate(RamadanInfo info) {
  final first = info.firstDay;
  if (first == null) return null;
  final eligible =
      info.phase == RamadanPhase.invite ||
      (info.phase == RamadanPhase.ramadan &&
          (info.day ?? lastTenEveDay + 1) <= lastTenEveDay);
  if (!eligible) return null;
  return DateTime(first.year, first.month, first.day + lastTenEveDay - 1);
}

/// When the reminder fires: [lastTenReminderLead] before [maghrib] on the
/// eve, or the fallback time that day. [maghrib] on another date is ignored.
/// Null when there is no eve ahead or the time has already passed.
DateTime? lastTenReminderAt({
  required RamadanInfo info,
  required DateTime now,
  DateTime? maghrib,
}) {
  final eve = lastTenEveDate(info);
  if (eve == null) return null;
  final localMaghrib = maghrib?.toLocal();
  final sameDay =
      localMaghrib != null &&
      localMaghrib.year == eve.year &&
      localMaghrib.month == eve.month &&
      localMaghrib.day == eve.day;
  final at = sameDay
      ? localMaghrib.subtract(lastTenReminderLead)
      : DateTime(
          eve.year,
          eve.month,
          eve.day,
          lastTenReminderFallbackHour,
          lastTenReminderFallbackMinute,
        );
  return at.isAfter(now) ? at : null;
}
