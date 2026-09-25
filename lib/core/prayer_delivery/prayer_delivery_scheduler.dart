import 'prayer_scheduled_event.dart';

/// Result of a scheduling round-trip with the delivery layer.
class PrayerDeliveryResult {
  const PrayerDeliveryResult({
    required this.success,
    required this.scheduledCount,
    this.exactSchedulingAllowed = false,
    this.error,
  });

  /// True when the delivery layer confirmed every event was accepted.
  final bool success;

  /// Number of occurrences the platform layer accepted.
  final int scheduledCount;

  /// Whether the platform granted exact-alarm scheduling for this batch.
  final bool exactSchedulingAllowed;

  /// Failure reason when [success] is false.
  final String? error;
}

/// Delivery-layer abstraction for prayer events (Prayer V2, Stage 3).
///
/// Contract:
///   - Transports already-planned [PrayerScheduledEvent]s to the platform.
///   - NEVER computes prayer times, NEVER knows the city, method,
///     Prayer Companion, or any other Talia feature.
///   - Cancel-first semantics: callers refresh via
///     [cancelPrayerEvents] → [schedulePrayerEvents]; [reschedulePrayerEvents]
///     is the same round-trip as one atomic convenience call.
///
/// Implementations:
///   - [AndroidPrayerDeliveryScheduler] — MethodChannel → AlarmManager (V2).
abstract interface class PrayerDeliveryScheduler {
  /// Cancels every native prayer alarm, then schedules [events].
  /// Returns a [PrayerDeliveryResult]; on failure the caller MUST keep the
  /// legacy (V1) delivery path as the active owner (migration rule §22).
  Future<PrayerDeliveryResult> schedulePrayerEvents(
    List<PrayerScheduledEvent> events,
  );

  /// Cancels every native prayer alarm owned by the delivery layer.
  Future<void> cancelPrayerEvents();

  /// Cancels a single occurrence (used by targeted settings changes).
  Future<void> cancelPrayerEvent(PrayerScheduledEvent event);

  /// Whether the platform currently permits exact alarms. When false the
  /// delivery layer falls back to inexact alarms — prayer notifications
  /// must never break because exact permission is denied (§11/§26).
  Future<bool> canScheduleExact();
}