/// What the Ramadan card says about the fast right now.
enum FastPhase { untilIftar, untilSuhoorEnd }

class IftarCountdown {
  const IftarCountdown.untilIftar(Duration this.remaining)
    : phase = FastPhase.untilIftar,
      fajr = null;

  const IftarCountdown.untilSuhoorEnd(DateTime this.fajr)
    : phase = FastPhase.untilSuhoorEnd,
      remaining = null;

  final FastPhase phase;

  /// Time left until Maghrib (iftar phase).
  final Duration? remaining;

  /// Fajr that ends suhoor (suhoor phase).
  final DateTime? fajr;
}

/// Between today's Fajr and Maghrib: time to iftar. From Maghrib until the
/// next Fajr (including the small hours before today's Fajr): the Fajr time
/// suhoor runs until. Null when the times are unknown, and after Maghrib on
/// the last day of Ramadan ([lastRamadanDay]): the next day is Eid, no suhoor.
IftarCountdown? iftarCountdownAt(
  DateTime now, {
  required DateTime? fajrToday,
  required DateTime? maghribToday,
  required DateTime? fajrTomorrow,
  bool lastRamadanDay = false,
}) {
  if (fajrToday == null || maghribToday == null) return null;
  if (now.isBefore(fajrToday)) return IftarCountdown.untilSuhoorEnd(fajrToday);
  if (now.isBefore(maghribToday)) {
    return IftarCountdown.untilIftar(maghribToday.difference(now));
  }
  if (lastRamadanDay || fajrTomorrow == null) return null;
  return IftarCountdown.untilSuhoorEnd(fajrTomorrow);
}
