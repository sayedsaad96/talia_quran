import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Bridges only the continuous Quran player to the platform media session.
///
/// Other short-lived players (ayah preview, adult memorization, and Kids)
/// remain ordinary [AudioPlayer] instances and are never wrapped globally.
class QuranBackgroundAudioHandler extends BaseAudioHandler with SeekHandler {
  QuranBackgroundAudioHandler({
    required AudioPlayer player,
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function() onStop,
    required Future<void> Function() onNext,
    required Future<void> Function() onPrevious,
    required Future<void> Function(Duration position) onSeek,
  }) : _player = player,
       _onPlay = onPlay,
       _onPause = onPause,
       _onStop = onStop,
       _onNext = onNext,
       _onPrevious = onPrevious,
       _onSeek = onSeek {
    _playbackSubscription = _player.playbackEventStream.listen(_broadcastState);
  }

  final AudioPlayer _player;
  final Future<void> Function() _onPlay;
  final Future<void> Function() _onPause;
  final Future<void> Function() _onStop;
  final Future<void> Function() _onNext;
  final Future<void> Function() _onPrevious;
  final Future<void> Function(Duration position) _onSeek;
  StreamSubscription<PlaybackEvent>? _playbackSubscription;

  void setQueueItems(List<MediaItem> items) {
    queue.add(List<MediaItem>.unmodifiable(items));
    _publishCurrentItem(_player.currentIndex);
  }

  void clearQueue() {
    queue.add(const <MediaItem>[]);
    mediaItem.add(null);
  }

  @override
  Future<void> play() => _onPlay();

  @override
  Future<void> pause() => _onPause();

  @override
  Future<void> stop() => _onStop();

  @override
  Future<void> skipToNext() => _onNext();

  @override
  Future<void> skipToPrevious() => _onPrevious();

  @override
  Future<void> seek(Duration position) => _onSeek(position);

  void _broadcastState(PlaybackEvent event) {
    _publishCurrentItem(event.currentIndex);
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 3],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  void _publishCurrentItem(int? index) {
    final items = queue.value;
    if (index == null || index < 0 || index >= items.length) return;
    final item = items[index];
    if (mediaItem.value?.id != item.id) mediaItem.add(item);
  }

  Future<void> disposeHandler() async {
    await _playbackSubscription?.cancel();
    _playbackSubscription = null;
  }
}
