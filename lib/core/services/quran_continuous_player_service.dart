import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/surah_names.dart';
import '../utils/talia_logger.dart';
import 'audio_lifecycle_manager.dart';
import 'quran_background_audio_handler.dart';
import 'quran_audio_service.dart';
import 'reader_repeat_plan.dart';
import 'sleep_timer.dart';
import 'quran_reciter.dart';
import 'quran_reciter_service.dart';
import '../../features/quran/domain/entities/quran_entities.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';

enum PlaybackStatus { idle, loading, playing, paused, error }

enum PlayScope { surah, page, singleAyah }

class ContinuousPlaybackState {
  const ContinuousPlaybackState({
    this.status = PlaybackStatus.idle,
    this.currentAyah,
    this.currentSurahId,
    this.currentAyahNumber,
    this.currentPageNumber,
    this.reciter,
    this.scope = PlayScope.surah,
    this.errorMessage,
    this.hasNext = false,
    this.hasPrevious = false,
    this.repeat = const ReaderRepeatSettings(),
    this.sleepChoice = SleepTimerChoice.off,
  });

  final PlaybackStatus status;
  final Ayah? currentAyah;
  final int? currentSurahId;
  final int? currentAyahNumber;
  final int? currentPageNumber;
  final QuranReciter? reciter;
  final PlayScope scope;
  final String? errorMessage;
  final bool hasNext;
  final bool hasPrevious;
  final ReaderRepeatSettings repeat;
  final SleepTimerChoice sleepChoice;

  bool get isIdle => status == PlaybackStatus.idle;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isError => status == PlaybackStatus.error;
  bool get hasActiveAudio => isPlaying || isPaused || isLoading;

  String get surahNameAr => SurahNames.nameAr(currentSurahId);
  String get surahNameEn => SurahNames.nameEn(currentSurahId);

  ContinuousPlaybackState copyWith({
    PlaybackStatus? status,
    Ayah? currentAyah,
    int? currentSurahId,
    int? currentAyahNumber,
    int? currentPageNumber,
    QuranReciter? reciter,
    PlayScope? scope,
    String? errorMessage,
    bool? hasNext,
    bool? hasPrevious,
    ReaderRepeatSettings? repeat,
    SleepTimerChoice? sleepChoice,
  }) {
    return ContinuousPlaybackState(
      status: status ?? this.status,
      currentAyah: currentAyah ?? this.currentAyah,
      currentSurahId: currentSurahId ?? this.currentSurahId,
      currentAyahNumber: currentAyahNumber ?? this.currentAyahNumber,
      currentPageNumber: currentPageNumber ?? this.currentPageNumber,
      reciter: reciter ?? this.reciter,
      scope: scope ?? this.scope,
      errorMessage: errorMessage ?? this.errorMessage,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
      repeat: repeat ?? this.repeat,
      sleepChoice: sleepChoice ?? this.sleepChoice,
    );
  }
}

/// Continuous Quran audio player backed by [just_audio]'s playlist API.
///
/// ### Why setAudioSources (playlist)?
/// The old implementation called `player.stop() → setUrl() → play()` for
/// every ayah transition. Each call blocks for a network round-trip, causing
/// a noticeable pause between every ayah. The new playlist API hands
/// just_audio the entire list upfront so the engine pre-buffers the next
/// item while the current one is still playing — achieving gapless (or
/// near-gapless) playback automatically.
class QuranContinuousPlayerService {
  QuranContinuousPlayerService({
    required this._quranRepository,
    required this._reciterService,
    AudioPlayer? player,
    this._enableBackgroundAudioIntegration = false,
  }) : _player = player ?? AudioPlayer() {
    _sleepTimer = SleepTimer(
      setVolume: (volume) {
        unawaited(_player.setVolume(volume));
      },
      stop: stop,
    );
    AudioLifecycleManager.instance.register(
      _player,
      shouldPause: () => !_isBackgroundPlaybackEnabled,
    );
    _initPlayerListeners();
    _loadBackgroundPlaybackPreference();
  }

  static const String _prefKeyBackgroundPlayback =
      'quran_background_playback_enabled';
  bool _isBackgroundPlaybackEnabled = true;

