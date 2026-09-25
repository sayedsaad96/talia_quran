import 'package:flutter/services.dart';

import '../utils/talia_logger.dart';
import 'prayer_delivery_scheduler.dart';
import 'prayer_scheduled_event.dart';

/// MethodChannel contract shared with `PrayerAlarmContract.kt` (Stage 4).
/// Keep both sides in sync — the Kotlin side must mirror these constants.
abstract final class PrayerDeliveryContract {
  static const String channelName = 'talia/prayer_delivery';

  static const String methodScheduleEvents = 'scheduleEvents';
  static const String methodCancelAll = 'cancelAll';
  static const String methodCancelEvent = 'cancelEvent';
  static const String methodCanScheduleExact = 'canScheduleExact';
}

/// Android V2 delivery implementation: sends planned prayer events to the
/// native `PrayerAlarmScheduler` (AlarmManager) over
/// [PrayerDeliveryContract.channelName].
///
/// Failure policy (migration rule §22): any platform error results in a
/// non-success [PrayerDeliveryResult] — never an exception — so the caller
/// can stay on the legacy FLN path.
class AndroidPrayerDeliveryScheduler implements PrayerDeliveryScheduler {
  AndroidPrayerDeliveryScheduler({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel(PrayerDeliveryContract.channelName);

  final MethodChannel _channel;

  @override
  Future<PrayerDeliveryResult> schedulePrayerEvents(
    List<PrayerScheduledEvent> events,
  ) async {
    if (events.isEmpty) {
      return const PrayerDeliveryResult(
        success: true,
        scheduledCount: 0,
      );
    }
    final result = await _invoke(
      PrayerDeliveryContract.methodScheduleEvents,
      <String, Object>{
        'events': events.map((event) => event.toMap()).toList(growable: false),
      },
    );
    if (result == null) {
      return const PrayerDeliveryResult(
        success: false,
        scheduledCount: 0,
        error: 'native scheduleEvents returned null',
      );
    }
    final success = result['success'] == true;
    final count = (result['scheduledCount'] as num?)?.toInt() ?? 0;
    final exact = result['exactAllowed'] == true;
    if (!success) {
      return PrayerDeliveryResult(
        success: false,
        scheduledCount: 0,
        exactSchedulingAllowed: exact,
        error: (result['error'] as String?) ?? 'native scheduling failed',
      );
    }
    return PrayerDeliveryResult(
      success: true,
      scheduledCount: count,
      exactSchedulingAllowed: exact,
    );
  }

  @override
  Future<void> cancelPrayerEvents() async {
    await _invoke(PrayerDeliveryContract.methodCancelAll);
  }

  @override
  Future<void> cancelPrayerEvent(PrayerScheduledEvent event) async {
    await _invoke(
      PrayerDeliveryContract.methodCancelEvent,
      <String, Object>{'event': event.toMap()},
    );
  }

  @override
  Future<bool> canScheduleExact() async {
    final result =
        await _invoke(PrayerDeliveryContract.methodCanScheduleExact);
    return result?['canScheduleExact'] == true;
  }

  /// Invokes a method, mapping any platform error to a logged `null` so
  /// callers observe failure through the return value instead of crashes.
  Future<Map<Object?, Object?>?> _invoke(
    String method, [
    Map<String, Object>? arguments,
  ]) async {
    try {
      final result = await _channel.invokeMethod<Object?>(
        method,
        arguments,
      );
      return result is Map<Object?, Object?> ? result : null;
    } on PlatformException catch (error, stack) {
      TaliaLogger.w(
        '[PrayerV2] delivery call failed: $method '
        'code=${error.code} message=${error.message}',
        error,
        stack,
      );
      return null;
    } on MissingPluginException catch (error, stack) {
      // V2 delivery registered before native side is present (e.g. tests
      // or a partially-upgraded build) — treat as unavailable, not fatal.
      TaliaLogger.w(
        '[PrayerV2] delivery unavailable for $method (no native handler)',
        error,
        stack,
      );
      return null;
    }
  }
}