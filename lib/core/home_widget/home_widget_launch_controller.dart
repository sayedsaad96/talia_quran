import 'dart:async';
import '../utils/talia_logger.dart';

/// Buffers cold/warm widget taps while the splash router owns navigation.
final class HomeWidgetLaunchController {
  HomeWidgetLaunchController({
    required this.events,
    required this.initial,
    required this.onOpen,
  });
  final Stream<Uri?> events;
  final Future<Uri?> Function() initial;
  final void Function(Uri) onOpen;
  StreamSubscription<Uri?>? _subscription;
  Uri? _pending;
  bool _active = false, _disposed = false;
  int _revision = 0;

  void start() {
    if (_subscription != null || _disposed) return;
    _subscription = events.listen(
      (uri) {
        _revision++;
        _receive(uri);
      },
      onError: (Object error, StackTrace stack) {
        TaliaLogger.w('Widget launch stream unavailable', error, stack);
      },
    );
    unawaited(_loadInitial(_revision));
  }

  Future<void> _loadInitial(int revision) async {
    try {
      final uri = await initial();
      if (revision == _revision) _receive(uri);
    } catch (error, stack) {
      TaliaLogger.w('Initial widget launch unavailable', error, stack);
    }
  }

  void _receive(Uri? uri) {
    if (_disposed || uri == null) return;
    _pending = uri;
    if (_active) _flush();
  }

  void activate() {
    _active = true;
    if (!_disposed) _flush();
  }

  void _flush() {
    final uri = _pending;
    _pending = null;
    if (uri != null) onOpen(uri);
  }

  Future<void> dispose() async {
    _disposed = true;
    _pending = null;
    await _subscription?.cancel();
  }
}
