import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/talia_logger.dart';
import 'prayer_serenity_policy.dart';

/// Provides the canonical prayer times for today (fajr, dhuhr, asr, maghrib,
/// isha). Returns null when prayer times are unavailable (no city selected,
/// disabled service, offline failure) — the watcher simply stays quiet.
typedef PrayerSerenityTimesProvider =
    Future<Map<String, DateTime>?> Function();

/// Pauses any playing recitation. Must be best-effort and silent on failure.
typedef PrayerSerenityPauseCallback = Future<void> Function();

/// Surfaces the gentle "حان وقت اللقاء" moment (local notification).
typedef PrayerSerenityMomentCallback = Future<void> Function();

/// Watches prayer times while the app is open and — at the moment a prayer
/// time enters — pauses recitation playback for a short serenity window and
/// shows a single gentle notification per occurrence.
///
/// Design notes:
/// - Foreground-only lifecycle: [start] is called from app initialization and
///   [dispose] cancels the timer. Background pausing is out of scope for V1.
/// - Each occurrence fires at most once per app session ([_lastHandledKey]).
/// - Every provider/callback is best-effort: any failure is logged and the
///   watcher keeps running.
class PrayerSerenityWatcher {
  PrayerSerenityWatcher({
    required Future<Map<String, DateTime>?> Function() prayerTimesProvider,
    required Future<void> Function() pauseAudio,
    required Future<void> Function() showSerenityMoment,
    required Future<bool> Function() isEnabled,
    PrayerSerenityPolicy policy = const PrayerSerenityPolicy(),
    DateTime Function()? now,
    Duration tickInterval = const Duration(seconds: 30),
  }) : _prayerTimesProvider = prayerTimesProvider,
       _pauseAudio = pauseAudio,
       _showSerenityMoment = showSerenityMoment,
       _isEnabled = isEnabled,
       _policy = policy,
       _now = now ?? DateTime.now,
       _tickInterval = tickInterval;

  static const enabledKey = 'prayer_serenity_enabled';

  final PrayerSerenityTimesProvider _prayerTimesProvider;
  final PrayerSerenityPauseCallback _pauseAudio;
  final PrayerSerenityMomentCallback _showSerenityMoment;
  final Future<bool> Function() _isEnabled;
  final PrayerSerenityPolicy _policy;
  final DateTime Function() _now;
  final Duration _tickInterval;

  Timer? _timer;
  String? _lastHandledKey;
  bool _ticking = false;

  /// Whether the current tick is running — exposed for tests.
  @visibleForTesting
  bool get isTicking => _ticking;

  void start() {
    if (_timer != null) return;
    unawaited(tick());
    _timer = Timer.periodic(_tickInterval, (_) => unawaited(tick()));
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// Runs one serenity check. Public for tests and manual refreshes.
  Future<void> tick() async {
    if (_ticking) return;
    _ticking = true;
    try {
      if (!await _isEnabled()) return;
      final times = await _prayerTimesProvider();
      if (times == null || times.isEmpty) return;

      final key = _policy.activeOccurrenceKey(
        prayerTimes: times,
        now: _now(),
      );
      if (key == null || key == _lastHandledKey) return;
      _lastHandledKey = key;

      try {
        await _pauseAudio();
      } catch (error, stack) {
        TaliaLogger.w('Serenity audio pause failed', error, stack);
      }
      await _showSerenityMoment();
    } catch (error, stack) {
      TaliaLogger.w('Prayer serenity tick failed', error, stack);
    } finally {
      _ticking = false;
    }
  }
}
