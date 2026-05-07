import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/services/achievement_service.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

import '../../../../core/services/quran_audio_service.dart';
import '../../../../features/quran/domain/repositories/quran_repository.dart';

part 'kids_mode_state.dart';

class KidsModeCubit extends Cubit<KidsModeState> {
  KidsModeCubit(
    this._getKidsProgress,
    this._awardPoints,
    this._markAyahMemorized,
    this._achievementService,
    this._quranRepository,
  ) : super(const KidsModeInitial()) {
    _player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        _onPlaybackCompleted();
      }
    });
  }

  final GetKidsProgressUsecase _getKidsProgress;
  final AwardKidsPointsUsecase _awardPoints;
  final MarkAyahMemorizedUsecase _markAyahMemorized;
  final AchievementService _achievementService;
  final QuranRepository _quranRepository;
  final AudioPlayer _player = AudioPlayer();

  int _loopCount = 0;
  static const int _maxLoops = 3;

  Future<void> load(int surahId, int ayahNumber, String ayahText) async {
    emit(const KidsModeLoading());

    String resolvedText = ayahText;
    if (resolvedText.isEmpty ||
        resolvedText == '...' ||
        resolvedText == 'النص غير متوفر') {
      try {
        final result = await _quranRepository.getSurahDetail(surahId);
        result.fold((_) {}, (detail) {
          resolvedText = detail.ayahs
              .firstWhere((a) => a.numberInSurah == ayahNumber)
              .text;
        });
      } catch (_) {}
      if (resolvedText.isEmpty || resolvedText == '...') {
        resolvedText = 'النص غير متوفر';
      }
    }

    final progressResult = await _getKidsProgress();
    final progress = progressResult.fold(
      (_) => const KidsProgress.initial(),
      (p) => p,
    );

    emit(
      KidsModeLoaded(
        surahId: surahId,
        ayahNumber: ayahNumber,
        ayahText: resolvedText,
        progress: progress,
        isPlaying: false,
        currentLoop: 0,
        maxLoops: _maxLoops,
        isCompleted: false,
      ),
    );
  }

  Future<void> playAudio() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;

    _loopCount = 0;
    emit(st.copyWith(isPlaying: true, currentLoop: 1));
    await _playAyah(st.surahId, st.ayahNumber);
  }

  Future<void> _playAyah(int surahId, int ayahNumber) async {
    try {
      final url = QuranAudioService.buildUrl(surahId, ayahNumber);
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {
      if (state is KidsModeLoaded) {
        emit((state as KidsModeLoaded).copyWith(isPlaying: false));
      }
    }
  }

  void _onPlaybackCompleted() {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;

    _loopCount++;
    if (_loopCount < _maxLoops) {
      emit(st.copyWith(currentLoop: _loopCount + 1));
      _playAyah(st.surahId, st.ayahNumber);
    } else {
      emit(st.copyWith(isPlaying: false, currentLoop: _maxLoops));
    }
  }

  Future<void> stopAudio() async {
    await _player.stop();
    if (state is KidsModeLoaded) {
      emit((state as KidsModeLoaded).copyWith(isPlaying: false));
    }
  }

  Future<void> markCompleted() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;

    final result = await _awardPoints(
      AwardKidsPointsParams(
        surahId: st.surahId,
        ayahNumber: st.ayahNumber,
        repeatsCompleted: _loopCount,
      ),
    );

    final updated = result.fold<KidsProgress?>((f) {
      emit(KidsModeError(f.message));
      return null;
    }, (progress) => progress);
    if (updated == null) return;

    final markResult = await _markAyahMemorized(
      MarkAyahMemorizedParams(surahId: st.surahId, ayahNumber: st.ayahNumber),
    );
    final markFailure = markResult.fold((f) => f, (_) => null);
    if (markFailure != null) {
      emit(KidsModeError(markFailure.message));
      return;
    }

    final newAwards = await _achievementService.checkAndUnlockCertificates();
    emit(
      st.copyWith(progress: updated, isCompleted: true, newAwards: newAwards),
    );
  }

  @override
  Future<void> close() {
    _player.dispose();
    return super.close();
  }
}
