enum AzkarPeriod { morning, evening }

/// Granular time buckets derived from the coarse [AzkarPeriod].
enum AzkarDayPart { afterFajr, morning, forenoon, afternoon, evening, night }

abstract class AzkarTimeContext {
  static AzkarPeriod resolvePeriod([DateTime? now]) {
    final time = now ?? DateTime.now();
    final hour = time.hour;
    if (hour >= 4 && (hour < 15 || (hour == 15 && time.minute < 30))) {
      return AzkarPeriod.morning;
    }
    return AzkarPeriod.evening;
  }

  /// Classifies the day into finer buckets for smart-wird composition.
  /// Boundaries are heuristics for product ordering, never religious rulings.
  static AzkarDayPart resolveDayPart([DateTime? now]) {
    final time = now ?? DateTime.now();
    final hour = time.hour;
    if (hour < 4) return AzkarDayPart.night;
    if (hour < 10) return AzkarDayPart.afterFajr;
    if (hour < 12) return AzkarDayPart.morning;
    if (hour < 15) return AzkarDayPart.forenoon;
    if (hour < 19) return AzkarDayPart.afternoon;
    if (hour < 21) return AzkarDayPart.evening;
    return AzkarDayPart.night;
  }

  /// Stable wire/enum name for persistence.
  static String nameOfDayPart(AzkarDayPart part) => part.name;

  /// Parses a persisted day-part name; unknown values fall back by hour.
  static AzkarDayPart dayPartFromName(String name, [DateTime? now]) {
    for (final part in AzkarDayPart.values) {
      if (part.name == name) return part;
    }
    return resolveDayPart(now);
  }
}
