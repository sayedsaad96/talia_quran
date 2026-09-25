import '../services/prayer_times_service.dart';
import '../services/prayer_sound.dart';
import 'prayer_scheduled_event.dart';

/// Converts planned prayer times from [PrayerTimesService] — the only
/// source of truth (V2 §4) — into transport events for the delivery layer.
///
/// Computes NOTHING itself: it reads the times the service calculated for
/// the active city/method and wraps them. Mirrors the legacy rolling-window
/// semantics (7 days, per-prayer filters, past occurrences skipped).
class PrayerEventBuilder {
  const PrayerEventBuilder._();

  /// Builds the events for the next [days] days.
  ///
  /// [prayerFilter] maps canonical prayer keys to enabled/disabled,
  /// [adhanEnabled] controls the adhan playback flag on every event,
  /// [muezzinId]/[fajrMuezzinId] select the bundled adhan recording
  /// (see `MuezzinCatalog`); they only affect WHICH clip plays, never WHEN
  /// the alarms fire.
  static Future<List<PrayerScheduledEvent>> build({
    required PrayerTimesService prayerService,
    required DateTime now,
    required Map<String, bool> prayerFilter,
    required bool adhanEnabled,
    String muezzinId = MuezzinCatalog.defaultId,
    String fajrMuezzinId = '',
    int days = 7,
  }) async {
    // Resolve the city exactly like PrayerTimesService does (selected id,
    // first-city fallback) so [timezoneId] always matches the calculation
    // zone and never the device zone.
    final all = await prayerService.cities();
    PrayerCity? city;
    if (all.isNotEmpty) {
      final id = prayerService.selectedCityId;
      for (final candidate in all) {
        if (candidate.id == id) {
          city = candidate;
          break;
        }
      }
      city ??= all.first;
    }
    final timezoneId = city?.timeZone ?? 'UTC';

    final events = <PrayerScheduledEvent>[];
    for (var day = 0; day < days; day++) {
      final targetDate = now.add(Duration(days: day));
      final prayers = await prayerService.timesForDate(targetDate);
      for (final prayer in prayers) {
        if (prayerFilter[prayer.key] != true) continue;
        if (prayer.time.isBefore(now)) continue;
        final time = prayer.time; // already city-local (TZDateTime)
        events.add(
          PrayerScheduledEvent(
            eventId: PrayerScheduledEvent.buildEventId(time, prayer.key),
            prayerKey: prayer.key,
            scheduledAtUtc: time.toUtc(),
            localPrayerTime:
                '${time.hour.toString().padLeft(2, '0')}:'
                '${time.minute.toString().padLeft(2, '0')}',
            timezoneId: timezoneId,
            notificationEnabled: true,
            adhanEnabled: adhanEnabled,
            soundProfile: soundProfileForPrayer(
              prayerKey: prayer.key,
              muezzinId: muezzinId,
              fajrMuezzinId: fajrMuezzinId,
            ),
          ),
        );
      }
    }
    return events;
  }
}