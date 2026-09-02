import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/surah_names.dart';
import '../utils/talia_logger.dart';
import 'audio_cache_service.dart';
import 'audio_lifecycle_manager.dart';
import 'quran_reciter.dart';
import 'quran_reciter_service.dart';
import '../../features/quran/domain/entities/quran_entities.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';

enum PlaybackStatus { idle, loading, playing, paused, error }

enum PlayScope { surah, page, singleAyah }

typedef QuranAudioSourceResolver =
    Future<String> Function(Ayah ayah, QuranReciter reciter);

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

class QuranContinuousPlayerService {
  QuranContinuousPlayerService({
    required QuranRepository quranRepository,
    required QuranReciterService reciterService,
    AudioPlayer? player,
    QuranAudioSourceResolver? audioSourceResolver,
  }) : _quranRepository = quranRepository,
       _reciterService = reciterService,
       _player = player ?? AudioPlayer(),
       _audioSourceResolver =
           audioSourceResolver ?? _resolveDefaultAudioSource {
    AudioLifecycleManager.instance.register(_player);
    _initPlayerListeners();
  }

  final QuranRepository _quranRepository;
  final QuranReciterService _reciterService;
  final AudioPlayer _player;
  final QuranAudioSourceResolver _audioSourceResolver;

  static Future<String> _resolveDefaultAudioSource(
    Ayah ayah,
    QuranReciter reciter,
  ) {
    return AudioCacheService.instance.getAudioSource(
      ayah.surahId,
      ayah.numberInSurah,
      reciter: reciter,
    );
  }

  final ValueNotifier<ContinuousPlaybackState> _stateNotifier =
      ValueNotifier<ContinuousPlaybackState>(const ContinuousPlaybackState());

  ValueListenable<ContinuousPlaybackState> get stateNotifier => _stateNotifier;
  ContinuousPlaybackState get state => _stateNotifier.value;

  List<Ayah> _queue = [];
  int _currentIndex = -1;
  PlayScope _activeScope = PlayScope.surah;
  int? _activeSurahId;
  StreamSubscription<PlayerState>? _playerStateSub;
  bool _isTransitioning = false;

  void _initPlayerListeners() {
    _playerStateSub = _player.playerStateStream.listen((playerState) {
      if (_isTransitioning) return;

      if (playerState.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      } else if (playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering) {
        if (_stateNotifier.value.status != PlaybackStatus.loading &&
            _stateNotifier.value.status != PlaybackStatus.idle) {
          _emitState(
            _stateNotifier.value.copyWith(status: PlaybackStatus.loading),
          );
        }
      } else if (playerState.processingState == ProcessingState.ready) {
        if (playerState.playing) {
          _emitState(
            _stateNotifier.value.copyWith(status: PlaybackStatus.playing),
          );
        } else {
          _emitState(
            _stateNotifier.value.copyWith(status: PlaybackStatus.paused),
          );
        }
      }
    });
  }

  void _handleTrackCompletion() {
    if (_isTransitioning) return;
    unawaited(_onAyahCompleted());
  }

  void _emitState(ContinuousPlaybackState newState) {
    _stateNotifier.value = newState;
  }

  QuranReciter _resolveReciter(QuranReciter? reciter) {
    return reciter ?? _reciterService.currentReciter.value;
  }

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
    final surahDetail = surahDetailResult.fold((_) => null, (detail) => detail);

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
    _currentIndex = startIndex;

    await _playCurrentQueueIndex();
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
    final pageDetail = pageDetailResult.fold((_) => null, (detail) => detail);

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
    _currentIndex = startAyahIndex.clamp(0, _queue.length - 1);

    await _playCurrentQueueIndex();
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
      // Single ayah mode: queue only this one ayah
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

      final ayah = surahDetail.ayahs.where(
        (a) => a.numberInSurah == ayahNumber,
      );
      if (ayah.isEmpty) {
        _emitState(
          _stateNotifier.value.copyWith(
            status: PlaybackStatus.error,
            errorMessage: 'تعذر تحميل الآية',
          ),
        );
        return;
      }

