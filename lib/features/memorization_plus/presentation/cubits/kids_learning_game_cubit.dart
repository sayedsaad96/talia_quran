import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/services/audio_lifecycle_manager.dart';
import '../../domain/entities/kids_learning_game.dart';
import '../../domain/entities/kids_session_log.dart';
import '../../domain/services/kids_learning_game_builder.dart';

enum KidsLearningGameStatus { loading, unavailable, playing, finished }

class KidsLearningGameState extends Equatable {
  const KidsLearningGameState({
    this.status = KidsLearningGameStatus.loading,
    this.game,
    this.roundIndex = 0,
    this.selected,
    this.result,
    this.correctCount = 0,
    this.isAudioPlaying = false,
    this.audioFailed = false,
  });

  final KidsLearningGameStatus status;
  final KidsLearningGame? game;
  final int roundIndex;

  /// The surah the child picked in this round; null until they answer.
  final int? selected;
  final KidsGameResult? result;
  final int correctCount;
  final bool isAudioPlaying;
  final bool audioFailed;

  KidsGameRound? get round => status == KidsLearningGameStatus.playing
      ? game?.rounds[roundIndex]
      : null;
  bool get answered => result != null;
  int get roundCount => game?.rounds.length ?? 0;
  bool get isLastRound => roundIndex >= roundCount - 1;

  KidsLearningGameState copyWith({
    KidsLearningGameStatus? status,
    KidsLearningGame? game,
    int? roundIndex,
    int? selected,
    KidsGameResult? result,
    bool clearAnswer = false,
    int? correctCount,
    bool? isAudioPlaying,
    bool? audioFailed,
  }) => KidsLearningGameState(
    status: status ?? this.status,
    game: game ?? this.game,
    roundIndex: roundIndex ?? this.roundIndex,
    selected: clearAnswer ? null : (selected ?? this.selected),
    result: clearAnswer ? null : (result ?? this.result),
    correctCount: correctCount ?? this.correctCount,
    isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
    audioFailed: audioFailed ?? this.audioFailed,
  );

  @override
  List<Object?> get props => [
    status,
    game,
    roundIndex,
    selected,
    result,
    correctCount,
    isAudioPlaying,
    audioFailed,
  ];
}

typedef KidsGameAudioSourceLoader =
    Future<String> Function(int surahId, int ayahNumber);

/// «أي سورة هذه؟». Owns one player for the recitation and nothing else: no
/// microphone, no session engine, no reward owner. A finished round set is
/// learning only and is never written as memorization.
class KidsLearningGameCubit extends Cubit<KidsLearningGameState> {
  KidsLearningGameCubit({
    required Future<List<KidsSessionLog>> Function() sessionLogs,
    required KidsGameAudioSourceLoader audioSource,
    AudioPlayer? player,
    Random? random,
  }) : _sessionLogs = sessionLogs,
       _audioSource = audioSource,
       _player = player ?? AudioPlayer(),
       _random = random ?? Random(),
       super(const KidsLearningGameState()) {
    AudioLifecycleManager.instance.register(_player);
    _playerState = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed && !isClosed) {
        emit(state.copyWith(isAudioPlaying: false));
      }
    });
  }

  final Future<List<KidsSessionLog>> Function() _sessionLogs;
  final KidsGameAudioSourceLoader _audioSource;
  final AudioPlayer _player;
  final Random _random;
  StreamSubscription<PlayerState>? _playerState;

  /// Bumped whenever playback should stop, so a late source load or a
  /// callback from an earlier round never plays.
  int _playback = 0;

  Future<void> start() async {
    emit(const KidsLearningGameState());
    KidsLearningGame? game;
    try {
      game = buildListenAndChooseSurahGame(
        await _sessionLogs(),
        random: _random,
      );
    } catch (_) {
      game = null;
    }
    if (isClosed) return;
    if (game == null || game.rounds.isEmpty) {
      emit(
        const KidsLearningGameState(status: KidsLearningGameStatus.unavailable),
      );
      return;
    }
    emit(
      KidsLearningGameState(status: KidsLearningGameStatus.playing, game: game),
    );
  }

  Future<void> playRecitation() async {
    final round = state.round;
    if (round == null) return;
    final ticket = ++_playback;
    emit(state.copyWith(isAudioPlaying: true, audioFailed: false));
    try {
      final source = await _audioSource(round.surahId, round.ayahNumber);
      if (ticket != _playback || isClosed) return;
      if (source.startsWith('http://') || source.startsWith('https://')) {
        await _player.setUrl(source);
      } else {
        await _player.setFilePath(source);
      }
      if (ticket != _playback || isClosed) return;
      await _player.seek(Duration.zero);
      // play() completes only when playback stops, so it is not awaited; a
      // later playback error still surfaces as a retryable failure.
      unawaited(
        _player.play().catchError((Object _) {
          if (ticket == _playback && !isClosed) {
            emit(state.copyWith(isAudioPlaying: false, audioFailed: true));
          }
        }),
      );
    } catch (_) {
      if (ticket != _playback || isClosed) return;
      emit(state.copyWith(isAudioPlaying: false, audioFailed: true));
    }
  }

  Future<void> stopAudio() async {
    _playback++;
    if (!isClosed && state.isAudioPlaying) {
      emit(state.copyWith(isAudioPlaying: false));
    }
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Scores the first answer of a round; later taps and unknown ids are
  /// ignored, so a double tap can never count twice.
  Future<void> answer(int surahId) async {
    final round = state.round;
    if (round == null || state.answered) return;
    final result = evaluateKidsGameAnswer(round: round, optionSurahId: surahId);
    if (result == KidsGameResult.unknownOption) return;
    await stopAudio();
    if (isClosed) return;
    emit(
      state.copyWith(
        selected: surahId,
        result: result,
        correctCount:
            state.correctCount + (result == KidsGameResult.correct ? 1 : 0),
      ),
    );
  }

  Future<void> next() async {
    if (state.status != KidsLearningGameStatus.playing || !state.answered) {
      return;
    }
    await stopAudio();
    if (isClosed) return;
    if (state.isLastRound) {
      emit(
        state.copyWith(
          status: KidsLearningGameStatus.finished,
          clearAnswer: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        roundIndex: state.roundIndex + 1,
        clearAnswer: true,
        audioFailed: false,
      ),
    );
  }

  @override
  Future<void> close() async {
    _playback++;
    await _playerState?.cancel();
    AudioLifecycleManager.instance.unregister(_player);
    try {
      await _player.stop();
      await _player.dispose();
    } catch (_) {}
    return super.close();
  }
}
