import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/memorization/listening/listening_quiz_engine.dart';
import '../../../../core/memorization/listening/listening_round_result.dart';
import '../../../../core/memorization/v2/recitation_evaluator.dart';
import '../../data/listening/listening_audio.dart';
import '../../data/listening/listening_quiz_source.dart';
import '../../data/listening/listening_recitation_capture.dart';
import '../../data/listening/listening_review_stats_store.dart';
import 'listening_review_state.dart';

/// Drives Listening Review rounds. Practice only: it has no access to review
/// records, the outcome committer, XP or sync, so it cannot change SRS.
class ListeningReviewCubit extends Cubit<ListeningReviewState> {
  ListeningReviewCubit({
    required ListeningQuizSource source,
    required ListeningAudio audio,
    required ListeningRecitationCapture capture,
    required ListeningReviewStatsStore stats,
    ListeningQuizEngine engine = const ListeningQuizEngine(),
    V2RecitationEvaluator evaluator = const V2RecitationEvaluator(),
    Random? random,
  }) : _source = source,
       _audio = audio,
       _capture = capture,
       _stats = stats,
       _engine = engine,
       _evaluator = evaluator,
       _random = random ?? Random(),
       super(const ListeningReviewLoading());

  final ListeningQuizSource _source;
  final ListeningAudio _audio;
  final ListeningRecitationCapture _capture;
  final ListeningReviewStatsStore _stats;
  final ListeningQuizEngine _engine;
  final V2RecitationEvaluator _evaluator;
  final Random _random;

  ListeningQuizMaterial? _material;
  ListeningQuizMaterial? get material => _material;

  Future<void> load() async {
    emit(const ListeningReviewLoading());
    final result = await _source.load();
    result.fold((_) => emit(const ListeningReviewError()), (material) {
      _material = material;
      final eligible = _engine.eligiblePromptCount(
        material.corpus,
        material.prompts,
      );
      emit(
        eligible < ListeningQuizEngine.minQuestions
            ? const ListeningReviewNotEnough()
            : ListeningReviewIdle(_stats.read()),
      );
    });
  }

  Future<void> startRound(ListeningQuizMode mode) async {
    final material = _material;
    if (material == null) return;
    final candidates = _engine.buildRound(
      corpus: material.corpus,
      prompts: material.prompts,
      mode: mode,
      random: _random,
      size: ListeningQuizEngine.candidateSize,
    );
    final cached = <ListeningQuestion>[];
    final uncached = <ListeningQuestion>[];
    for (final q in candidates) {
      (await _audio.isCached(q.prompt) ? cached : uncached).add(q);
    }
    final questions = [
      ...cached,
      ...uncached,
    ].take(ListeningQuizEngine.roundSize).toList();
    if (questions.length < ListeningQuizEngine.minQuestions) {
      emit(const ListeningReviewNotEnough());
      return;
    }
    emit(ListeningReviewInRound(mode: mode, questions: questions, index: 0));
    await _playCurrent();
  }

  Future<void> replay() => _playCurrent();

  void answerSurah(int surahId) {
    final st = state;
    if (st is! ListeningReviewInRound || st.isAnswered) return;
    final question = st.question;
    if (question is! WhichSurahQuestion) return;
    _answer(
      st,
      surahId == question.prompt.surahId
          ? ListeningOutcome.correct
          : ListeningOutcome.wrong,
    );
  }

  Future<void> startRecording() async {
    final st = state;
    if (st is! ListeningReviewInRound ||
        st.isAnswered ||
        st.isRecording ||
        st.question is! NextAyahQuestion) {
      return;
    }
    if (st.isPlaying) await _audio.stop();
    final readiness = await _capture.prepare();
    if (readiness != ListeningCaptureReadiness.ready) {
      emit(st.copyWith(selfGradeMode: true, isPlaying: false));
      return;
    }
    emit(st.copyWith(isRecording: true, recognizedText: '', isPlaying: false));
    await _capture.start((words) {
      final current = state;
      if (current is ListeningReviewInRound && current.isRecording) {
        emit(current.copyWith(recognizedText: words));
      }
    });
  }

  Future<void> stopRecording() async {
    final st = state;
    if (st is! ListeningReviewInRound || !st.isRecording) return;
    final spoken = await _capture.stop();
    final question = st.question as NextAyahQuestion;
    final result = _evaluator.evaluate(
      targetText: question.nextAyahText,
      spokenText: spoken,
    );
    final stopped = st.copyWith(isRecording: false, recognizedText: spoken);
    if (result.isNoAttempt) {
      final attempts = stopped.emptyAttempts + 1;
      emit(
        stopped.copyWith(emptyAttempts: attempts, selfGradeMode: attempts >= 2),
      );
      return;
    }
    _answer(
      stopped,
      result.passed ? ListeningOutcome.correct : ListeningOutcome.wrong,
    );
  }

  void useSelfGrade() {
    final st = state;
    if (st is ListeningReviewInRound && !st.isAnswered) {
      emit(st.copyWith(selfGradeMode: true));
    }
  }

  void revealForSelfGrade() {
    final st = state;
    if (st is ListeningReviewInRound && st.selfGradeMode && !st.isAnswered) {
      emit(st.copyWith(selfGradeRevealed: true));
    }
  }

  void selfGrade(ListeningOutcome outcome) {
    final st = state;
    if (st is! ListeningReviewInRound ||
        st.isAnswered ||
        !st.selfGradeRevealed ||
        outcome == ListeningOutcome.skipped) {
      return;
    }
    _answer(st, outcome);
  }

  Future<void> next() async {
    final st = state;
    if (st is! ListeningReviewInRound || !st.isAnswered) return;
    await _advance(st, st.answers);
  }

  Future<void> backToStart() async {
    await _audio.stop();
    if (_material == null) {
      await load();
      return;
    }
    emit(ListeningReviewIdle(_stats.read()));
  }

  void _answer(ListeningReviewInRound st, ListeningOutcome outcome) {
    final answer = ListeningAnswer(st.question, outcome);
    emit(st.copyWith(current: answer, answers: [...st.answers, answer]));
  }

  Future<void> _playCurrent() async {
    final st = state;
    if (st is! ListeningReviewInRound ||
        st.isPlaying ||
        st.isRecording ||
        st.playsLeft <= 0) {
      return;
    }
    emit(st.copyWith(isPlaying: true, playsUsed: st.playsUsed + 1));
    final played = await _audio.play(st.question.prompt);
    final after = state;
    if (after is! ListeningReviewInRound || after.index != st.index) return;
    if (played) {
      emit(after.copyWith(isPlaying: false));
      return;
    }
    // Audio unavailable (e.g. offline, not cached): skip without scoring.
    await _advance(after, [
      ...after.answers,
      ListeningAnswer(after.question, ListeningOutcome.skipped),
    ]);
  }

  Future<void> _advance(
    ListeningReviewInRound st,
    List<ListeningAnswer> answers,
  ) async {
    if (st.index + 1 >= st.questions.length) {
      final result = ListeningRoundResult(answers);
      await _stats.record(result);
      emit(ListeningReviewFinished(result));
      return;
    }
    emit(
      ListeningReviewInRound(
        mode: st.mode,
        questions: st.questions,
        index: st.index + 1,
        answers: answers,
      ),
    );
    await _playCurrent();
  }

  @override
  Future<void> close() async {
    await _capture.cancel();
    await _audio.dispose();
    return super.close();
  }
}
