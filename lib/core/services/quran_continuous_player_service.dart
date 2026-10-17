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
    this.isSurahQueue = false,
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

  /// True while a [QuranContinuousPlayerService.playSurahQueue] session (kids
  /// bedtime) owns playback; adult surfaces must not record its position.
  final bool isSurahQueue;

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
    bool? isSurahQueue,
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
      isSurahQueue: isSurahQueue ?? this.isSurahQueue,
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

  /// Queue items removed after the surah end while endOfSurah is active.
  List<Ayah> _tail = [];
  Future<void> _sleepOps = Future<void>.value();
  late final SleepTimer _sleepTimer;
  bool _playerSettingsTouched = false;
  int _currentIndex = -1;
  PlayScope _activeScope = PlayScope.surah;
  int? _activeSurahId;

  /// True while a [playSurahQueue] session owns the player. Its settings never
  /// carry over to the reader, and endOfSurah means the end of the queue.
  bool _surahQueueMode = false;

  /// Bumped by every playlist load and every [stop]; an older load that sees
  /// a newer value never starts playback.
  int _playbackGeneration = 0;

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
      _currentIndex = index;
      final ayah = _queue[index];
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
          // A playlist that finished loading after stop() has no session.
          if (_queue.isEmpty) return;
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
      isSurahQueue: _surahQueueMode,
    );
  }

  int get _perAyah => _repeat.perAyah.clamp(1, 10);

  bool get _hasRepeats => _perAyah > 1 || _repeat.rangeTimes > 1;

  void _setQueueFromBase(List<Ayah> base) {
    _baseQueue = List<Ayah>.from(base);
    _queue = expandRepeatQueue<Ayah>(_baseQueue, _repeat);
  }

  bool get _endOfSurahActive => _sleepChoice == SleepTimerChoice.endOfSurah;

  LoopMode get _loopMode => _repeat.rangeTimes == 0 && !_endOfSurahActive
      ? LoopMode.all
      : LoopMode.off;

  /// Index of the last item of the contiguous run of [surahId] that contains
  /// [from] in [_queue].
  int _lastIndexOfSurahRun(int from, int surahId) {
    var last = from;
    while (last + 1 < _queue.length && _queue[last + 1].surahId == surahId) {
      last++;
    }
    return last;
  }

  /// Last index endOfSurah may play when anchored at [from]: the end of the
  /// current surah run, or the end of the whole queue in [playSurahQueue].
  int _endOfSurahLastIndex(int from) {
    if (_surahQueueMode) return _queue.length - 1;
    return _lastIndexOfSurahRun(from, _queue[from].surahId);
  }

  /// Resets reader settings when [applyReaderSettings] is false, or when a
  /// [playSurahQueue] session's settings would otherwise leak into this one.
  Future<bool> _prepareSession(bool applyReaderSettings) async {
    final leavingQueue = _surahQueueMode;
    _surahQueueMode = false;
    if (applyReaderSettings && !leavingQueue) return false;
    return _resetReaderSettings();
  }

  Future<void> _applyPlayerSettings() async {
    await _player.setLoopMode(_loopMode);
    await _player.setSpeed(_repeat.normalizedSpeed);
  }

  QuranReciter _resolveReciter(QuranReciter? reciter) {
    return reciter ?? _reciterService.currentReciter.value;
  }

  // ---------------------------------------------------------------------------
  // Public playback API
  // ---------------------------------------------------------------------------

  /// Plays an entire Surah starting from [startAyah].
  ///
  /// Repeat, speed and the sleep choice belong to the adult reader. Playback
  /// from any other surface leaves [applyReaderSettings] false, which resets
  /// them to their defaults before loading.
  Future<void> playSurah(
    int surahId, {
    int startAyah = 1,
    QuranReciter? reciter,
    bool applyReaderSettings = false,
  }) async {
    await _prepareSession(applyReaderSettings);
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

  /// Plays [surahIds] in order (each whole surah), resetting reader repeat and
  /// speed, then applies [sleep]. [SleepTimerChoice.endOfSurah] here means the
  /// end of the LAST surah, i.e. the end of the queue. The session's settings
  /// are never inherited by later reader playback.
  Future<void> playSurahQueue(
    List<int> surahIds, {
    SleepTimerChoice sleep = SleepTimerChoice.off,
  }) async {
    await _prepareSession(false);
    // Owner check after the await: a newer play call clears the flag.
    _surahQueueMode = true;
    final generation = _playbackGeneration;
    final activeReciter = _resolveReciter(null);
    _activeScope = PlayScope.surah;
    _activeSurahId = null;

    _emitState(
      ContinuousPlaybackState(
        status: PlaybackStatus.loading,
        currentSurahId: surahIds.isEmpty ? null : surahIds.first,
        currentAyahNumber: 1,
        reciter: activeReciter,
        scope: PlayScope.surah,
      ),
    );

    final ayahs = <Ayah>[];
    for (final surahId in surahIds) {
      final result = await _quranRepository.getSurahDetail(surahId);
      final detail = result.fold((_) => null, (d) => d);
      if (detail != null) ayahs.addAll(detail.ayahs);
    }
    // Stopped or superseded while the surahs were loading.
    if (!_surahQueueMode || generation != _playbackGeneration) return;

    if (ayahs.isEmpty) {
      _emitState(
        _stateNotifier.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'تعذر تحميل آيات السورة',
        ),
      );
      return;
    }

    _setQueueFromBase(ayahs);
    final started = await _loadPlaylistAndPlay(
      startIndex: 0,
      activeReciter: activeReciter,
    );
    if (!started || !_surahQueueMode || _stateNotifier.value.isError) return;
    if (sleep != SleepTimerChoice.off) await setSleepTimer(sleep);
  }

  /// Plays all ayahs on a Mushaf page [pageNumber] in sequence.
  Future<void> playPage(
    int pageNumber, {
    int startAyahIndex = 0,
    QuranReciter? reciter,
    bool applyReaderSettings = false,
  }) async {
    await _prepareSession(applyReaderSettings);
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
    bool applyReaderSettings = false,
  }) async {
    final wasReset = await _prepareSession(applyReaderSettings);
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
    if (!wasReset &&
        _activeScope == PlayScope.surah &&
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
    await playSurah(
      surahId,
      startAyah: ayahNumber,
      reciter: reciter,
      applyReaderSettings: true, // already reset above when it was needed
    );
  }

  // ---------------------------------------------------------------------------
  // Core: build playlist and play gaplessly
  // ---------------------------------------------------------------------------

  /// Resolves audio sources for [_queue] and calls [AudioPlayer.setAudioSources]
  /// so just_audio pre-buffers consecutive items — eliminating inter-ayah gaps.
  ///
  /// Returns false when the load failed or was superseded by a newer load or
  /// a [stop] while it was waiting; such a load never calls play().
  Future<bool> _loadPlaylistAndPlay({
    required int startIndex,
    required QuranReciter activeReciter,
    bool play = true,
  }) async {
    final generation = ++_playbackGeneration;
    try {
      // A new queue always starts complete; endOfSurah re-anchors to the
      // surah of the ayah that starts and cuts the queue after its last item.
      _tail = [];
      if (_endOfSurahActive && startIndex >= 0 && startIndex < _queue.length) {
        final last = _endOfSurahLastIndex(startIndex);
        _tail = _queue.sublist(last + 1);
        _queue = _queue.sublist(0, last + 1);
      }
      final backgroundHandler = await _ensureBackgroundAudioHandler();
      await _player.stop();
      if (await _loadSuperseded(generation)) return false;

      final mediaItems = _buildMediaItems(activeReciter);
      final audioSources = _buildAudioSources(activeReciter, mediaItems);

      if (audioSources.isEmpty) {
        _emitState(
          _stateNotifier.value.copyWith(
            status: PlaybackStatus.error,
            errorMessage: 'تعذر تحميل التلاوة',
          ),
        );
        return false;
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
      if (await _loadSuperseded(generation)) return false;

      if (_playerSettingsTouched || !_repeat.isDefault || _endOfSurahActive) {
        _playerSettingsTouched = true;
        await _applyPlayerSettings();
      }
      if (await _loadSuperseded(generation)) return false;

      // Call play() and immediately emit playing status.
      // Do NOT rely solely on the playerStateStream here: setAudioSources
      // emits ProcessingState.ready with playing=false BEFORE play() takes
      // effect, which would incorrectly set status to paused and then get
      // stuck when the subsequent buffering event is suppressed.
      if (play) {
        unawaited(_player.play());
        _emitState(
          _stateNotifier.value.copyWith(status: PlaybackStatus.playing),
        );
      } else {
        await _player.pause();
        _emitState(
          _stateNotifier.value.copyWith(status: PlaybackStatus.paused),
        );
      }
      return true;
    } catch (e, stack) {
      TaliaLogger.w('Continuous player failed to load playlist', e, stack);
      if (generation != _playbackGeneration) return false;
      _emitState(
        _stateNotifier.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'تعذر تشغيل التلاوة',
        ),
      );
      return false;
    }
  }

  /// True when a newer load or a [stop] happened since [generation] started.
  /// After a stop with nothing newer queued, the half-loaded playlist is
  /// unloaded and the idle state restored (setAudioSources may have reported
  /// ready in the meantime).
  Future<bool> _loadSuperseded(int generation) async {
    if (generation == _playbackGeneration) return false;
    if (_queue.isEmpty) {
      try {
        await _player.stop();
      } catch (_) {}
      if (_queue.isEmpty) {
        _emitState(const ContinuousPlaybackState(status: PlaybackStatus.idle));
      }
    }
    return true;
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
        _queue.isNotEmpty &&
        _currentIndex >= 0 &&
        _currentIndex < _queue.length;

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
          play: !wasPaused,
        );
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
  /// stops after the last ayah of the surah playing right now (in a
  /// [playSurahQueue] session: after the last ayah of the queue).
  Future<void> setSleepTimer(SleepTimerChoice choice) {
    // Serialized: queue edits for quick consecutive choices must not interleave.
    final run = _sleepOps.then((_) => _applySleepChoice(choice));
    _sleepOps = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> _applySleepChoice(SleepTimerChoice choice) async {
    final wasEndOfSurah = _endOfSurahActive;
    _sleepTimer.cancel();
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
        break;
    }
    final hasQueue =
        _queue.isNotEmpty &&
        _currentIndex >= 0 &&
        _currentIndex < _queue.length;
    if (choice == SleepTimerChoice.endOfSurah && !hasQueue) {
      choice = SleepTimerChoice.off;
    }
    _sleepChoice = choice;
    try {
      if (choice == SleepTimerChoice.endOfSurah && !wasEndOfSurah) {
        await _truncateAtSurahEnd();
      } else if (choice != SleepTimerChoice.endOfSurah && wasEndOfSurah) {
        await _restoreTail();
      }
    } catch (e, stack) {
      TaliaLogger.w(
        'Continuous player sleep timer queue update failed',
        e,
        stack,
      );
    }
    _emitState(_stateNotifier.value);
  }

  /// Cuts the playlist after the last item of the surah playing now, so the
  /// player completes exactly at the surah end (no next-surah ayah starts).
  /// The queue is cut before the first await and rolled back on failure.
  Future<void> _truncateAtSurahEnd() async {
    final last = _endOfSurahLastIndex(_currentIndex);
    final loopWasAll = _repeat.rangeTimes == 0;
    var loopSet = false;
    if (last + 1 < _queue.length) {
      final previousQueue = _queue;
      final previousTail = _tail;
      _tail = _queue.sublist(last + 1);
      _queue = _queue.sublist(0, last + 1);
      try {
        // Loop off first: with LoopMode.all the last item could wrap to
        // index 0 while the tail is being removed.
        if (loopWasAll) {
          _playerSettingsTouched = true;
          await _player.setLoopMode(LoopMode.off);
          loopSet = true;
        }
        await _player.removeAudioSourceRange(last + 1, previousQueue.length);
      } catch (_) {
        _queue = previousQueue;
        _tail = previousTail;
        if (loopWasAll) {
          try {
            await _player.setLoopMode(LoopMode.all);
          } catch (_) {}
        }
        rethrow;
      }
      _backgroundAudioHandler?.setQueueItems(
        _buildMediaItems(_activeReciterOrDefault()),
      );
    }
    if (loopWasAll && !loopSet) {
      _playerSettingsTouched = true;
      await _player.setLoopMode(LoopMode.off);
    }
    _emitState(
      _stateNotifier.value.copyWith(
        hasNext: _hasNextAyah(),
        hasPrevious: _hasPreviousAyah(),
      ),
    );
  }

  Future<void> _restoreTail() async {
    if (_tail.isNotEmpty) {
      final reciter = _activeReciterOrDefault();
      final previousQueue = _queue;
      final previousTail = _tail;
      final offset = previousQueue.length;
      _queue = [...previousQueue, ...previousTail];
      _tail = [];
      try {
        final items = _buildMediaItems(reciter);
        final sources = _buildAudioSources(reciter, items);
        await _player.addAudioSources(sources.sublist(offset));
        _backgroundAudioHandler?.setQueueItems(items);
      } catch (_) {
        _queue = previousQueue;
        _tail = previousTail;
        rethrow;
      }
    }
    if (_repeat.rangeTimes == 0) {
      await _player.setLoopMode(LoopMode.all);
    }
    _emitState(
      _stateNotifier.value.copyWith(
        hasNext: _hasNextAyah(),
        hasPrevious: _hasPreviousAyah(),
      ),
    );
  }

  QuranReciter _activeReciterOrDefault() =>
      _resolveReciter(_stateNotifier.value.reciter);

  /// Returns repeat, speed, loop and the sleep choice to their defaults when a
  /// non-reader surface starts playback. Returns false (and does nothing)
  /// while nothing was changed.
  Future<bool> _resetReaderSettings() async {
    if (_repeat.isDefault &&
        _sleepChoice == SleepTimerChoice.off &&
        !_playerSettingsTouched) {
      return false;
    }
    _resetSession();
    if (_playerSettingsTouched) {
      _playerSettingsTouched = false;
      try {
        await _player.setLoopMode(LoopMode.off);
        await _player.setSpeed(1.0);
      } catch (_) {}
    }
    return true;
  }

  void _resetSession() {
    _sleepTimer.cancel();
    _sleepChoice = SleepTimerChoice.off;
    _tail = [];
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
    _playbackGeneration++;
    try {
      await _player.stop();
      if (_playerSettingsTouched) {
        _playerSettingsTouched = false;
        await _player.setLoopMode(LoopMode.off);
        await _player.setSpeed(1.0);
      }
    } catch (_) {}
    _resetSession();
    _surahQueueMode = false;
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
      // Rejoin an endOfSurah tail first; the reload cuts it again.
      if (_tail.isNotEmpty) {
        _queue = [..._queue, ..._tail];
        _tail = [];
      }
      await _loadPlaylistAndPlay(
        startIndex: _currentIndex,
        activeReciter: reciter,
        play: !_stateNotifier.value.isPaused,
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
    if (_activeScope == PlayScope.singleAyah || _currentIndex <= 0) {
      return false;
    }
    if (_hasRepeats) {
      return previousDistinctIndex<Ayah>(_queue, _currentIndex) != null;
    }
    return true;
  }
}
