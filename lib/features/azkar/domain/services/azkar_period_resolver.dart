import 'azkar_time_context.dart';

/// Fajr and Asr for one day, used to decide whether it is the morning or the
/// evening azkar period. Boundaries are product ordering, never a ruling.
class AzkarPrayerWindow {
  const AzkarPrayerWindow({required this.fajr, required this.asr});

  final DateTime fajr;
  final DateTime asr;

  bool get isConsistent => fajr.isBefore(asr);

  /// A window is only trusted near the day it was computed for: from six hours
  /// before its Fajr (the tail of the previous evening) up to 24 hours after.
  bool appliesTo(DateTime now) =>
      isConsistent &&
      !now.isBefore(fajr.subtract(const Duration(hours: 6))) &&
      now.isBefore(fajr.add(const Duration(hours: 24)));
}

/// Supplies today's prayer window, or null when prayer times are unavailable.
abstract interface class AzkarPrayerWindowSource {
  Future<AzkarPrayerWindow?> load(DateTime now);
}

/// The single rule that says whether it is morning or evening for azkar.
abstract class AzkarPeriodResolver {
  /// Morning is `[Fajr, Asr)` when a usable [window] exists, evening is the
  /// rest. Otherwise the fixed 04:00–15:30 rule applies.
  static AzkarPeriod resolve(DateTime now, {AzkarPrayerWindow? window}) {
    if (window != null && window.appliesTo(now)) {
      final inMorning = !now.isBefore(window.fajr) && now.isBefore(window.asr);
      return inMorning ? AzkarPeriod.morning : AzkarPeriod.evening;
    }
    return AzkarTimeContext.resolvePeriod(now);
  }

  /// Like [resolve], loading the window from [source]. Never throws: any
  /// failure falls back to the fixed rule.
  static Future<AzkarPeriod> resolveWith(
    DateTime now,
    AzkarPrayerWindowSource? source,
  ) async {
    AzkarPrayerWindow? window;
    if (source != null) {
      try {
        window = await source.load(now);
      } catch (_) {
        window = null;
      }
    }
    return resolve(now, window: window);
  }
}
