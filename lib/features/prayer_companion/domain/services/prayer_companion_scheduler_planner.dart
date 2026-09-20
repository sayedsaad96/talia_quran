import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../data/datasources/prayer_companion_preferences.dart';
import '../entities/prayer_companion.dart';
import '../repositories/prayer_companion_repository.dart';

/// A single Companion notification request produced by the planner.
class ScheduledPrayerCompanionNotification extends Equatable {
  const ScheduledPrayerCompanionNotification({
    required this.id,
    required this.kind,
    required this.occurrence,
    required this.scheduledAt,
  });

  final int id;
  final PrayerCompanionNotificationKind kind;
  final PrayerOccurrence occurrence;
  final DateTime scheduledAt;

  @override
  List<Object?> get props => [id, kind, occurrence, scheduledAt];
}

/// Builds the deterministic two-day Companion notification schedule.
///
/// Notification IDs never collide with the legacy prayer-time range
/// (2000–2039):
///
/// - Planned events: `2100 + dayOffset * 10 + prayerIndex * 2 + eventIndex`
///   where eventIndex is 0 for preparation and 1 for check-in.
/// - Follow-ups: `2120 + dayOffset * 5 + prayerIndex` for the two rolling
///   days (2120–2129).
/// - Spillover follow-ups: `2120 + 10 + prayerIndex` (2130–2134) re-plans
///   yesterday's still-pending follow-up that fires just past midnight.
///
/// prayerIndex follows [PrayerKey] declaration order (fajr=0 … isha=4).
///
/// The planner is pure time arithmetic: quiet-hours suppression happens at
/// the scheduler layer, never here. It reads records but never writes them.
class PrayerCompanionPlanner {
  const PrayerCompanionPlanner({
    required PrayerTimesService prayerTimesService,
    required PrayerCompanionPreferences preferences,
    required PrayerCompanionRepository repository,
    required Future<SharedPreferences> prefs,
    RecordOwnerProvider owner = const SupabaseRecordOwnerProvider(),
  }) : _prayerTimesService = prayerTimesService,
       _preferences = preferences,
       _repository = repository,
       _prefs = prefs,
       _owner = owner;

  /// Check-in fires a fixed 20 minutes after the prayer.
  static const Duration checkInDelay = Duration(minutes: 20);

  static const int plannedBaseId = 2100;
  static const int followUpBaseId = 2120;

  /// Existing per-prayer notification filters; the Companion follows these
  /// but not the prayer-alert master switch.
  static const Map<PrayerKey, String> prayerFilterKeys = {
    PrayerKey.fajr: TaliaNotificationService.prayerFajrKey,
    PrayerKey.dhuhr: TaliaNotificationService.prayerDhuhrKey,
    PrayerKey.asr: TaliaNotificationService.prayerAsrKey,
    PrayerKey.maghrib: TaliaNotificationService.prayerMaghribKey,
    PrayerKey.isha: TaliaNotificationService.prayerIshaKey,
  };

  final PrayerTimesService _prayerTimesService;
  final PrayerCompanionPreferences _preferences;
  final PrayerCompanionRepository _repository;
  final Future<SharedPreferences> _prefs;
  final RecordOwnerProvider _owner;

