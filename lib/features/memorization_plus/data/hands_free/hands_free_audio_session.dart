import 'dart:async';

import 'package:audio_session/audio_session.dart';

typedef AudioSessionResolver = Future<AudioSession> Function();

abstract interface class HandsFreeAudioSession {
  Stream<void> get interruptions;
  Future<void> activate();
  Future<void> release();
  Future<void> dispose();
}

final class PlatformHandsFreeAudioSession implements HandsFreeAudioSession {
  PlatformHandsFreeAudioSession({AudioSessionResolver? sessionResolver})
    : _sessionResolver = sessionResolver ?? (() => AudioSession.instance);

  final AudioSessionResolver _sessionResolver;
  final _events = StreamController<void>.broadcast(sync: true);
  final _subscriptions = <StreamSubscription<dynamic>>[];
  AudioSession? _session;
  AudioSessionConfiguration? _previous;

  @override
  Stream<void> get interruptions => _events.stream;

  @override
  Future<void> activate() async {
    final session = await _sessionResolver();
    _session = session;
    _previous = session.configuration;
    _subscriptions.add(
      session.interruptionEventStream.listen((event) {
        if (event.begin && !_events.isClosed) _events.add(null);
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
