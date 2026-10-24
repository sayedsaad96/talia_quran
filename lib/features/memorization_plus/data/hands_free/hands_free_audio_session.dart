import 'dart:async';

import 'package:audio_session/audio_session.dart';

typedef AudioSessionResolver = Future<AudioSession> Function();

abstract interface class HandsFreeAudioSession {
  Stream<void> get interruptions;

  /// True while our own recognizer owns (or is starting to own) the
  /// microphone. Its transient focus request is not an interruption.
  void setCaptureActive(bool active);
  Future<void> activate();
  Future<void> release();
  Future<void> dispose();
}

final class PlatformHandsFreeAudioSession implements HandsFreeAudioSession {
  PlatformHandsFreeAudioSession({
    AudioSessionResolver? sessionResolver,
    DateTime Function()? clock,
  }) : _sessionResolver = sessionResolver ?? (() => AudioSession.instance),
       _clock = clock ?? DateTime.now;

  /// Our recognizer's own transient focus request lands right after capture
  /// starts; a transient loss later (an incoming call) is a real interruption.
  static const captureFocusGrace = Duration(milliseconds: 1500);

  final AudioSessionResolver _sessionResolver;
  final DateTime Function() _clock;
  DateTime? _captureStartedAt;
  final _events = StreamController<void>.broadcast(sync: true);
  final _subscriptions = <StreamSubscription<dynamic>>[];
  AudioSession? _session;
  AudioSessionConfiguration? _previous;
  bool _captureActive = false;

  @override
  Stream<void> get interruptions => _events.stream;

  @override
  void setCaptureActive(bool active) {
    if (active && !_captureActive) _captureStartedAt = _clock();
    if (!active) _captureStartedAt = null;
    _captureActive = active;
  }

  bool get _withinCaptureGrace {
    final startedAt = _captureStartedAt;
    return _captureActive &&
        startedAt != null &&
        _clock().difference(startedAt) <= captureFocusGrace;
  }

  @override
  Future<void> activate() async {
    final session = await _sessionResolver();
    _session = session;
    _previous = session.configuration;
    _subscriptions.add(
      session.interruptionEventStream.listen((event) {
        if (!event.begin || _events.isClosed) return;
        switch (event.type) {
          case AudioInterruptionType.duck:
            return; // Lowered volume only (e.g. navigation prompts).
          case AudioInterruptionType.pause:
            // The recognizer takes transient focus as each user turn starts.
            if (_withinCaptureGrace) return;
          case AudioInterruptionType.unknown:
            break; // Permanent loss always ends the round.
        }
        _events.add(null);
      }),
    );
    _subscriptions.add(
      session.becomingNoisyEventStream.listen((_) {
        if (!_events.isClosed) _events.add(null);
      }),
    );
    await session.configure(const AudioSessionConfiguration.speech());
    if (!await session.setActive(true)) throw StateError('Audio focus denied');
  }

  @override
  Future<void> release() async {
    _captureActive = false;
    _captureStartedAt = null;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    final session = _session;
    if (session != null) {
      try {
        if (!await session.setActive(false)) {
          throw StateError('Audio focus release denied');
        }
      } finally {
        await session.configure(
          _previous ?? const AudioSessionConfiguration.music(),
        );
      }
      _session = null;
    }
  }

  @override
  Future<void> dispose() async {
    await release();
    await _events.close();
  }
}
