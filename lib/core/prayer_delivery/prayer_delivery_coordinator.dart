import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/talia_logger.dart';
import 'prayer_delivery_scheduler.dart';
import 'prayer_delivery_version.dart';
import 'prayer_scheduled_event.dart';

/// Decides who owns prayer delivery for the current refresh (V1 legacy FLN
/// vs V2 native Android) and runs the one-way migration and the rollback
/// path (V2 §21, §22, §23, §40).
///
/// Golden rule (§3): exactly one owner per refresh. When this coordinator
/// returns true from [refreshNativeDelivery], the legacy FLN block MUST NOT
/// also run.
class PrayerDeliveryCoordinator {
  PrayerDeliveryCoordinator(
    this._scheduler, {
    bool Function()? isAndroid,
  }) : _isAndroid = isAndroid?.call() ?? Platform.isAndroid;

  final PrayerDeliveryScheduler _scheduler;
  final bool _isAndroid;

  /// Whether this device can ever use the native V2 path.
  bool get isAndroid => _isAndroid;

  /// Whether native V2 currently owns delivery per persisted state.
  bool isNativeOwner(SharedPreferences prefs) =>
      _isAndroid &&
      PrayerDeliveryVersion.read(prefs) == PrayerDeliveryVersion.nativeAndroidV2;

  /// Cancels every native prayer alarm (used when prayer notifications are
  /// disabled while V2 is the owner).
  Future<void> cancelNative() => _scheduler.cancelPrayerEvents();

  /// Runs the prayer delivery round natively.
  ///
  /// - First refresh after update (version 1): executes the §22 migration —
  ///   cancel legacy → cancel native defensively → schedule native → verify
  ///   → persist version 2 ONLY on success; on failure the legacy schedule
  ///   is rebuilt in the same refresh and version stays 1.
  /// - Version 2: §23 cancel-first rebuild via the native scheduler; on
  ///   failure executes the §40 rollback (cancel native → version 1 →
  ///   rebuild legacy).
  /// - Empty [events] while V2 is owner: cancels native alarms (all prayers
  ///   filtered off) and reports handled. Empty events on V1: reports
  ///   not-handled so the legacy path cancels legacy ids as before.
  ///
  /// Returns true when prayer delivery was fully handled for this refresh
  /// (the legacy block must not run); false when the legacy path should run.
  Future<bool> refreshNativeDelivery({
    required SharedPreferences prefs,
    required List<PrayerScheduledEvent> events,
    required Future<void> Function() cancelLegacyReminders,
    required Future<void> Function() rebuildLegacyReminders,
  }) async {
    if (!_isAndroid) return false;
    final nativeOwner =
        PrayerDeliveryVersion.read(prefs) == PrayerDeliveryVersion.nativeAndroidV2;

    if (events.isEmpty) {
      if (nativeOwner) {
        await _scheduler.cancelPrayerEvents();
        return true;
      }
      return false;
    }

    if (nativeOwner) {
      final result = await _scheduler.schedulePrayerEvents(events);
      if (result.success) {
        return true;
      }
      TaliaLogger.w(
        '[PrayerV2] native refresh failed (${result.error}); '
        'rolling back to legacy delivery',
      );
      await _scheduler.cancelPrayerEvents();
      await PrayerDeliveryVersion.save(prefs, PrayerDeliveryVersion.legacy);
      await rebuildLegacyReminders();
      return true;
    }

    // §22 V1 → V2 migration.
    await cancelLegacyReminders();
    await _scheduler.cancelPrayerEvents(); // §22 step 2 (defensive)
    final result = await _scheduler.schedulePrayerEvents(events);
    if (!result.success) {
      TaliaLogger.w(
        '[PrayerV2] migration scheduling failed (${result.error}); '
        'staying on legacy delivery',
      );
      await rebuildLegacyReminders(); // restore what step 1 cancelled
      return true;
    }
    // §22 step 6: persist only after verified success.
    await PrayerDeliveryVersion.save(prefs, PrayerDeliveryVersion.nativeAndroidV2);
    TaliaLogger.i(
      '[PrayerV2] migration complete: native delivery owns prayer alarms',
    );
    return true;
  }
}