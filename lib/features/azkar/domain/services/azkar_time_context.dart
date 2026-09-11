enum AzkarPeriod { morning, evening }

abstract class AzkarTimeContext {
  static AzkarPeriod resolvePeriod([DateTime? now]) {
    final time = now ?? DateTime.now();
    final hour = time.hour;
    if (hour >= 4 && (hour < 15 || (hour == 15 && time.minute < 30))) {
      return AzkarPeriod.morning;
    }
    return AzkarPeriod.evening;
  }
}
