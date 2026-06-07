import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:just_audio/just_audio.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/hifz_unlock_rules.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/usecases/get_surahs_usecase.dart';
import '../../data/models/ayah_progress_model.dart';
import '../../domain/entities/hifz_entities.dart';
import '../../domain/usecases/get_hifz_progress_usecase.dart';
import '../../domain/usecases/save_ayah_progress_usecase.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/services/xp_service.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';

part 'hifz_session_state.dart';

class HifzSessionCubit extends Cubit<HifzSessionState> {
  HifzSessionCubit(
    this._getSurahs,
    this._getDetail,
    this._saveProgress,
    this._getSurahProgress,
    this._getAllSurahProgress,
    this._getPath,
    this._generateSegments,
    this._checkNextAyahUnlock,
    this._getNextRequiredCheckpoint,
    this._getPassedCheckpointKeys,
    this._markCheckpointPassed,
    this._settings,
    this._streakService,
    this._xpService,
    this._achievementService,
    this._memorizationRepository,
  ) : super(const HifzSessionInitial()) {
    _initSpeech();
    // BUG-NEW-004 FIX: Store subscription reference
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (!isClosed && this.state is HifzSessionLoaded) {
          emit((this.state as HifzSessionLoaded).copyWith(isPlaying: false));
        }
      }
    });
  }

  final GetSurahsUsecase _getSurahs;
  final GetSurahDetailUsecase _getDetail;
  final SaveAyahProgressUsecase _saveProgress;
  final GetProgressForSurahUsecase _getSurahProgress;
  final GetHifzProgressUsecase _getAllSurahProgress;
  final GetHifzPathUsecase _getPath;
  final GenerateHifzSegmentsUsecase _generateSegments;
  final CheckNextAyahUnlockUsecase _checkNextAyahUnlock;
  final GetNextRequiredReviewCheckpointUsecase _getNextRequiredCheckpoint;
  final GetPassedCheckpointKeysUsecase _getPassedCheckpointKeys;
  final MarkCheckpointReviewPassedUsecase _markCheckpointPassed;
  // ARCH-3 FIX: SettingsRepository instead of direct SharedPreferences access.
  final SettingsRepository _settings;
  final StreakService _streakService;
  final XpService _xpService;
  final AchievementService _achievementService;
  // T-06: Used for the defensive kids-profile check in startSession().
  final MemorizationPlusRepository _memorizationRepository;

  final SpeechToText _speechToText = SpeechToText();
  final AudioPlayer _player = AudioPlayer();
  // BUG-NEW-004 FIX: Store subscription so it can be cancelled in close()
  StreamSubscription<PlayerState>? _playerStateSub;

  List<Ayah> _ayahs = [];
  Map<int, AyahProgressModel> _progressMap = {};
  List<HifzSegment> _segments = [];
  Set<String> _passedCheckpointKeys = {};
  late Surah _surah;

  bool _speechEnabled = false;

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
  }

  AyahProgressModel _toProgressModel(AyahProgress progress) {
    if (progress is AyahProgressModel) return progress;
    return AyahProgressModel(
      surahId: progress.surahId,
      ayahNumber: progress.ayahNumber,
      status: progress.status,
      repetitions: progress.repetitions,
      nextReviewDate: progress.nextReviewDate,
      lastReviewDate: progress.lastReviewDate,
    );
  }

  Future<void> startSession(int surahId, int startAyah) async {
    emit(const HifzSessionLoading());

    // T-06 FIX: Defensive guard — reject basic-memorization session
    // initialization for child profiles at the Cubit level (not only the router).
    try {
      final profileResult = await _memorizationRepository
          .getMemorizationProfile();
      final isKids = profileResult.fold((_) => false, (p) => p.isChild);
      if (isKids) {
        emit(
          const HifzSessionError(
            'هذا المسار مخصص للبالغين. سيتم توجيهك لمسار الأطفال.',
            redirectToKidsHome: true,
          ),
        );
        return;
      }
    } catch (_) {
      // If profile check fails, allow session to continue (offline-safe).
    }

    final unlockError = await _validateSurahAccess(surahId);
    if (unlockError != null) {
      emit(HifzSessionError(unlockError));
      return;
    }

    final progressResult = await _getSurahProgress(surahId);
    final progressFailure = progressResult.fold((f) => f, (_) => null);
    if (progressFailure != null) {
      emit(HifzSessionError(progressFailure.message));
      return;
    }
    final existingProgress = progressResult
        .getOrElse(() => const [])
        .map(_toProgressModel)
        .toList();

    final result = await _getDetail(surahId);
    await result.fold((f) async => emit(HifzSessionError(f.message)), (
      detail,
    ) async {
      _surah = detail.surah;
      _ayahs = detail.ayahs;
      _segments = _generateSegments(
        surahId: _surah.id,
        totalAyahs: _surah.ayahCount,
      );

      final checkpointResult = await _getPassedCheckpointKeys(surahId);
      final checkpointFailure = checkpointResult.fold((f) => f, (_) => null);
      if (checkpointFailure != null) {
        emit(HifzSessionError(checkpointFailure.message));
        return;
      }
      _passedCheckpointKeys = checkpointResult.getOrElse(() => const {});

      final map = <int, AyahProgressModel>{};
      for (final p in existingProgress) {
        map[p.ayahNumber] = p;
      }
      for (final a in _ayahs) {
        if (!map.containsKey(a.numberInSurah)) {
          map[a.numberInSurah] = AyahProgressModel.initial(
            surahId,
            a.numberInSurah,
          );
        }
      }
      _progressMap = map;

      // Find the index of the startAyah
      int startIndex = 0;
      if (startAyah > 0) {
        final idx = _ayahs.indexWhere((a) => a.numberInSurah == startAyah);
        if (idx != -1) startIndex = idx;
      }

      final blockedCheckpoint = _firstBlockingCheckpointBeforeStart(
        _ayahs[startIndex].numberInSurah,
      );
      if (blockedCheckpoint != null) {
        final idx = _ayahs.indexWhere(
          (a) => a.numberInSurah == blockedCheckpoint.endAyah,
        );
        if (idx != -1) startIndex = idx;
      }
      final requiredCheckpoint =
          blockedCheckpoint ??
          _requiredCheckpointAfterAyah(_ayahs[startIndex].numberInSurah);

      emit(
        HifzSessionLoaded(
          surah: _surah,
          ayahs: _ayahs,
          progressMap: map,
          currentIndex: startIndex,
          passThreshold: _settings.getSimilarityThreshold(), // BUG-2 FIX
          segments: _segments,
          passedCheckpointKeys: _passedCheckpointKeys,
          requiredCheckpoint: requiredCheckpoint,
        ),
      );

      // Prefetch audio for the next few ayahs in the background.
      // Bounded to current + next 4 to avoid downloading the entire surah at once.
      const int prefetchWindow = 5;
      final prefetchNumbers = _ayahs
          .skip(startIndex)
          .take(prefetchWindow)
          .map((a) => a.numberInSurah)
          .toList();
      unawaited(
        AudioCacheService.instance.prefetchSession(
          surahId: surahId,
          ayahNumbers: prefetchNumbers,
        ),
      );
    });
  }

  HifzSegment? _firstBlockingCheckpointBeforeStart(int ayahNumber) {
    for (final segment in _segments) {
      if (segment.endAyah < ayahNumber &&
          !_passedCheckpointKeys.contains(segment.key)) {
        return segment;
      }
    }
    return null;
  }

  HifzSegment? _requiredCheckpointAfterAyah(int ayahNumber) {
    final checkpoint = _getNextRequiredCheckpoint(
      segments: _segments,
      passedSegmentKeys: _passedCheckpointKeys,
      progressMap: Map<int, AyahProgress>.from(_progressMap),
    );
    if (checkpoint == null) return null;
    return checkpoint.endAyah == ayahNumber ? checkpoint : null;
  }

  String _checkpointExpectedText(HifzSegment checkpoint) {
    return _ayahs
        .where(
          (ayah) =>
              ayah.numberInSurah >= checkpoint.startAyah &&
              ayah.numberInSurah <= checkpoint.endAyah,
        )
        .map((ayah) => ayah.text)
        .join(' ');
  }

  Future<void> playAudio() async {
    if (state is! HifzSessionLoaded) return;
    final st = state as HifzSessionLoaded;

    emit(st.copyWith(isPlaying: true));

    try {
      final ayah = st.ayahs[st.currentIndex];
      final audioSource = await AudioCacheService.instance.getAudioSource(
        st.surah.id,
        ayah.numberInSurah,
      );

      await AudioCacheService.playFromSource(_player, audioSource);
    } catch (e) {
      emit(
        st.copyWith(
          isPlaying: false,
          audioError: 'فشل تشغيل الصوت. تحقق من الاتصال بالإنترنت.',
        ),
      );
      // Clear the error after showing it
      Future.delayed(const Duration(seconds: 3), () {
        if (isClosed) return;
        if (state is HifzSessionLoaded) {
          emit((state as HifzSessionLoaded).copyWith(clearAudioError: true));
        }
      });
    }
  }

  Future<String?> _validateSurahAccess(int surahId) async {
    final pathResult = await _getPath();
    final selectedPath = pathResult.fold((_) => null, (path) => path);
    if (selectedPath == null) return null;

    final surahsResult = await _getSurahs();
    final progressResult = await _getAllSurahProgress();

    final surahs = surahsResult.fold((_) => null, (items) => items);
    final progress = progressResult.fold((_) => null, (items) => items);
    if (surahs == null || progress == null) return null;

    final orderedSurahs = sortSurahsForHifzPath(
      surahs: surahs,
      path: selectedPath,
    );
    final progressMap = {for (final item in progress) item.surahId: item};
    final unlockedSurahIds = buildUnlockedSurahIds(
      orderedSurahs: orderedSurahs,
      progressMap: progressMap,
    );

    if (unlockedSurahIds.contains(surahId)) return null;

    final targetIndex = orderedSurahs.indexWhere(
      (surah) => surah.id == surahId,
    );
    if (targetIndex <= 0) return null;

    final requiredSurah = orderedSurahs[targetIndex - 1];
    return 'هذه السورة مقفلة حالياً. أكمل حفظ سورة ${requiredSurah.nameAr} أولاً لفتحها.';
  }

  Future<void> pauseAudio() async {
    if (state is! HifzSessionLoaded) return;
    await _player.pause();
    emit((state as HifzSessionLoaded).copyWith(isPlaying: false));
  }

  Future<void> startRecording() async {
    if (state is! HifzSessionLoaded) return;
    final st = state as HifzSessionLoaded;

    if (st.isPlaying) await pauseAudio();

    // Check permissions
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        // UX-013: Emit error so UI can guide the user
        emit(
          st.copyWith(
            audioError:
                'يحتاج التطبيق إذن الميكروفون للتسميع الصوتي. يرجى السماح من إعدادات الجهاز.',
          ),
        );
        Future.delayed(const Duration(seconds: 5), () {
          if (isClosed) return;
          if (state is HifzSessionLoaded) {
            emit((state as HifzSessionLoaded).copyWith(clearAudioError: true));
          }
        });
        return;
      }
    }

    if (!_speechEnabled) {
      await _initSpeech();
    }

    if (_speechEnabled) {
      emit(
        st.copyWith(
          isRecording: true,
          clearScore: true,
          recognizedText: '',
          clearCompletedCheckpoint: true,
          isCheckpointReviewActive: st.requiredCheckpoint != null,
        ),
      );
      await _speechToText.listen(
        onResult: (result) {
          if (state is HifzSessionLoaded) {
            emit(
              (state as HifzSessionLoaded).copyWith(
                recognizedText: result.recognizedWords,
              ),
            );
          }
        },
        localeId: 'ar-SA',
        pauseFor: const Duration(
          seconds: 5,
        ), // auto-stop if silent for 5 seconds
      );
    }
  }

  Future<void> stopRecording() async {
    if (state is! HifzSessionLoaded) return;
    final st = state as HifzSessionLoaded;

    if (st.isRecording) {
      await _speechToText.stop();
      emit(st.copyWith(isRecording: false, isEvaluating: true));

      // Delay slightly so the UI can show "Evaluating..."
      await Future.delayed(const Duration(milliseconds: 500));
      await _evaluateRecitation();
    }
  }

  Future<void> _evaluateRecitation() async {
    if (state is! HifzSessionLoaded) return;
    final st = state as HifzSessionLoaded;

    final ayah = st.ayahs[st.currentIndex];
    final checkpoint = st.isCheckpointReviewActive
        ? st.requiredCheckpoint
        : null;

    final expectedText = checkpoint == null
        ? ayah.text
        : _checkpointExpectedText(checkpoint);
    final normalizedExpected = ArabicNormalizer.normalize(expectedText);
    final normalizedSpoken = ArabicNormalizer.normalize(st.recognizedText);

    // BUG-010: If STT returned empty, don't count as failure
    if (normalizedSpoken.isEmpty) {
      emit(
        st.copyWith(isEvaluating: false, clearScore: true, recognizedText: ''),
      );
      return;
    }

    double score = 0.0;
    // Dice's Coefficient to find similarity
    score = normalizedExpected.similarityTo(normalizedSpoken);

    final threshold = _settings.getSimilarityThreshold();
    final pass = score >= threshold;

    if (checkpoint != null) {
      if (pass) {
        final saveResult = await _markCheckpointPassed(checkpoint);
        final failure = saveResult.fold((f) => f, (_) => null);
        if (failure != null) {
          TaliaLogger.e(
            'Failed to save checkpoint progress in session',
            failure,
            StackTrace.current,
          );
          emit(
            st.copyWith(
              isEvaluating: false,
              audioError: 'فشل حفظ تقدم المراجعة. حاول مرة أخرى.',
              isCheckpointReviewActive: false,
            ),
          );
          return;
        }
        _passedCheckpointKeys = {..._passedCheckpointKeys, checkpoint.key};
      }

      if (pass) {
        try {
          await _streakService.recordActivity(activityDelta: 1);
          await _xpService.addXp('daily_review');
          final newAwards = await _achievementService
              .checkAndUnlockCertificates();
          if (newAwards.isNotEmpty && state is HifzSessionLoaded) {
            final prevState = state as HifzSessionLoaded;
            emit(
              CertificatesEarned(awards: newAwards, previousState: prevState),
            );
            await Future.delayed(const Duration(milliseconds: 100));
            if (!isClosed) emit(prevState);
          }
        } catch (e, stack) {
          TaliaLogger.e('Non-critical: Failed to record streak/xp', e, stack);
        }
      }
    } else {
      // Update progress with Soft Penalty instead of Hard Reset
      var currentProgress = _progressMap[ayah.numberInSurah];
      if (currentProgress != null) {
        if (pass) {
          currentProgress = currentProgress.advanceWithSpacedRepetition();
        } else {
          // Soft Penalty: decrease repetitions by 1 (min 0) and reschedule review
          currentProgress = currentProgress.softPenalty();
        }
        _progressMap[ayah.numberInSurah] = currentProgress;
        final saveResult = await _saveProgress(currentProgress);
        final failure = saveResult.fold((f) => f, (_) => null);
        if (failure != null) {
          TaliaLogger.e(
            'Failed to save ayah progress in session',
            failure,
            StackTrace.current,
          );
          emit(
            st.copyWith(
              isEvaluating: false,
              audioError: 'فشل حفظ تقدم الحفظ. حاول مرة أخرى.',
            ),
          );
          Future.delayed(const Duration(seconds: 4), () {
            if (isClosed) return;
            if (state is HifzSessionLoaded) {
              emit(
                (state as HifzSessionLoaded).copyWith(clearAudioError: true),
              );
            }
          });
          return;
        }

        if (pass) {
          try {
            await _streakService.recordActivity(activityDelta: 1);
            await _xpService.addXp('ayah_memorized');
            final newAwards = await _achievementService
                .checkAndUnlockCertificates();
            if (newAwards.isNotEmpty && state is HifzSessionLoaded) {
              final prevState = state as HifzSessionLoaded;
              emit(
                CertificatesEarned(awards: newAwards, previousState: prevState),
              );
              await Future.delayed(const Duration(milliseconds: 100));
              if (!isClosed) emit(prevState);
            }
          } catch (e, stack) {
            TaliaLogger.e('Non-critical: Failed to record streak/xp', e, stack);
          }
        }
      }
    }

    // Haptic feedback on evaluation result
    if (pass) {
      unawaited(HapticService.success());
    } else {
      unawaited(HapticService.error());
    }

    emit(
      st.copyWith(
        isEvaluating: false,
        similarityScore: score,
        progressMap: Map.from(_progressMap),
        passedCheckpointKeys: _passedCheckpointKeys,
        requiredCheckpoint: pass && checkpoint == null
            ? _requiredCheckpointAfterAyah(ayah.numberInSurah)
            : null,
        clearRequiredCheckpoint: pass && checkpoint != null,
        completedCheckpoint: pass && checkpoint != null ? checkpoint : null,
        isCheckpointReviewActive: false,
        passThreshold: threshold, // BUG-2 FIX: keep threshold in sync
      ),
    );
  }

  void nextAyah() {
    if (state is! HifzSessionLoaded) return;
    final st = state as HifzSessionLoaded;
    if (st.currentIndex < st.ayahs.length - 1) {
      final currentAyah = st.ayahs[st.currentIndex].numberInSurah;
      final canUnlock = _checkNextAyahUnlock(
        currentAyah: currentAyah,
        totalAyahs: st.surah.ayahCount,
        segments: _segments,
        passedSegmentKeys: _passedCheckpointKeys,
      );
      if (!canUnlock) {
        emit(
          st.copyWith(
            requiredCheckpoint: _requiredCheckpointAfterAyah(currentAyah),
            clearCompletedCheckpoint: true,
          ),
        );
        return;
      }

      HapticService.selection();
      final nextIndex = st.currentIndex + 1;
      emit(
        st.copyWith(
          currentIndex: nextIndex,
          clearScore: true,
          recognizedText: '',
          clearRequiredCheckpoint: true,
          clearCompletedCheckpoint: true,
        ),
      );
      // Sliding prefetch: ensure audio is cached for the next 2 upcoming ayahs.
      const int slideAhead = 2;
      final upcomingNumbers = _ayahs
          .skip(nextIndex)
          .take(slideAhead)
          .map((a) => a.numberInSurah)
          .toList();
      if (upcomingNumbers.isNotEmpty) {
        unawaited(
          AudioCacheService.instance.prefetchSession(
            surahId: st.surah.id,
            ayahNumbers: upcomingNumbers,
          ),
        );
      }
    }
  }

  void retryAyah() {
    if (state is! HifzSessionLoaded) return;
    emit(
      (state as HifzSessionLoaded).copyWith(
        clearScore: true,
        recognizedText: '',
      ),
    );
  }

  /// BUG-1 FIX: skipAyah applies a softPenalty to the current ayah so skips
  /// are not silently ignored — they are rescheduled without a full reset.
  Future<void> skipAyah() async {
    if (state is! HifzSessionLoaded) return;
    final st = state as HifzSessionLoaded;
    final ayah = st.ayahs[st.currentIndex];

    var currentProgress = _progressMap[ayah.numberInSurah];
    if (currentProgress != null &&
        currentProgress.status != AyahStatus.notStarted) {
      // Apply soft penalty: moves ayah back one rep & schedules review tomorrow
      currentProgress = currentProgress.softPenalty();
      _progressMap[ayah.numberInSurah] = currentProgress;
      await _saveProgress(currentProgress);
    }

    unawaited(HapticService.selection());

    if (st.currentIndex < st.ayahs.length - 1) {
      final canUnlock = _checkNextAyahUnlock(
        currentAyah: ayah.numberInSurah,
        totalAyahs: st.surah.ayahCount,
        segments: _segments,
        passedSegmentKeys: _passedCheckpointKeys,
      );
      if (!canUnlock) {
        emit(
          st.copyWith(
            requiredCheckpoint: _requiredCheckpointAfterAyah(
              ayah.numberInSurah,
            ),
            progressMap: Map.from(_progressMap),
          ),
        );
        return;
      }

      emit(
        st.copyWith(
          currentIndex: st.currentIndex + 1,
          clearScore: true,
          recognizedText: '',
          progressMap: Map.from(_progressMap),
          clearRequiredCheckpoint: true,
          clearCompletedCheckpoint: true,
        ),
      );
    }
    // If last ayah, just let the UI handle navigation via the finish button
  }

  @override
  Future<void> close() {
    _playerStateSub?.cancel(); // BUG-NEW-004 FIX: Cancel subscription
    _player.dispose();
    _speechToText.cancel();
    return super.close();
  }
}
