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
import '../../../../core/utils/arabic_normalizer.dart';

part 'hifz_session_state.dart';

class HifzSessionCubit extends Cubit<HifzSessionState> {
  HifzSessionCubit(
    this._getDetail,
    this._saveProgress,
    this._getSurahProgress,
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

  final SpeechToText _speechToText = SpeechToText();
  final AudioPlayer _player = AudioPlayer();
  
  List<Ayah> _ayahs = [];
  Map<int, AyahProgressModel> _progressMap = {};
  late Surah _surah;
  
  bool _speechEnabled = false;

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (val) => print('STT Error: $val'),
      onStatus: (val) => print('STT Status: $val'),
    );
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
      },
    );
  }

  Future<void> playAudio() async {
    if (state is! HifzSessionLoaded) return;
    final st = state as HifzSessionLoaded;
    
    // Request player state update
    emit(st.copyWith(isPlaying: true));
    
    try {
      final ayah = st.ayahs[st.currentIndex];
      // Format URLs using Mishary Alafasy offline/online source standard
      // URL format: https://everyayah.com/data/Alafasy_128kbps/001001.mp3
      final surahStr = st.surah.id.toString().padLeft(3, '0');
      final ayahStr = ayah.numberInSurah.toString().padLeft(3, '0');
      final audioUrl = "https://everyayah.com/data/Alafasy_128kbps/$surahStr$ayahStr.mp3";
      
      await _player.setUrl(audioUrl);
      await _player.play();
    } catch (e) {
      emit(st.copyWith(isPlaying: false));
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
      if (!status.isGranted) return; // Must have mic permission
    }

    if (!_speechEnabled) {
      await _initSpeech();
    }

    if (_speechEnabled) {
      emit(st.copyWith(isRecording: true, similarityScore: -1, recognizedText: ''));
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

    double score = 0.0;
    if (normalizedSpoken.isNotEmpty) {
      // Dice's Coefficient to find similarity
      score = normalizedExpected.similarityTo(normalizedSpoken);
    }

    final pass = score >= 0.85;

    // Output to map and calculate repetition logic
    var currentProgress = _progressMap[ayah.numberInSurah];
    if (currentProgress != null) {
      if (pass) {
        currentProgress = currentProgress.advanceWithSpacedRepetition();
      } else {
        currentProgress = AyahProgressModel.initial(currentProgress.surahId, currentProgress.ayahNumber);
      }
      _progressMap[ayah.numberInSurah] = currentProgress;
      await _saveProgress(currentProgress);
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
      emit(st.copyWith(
        currentIndex: st.currentIndex + 1,
        similarityScore: -1,
        recognizedText: '',
      ));
    }
  }

  void retryAyah() {
    if (state is! HifzSessionLoaded) return;
    emit((state as HifzSessionLoaded).copyWith(
      similarityScore: -1,
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
