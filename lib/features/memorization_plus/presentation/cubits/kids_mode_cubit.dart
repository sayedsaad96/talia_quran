import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/streak_service.dart'; // RISK-5 FIX
import '../../../../core/services/xp_service.dart'; // RISK-5 FIX
import '../../domain/entities/memorization_entities.dart';
import '../../domain/usecases/memorization_plus_usecases.dart';

import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/services/quran_audio_service.dart';
import '../../../../features/quran/domain/repositories/quran_repository.dart';

part 'kids_mode_state.dart';

class KidsModeCubit extends Cubit<KidsModeState> {
  KidsModeCubit(
    this._getKidsProgress,
    this._awardPoints,
    this._markAyahMemorized,
    this._saveKidsSessionLog,
    this._achievementService,
    this._quranRepository,
    this._streakService, // RISK-5 FIX
    this._xpService, // RISK-5 FIX
  ) : super(const KidsModeInitial()) {
    _playerSub = _player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        _onPlaybackCompleted();
      }
    });
    // Track buffering state separately so the UI shows a precise loading indicator
    _bufferingSub = _player.processingStateStream.listen((ps) {
      if (state is KidsModeLoaded) {
        final buffering =
            ps == ProcessingState.loading || ps == ProcessingState.buffering;
        emit((state as KidsModeLoaded).copyWith(isBuffering: buffering));
      }
    });
  }

  final GetKidsProgressUsecase _getKidsProgress;
  final AwardKidsPointsUsecase _awardPoints;
  final MarkAyahMemorizedUsecase _markAyahMemorized;
  final SaveKidsSessionLogUsecase _saveKidsSessionLog;
  final AchievementService _achievementService;
  final QuranRepository _quranRepository;
  final StreakService _streakService; // RISK-5 FIX
  final XpService _xpService; // RISK-5 FIX
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerSub;
  late final StreamSubscription<ProcessingState> _bufferingSub;

  int _loopCount = 0;
  final Set<String> _completionsInFlight = <String>{};
  static const int _maxLoops = 3;

  @visibleForTesting
  void debugSetLoopCount(int count) {
    _loopCount = count;
  }

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
    emit(
      st.copyWith(
        isPlaying: true,
        isBuffering: true,
        currentLoop: 1,
        clearAudioError: true,
      ),
    );
    await _playAyah(st.surahId, st.ayahNumber);
  }

  Future<void> _playAyah(int surahId, int ayahNumber) async {
    try {
      final url = QuranAudioService.buildUrl(surahId, ayahNumber);
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {
      if (state is KidsModeLoaded) {
        emit(
          (state as KidsModeLoaded).copyWith(
            isPlaying: false,
            audioError: CubitMessageCodes.kidsAudioPlaybackFailed,
          ),
        );
      }
    }
  }

  void _onPlaybackCompleted() {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;

    _loopCount++;
    if (_loopCount < _maxLoops) {
      emit(st.copyWith(currentLoop: _loopCount + 1, clearAudioError: true));
      _playAyah(st.surahId, st.ayahNumber);
    } else {
      emit(
        st.copyWith(
          isPlaying: false,
          currentLoop: _maxLoops,
          clearAudioError: true,
        ),
      );
    }
  }

  Future<void> stopAudio() async {
    await _player.stop();
    if (state is KidsModeLoaded) {
      emit(
        (state as KidsModeLoaded).copyWith(
          isPlaying: false,
          isBuffering: false,
        ),
      );
    }
  }

  /// Shows a brief visual recording animation, then finalises completion.
  /// This satisfies US4 Acceptance Scenario 3: the child sees a visual
  /// indicator before the session is marked as done.
  Future<void> startRecording() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    if (st.isCompleted) return;

    if (_loopCount < _maxLoops) {
      emit(st.copyWith(mustListenFirst: true));
      Future.delayed(const Duration(seconds: 2), () {
        if (state is KidsModeLoaded) {
          emit((state as KidsModeLoaded).copyWith(mustListenFirst: false));
        }
      });
      return;
    }

    // Show recording indicator for 1.5 s so the child has visual feedback
    emit(st.copyWith(isRecording: true));
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    // Guard: cubit may have been closed during the delay
    if (isClosed || state is! KidsModeLoaded) return;
    emit((state as KidsModeLoaded).copyWith(isRecording: false));

    await markCompleted();
  }

  Future<void> markCompleted() async {
    if (state is! KidsModeLoaded) return;
    final st = state as KidsModeLoaded;
    if (st.isCompleted) return;

    // BUG-4 FIX: prevent completing without listening the required times
    if (_loopCount < _maxLoops) {
      // Emit a warning state so the UI can show a message
      emit(st.copyWith(mustListenFirst: true));
      // Clear the flag after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (state is KidsModeLoaded) {
          emit((state as KidsModeLoaded).copyWith(mustListenFirst: false));
        }
      });
      return;
    }

    final completionKey = '${st.surahId}_${st.ayahNumber}';
    if (_completionsInFlight.contains(completionKey)) return;
    _completionsInFlight.add(completionKey);

    try {
      final result = await _awardPoints(
        AwardKidsPointsParams(
          surahId: st.surahId,
          ayahNumber: st.ayahNumber,
          repeatsCompleted: _loopCount,
        ),
      );

      final completion = result.fold<KidsCompletionResult?>((f) {
        emit(KidsModeError(f.message));
        return null;
      }, (completion) => completion);
      if (completion == null) return;

      if (completion.alreadyCompleted) {
        emit(
          st.copyWith(
            progress: completion.progress,
            isCompleted: true,
            sessionStarsEarned: 0,
          ),
        );
        return;
      }

      final markResult = await _markAyahMemorized(
        MarkAyahMemorizedParams(
          surahId: st.surahId,
          ayahNumber: st.ayahNumber,
          createdByMode: ReviewRecordCreatedByMode.kidsMode,
        ),
      );
      final markFailure = markResult.fold((f) => f, (_) => null);
      if (markFailure != null) {
        emit(KidsModeError(markFailure.message));
        return;
      }

      // RISK-5 FIX: record streak & XP from Kids Mode — same as Hifz & Adults
      try {
        await _streakService.recordActivity(activityDelta: 1);
        await _xpService.addXp('ayah_memorized');
      } catch (_) {
        // Non-critical
      }

      await _saveKidsSessionLog(
        SaveKidsSessionLogParams(
          surahId: st.surahId,
          ayahNumber: st.ayahNumber,
          repeatsCompleted: _loopCount,
          pointsEarned: completion.pointsEarned,
        ),
      );

      final newAwards = await _achievementService.checkAndUnlockCertificates();
      emit(
        st.copyWith(
          progress: completion.progress,
          isCompleted: true,
          newAwards: newAwards,
          sessionStarsEarned: completion.starsEarned,
        ),
      );
    } finally {
      _completionsInFlight.remove(completionKey);
    }
  }

  @override
  Future<void> close() async {
    await _playerSub.cancel();
    await _bufferingSub.cancel();
    await _player.dispose();
    return super.close();
  }
}
