import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../../../../core/memorization/hands_free/hands_free_round_engine.dart';
import '../../../../core/memorization/hands_free/hands_free_round_state.dart';
import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/services/quran_reciter.dart';

abstract interface class HandsFreePracticeAudio {
  Future<bool> playPrompt(ListeningAyahRef ref);
  Future<void> playFeedback(HandsFreeGrade grade);
  Future<void> stop();
  Future<void> dispose();
}

abstract interface class HandsFreePlaybackStatus {
  Stream<bool> get playing;
}

final class JustAudioHandsFreePractice
    implements HandsFreePracticeAudio, HandsFreePlaybackStatus {
  JustAudioHandsFreePractice(
    this.cache,
    this.reciter, {
    this._player,
    this.operationTimeout = const Duration(seconds: 15),
  });
  final AudioCacheService cache;
  final QuranReciter reciter;
  final Duration operationTimeout;
  AudioPlayer? _player;
  final _playing = StreamController<bool>.broadcast(sync: true);
  StreamSubscription<PlayerState>? _playerState;
  @override
  Stream<bool> get playing => _playing.stream;
  AudioPlayer get player {
    final value = _player ??= AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
    );
    _playerState ??= value.playerStateStream.listen((state) {
      if (!_playing.isClosed) {
        _playing.add(
          state.playing && state.processingState == ProcessingState.ready,
        );
      }
    });
    return value;
  }

  int _generation = 0;
  Future<void> _pending = Future.value();
  bool _disposed = false;

  @override
  Future<bool> playPrompt(ListeningAyahRef ref) async {
    if (_disposed) return false;
    final generation = ++_generation;
    var completed = false;
    final operation = () async {
      final source = await cache.getAudioSource(
        ref.surahId,
        ref.ayahNumber,
        reciter: reciter,
      );
      if (!_current(generation)) return;
      final duration = await player.setAudioSource(
        AudioSource.uri(
          source.startsWith('http') ? Uri.parse(source) : Uri.file(source),
        ),
      );
      if (!_current(generation)) return;
      if (duration == null || duration <= Duration.zero) {
        throw StateError('Prompt duration unavailable');
      }
      final requested = promptClipLength(duration);
      await player.setClip(
        start: Duration.zero,
        end: requested < duration ? requested : duration,
      );
      if (!_current(generation)) return;
      await _play(generation);
      completed =
          _current(generation) &&
          player.processingState == ProcessingState.completed;
    }();
    _pending = operation;
    try {
      await operation.timeout(operationTimeout);
      return completed;
    } catch (_) {
      if (_current(generation)) _generation++;
      rethrow;
    } finally {
      if (_current(generation)) await _stopPlayer();
    }
  }

  @override
  Future<void> playFeedback(HandsFreeGrade grade) async {
    if (_disposed) throw StateError('Practice audio disposed');
    final generation = ++_generation;
    final operation = () async {
      await player.setAsset('assets/audio/tones/${grade.name}.wav');
      if (!_current(generation)) return;
      await player.setClip();
      if (_current(generation)) await _play(generation);
    }();
    _pending = operation;
    try {
      await operation.timeout(operationTimeout);
    } catch (_) {
      if (_current(generation)) _generation++;
      rethrow;
    } finally {
      if (_current(generation)) await _stopPlayer();
    }
  }

  Future<void> _play(int generation) async {
    await player.setLoopMode(LoopMode.off);
    if (!_current(generation)) return;
    await player.setSpeed(1);
    if (_current(generation)) await player.play();
  }

  bool _current(int generation) => !_disposed && generation == _generation;

  Future<void> _stopPlayer() async {
    await _player?.stop().timeout(operationTimeout);
  }

  @override
  Future<void> stop() async {
    _generation++;
    await _stopPlayer();
    try {
      await _pending.timeout(operationTimeout);
    } on TimeoutException {
      rethrow;
    } catch (_) {
      /* drain a failed preparation */
    }
    await _stopPlayer();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _player?.dispose().timeout(operationTimeout);
    await _playerState?.cancel();
    await _playing.close();
  }
}
