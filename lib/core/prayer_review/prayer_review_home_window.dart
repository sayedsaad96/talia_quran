import '../../features/prayer_companion/domain/entities/prayer_companion.dart';

PrayerOccurrence? prayerReviewHomeOccurrence({
  required String ownerId,
  required Map<PrayerKey, DateTime> times,
  required DateTime now,
  required bool preparationNotificationsEnabled,
  required int preparationMinutes,
}) {
  if (preparationNotificationsEnabled ||
      ownerId.isEmpty ||
      times.length != PrayerKey.values.length ||
      !{0, 5, 10, 15}.contains(preparationMinutes)) {
    return null;
  }
  // With no preparation notification configured, use a 15-minute Home window.
  // This changes no prayer or notification time.
  final minutes = preparationMinutes == 0 ? 15 : preparationMinutes;
  final ordered = times.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  for (final entry in ordered) {
    final time = entry.value;
    if (!now.isBefore(time) ||
        now.isBefore(time.subtract(Duration(minutes: minutes)))) {
      continue;
    }
    final local = time.toLocal();
    return PrayerOccurrence(
      ownerId: ownerId,
      localDate: DateTime(local.year, local.month, local.day),
      prayerKey: entry.key,
      scheduledAt: time,
    );
  }
  return null;
}
