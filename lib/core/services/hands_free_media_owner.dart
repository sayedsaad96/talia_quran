import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'quran_background_audio_handler.dart';

/// One synchronous reservation spans reader stop, lazy init and practice use.
final class HandsFreeMediaOwner {
  HandsFreeMediaOwner({this.acquisitionTimeout = const Duration(seconds: 5)});
  final Duration acquisitionTimeout;
  Object? _token;
  HandsFreeMediaDelegate? _delegate;
  QuranBackgroundAudioHandler? _handler;
  bool _disposed = false;
  bool _stopping = false, _cancelled = false;
  bool get isReserved => _disposed || _token != null;
  bool get isDisposed => _disposed;

  Future<HandsFreeMediaLease?> acquire(
    HandsFreeMediaDelegate delegate, {
    required Future<void> Function() stopReader,
    required Future<QuranBackgroundAudioHandler?> Function() initialize,
  }) async {
    if (isReserved) return null;
    final token = Object();
    _token = token;
    _delegate = delegate;
    _cancelled = false;
    try {
      await _confirmReaderStopped(token, stopReader);
      if (!_current(token)) return null;
      final handler = await initialize().timeout(
        acquisitionTimeout,
        onTimeout: () => null,
      );
      if (!_current(token)) return null;
      if (handler == null || !handler.attachMediaDelegate(token, delegate)) {
        _release(token);
        return null;
      }
      _handler = handler;
      return _Lease(
        () => _current(token) && handler.ownsMedia(token),
        (item, playing) =>
            handler.publishPractice(token, item: item, playing: playing),
        () => _release(token),
      );
    } catch (_) {
      // A deadline cannot cancel a native stop. Keep transport excluded until
      // its successful completion; an unknown hardware failure stays closed.
      if (identical(token, _token) && _stopping) {
        _cancelled = true;
      } else {
        _release(token);
      }
      return null;
    }
  }

  Future<void> _confirmReaderStopped(
    Object token,
    Future<void> Function() stopReader,
  ) async {
    _stopping = true;
    final stop = Future<void>.sync(stopReader);
    // Success clears a cancelled reservation; a failed stop means the reader
    // still owns transport, so the reservation must not outlive the attempt.
    unawaited(stop.then(
      (_) {
        if (!identical(token, _token)) return;
        _stopping = false;
        if (_cancelled) _release(token);
      },
      onError: (Object _, StackTrace _) {
        if (identical(token, _token)) _release(token);
      },
    ));
    await stop.timeout(acquisitionTimeout);
  }

  bool _current(Object token) =>
      !_disposed && !_cancelled && identical(token, _token);

  void _release(Object token) {
    if (!identical(token, _token)) return;
    _handler?.detachMediaDelegate(token);
    _handler = null;
    _delegate = null;
    _token = null;
    _stopping = false;
    _cancelled = false;
  }

  void interrupt() => _delegate?.onInterrupted();

  void cancelPending(HandsFreeMediaDelegate delegate) {
    if (_handler == null && identical(_delegate, delegate) && _token != null) {
      if (_stopping) {
        _cancelled = true;
      } else {
        _release(_token!);
      }
    }
  }

  void dispose() {
    _disposed = true;
    final delegate = _delegate;
    delegate?.onInterrupted();
    final token = _token;
    if (token != null) _release(token);
  }
}

final class _Lease implements HandsFreeMediaLease {
  _Lease(this._current, this._publish, this._release);
  final bool Function() _current;
  final void Function(MediaItem, bool) _publish;
  final void Function() _release;
  @override
  bool get isCurrent => _current();
  @override
  void publish({required MediaItem item, required bool playing}) {
    if (isCurrent) _publish(item, playing);
  }

  @override
  Future<void> release() async => _release();
}
