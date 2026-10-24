import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'hands_free_media_delegate.dart';
export 'hands_free_media_delegate.dart';

/// Bridges only the continuous Quran player to the platform media session.
///
/// Other short-lived players (ayah preview, adult memorization, and Kids)
/// remain ordinary [AudioPlayer] instances and are never wrapped globally.
class QuranBackgroundAudioHandler extends BaseAudioHandler with SeekHandler {
  QuranBackgroundAudioHandler({
    required this._player,
    required this._onPlay,
    required this._onPause,
    required this._onStop,
    required this._onNext,
    required this._onPrevious,
    required this._onSeek,
  }) {
    _playbackSubscription = _player.playbackEventStream.listen(
      (_) => _broadcastState(),
    );
    _playerStateSubscription = _player.playerStateStream.listen(
      (_) => _broadcastState(),
    );
  }

  final AudioPlayer _player;
  final Future<void> Function() _onPlay;
  final Future<void> Function() _onPause;
  final Future<void> Function() _onStop;
  final Future<void> Function() _onNext;
  final Future<void> Function() _onPrevious;
  final Future<void> Function(Duration position) _onSeek;
  StreamSubscription<PlaybackEvent>? _playbackSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _disposed = false;
  bool _queuePending = false;
  int? _queueIndex;
  bool? _hasNext;
  bool? _hasPrevious;
  HandsFreeMediaDelegate? _mediaDelegate;
  Object? _mediaOwner;
  PlaybackState? _readerState;
  MediaItem? _readerItem;

  bool ownsMedia(Object token) => identical(token, _mediaOwner);

  bool attachMediaDelegate(Object token, HandsFreeMediaDelegate delegate) {
    if (_mediaOwner != null) return false;
    _readerState = playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    );
    _readerItem = mediaItem.value;
    _mediaOwner = token;
    _mediaDelegate = delegate;
    mediaItem.add(null);
    publishPractice(token, playing: false);
    return true;
  }

  bool detachMediaDelegate(Object token) {
    if (!ownsMedia(token)) return false;
    _mediaOwner = null;
    _mediaDelegate = null;
    mediaItem.add(_readerItem);
    if (_readerState != null) playbackState.add(_readerState!);
    _readerState = null;
    _readerItem = null;
    return true;
  }

  void setMediaDelegate(HandsFreeMediaDelegate? delegate) {
    final old = _mediaDelegate;
    if (identical(old, delegate)) return;
    if (_mediaOwner != null && !identical(_mediaOwner, old)) return;
    final token = _mediaOwner;
    if (token != null) detachMediaDelegate(token);
    if (delegate != null) attachMediaDelegate(delegate, delegate);
    old?.onInterrupted();
  }

  void clearMediaDelegate(HandsFreeMediaDelegate delegate) {
    if (identical(_mediaDelegate, delegate) && _mediaOwner != null) {
      detachMediaDelegate(_mediaOwner!);
    }
  }

  void publishPractice(Object token, {MediaItem? item, required bool playing}) {
    if (!ownsMedia(token)) return;
    if (item != null) mediaItem.add(item);
    playbackState.add(
      PlaybackState(
        controls: [
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: playing,
      ),
    );
  }

  void prepareQueue(
    List<MediaItem> items, {
    required int initialIndex,
    required bool hasNext,
    required bool hasPrevious,
  }) {
    _queuePending = true;
    setQueueItems(
      items,
      currentIndex: initialIndex,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
    );
    _publishLoading();
  }

  void commitQueue() {
    if (_disposed) return;
    _queuePending = false;
    _refreshState();
  }

  void setQueueItems(
    List<MediaItem> items, {
    int? currentIndex,
    bool? hasNext,
    bool? hasPrevious,
  }) {
    if (_disposed) return;
    _queueIndex = currentIndex ?? _player.currentIndex;
    _hasNext = hasNext;
    _hasPrevious = hasPrevious;
    queue.add(List<MediaItem>.unmodifiable(items));
    _publishCurrentItem(_queueIndex);
  }

  void updateTransport({required bool hasNext, required bool hasPrevious}) {
    _hasNext = hasNext;
    _hasPrevious = hasPrevious;
    if (!_queuePending) _refreshState();
  }

  void _refreshState() {
    if (_disposed || _mediaDelegate != null || queue.value.isEmpty) return;
    _broadcastState();
  }

  void _publishLoading() {
    if (_disposed || _mediaDelegate != null) return;
    playbackState.add(
      PlaybackState(
        processingState: AudioProcessingState.loading,
        queueIndex: _queueIndex,
      ),
    );
  }

  void clearQueue() {
    _queuePending = false;
    _queueIndex = null;
    queue.add(const <MediaItem>[]);
    if (_mediaDelegate == null) {
      mediaItem.add(null);
      playbackState.add(
        PlaybackState(processingState: AudioProcessingState.idle),
      );
    }
  }

  @override
  Future<void> play() async {
    final delegate = _mediaDelegate;
    if (delegate != null) {
      delegate.onPrimary();
      return;
    }
    await _onPlay();
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    final delegate = _mediaDelegate;
    if (delegate == null) return super.click(button);
    switch (button) {
      case MediaButton.media:
        delegate.onHardwareButton(primary: true);
      case MediaButton.next:
        delegate.onHardwareButton(primary: false);
      case MediaButton.previous:
        break;
    }
  }

  @override
  Future<void> pause() async {
    // The notification/lock-screen pause action (not a physical key, which
    // arrives through [click]) ends the hands-free round without grading.
    final delegate = _mediaDelegate;
    if (delegate != null) {
      delegate.onInterrupted();
      return;
    }
    await _onPause();
  }

  @override
  Future<void> stop() async {
    final delegate = _mediaDelegate;
    if (delegate != null) {
      delegate.onInterrupted();
      return;
    }
    await _onStop();
  }

  @override
  Future<void> skipToNext() async {
    final delegate = _mediaDelegate;
    if (delegate != null) {
      delegate.onSecondary();
      return;
    }
    await _onNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_mediaDelegate == null) await _onPrevious();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_mediaDelegate == null) await _onSeek(position);
  }

  void _broadcastState() {
    if (_disposed || _mediaDelegate != null || queue.value.isEmpty) return;
    if (_queuePending) return _publishLoading();
    // Events already queued by the previous source may arrive after commit.
    // The live player's index belongs to the installed source list.
    _queueIndex = _player.currentIndex;
    _publishCurrentItem(_queueIndex);
    final isPlaying = _player.playing;
    final controls = <MediaControl>[
      if (_hasPrevious ?? ((_queueIndex ?? 0) > 0)) MediaControl.skipToPrevious,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      MediaControl.stop,
      if (_hasNext ?? ((_queueIndex ?? 0) < queue.value.length - 1))
        MediaControl.skipToNext,
    ];
    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: [
          for (var i = 0; i < controls.length; i++)
            if (controls[i] != MediaControl.stop) i,
        ],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: isPlaying,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _queueIndex,
      ),
    );
  }

  void _publishCurrentItem(int? index) {
    if (_mediaDelegate != null) return;
    final items = queue.value;
    if (index == null || index < 0 || index >= items.length) return;
    final item = items[index];
    if (!identical(mediaItem.value, item)) mediaItem.add(item);
  }

  Future<void> disposeHandler() async {
    if (_disposed) return;
    _disposed = true;
    final delegate = _mediaDelegate;
    _mediaOwner = null;
    _mediaDelegate = null;
    delegate?.onInterrupted();
    clearQueue();
    await _playbackSubscription?.cancel();
    _playbackSubscription = null;
    await _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
  }
}