  Future<List<ScheduledPrayerCompanionNotification>> plan({
    required DateTime now,
  }) async {
    final settings = _preferences.read();
    if (!settings.enabled) return const [];

    final prefs = await _prefs;
    final ownerId = _owner.currentOwnerId;
    final today = DateTime(now.year, now.month, now.day);
    final windowEnd = today.add(const Duration(days: 2));

    final events = <ScheduledPrayerCompanionNotification>[];
    for (var dayOffset = 0; dayOffset < 2; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final times = await _prayerTimesService.timesForDate(date);
      // Sunrise is deliberately excluded: only the five obligatory prayers
      // are planned (non-matching keys are dropped by _prayerKeyFor).
      final timesByKey = <PrayerKey, DateTime>{
        for (final entry in times) ?_prayerKeyFor(entry.key): entry.time,
      };
      final records = await _repository.readDay(
        ownerId: ownerId,
        localDate: date,
      );

      // A follow-up requested late in the evening (e.g. isha at 23:55) can
      // fire a few minutes past midnight. A replan after 00:00 no longer sees
      // yesterday's records and the cancel-first reschedule would silently
      // drop that pending follow-up, so yesterday's still-pending follow-ups
      // are re-planned here under the dedicated spillover ID range
      // (2130–2134) with their original occurrence identity.
      if (dayOffset == 0) {
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayRecords = await _repository.readDay(
          ownerId: ownerId,
          localDate: yesterday,
        );
        final todayFajr = timesByKey[PrayerKey.fajr];
        for (final prayerKey in PrayerKey.values) {
          if (!(prefs.getBool(prayerFilterKeys[prayerKey]!) ?? true)) continue;
          if (!settings.followUpEnabled) continue;
          final record = yesterdayRecords[prayerKey];
          final followUpAt = record?.followUpAt;
          if (record == null ||
              record.status == PrayerCompanionStatus.confirmed ||
              followUpAt == null ||
              !followUpAt.isAfter(now)) {
            continue;
          }
          // The spillover window is bounded: a follow-up is scheduled at
          // most 15 minutes after its command, so any still-future spillover
          // must land before today's fajr (the next obligatory prayer after
          // yesterday's isha). Anything later belongs to an expired window.
          if (todayFajr != null && !followUpAt.isBefore(todayFajr)) continue;
          if (followUpAt.isAfter(windowEnd)) continue;
          events.add(
            ScheduledPrayerCompanionNotification(
              id: followUpBaseId + 2 * 5 + prayerKey.index,
              kind: PrayerCompanionNotificationKind.followUp,
              occurrence: PrayerOccurrence(
                ownerId: ownerId,
                localDate: yesterday,
                prayerKey: prayerKey,
                scheduledAt: followUpAt,
              ),
              scheduledAt: followUpAt,
            ),
          );
        }
      }

      for (final prayerKey in PrayerKey.values) {
        if (!(prefs.getBool(prayerFilterKeys[prayerKey]!) ?? true)) continue;
        final time = timesByKey[prayerKey];
        if (time == null) continue;
        final record = records[prayerKey];
        if (record?.status == PrayerCompanionStatus.confirmed) continue;

        final occurrence = PrayerOccurrence(
          ownerId: ownerId,
          localDate: date,
          prayerKey: prayerKey,
          scheduledAt: time,
        );
        final prayerIndex = prayerKey.index;
        final base = plannedBaseId + dayOffset * 10 + prayerIndex * 2;

        if (settings.preparationMinutes > 0) {
          final at = time.subtract(
            Duration(minutes: settings.preparationMinutes),
          );
          if (at.isAfter(now)) {
            events.add(
              ScheduledPrayerCompanionNotification(
                id: base,
                kind: PrayerCompanionNotificationKind.preparation,
                occurrence: occurrence,
                scheduledAt: at,
              ),
            );
          }
        }
        if (settings.checkInEnabled) {
          final at = time.add(checkInDelay);
          if (at.isAfter(now)) {
            events.add(
              ScheduledPrayerCompanionNotification(
                id: base + 1,
                kind: PrayerCompanionNotificationKind.checkIn,
                occurrence: occurrence,
                scheduledAt: at,
              ),
            );
          }
        }

        final followUpAt = record?.followUpAt;
        if (settings.followUpEnabled && followUpAt != null) {
          final next = _nextPrayerTime(timesByKey, prayerKey);
          final beforeNext = next == null || followUpAt.isBefore(next);
          if (followUpAt.isAfter(now) &&
              followUpAt.isBefore(windowEnd) &&
              beforeNext) {
            events.add(
              ScheduledPrayerCompanionNotification(
                id: followUpBaseId + dayOffset * 5 + prayerIndex,
                kind: PrayerCompanionNotificationKind.followUp,
                occurrence: occurrence,
                scheduledAt: followUpAt,
              ),
            );
          }
        }
      }
    }
    events.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return events;
  }

  static PrayerKey? _prayerKeyFor(String key) {
    for (final prayerKey in PrayerKey.values) {
      if (prayerKey.name == key) return prayerKey;
    }
    return null;
  }

  static DateTime? _nextPrayerTime(
    Map<PrayerKey, DateTime> timesByKey,
    PrayerKey prayerKey,
  ) {
    for (var i = prayerKey.index + 1; i < PrayerKey.values.length; i++) {
      final time = timesByKey[PrayerKey.values[i]];
      if (time != null) return time;
    }
    return null;
  }
}
