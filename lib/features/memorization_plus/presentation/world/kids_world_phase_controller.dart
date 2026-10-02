import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/services/kids_world_phase.dart';

typedef KidsWorldPrayerTimesLoader =
    Future<({DateTime fajr, DateTime maghrib})?> Function();

/// Live day/night phase of the kids world.
///
/// Resolves the phase from today's prayer times (or the 06:00/18:00 fallback),
/// arms a timer for the next boundary, and can be refreshed on app resume.
class KidsWorldPhaseController extends ValueNotifier<KidsWorldPhase> {
  KidsWorldPhaseController({
    required KidsWorldPrayerTimesLoader prayerTimes,
    DateTime Function() clock = DateTime.now,
  }) : _prayerTimes = prayerTimes,
       _clock = clock,
       super(KidsWorldPhase.night);

  final KidsWorldPrayerTimesLoader _prayerTimes;
  final DateTime Function() _clock;
  Timer? _timer;
  bool _started = false;
  bool _disposed = false;
  int _generation = 0;

  /// Idempotent; first call resolves the phase and arms the boundary timer.
  void ensureStarted() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(refresh());
  }

  /// Re-reads prayer times, updates value, re-arms the timer.
  Future<void> refresh() async {
    if (_disposed) return;
    final generation = ++_generation;
    ({DateTime fajr, DateTime maghrib})? times;
    try {
      times = await _prayerTimes();
    } catch (_) {
      times = null;
    }
    // Disposed or superseded by a newer refresh while loading.
    if (_disposed || generation != _generation) return;

    final now = _clock();
    value = kidsWorldPhaseAt(now, fajr: times?.fajr, maghrib: times?.maghrib);
    final boundary = kidsWorldNextBoundary(
      now,
      fajr: times?.fajr,
      maghrib: times?.maghrib,
    );
    _timer?.cancel();
    _timer = Timer(
      boundary.difference(now) + const Duration(seconds: 1),
      () => unawaited(refresh()),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
