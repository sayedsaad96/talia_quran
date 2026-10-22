import 'dart:async';

enum SleepTimerChoice { off, min15, min30, min60, endOfSurah }

/// Stops playback after a duration, fading volume over the last 10 seconds.
class SleepTimer {
  SleepTimer({
    required this._setVolume,
    required this._stop,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const Duration fadeWindow = Duration(seconds: 10);
  static const Duration _tick = Duration(milliseconds: 500);

  final void Function(double volume) _setVolume;
  final Future<void> Function() _stop;
  final DateTime Function() _clock;

  Timer? _expiry;
  Timer? _ticker;
  DateTime? _end;

  bool get isActive => _end != null;

  Duration? get remaining {
    final end = _end;
    if (end == null) return null;
    final r = end.difference(_clock());
    return r.isNegative ? Duration.zero : r;
  }

  void start(Duration d) {
    final wasActive = _end != null;
    _cancelTimers();
    if (wasActive) _setVolume(1.0);
    _end = _clock().add(d);
    _expiry = Timer(d, _expire);
    _ticker = Timer.periodic(_tick, (_) => _onTick());
  }

  void cancel() {
    final wasActive = _end != null;
    _cancelTimers();
    if (wasActive) _setVolume(1.0);
  }

  void _cancelTimers() {
    _expiry?.cancel();
    _ticker?.cancel();
    _expiry = null;
    _ticker = null;
    _end = null;
  }

  void _onTick() {
    final r = remaining;
    if (r == null || r > fadeWindow) return;
    _setVolume((r.inMilliseconds / fadeWindow.inMilliseconds).clamp(0.0, 1.0));
  }

  Future<void> _expire() async {
    _cancelTimers();
    try {
      await _stop();
    } catch (_) {
      // Stopping failed; still restore the volume below.
    } finally {
      _setVolume(1.0);
    }
  }
}
