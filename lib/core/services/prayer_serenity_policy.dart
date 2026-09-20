/// Pure rules for "وضع سكينة الصلاة" (Prayer Serenity Mode).
///
/// When the app is open and a prayer time arrives, Talia pauses any playing
/// recitation for a short serenity window — a quiet courtesy at the time of
/// the meeting, never a punishment. This class contains no I/O so it stays
/// trivially testable; [PrayerSerenityWatcher] owns the scheduling.
class PrayerSerenityPolicy {
  const PrayerSerenityPolicy({
    this.serenityDuration = const Duration(minutes: 10),
  });

  /// How long after the adhan the serenity window stays open.
  final Duration serenityDuration;

  /// Returns a stable occurrence key (e.g. `dhuhr-20250919`) when [now] falls
  /// inside an open serenity window, or null otherwise.
  ///
  /// [prayerTimes] maps canonical prayer names to their absolute times; null
  /// values (unknown times) are skipped. Comparison uses absolute instants,
  /// so city time-zones are handled correctly by the epoch math.
  String? activeOccurrenceKey({
    required Map<String, DateTime> prayerTimes,
    required DateTime now,
  }) {
    for (final entry in prayerTimes.entries) {
      final start = entry.value;
      final end = start.add(serenityDuration);
      if (!now.isBefore(start) && now.isBefore(end)) {
        final day = DateTime.utc(start.year, start.month, start.day);
        final stamp =
            '${day.year.toString().padLeft(4, '0')}'
            '${day.month.toString().padLeft(2, '0')}'
            '${day.day.toString().padLeft(2, '0')}';
        return '${entry.key}-$stamp';
      }
    }
    return null;
  }
}
