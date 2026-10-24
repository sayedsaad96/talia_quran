import 'dart:async';

import '../services/quran_continuous_player_service.dart';

/// Routes actual media-notification taps to the active reader page.
///
/// The owner supplies its lifecycle and playback ownership checks through
/// [setReady] and [canOpenReader]. This class never changes playback state.
class QuranAudioNotificationController {
  factory QuranAudioNotificationController({
    required Stream<bool> notificationClicks,
    required ContinuousPlaybackState Function() currentState,
    required bool Function() canOpenReader,
    required FutureOr<void> Function(String location) onOpen,
    required String Function() currentLocation,
  }) => QuranAudioNotificationController._(
    notificationClicks,
    currentState,
    canOpenReader,
    onOpen,
    currentLocation,
  );

  QuranAudioNotificationController._(
    this._notificationClicks,
    this._currentState,
    this._canOpenReader,
    this._onOpen,
    this._currentLocation,
  );

  final Stream<bool> _notificationClicks;
  final ContinuousPlaybackState Function() _currentState;
  final bool Function() _canOpenReader;
  final FutureOr<void> Function(String location) _onOpen;
  final String Function() _currentLocation;

  StreamSubscription<bool>? _subscription;
  bool _ready = false;
  bool _disposed = false;
  bool _pendingClick = false;
  bool _opening = false;

  void start() {
    if (_disposed || _subscription != null) return;
    _subscription = _notificationClicks.listen((clicked) {
      if (_disposed) return;
      if (!clicked) {
        _pendingClick = false;
        return;
      }
      if (!_ready) {
        _pendingClick = true;
        return;
      }
      _openCurrentPage();
    });
  }

  void setReady(bool ready) {
    if (_disposed) return;
    _ready = ready;
    if (ready && _pendingClick) {
      _pendingClick = false;
      _openCurrentPage();
    }
  }

  void _openCurrentPage() {
    if (_disposed || !_ready || _opening || !_canOpenReader()) return;
    final state = _currentState();
    if (!state.hasActiveAudio || state.isSurahQueue) return;
    final surah = state.currentSurahId;
    final ayah = state.currentAyahNumber;
    final page = state.currentPageNumber;
    if (surah == null ||
        surah < 1 ||
        surah > 114 ||
        ayah == null ||
        ayah < 1 ||
        page == null ||
        page < 1 ||
        page > 604) {
      return;
    }
    final target = '/quran/page/$page';
    if (Uri.tryParse(_currentLocation())?.path == target) return;
    _opening = true;
    Future<void>.sync(() async {
          if (_disposed || !_ready || !_canOpenReader()) return;
          await _onOpen(target);
        })
        .catchError((Object _) {
          // A disposed or changing router must not break media playback.
        })
        .whenComplete(() => _opening = false);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pendingClick = false;
    await _subscription?.cancel();
    _subscription = null;
  }
}
