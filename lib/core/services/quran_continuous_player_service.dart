import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/surah_names.dart';
import '../utils/talia_logger.dart';
import 'audio_lifecycle_manager.dart';
import 'quran_audio_service.dart';
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
    required QuranRepository quranRepository,
    required QuranReciterService reciterService,
    AudioPlayer? player,
  }) : _quranRepository = quranRepository,
       _reciterService = reciterService,
       _player = player ?? AudioPlayer() {
    AudioLifecycleManager.instance.register(_player);
    _initPlayerListeners();
  }

  final QuranRepository _quranRepository;
  final QuranReciterService _reciterService;
  final AudioPlayer _player;

  final ValueNotifier<ContinuousPlaybackState> _stateNotifier =
      ValueNotifier<ContinuousPlaybackState>(const ContinuousPlaybackState());

  ValueListenable<ContinuousPlaybackState> get stateNotifier => _stateNotifier;
  ContinuousPlaybackState get state => _stateNotifier.value;

  List<Ayah> _queue = [];
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
    _stateNotifier.value = newState;
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

    _queue = List<Ayah>.from(surahDetail.ayahs);
    var startIndex = _queue.indexWhere((a) => a.numberInSurah == startAyah);
    if (startIndex < 0) startIndex = 0;

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

    _queue = List<Ayah>.from(pageDetail.ayahs);
    final clampedStart = startAyahIndex.clamp(0, _queue.length - 1);

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

      _queue = [ayah];
      await _loadPlaylistAndPlay(
        startIndex: 0,
        activeReciter: activeReciter,
      );
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
      await _player.stop();

      final audioSources = _buildAudioSources(activeReciter);

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
          hasNext: startIndex < _queue.length - 1,
          hasPrevious: startIndex > 0,
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

  /// Builds a list of [AudioSource] for every ayah in [_queue].
  /// Uses [AudioSource.uri] so just_audio streams and caches each file.
  List<AudioSource> _buildAudioSources(QuranReciter activeReciter) {
    return _queue.map((ayah) {
      final url = QuranAudioService.buildUrl(
        ayah.surahId,
        ayah.numberInSurah,
        reciter: activeReciter,
      );
      return AudioSource.uri(Uri.parse(url));
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  Future<void> nextAyah() async {
    if (_currentIndex + 1 < _queue.length) {
      await _player.seekToNext();
    }
  }

  Future<void> previousAyah() async {
    if (_currentIndex > 0) {
      await _player.seekToPrevious();
    }
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
    } catch (_) {}
    _queue = [];
    _currentIndex = -1;
    _emitState(const ContinuousPlaybackState(status: PlaybackStatus.idle));
  }

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
    _currentIndexSub?.cancel();
    _playerStateSub?.cancel();
    unawaited(_player.dispose());
    _stateNotifier.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _hasNextAyah() {
    return _activeScope != PlayScope.singleAyah &&
        _currentIndex >= 0 &&
        _currentIndex < _queue.length - 1;
  }

  bool _hasPreviousAyah() {
    return _activeScope != PlayScope.singleAyah && _currentIndex > 0;
  }
}
