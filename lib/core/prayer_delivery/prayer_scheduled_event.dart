import 'package:equatable/equatable.dart';

/// Deterministic alarm-identity namespace for native Android prayer delivery.
///
/// Frozen notification/alarm ID namespaces in Talia:
///   2000–2039  legacy FLN prayer reminders (V1)
///   2100–2134  prayer companion reminders
///   2200–2499  native Android prayer delivery alarms (V2) ← this file
///
/// One alarm request code per prayer occurrence, derived purely from
/// (date, prayerKey) so schedule/cancel/reschedule are reliable and
/// duplicates are impossible for the same occurrence.
abstract final class PrayerAlarmIdentity {
  /// First request code of the V2 native prayer range (inclusive).
  static const int rangeStart = 2200;

  /// Last request code of the V2 native prayer range (inclusive).
  static const int rangeEnd = 2499;

  /// Number of distinct epoch-day buckets in the rotation.
  static const int dayBuckets = 60;

  /// Canonical prayer-key order used to derive the per-day slot.
  static const List<String> prayerOrder = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  /// Stable request code for a prayer occurrence on [date] (any timezone —
  /// only the calendar day matters). Unknown prayer keys fall back to a
  /// stable hash slot so scheduling never throws.
  static int requestCodeFor(DateTime date, String prayerKey) {
    final epochDay =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay;
    final daySlot = epochDay % dayBuckets;
    final prayerSlot = _prayerSlot(prayerKey);
    return rangeStart + daySlot * prayerOrder.length + prayerSlot;
  }

  static int _prayerSlot(String prayerKey) {
    final index = prayerOrder.indexOf(prayerKey);
    if (index >= 0) return index;
    // Unknown key: stable non-negative slot that never throws.
    return prayerKey.hashCode.abs() % prayerOrder.length;
  }
}

/// Pure data model that carries one planned prayer occurrence from the
/// existing planning layer (PrayerTimesService + NotificationScheduler)
/// to the delivery layer.
///
/// V2 contract:
///   - Contains NO business logic and computes NO prayer times.
///   - Native Android executes it; Flutter owns all calculation.
class PrayerScheduledEvent extends Equatable {
  const PrayerScheduledEvent({
    required this.eventId,
    required this.prayerKey,
    required this.scheduledAtUtc,
    required this.localPrayerTime,
    required this.timezoneId,
    required this.notificationEnabled,
    required this.adhanEnabled,
    this.soundProfile = 'default',
    this.payload = const <String, String>{},
  });

  /// Deterministic identity: `<yyyy-MM-dd>_<prayerKey>` in the prayer's
  /// city-local calendar day. Two refreshes planning the same occurrence
  /// must produce the same [eventId].
  final String eventId;

  /// One of [PrayerAlarmIdentity.prayerOrder] (`fajr` … `isha`).
  final String prayerKey;

  /// UTC instant of the prayer (derived from the city IANA timezone).
  final DateTime scheduledAtUtc;

  /// City-local wall-clock time as `HH:mm` (display only — native never
  /// recomputes times from this).
  final String localPrayerTime;

  /// IANA timezone id of the city the times were calculated for.
  final String timezoneId;

  /// Whether the "prayer time has come" notification should be posted.
  final bool notificationEnabled;

  /// Whether the full Adhan playback service should start (Android V2).
  /// When false the receiver posts the notification and exits.
  final bool adhanEnabled;

  /// Sound-profile resolver output. V2-first ships `default` only; the
  /// field keeps the architecture ready for muezzin profiles later.
  final String soundProfile;

  /// Opaque extra data forwarded to the receiver. Values must be
  /// JSON-primitive-safe (String for V2-first).
  final Map<String, String> payload;

  /// Builds a canonical event id for a city-local calendar day + prayer.
  static String buildEventId(DateTime cityLocalDate, String prayerKey) {
    final mm = cityLocalDate.month.toString().padLeft(2, '0');
    final dd = cityLocalDate.day.toString().padLeft(2, '0');
    return '${cityLocalDate.year}-$mm-$dd' '_$prayerKey';
  }

  /// MethodChannel-safe encoding. All values are JSON primitives.
  Map<String, Object> toMap() => <String, Object>{
        'eventId': eventId,
        'prayerKey': prayerKey,
        'scheduledAtUtc': scheduledAtUtc.toUtc().toIso8601String(),
        'localPrayerTime': localPrayerTime,
        'timezoneId': timezoneId,
        'notificationEnabled': notificationEnabled,
        'adhanEnabled': adhanEnabled,
        'soundProfile': soundProfile,
        'payload': payload,
      };

  /// Inverse of [toMap]. Tolerates a locally-stored [scheduledAtUtc]
  /// (no `Z` suffix) by re-interpreting it as UTC.
  static PrayerScheduledEvent fromMap(Map<Object?, Object?> map) {
    final rawScheduledAt = map['scheduledAtUtc'] as String;
    final scheduledAtUtc = rawScheduledAt.endsWith('Z')
        ? DateTime.parse(rawScheduledAt)
        : DateTime.parse('${rawScheduledAt}Z');
    return PrayerScheduledEvent(
      eventId: map['eventId'] as String,
      prayerKey: map['prayerKey'] as String,
      scheduledAtUtc: scheduledAtUtc,
      localPrayerTime: map['localPrayerTime'] as String,
      timezoneId: map['timezoneId'] as String,
      notificationEnabled: (map['notificationEnabled'] as bool?) ?? true,
      adhanEnabled: (map['adhanEnabled'] as bool?) ?? false,
      soundProfile: (map['soundProfile'] as String?) ?? 'default',
      payload: ((map['payload'] as Map<Object?, Object?>?) ?? const {})
          .cast<String, String>(),
    );
  }

  /// Deterministic native alarm request code for this occurrence
  /// (see [PrayerAlarmIdentity] for the frozen namespace contract).
  int get alarmRequestCode =>
      PrayerAlarmIdentity.requestCodeFor(scheduledAtUtc, prayerKey);

  @override
  List<Object?> get props => <Object?>[
        eventId,
        prayerKey,
        scheduledAtUtc,
        localPrayerTime,
        timezoneId,
        notificationEnabled,
        adhanEnabled,
        soundProfile,
        payload,
      ];
}