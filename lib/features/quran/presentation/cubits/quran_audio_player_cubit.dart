import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/quran_continuous_player_service.dart';
import '../../../../core/services/quran_reciter.dart';
import '../../domain/entities/quran_entities.dart';

class QuranAudioPlayerState extends Equatable {
  const QuranAudioPlayerState({
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

  factory QuranAudioPlayerState.fromContinuous(ContinuousPlaybackState s) {
    return QuranAudioPlayerState(
      status: s.status,
      currentAyah: s.currentAyah,
      currentSurahId: s.currentSurahId,
      currentAyahNumber: s.currentAyahNumber,
      currentPageNumber: s.currentPageNumber,
      reciter: s.reciter,
      scope: s.scope,
      errorMessage: s.errorMessage,
      hasNext: s.hasNext,
      hasPrevious: s.hasPrevious,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentAyah,
        currentSurahId,
        currentAyahNumber,
        currentPageNumber,
        reciter,
        scope,
        errorMessage,
        hasNext,
        hasPrevious,
      ];
}

class QuranAudioPlayerCubit extends Cubit<QuranAudioPlayerState> {
  QuranAudioPlayerCubit(this._playerService)
      : super(QuranAudioPlayerState.fromContinuous(_playerService.state)) {
    _playerService.stateNotifier.addListener(_onServiceStateChanged);
  }

  final QuranContinuousPlayerService _playerService;

  void _onServiceStateChanged() {
    emit(QuranAudioPlayerState.fromContinuous(_playerService.state));
  }

  Future<void> playSurah(
    int surahId, {
    int startAyah = 1,
    QuranReciter? reciter,
  }) async {
    // If already actively playing/paused for this Surah, toggle play/pause
    if (state.currentSurahId == surahId &&
        state.scope == PlayScope.surah &&
        (state.isPlaying || state.isPaused)) {
      await togglePlayPause();
      return;
    }
    await _playerService.playSurah(surahId, startAyah: startAyah, reciter: reciter);
  }

  Future<void> playPage(
    int pageNumber, {
    int startAyahIndex = 0,
    QuranReciter? reciter,
  }) async {
    if (state.currentPageNumber == pageNumber &&
        state.scope == PlayScope.page &&
        state.hasActiveAudio) {
      await togglePlayPause();
      return;
    }
    await _playerService.playPage(pageNumber, startAyahIndex: startAyahIndex, reciter: reciter);
  }

  Future<void> playAyah(
    int surahId,
    int ayahNumber, {
    QuranReciter? reciter,
    PlayScope scope = PlayScope.singleAyah,
  }) async {
    await _playerService.playAyah(surahId, ayahNumber, reciter: reciter, scope: scope);
  }

  Future<void> pause() => _playerService.pause();

  Future<void> resume() => _playerService.resume();

  Future<void> togglePlayPause() => _playerService.togglePlayPause();

  Future<void> nextAyah() => _playerService.nextAyah();

  Future<void> previousAyah() => _playerService.previousAyah();

  Future<void> stop() => _playerService.stop();

  Future<void> changeReciter(QuranReciter reciter) =>
      _playerService.changeReciter(reciter);

  @override
  Future<void> close() {
    _playerService.stateNotifier.removeListener(_onServiceStateChanged);
    return super.close();
  }
}
