import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../../../core/services/audio_lifecycle_manager.dart';
import '../../domain/entities/azkar_entities.dart';

enum ZikrAudioStatus { idle, loading, playing, paused, stopped, failed }

class ZikrAudioState {
  const ZikrAudioState({
    this.status = ZikrAudioStatus.idle,
    this.zikrId,
    this.error,
  });

  final ZikrAudioStatus status;
  final String? zikrId;
  final String? error;

  bool get isPlaying => status == ZikrAudioStatus.playing;
  bool get isActive =>
      status == ZikrAudioStatus.loading ||
      status == ZikrAudioStatus.playing ||
      status == ZikrAudioStatus.paused;

  ZikrAudioState copyWith({
    ZikrAudioStatus? status,
    String? zikrId,
    String? error,
  }) =>
      ZikrAudioState(
        status: status ?? this.status,
        zikrId: zikrId ?? this.zikrId,
        error: error,
      );
}

/// The read side of the audio service, so widgets can follow playback state
/// without depending on the platform player.
abstract interface class ZikrAudioStateSource {
  ZikrAudioState get state;
  void addListener(void Function(ZikrAudioState) listener);
  void removeListener(void Function(ZikrAudioState) listener);
}

/// Recites a single zikr from its optional [Zikr.audioUrl] asset/URL.
///
/// The player only ever plays a fully-qualified source shipped with the
/// approved dataset — it never synthesizes speech for religious text. If a
/// record has no audio the service stays idle and the UI hides the control.
class ZikrAudioService implements ZikrAudioStateSource {
  ZikrAudioService({AudioLifecycleManager? lifecycleManager})
      : _lifecycle = lifecycleManager;

  final AudioLifecycleManager? _lifecycle;
  AudioPlayer? _player;
  StreamSubscription<void>? _completionSub;
  ZikrAudioState _state = const ZikrAudioState();
  final List<void Function(ZikrAudioState)> _listeners = [];

  @override
  ZikrAudioState get state => _state;

  @override
  void addListener(void Function(ZikrAudioState) listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function(ZikrAudioState) listener) {
    _listeners.remove(listener);
  }

  void _emit(ZikrAudioState next) {
    _state = next;
    for (final listener in List.of(_listeners)) {
      listener(next);
    }
  }

  bool hasAudio(Zikr zikr) =>
      zikr.audioUrl != null && zikr.audioUrl!.trim().isNotEmpty;

  Future<void> toggle(Zikr zikr) async {
    if (!hasAudio(zikr)) return;
    if (_state.isActive && _state.zikrId == zikr.id) {
      if (_state.isPlaying) {
        await pause();
      } else {
        await resume();
      }
      return;
    }
    await play(zikr);
  }

  Future<void> play(Zikr zikr) async {
    if (!hasAudio(zikr)) return;
    try {
      _emit(_state.copyWith(status: ZikrAudioStatus.loading, zikrId: zikr.id));
      final player = await _ensurePlayer();
      await player.setUrl(zikr.audioUrl!);
      await player.play();
      _emit(
        _state.copyWith(status: ZikrAudioStatus.playing, zikrId: zikr.id),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          status: ZikrAudioStatus.failed,
          zikrId: zikr.id,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> pause() async {
    await _player?.pause();
    _emit(_state.copyWith(status: ZikrAudioStatus.paused));
  }

  Future<void> resume() async {
    await _player?.play();
    _emit(_state.copyWith(status: ZikrAudioStatus.playing));
  }

  Future<void> stop() async {
    await _completionSub?.cancel();
    await _player?.stop();
    _emit(const ZikrAudioState(status: ZikrAudioStatus.stopped));
  }

  Future<AudioPlayer> _ensurePlayer() async {
    if (_player != null) return _player!;
    final player = AudioPlayer();
    _player = player;
    _completionSub = player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _emit(const ZikrAudioState(status: ZikrAudioStatus.stopped));
      }
    });
    _lifecycle?.register(player);
    return player;
  }

  Future<void> dispose() async {
    await _completionSub?.cancel();
    await _player?.dispose();
    _player = null;
    _listeners.clear();
  }
}
