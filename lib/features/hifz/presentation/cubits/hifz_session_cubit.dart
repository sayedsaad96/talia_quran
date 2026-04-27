import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:just_audio/just_audio.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../quran/domain/entities/quran_entities.dart';
import '../../../quran/domain/usecases/get_surahs_usecase.dart';
import '../../data/models/ayah_progress_model.dart';
import '../../domain/usecases/get_hifz_progress_usecase.dart';
import '../../domain/usecases/save_ayah_progress_usecase.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'hifz_session_state.dart';

class HifzSessionCubit extends Cubit<HifzSessionState> {
  HifzSessionCubit(
    this._getDetail,
    this._saveProgress,
    this._getSurahProgress,
    this._prefs,
  ) : super(const HifzSessionInitial()) {
    _initSpeech();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (this.state is HifzSessionLoaded) {
          emit((this.state as HifzSessionLoaded).copyWith(isPlaying: false));
        }
      }
    });
  }

  final GetSurahDetailUsecase _getDetail;
  final SaveAyahProgressUsecase _saveProgress;
  final GetProgressForSurahUsecase _getSurahProgress;
  final SharedPreferences _prefs;

  final SpeechToText _speechToText = SpeechToText();
  final AudioPlayer _player = AudioPlayer();
  
  List<Ayah> _ayahs = [];
  Map<int, AyahProgressModel> _progressMap = {};
  late Surah _surah;
  
  bool _speechEnabled = false;

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
  }

  Future<void> startSession(int surahId, int startAyah) async {
    emit(const HifzSessionLoading());

    final progressResult = await _getSurahProgress(surahId);
    final existingProgress = progressResult.fold(
      (l) => <AyahProgressModel>[],
      (r) => r.cast<AyahProgressModel>(),
    );

    final result = await _getDetail(surahId);
    result.fold(
      (f) => emit(HifzSessionError(f.message)),
      (detail) {
        _surah = detail.surah;
        _ayahs = detail.ayahs;
        
        final map = <int, AyahProgressModel>{};
        for (final p in existingProgress) {
          map[p.ayahNumber] = p;
        }
        for (final a in _ayahs) {
          if (!map.containsKey(a.numberInSurah)) {
            map[a.numberInSurah] = AyahProgressModel.initial(surahId, a.numberInSurah);
          }
        }
        _progressMap = map;

        // Find the index of the startAyah
        int startIndex = 0;
        if (startAyah > 0) {
          final idx = _ayahs.indexWhere((a) => a.numberInSurah == startAyah);
          if (idx != -1) startIndex = idx;
        }

        emit(HifzSessionLoaded(
          surah: _surah,
          ayahs: _ayahs,
          progressMap: map,
          currentIndex: startIndex,
        ));

        // Prefetch audio for upcoming ayahs in the background
        AudioCacheService.instance.prefetchSession(
          surahId: surahId,
          ayahNumbers: _ayahs.map((a) => a.numberInSurah).toList(),
        );
      },
    );
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
      
      await _player.setUrl(audioSource);
      await _player.play();
    } catch (e) {
      emit(st.copyWith(
        isPlaying: false,
        audioError: 'فشل تشغيل الصوت. تحقق من الاتصال بالإنترنت.',
      ));
      // Clear the error after showing it
      Future.delayed(const Duration(seconds: 3), () {
        if (state is HifzSessionLoaded) {
          emit((state as HifzSessionLoaded).copyWith(clearAudioError: true));
        }
      });
    }
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
        emit(st.copyWith(
          audioError: 'يحتاج التطبيق إذن الميكروفون للتسميع الصوتي. يرجى السماح من إعدادات الجهاز.',
        ));
        Future.delayed(const Duration(seconds: 5), () {
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
      emit(st.copyWith(isRecording: true, clearScore: true, recognizedText: ''));
      await _speechToText.listen(
        onResult: (result) {
          if (state is HifzSessionLoaded) {
            emit((state as HifzSessionLoaded).copyWith(recognizedText: result.recognizedWords));
          }
        },
        localeId: 'ar-SA',
        pauseFor: const Duration(seconds: 5), // auto-stop if silent for 5 seconds
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
      _evaluateRecitation();
    }
  }

  void _evaluateRecitation() async {
    if (state is! HifzSessionLoaded) return;
    final st = state as HifzSessionLoaded;

    final ayah = st.ayahs[st.currentIndex];
    
    final normalizedExpected = ArabicNormalizer.normalize(ayah.text);
    final normalizedSpoken = ArabicNormalizer.normalize(st.recognizedText);

    // BUG-010: If STT returned empty, don't count as failure
    if (normalizedSpoken.isEmpty) {
      emit(st.copyWith(
        isEvaluating: false,
        clearScore: true,
        recognizedText: '',
      ));
      return;
    }

    double score = 0.0;
    // Dice's Coefficient to find similarity
    score = normalizedExpected.similarityTo(normalizedSpoken);

    final threshold = _prefs.getDouble('similarity_threshold')
        ?? AppConstants.kSimilarityThreshold;
    final pass = score >= threshold;

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
      try {
        await _saveProgress(currentProgress);
      } catch (_) {
        // Silently handle save failure — don't crash the session
      }
    }

    // Haptic feedback on evaluation result
    if (pass) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    emit(st.copyWith(
      isEvaluating: false,
      similarityScore: score,
      progressMap: Map.from(_progressMap),
    ));
  }
  
  void nextAyah() {
    if (state is! HifzSessionLoaded) return;
    final st = state as HifzSessionLoaded;
    if (st.currentIndex < st.ayahs.length - 1) {
      HapticFeedback.lightImpact();
      emit(st.copyWith(
        currentIndex: st.currentIndex + 1,
        clearScore: true,
        recognizedText: '',
      ));
    }
  }

  void retryAyah() {
    if (state is! HifzSessionLoaded) return;
    emit((state as HifzSessionLoaded).copyWith(
      clearScore: true,
      recognizedText: '',
    ));
  }

  @override
  Future<void> close() {
    _player.dispose();
    _speechToText.cancel();
    return super.close();
  }
}