  /// Whether Quran recitation continues in the background with notification controls.
  bool get isBackgroundPlaybackEnabled => _isBackgroundPlaybackEnabled;

  /// Updates whether recitation continues in the background.
  Future<void> setBackgroundPlaybackEnabled(bool enabled) async {
    _isBackgroundPlaybackEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyBackgroundPlayback, enabled);
    } catch (_) {}
  }

  Future<void> _loadBackgroundPlaybackPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isBackgroundPlaybackEnabled =
          prefs.getBool(_prefKeyBackgroundPlayback) ?? true;
    } catch (_) {}
  }

  final QuranRepository _quranRepository;
  final QuranReciterService _reciterService;
  final bool _enableBackgroundAudioIntegration;
  final AudioPlayer _player;
  QuranBackgroundAudioHandler? _backgroundAudioHandler;
  Future<QuranBackgroundAudioHandler?>? _backgroundAudioInitialization;

  final ValueNotifier<ContinuousPlaybackState> _stateNotifier =
      ValueNotifier<ContinuousPlaybackState>(const ContinuousPlaybackState());

  ValueListenable<ContinuousPlaybackState> get stateNotifier => _stateNotifier;
  ContinuousPlaybackState get state => _stateNotifier.value;

  /// The ayahs of the scope that started playback, without repeats.
  List<Ayah> _baseQueue = [];

  /// [_baseQueue] expanded by [_repeat]; player indexes map into this list.
  List<Ayah> _queue = [];
  ReaderRepeatSettings _repeat = const ReaderRepeatSettings();
  SleepTimerChoice _sleepChoice = SleepTimerChoice.off;
  int? _sleepSurahId;
  late final SleepTimer _sleepTimer;
  bool _playerSettingsTouched = false;
  int _currentIndex = -1;
  PlayScope _activeScope = PlayScope.surah;
  int? _activeSurahId;

  StreamSubscription<int?>? _currentIndexSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  // ---------------------------------------------------------------------------
  // Listener setup
  // ---------------------------------------------------------------------------

  void _initPlayerListeners() {
    // Track which item in the playlist is now playing.
    _currentIndexSub = _player.currentIndexStream.listen((index) {
      if (index == null || index < 0 || index >= _queue.length) return;
      if (index == _currentIndex) return;
      final previous = (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;
      _currentIndex = index;
      final ayah = _queue[index];
      if (_sleepChoice == SleepTimerChoice.endOfSurah &&
          _sleepSurahId != null &&
          (ayah.surahId != _sleepSurahId ||
              (previous != null &&
                  previous.surahId == ayah.surahId &&
                  ayah.numberInSurah < previous.numberInSurah))) {
        // The surah that was playing when the choice was made has ended.
        unawaited(stop());
        return;
      }
      _emitState(
        _stateNotifier.value.copyWith(
          currentAyah: ayah,
          currentSurahId: ayah.surahId,
          currentAyahNumber: ayah.numberInSurah,
          currentPageNumber: ayah.page,
          hasNext: _hasNextAyah(),
          hasPrevious: _hasPreviousAyah(),
        ),
      );
    });

    _playerStateSub = _player.playerStateStream.listen((playerState) {
      switch (playerState.processingState) {
        case ProcessingState.loading:
        case ProcessingState.buffering:
          // After the playlist is loaded and play() was called, just_audio
          // may briefly re-enter buffering between ayahs (gapless pre-buffer)
          // or when the network is slow. In both cases the user already sees
          // content playing — do NOT flip back to a loading spinner.
          // Only show the loading state during the very first cold start
          // (status is explicitly loading and never reached playing yet).
          if (_stateNotifier.value.status != PlaybackStatus.loading) return;
        // Already in loading — keep it; no need to re-emit.
        case ProcessingState.ready:
          _emitState(
            _stateNotifier.value.copyWith(
              status: playerState.playing
                  ? PlaybackStatus.playing
                  : PlaybackStatus.paused,
            ),
          );
        case ProcessingState.completed:
          unawaited(stop());
        case ProcessingState.idle:
          break;
      }
    });
  }

  void _emitState(ContinuousPlaybackState newState) {
    _stateNotifier.value = newState.copyWith(
      repeat: _repeat,
      sleepChoice: _sleepChoice,
    );
  }

  int get _perAyah => _repeat.perAyah.clamp(1, 10);

  bool get _hasRepeats => _perAyah > 1 || _repeat.rangeTimes > 1;

  void _setQueueFromBase(List<Ayah> base) {
    _baseQueue = List<Ayah>.from(base);
    _queue = expandRepeatQueue<Ayah>(_baseQueue, _repeat);
  }

  Future<void> _applyPlayerSettings() async {
    await _player.setLoopMode(
      _repeat.rangeTimes == 0 ? LoopMode.all : LoopMode.off,
    );
    await _player.setSpeed(_repeat.normalizedSpeed);
  }

  QuranReciter _resolveReciter(QuranReciter? reciter) {
    return reciter ?? _reciterService.currentReciter.value;
  }

  // ---------------------------------------------------------------------------
  // Public playback API
  // ---------------------------------------------------------------------------

  /// Plays an entire Surah starting from [startAyah].
  Future<void> playSurah(
    int surahId, {
    int startAyah = 1,
    QuranReciter? reciter,
  }) async {
    final activeReciter = _resolveReciter(reciter);
    _activeScope = PlayScope.surah;
    _activeSurahId = surahId;

    _emitState(
      ContinuousPlaybackState(
        status: PlaybackStatus.loading,
        currentSurahId: surahId,
        currentAyahNumber: startAyah,
        reciter: activeReciter,
        scope: PlayScope.surah,
      ),
    );

    final surahDetailResult = await _quranRepository.getSurahDetail(surahId);
    final surahDetail = surahDetailResult.fold((_) => null, (d) => d);

    if (surahDetail == null || surahDetail.ayahs.isEmpty) {
      _emitState(
        _stateNotifier.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'تعذر تحميل آيات السورة',
        ),
      );
      return;
    }

    _setQueueFromBase(surahDetail.ayahs);
    var startIndex = _baseQueue.indexWhere((a) => a.numberInSurah == startAyah);
    if (startIndex < 0) startIndex = 0;
    startIndex *= _perAyah;

    await _loadPlaylistAndPlay(
      startIndex: startIndex,
      activeReciter: activeReciter,
    );
  }

  /// Plays all ayahs on a Mushaf page [pageNumber] in sequence.
  Future<void> playPage(
    int pageNumber, {
    int startAyahIndex = 0,
    QuranReciter? reciter,
  }) async {
    final activeReciter = _resolveReciter(reciter);
    _activeScope = PlayScope.page;
    _activeSurahId = null;

    _emitState(
      ContinuousPlaybackState(
        status: PlaybackStatus.loading,
        currentPageNumber: pageNumber,
        reciter: activeReciter,
        scope: PlayScope.page,
      ),
    );

    final pageDetailResult = await _quranRepository.getQuranPage(pageNumber);
    final pageDetail = pageDetailResult.fold((_) => null, (d) => d);

    if (pageDetail == null || pageDetail.ayahs.isEmpty) {
      _emitState(
        _stateNotifier.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'تعذر تحميل آيات الصفحة',
        ),
      );
      return;
    }

    _setQueueFromBase(pageDetail.ayahs);
    final clampedStart =
        startAyahIndex.clamp(0, _baseQueue.length - 1) * _perAyah;

    await _loadPlaylistAndPlay(
      startIndex: clampedStart,
      activeReciter: activeReciter,
    );
  }

  /// Plays a specific ayah.
  ///
  /// When [scope] is [PlayScope.singleAyah], only this ayah is played and
  /// playback stops when it finishes. When [scope] is [PlayScope.surah],
  /// the entire surah is queued starting from this ayah.
  Future<void> playAyah(
    int surahId,
    int ayahNumber, {
    QuranReciter? reciter,
    PlayScope scope = PlayScope.singleAyah,
  }) async {
    if (scope == PlayScope.singleAyah) {
      final activeReciter = _resolveReciter(reciter);
      _activeScope = PlayScope.singleAyah;
      _activeSurahId = surahId;

      _emitState(
        ContinuousPlaybackState(
          status: PlaybackStatus.loading,
          currentSurahId: surahId,
          currentAyahNumber: ayahNumber,
          reciter: activeReciter,
          scope: PlayScope.singleAyah,
        ),
      );

      final surahDetailResult = await _quranRepository.getSurahDetail(surahId);
      final surahDetail = surahDetailResult.fold((_) => null, (d) => d);
      if (surahDetail == null) {
        _emitState(
          _stateNotifier.value.copyWith(
            status: PlaybackStatus.error,
            errorMessage: 'تعذر تحميل الآية',
          ),
        );
        return;
      }

      final ayah = surahDetail.ayahs
          .where((a) => a.numberInSurah == ayahNumber)
          .firstOrNull;
      if (ayah == null) {
        _emitState(
          _stateNotifier.value.copyWith(
            status: PlaybackStatus.error,
            errorMessage: 'تعذر تحميل الآية',
          ),
        );
        return;
      }

      _setQueueFromBase([ayah]);
      await _loadPlaylistAndPlay(startIndex: 0, activeReciter: activeReciter);
      return;
    }

    // Surah continuation mode: if same surah is already queued, jump directly.
    if (_activeScope == PlayScope.surah &&
        _activeSurahId == surahId &&
        _queue.isNotEmpty) {
      final index = _queue.indexWhere((a) => a.numberInSurah == ayahNumber);
      if (index >= 0) {
        _currentIndex = index;
        await _player.seek(Duration.zero, index: index);
        unawaited(_player.play());
        return;
      }
    }
    await playSurah(surahId, startAyah: ayahNumber, reciter: reciter);
  }

  // ---------------------------------------------------------------------------
  // Core: build playlist and play gaplessly
  // ---------------------------------------------------------------------------

  /// Resolves audio sources for [_queue] and calls [AudioPlayer.setAudioSources]
  /// so just_audio pre-buffers consecutive items — eliminating inter-ayah gaps.
  Future<void> _loadPlaylistAndPlay({
    required int startIndex,
    required QuranReciter activeReciter,
  }) async {
    try {
      final backgroundHandler = await _ensureBackgroundAudioHandler();
      await _player.stop();

      final mediaItems = _buildMediaItems(activeReciter);
      final audioSources = _buildAudioSources(activeReciter, mediaItems);

      if (audioSources.isEmpty) {
        _emitState(
          _stateNotifier.value.copyWith(
            status: PlaybackStatus.error,
            errorMessage: 'تعذر تحميل التلاوة',
          ),
        );
        return;
      }

      _currentIndex = startIndex;
      backgroundHandler?.setQueueItems(mediaItems);

      final firstAyah = _queue[startIndex];
      _emitState(
        ContinuousPlaybackState(
          status: PlaybackStatus.loading,
          currentAyah: firstAyah,
          currentSurahId: firstAyah.surahId,
          currentAyahNumber: firstAyah.numberInSurah,
          currentPageNumber: firstAyah.page,
          reciter: activeReciter,
          scope: _activeScope,
          hasNext: _hasNextAyah(),
          hasPrevious: _hasPreviousAyah(),
        ),
      );

      // setAudioSources is the just_audio 0.10+ replacement for
      // ConcatenatingAudioSource — hands the engine a playlist so it can
      // pre-buffer the next item while the current one plays.
      await _player.setAudioSources(
        audioSources,
        initialIndex: startIndex,
        initialPosition: Duration.zero,
      );

      if (_playerSettingsTouched || !_repeat.isDefault) {
        _playerSettingsTouched = true;
        await _applyPlayerSettings();
      }

      // Call play() and immediately emit playing status.
      // Do NOT rely solely on the playerStateStream here: setAudioSources
      // emits ProcessingState.ready with playing=false BEFORE play() takes
      // effect, which would incorrectly set status to paused and then get
      // stuck when the subsequent buffering event is suppressed.
      unawaited(_player.play());
      _emitState(_stateNotifier.value.copyWith(status: PlaybackStatus.playing));
    } catch (e, stack) {
      TaliaLogger.w('Continuous player failed to load playlist', e, stack);
      _emitState(
        _stateNotifier.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'تعذر تشغيل التلاوة',
        ),
      );
    }
  }

  List<MediaItem> _buildMediaItems(QuranReciter activeReciter) {
    return _queue
        .map((ayah) {
          final surahName = SurahNames.arabic[ayah.surahId] ?? 'القرآن الكريم';
          return MediaItem(
            id: '${ayah.surahId}_${ayah.numberInSurah}',
            album: 'القرآن الكريم',
            title: 'سورة $surahName — الآية ${ayah.numberInSurah}',
            artist: activeReciter.name,
          );
        })
        .toList(growable: false);
  }

  /// Builds the just_audio playlist. Metadata is also handed explicitly to
  /// the scoped [QuranBackgroundAudioHandler] for platform media controls.
  List<AudioSource> _buildAudioSources(
    QuranReciter activeReciter,
    List<MediaItem> mediaItems,
  ) {
    return List<AudioSource>.generate(_queue.length, (index) {
      final ayah = _queue[index];
      final url = QuranAudioService.buildUrl(
        ayah.surahId,
        ayah.numberInSurah,
        reciter: activeReciter,
      );
      return AudioSource.uri(Uri.parse(url), tag: mediaItems[index]);
    });
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  Future<void> nextAyah() async {
    if (_hasRepeats) {
      final target = nextDistinctIndex<Ayah>(_queue, _currentIndex);
      if (target != null) await _player.seek(Duration.zero, index: target);
      return;
    }
    if (_currentIndex + 1 < _queue.length) {
      await _player.seekToNext();
    }
  }

  Future<void> previousAyah() async {
    if (_hasRepeats) {
      final target = previousDistinctIndex<Ayah>(_queue, _currentIndex);
      if (target != null) await _player.seek(Duration.zero, index: target);
      return;
    }
    if (_currentIndex > 0) {
      await _player.seekToPrevious();
    }
  }

  // ---------------------------------------------------------------------------
  // Repeat, speed and sleep timer (session-only, never persisted)
  // ---------------------------------------------------------------------------

  ReaderRepeatSettings get repeatSettings => _repeat;

  SleepTimerChoice get sleepChoice => _sleepChoice;

  /// Applies repeat/speed settings. When the repeat counts change during
  /// playback the queue is rebuilt from the current ayah to the end of the
  /// scope that started playback.
  Future<void> setRepeat(ReaderRepeatSettings settings) async {
    final previous = _repeat;
    if (settings == previous) return;
    _repeat = settings;
    final needsRebuild =
        previous.perAyah != settings.perAyah ||
        previous.rangeTimes != settings.rangeTimes;
    final hasQueue =
        _queue.isNotEmpty && _currentIndex >= 0 && _currentIndex < _queue.length;

    if (!hasQueue) {
      _emitState(_stateNotifier.value);
      return;
    }

    try {
      if (needsRebuild) {
        final current = _queue[_currentIndex];
        var baseIndex = _baseQueue.indexOf(current);
        if (baseIndex < 0) baseIndex = 0;
        final wasPaused = _stateNotifier.value.isPaused;
        _queue = expandRepeatQueue<Ayah>(
          _baseQueue.sublist(baseIndex),
          _repeat,
        );
        await _loadPlaylistAndPlay(
          startIndex: 0,
          activeReciter: _resolveReciter(_stateNotifier.value.reciter),
        );
        if (wasPaused) await pause();
      } else {
        _playerSettingsTouched = true;
        await _player.setSpeed(_repeat.normalizedSpeed);
        _emitState(_stateNotifier.value);
      }
    } catch (e, stack) {
      TaliaLogger.w('Continuous player setRepeat failed', e, stack);
    }
  }

  /// Starts, replaces or cancels the sleep timer. [SleepTimerChoice.endOfSurah]
  /// stops after the last ayah of the surah playing right now.
  Future<void> setSleepTimer(SleepTimerChoice choice) async {
    _sleepTimer.cancel();
    _sleepSurahId = null;
    switch (choice) {
      case SleepTimerChoice.off:
        break;
      case SleepTimerChoice.min15:
        _sleepTimer.start(const Duration(minutes: 15));
      case SleepTimerChoice.min30:
        _sleepTimer.start(const Duration(minutes: 30));
      case SleepTimerChoice.min60:
        _sleepTimer.start(const Duration(minutes: 60));
      case SleepTimerChoice.endOfSurah:
        _sleepSurahId = _stateNotifier.value.currentSurahId;
        if (_sleepSurahId == null) choice = SleepTimerChoice.off;
    }
    _sleepChoice = choice;
    _emitState(_stateNotifier.value);
  }

  void _resetSession() {
    _sleepTimer.cancel();
    _sleepChoice = SleepTimerChoice.off;
    _sleepSurahId = null;
    _repeat = const ReaderRepeatSettings();
    _baseQueue = [];
  }

  // ---------------------------------------------------------------------------
  // Playback control
  // ---------------------------------------------------------------------------

  Future<void> pause() async {
    try {
      await _player.pause();
      _emitState(_stateNotifier.value.copyWith(status: PlaybackStatus.paused));
    } catch (e, stack) {
      TaliaLogger.w('Continuous player pause failed', e, stack);
    }
  }

  Future<void> resume() async {
    try {
      unawaited(_player.play());
      _emitState(_stateNotifier.value.copyWith(status: PlaybackStatus.playing));
    } catch (e, stack) {
      TaliaLogger.w('Continuous player resume failed', e, stack);
    }
  }

  Future<void> togglePlayPause() async {
    final currentStatus = _stateNotifier.value.status;
    switch (currentStatus) {
      case PlaybackStatus.playing:
        await pause();
      case PlaybackStatus.paused:
        await resume();
      case PlaybackStatus.loading:
        await stop();
      case PlaybackStatus.error:
        await stop();
      case PlaybackStatus.idle:
        break;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      if (_playerSettingsTouched) {
        _playerSettingsTouched = false;
        await _player.setLoopMode(LoopMode.off);
        await _player.setSpeed(1.0);
      }
    } catch (_) {}
    _resetSession();
    _queue = [];
    _currentIndex = -1;
    _backgroundAudioHandler?.clearQueue();
    _emitState(const ContinuousPlaybackState(status: PlaybackStatus.idle));
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> changeReciter(QuranReciter reciter) async {
    if (_stateNotifier.value.reciter == reciter) return;
    _emitState(_stateNotifier.value.copyWith(reciter: reciter));
    if (_stateNotifier.value.hasActiveAudio && _currentIndex >= 0) {
      await _loadPlaylistAndPlay(
        startIndex: _currentIndex,
        activeReciter: reciter,
      );
    }
  }

  void dispose() {
    AudioLifecycleManager.instance.unregister(_player);
    if (_sleepChoice != SleepTimerChoice.off) _sleepTimer.cancel();
    _currentIndexSub?.cancel();
    _playerStateSub?.cancel();
    unawaited(_backgroundAudioHandler?.disposeHandler());
    unawaited(_player.dispose());
    _stateNotifier.dispose();
  }

  Future<QuranBackgroundAudioHandler?> _ensureBackgroundAudioHandler() {
    if (!_enableBackgroundAudioIntegration) {
      return Future<QuranBackgroundAudioHandler?>.value(null);
    }
    return _backgroundAudioInitialization ??= _initializeBackgroundAudio();
  }

  Future<QuranBackgroundAudioHandler?> _initializeBackgroundAudio() async {
    try {
      final handler = await AudioService.init<QuranBackgroundAudioHandler>(
        builder: () => QuranBackgroundAudioHandler(
          player: _player,
          onPlay: resume,
          onPause: pause,
          onStop: stop,
          onNext: nextAyah,
          onPrevious: previousAyah,
          onSeek: seek,
        ),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.talia.quran.channel.audio',
          androidNotificationChannelName: 'تلاوة القرآن الكريم',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'drawable/ic_notification',
        ),
      );
      _backgroundAudioHandler = handler;
      return handler;
    } catch (error, stack) {
      TaliaLogger.w(
        'Failed to initialize scoped Quran background audio',
        error,
        stack,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _hasNextAyah() {
    if (_activeScope == PlayScope.singleAyah || _currentIndex < 0) return false;
    if (_hasRepeats) {
      return nextDistinctIndex<Ayah>(_queue, _currentIndex) != null;
    }
    return _currentIndex < _queue.length - 1;
  }

  bool _hasPreviousAyah() {
    if (_activeScope == PlayScope.singleAyah || _currentIndex <= 0) return false;
    if (_hasRepeats) {
      return previousDistinctIndex<Ayah>(_queue, _currentIndex) != null;
    }
    return true;
  }
}
