enum KidsWorldPhase { day, night }

const int kKidsWorldFallbackDayStartHour = 6;
const int kKidsWorldFallbackNightStartHour = 18;

/// Determines the kids world phase at a given moment.
///
/// **Phase rules:**
/// - **Day**: `fajr <= now < maghrib`
/// - **Night**: all other times
///
/// If neither `fajr` nor `maghrib` are provided, or if only one is provided,
/// uses the fallback times:
/// - **Day**: `06:00 <= local time < 18:00`
/// - **Night**: all other times
KidsWorldPhase kidsWorldPhaseAt(
  DateTime now, {
  DateTime? fajr,
  DateTime? maghrib,
}) {
  // If either prayer time is missing, use fallback
  if (fajr == null || maghrib == null) {
    return _kidsWorldPhaseAtFallback(now);
  }

  // Check if now is within day period: fajr <= now < maghrib
  if (!now.isBefore(fajr) && now.isBefore(maghrib)) {
    return KidsWorldPhase.day;
  }

  return KidsWorldPhase.night;
}

/// Returns the next instant when the phase flips (strictly after [now]).
///
/// With prayer times:
/// - From day (fajr <= now < maghrib): returns today's maghrib
/// - From night after maghrib: returns tomorrow's fajr
/// - From night before fajr: returns today's fajr
///
/// Without prayer times (or if only one is provided), uses fallback times.
DateTime kidsWorldNextBoundary(
  DateTime now, {
  DateTime? fajr,
  DateTime? maghrib,
}) {
  // If either prayer time is missing, use fallback
  if (fajr == null || maghrib == null) {
    return _kidsWorldNextBoundaryFallback(now);
  }

  final currentPhase = kidsWorldPhaseAt(now, fajr: fajr, maghrib: maghrib);

  if (currentPhase == KidsWorldPhase.day) {
    // In day phase, next boundary is maghrib
    return maghrib;
  } else {
    // In night phase, check if we're before or after maghrib
    if (now.isBefore(fajr)) {
      // Before fajr, next boundary is today's fajr
      return fajr;
    } else {
      // After maghrib, next boundary is tomorrow's fajr
      return fajr.add(const Duration(days: 1));
    }
  }
}

/// Fallback phase calculation using fixed hours (06:00 and 18:00).
KidsWorldPhase _kidsWorldPhaseAtFallback(DateTime now) {
  final hour = now.hour;

  if (hour >= kKidsWorldFallbackDayStartHour &&
      hour < kKidsWorldFallbackNightStartHour) {
    return KidsWorldPhase.day;
  }

  return KidsWorldPhase.night;
}

/// Fallback next boundary calculation using fixed hours.
DateTime _kidsWorldNextBoundaryFallback(DateTime now) {
  final hour = now.hour;

  if (hour >= kKidsWorldFallbackDayStartHour &&
      hour < kKidsWorldFallbackNightStartHour) {
    // In day phase, next boundary is 18:00 today
    return DateTime(
      now.year,
      now.month,
      now.day,
      kKidsWorldFallbackNightStartHour,
    );
  } else {
    // Night phase: after midnight (hour < 6) the boundary is today's 06:00;
    // from 18:00 onwards it is next wall-clock day's 06:00. Built from
    // calendar fields (day + 1 normalises) so DST 23/25h days cannot skew it.
    final dayOffset = hour < kKidsWorldFallbackDayStartHour ? 0 : 1;
    return DateTime(
      now.year,
      now.month,
      now.day + dayOffset,
      kKidsWorldFallbackDayStartHour,
    );
  }
}
