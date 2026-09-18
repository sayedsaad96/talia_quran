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
/// - Follow-ups: `2120 + dayOffset * 5 + prayerIndex`.
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
      final timesByKey = <PrayerKey, DateTime>{
        for (final entry in times) ?_prayerKeyFor(entry.key): entry.time,
      };
      final records = await _repository.readDay(
        ownerId: ownerId,
        localDate: date,
      );

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