      _queue = [ayah.first];
      _currentIndex = 0;
      await _playCurrentQueueIndex();
      return;
    }

    // Surah continuation mode: queue entire surah from this ayah
    if (_activeScope == PlayScope.surah &&
        _activeSurahId == surahId &&
        _queue.isNotEmpty) {
      final index = _queue.indexWhere((a) => a.numberInSurah == ayahNumber);
      if (index >= 0) {
        _currentIndex = index;
        await _playCurrentQueueIndex();
        return;
      }
    }
    await playSurah(surahId, startAyah: ayahNumber, reciter: reciter);
  }

  Future<void> _playCurrentQueueIndex() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) {
      await stop();
      return;
    }

    final ayah = _queue[_currentIndex];
    final activeReciter =
        _stateNotifier.value.reciter ?? _reciterService.currentReciter.value;

    _isTransitioning = true;
    _emitState(
      ContinuousPlaybackState(
        status: PlaybackStatus.loading,
        currentAyah: ayah,
        currentSurahId: ayah.surahId,
        currentAyahNumber: ayah.numberInSurah,
        currentPageNumber: ayah.page,
        reciter: activeReciter,
        scope: _activeScope,
        hasNext: _hasNextAyah(),
        hasPrevious: _hasPreviousAyah(),
      ),
    );

    try {
      // A completed source must be reset before loading the next ayah.
      try {
        await _player.stop();
      } catch (_) {}

      final source = await _audioSourceResolver(ayah, activeReciter);

      if (source.startsWith('http://') || source.startsWith('https://')) {
        await _player.setUrl(source);
      } else {
        await _player.setFilePath(source);
      }
      await _player.seek(Duration.zero);

      // just_audio's play Future completes when the track ends, not when it starts.
      final playback = _player.play();
      _isTransitioning = false;
      unawaited(_observePlayback(playback, ayah));

      _emitState(
        _stateNotifier.value.copyWith(
          status: PlaybackStatus.playing,
          currentAyah: ayah,
          currentSurahId: ayah.surahId,
          currentAyahNumber: ayah.numberInSurah,
          currentPageNumber: ayah.page,
          hasNext: _hasNextAyah(),
          hasPrevious: _hasPreviousAyah(),
        ),
      );

      _prefetchNextAyahs();
    } catch (e, stack) {
      _isTransitioning = false;
      TaliaLogger.w(
        'Continuous player playback failed for Surah ${ayah.surahId}:${ayah.numberInSurah}',
        e,
        stack,
      );
      _emitState(
        _stateNotifier.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'تعذر تشغيل التلاوة',
        ),
      );
    }
  }

  Future<void> _observePlayback(Future<void> playback, Ayah ayah) async {
    try {
      await playback;
    } catch (error, stack) {
      final currentAyah = _stateNotifier.value.currentAyah;
      final isStillCurrent =
          currentAyah?.surahId == ayah.surahId &&
          currentAyah?.numberInSurah == ayah.numberInSurah;
      if (!isStillCurrent || _stateNotifier.value.isIdle) return;

      TaliaLogger.w(
        'Continuous player failed during Surah '
        '${ayah.surahId}:${ayah.numberInSurah}',
        error,
        stack,
      );
      _emitState(
        _stateNotifier.value.copyWith(
          status: PlaybackStatus.error,
          errorMessage: 'تعذر تشغيل التلاوة',
        ),
      );
    }
  }

  bool _hasNextAyah() {
    return _activeScope != PlayScope.singleAyah &&
        _currentIndex >= 0 &&
        _currentIndex < _queue.length - 1;
  }

  bool _hasPreviousAyah() {
    return _activeScope != PlayScope.singleAyah && _currentIndex > 0;
  }

  void _prefetchNextAyahs() {
    for (int offset = 1; offset <= 2; offset++) {
      if (_currentIndex + offset < _queue.length) {
        final nextAyah = _queue[_currentIndex + offset];
        final activeReciter =
            _stateNotifier.value.reciter ??
            _reciterService.currentReciter.value;
        unawaited(_audioSourceResolver(nextAyah, activeReciter));
      }
    }
  }

  Future<void> _onAyahCompleted() async {
    if (_currentIndex + 1 >= _queue.length) {
      await stop();
      return;
    }

    _currentIndex++;
    await _playCurrentQueueIndex();
  }

  Future<void> nextAyah() async {
    if (_currentIndex + 1 < _queue.length) {
      _currentIndex++;
      await _playCurrentQueueIndex();
    }
  }

  Future<void> previousAyah() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await _playCurrentQueueIndex();
    }
  }

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
        // While loading, stop entirely (pause on loading player can throw)
        await stop();
      case PlaybackStatus.error:
        // In error state, just reset
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
      await _playCurrentQueueIndex();
    }
  }

  void dispose() {
    AudioLifecycleManager.instance.unregister(_player);
    _playerStateSub?.cancel();
    unawaited(_player.dispose());
    _stateNotifier.dispose();
  }
}
