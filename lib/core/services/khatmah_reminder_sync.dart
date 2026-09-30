import 'dart:async';

/// Re-plans khatmah reminders whenever khatmah data changes, so a finished
/// wird is not nagged about and tomorrow's reminder shows the right pages.
class KhatmahReminderSync {
  KhatmahReminderSync(
    this._changes,
    this._refresh, {
    this.debounce = const Duration(seconds: 2),
  });

  final Stream<void>? _changes;
  final Future<void> Function() _refresh;
  final Duration debounce;
  StreamSubscription<void>? _subscription;
  Timer? _timer;

  void start() {
    _subscription ??= _changes?.listen((_) {
      _timer?.cancel();
      _timer = Timer(debounce, () => unawaited(_refresh()));
    });
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
  }
}
