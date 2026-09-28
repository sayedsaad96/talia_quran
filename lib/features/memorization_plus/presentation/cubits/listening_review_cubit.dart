import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/memorization/listening/listening_corpus.dart';
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

  /// Built but unused candidates; they replace questions whose audio fails.
  List<ListeningQuestion> _spares = const [];

  /// Page may be closed while audio, speech or loading is in flight.
  void _emit(ListeningReviewState next) {
    if (!isClosed) emit(next);
  }

  Future<void> load() async {
    _emit(const ListeningReviewLoading());
    final result = await _source.load();
    if (isClosed) return;
    result.fold((_) => _emit(const ListeningReviewError()), (material) {
      _material = material;
      final eligible = _engine.eligiblePromptCount(
        material.corpus,
        material.prompts,
      );
      _emit(
        eligible < ListeningQuizEngine.minQuestions
            ? const ListeningReviewNotEnough()
            : ListeningReviewIdle(_stats.read()),
      );
    });
  }

  Future<void> startRound(ListeningQuizMode mode) async {
    final material = _material;
    if (material == null || state is! ListeningReviewIdle) return;
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
      if (isClosed) return;
    }
    final ordered = [...cached, ...uncached];
    final questions = ordered.take(ListeningQuizEngine.roundSize).toList();
    _spares = ordered.skip(questions.length).toList();
    if (questions.length < ListeningQuizEngine.minQuestions) {
      _emit(const ListeningReviewNotEnough());
      return;
    }
    _emit(ListeningReviewInRound(mode: mode, questions: questions, index: 0));
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
    if (isClosed) return;
    if (readiness != ListeningCaptureReadiness.ready) {
      _emit(st.copyWith(selfGradeMode: true, isPlaying: false));
      return;
    }
    _emit(st.copyWith(isRecording: true, recognizedText: '', isPlaying: false));
    await _capture.start(
      (words) {
        final current = state;
        if (current is ListeningReviewInRound && current.isRecording) {
          _emit(current.copyWith(recognizedText: words));
        }
      },
      // Silence timeout or recognizer error: evaluate what was heard.
      onStopped: () => unawaited(stopRecording()),
    );
  }

  Future<void> stopRecording() async {
    final st = state;
    if (st is! ListeningReviewInRound || !st.isRecording) return;
    final spoken = await _capture.stop();
    if (isClosed) return;
    final question = st.question as NextAyahQuestion;
    final result = _evaluator.evaluate(
      // Letters-only target: marks such as ۞ are not recited, so they must
      // not count as missing words. Display still uses the canonical text.
      targetText: ListeningCorpus.normalizedKey(question.nextAyahText),
      spokenText: spoken,
    );
    final stopped = st.copyWith(isRecording: false, recognizedText: spoken);
    if (result.isNoAttempt) {
      final attempts = stopped.emptyAttempts + 1;
      _emit(
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
      _emit(st.copyWith(selfGradeMode: true));
    }
  }

  void revealForSelfGrade() {
    final st = state;
    if (st is ListeningReviewInRound && st.selfGradeMode && !st.isAnswered) {
      _emit(st.copyWith(selfGradeRevealed: true));
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
    if (isClosed) return;
    if (_material == null) {
      await load();
      return;
    }
    _emit(ListeningReviewIdle(_stats.read()));
  }

  void _answer(ListeningReviewInRound st, ListeningOutcome outcome) {
    // Answering ends the listening part: stop the ayah so the next
    // question's audio starts from a stopped player.
    if (st.isPlaying) unawaited(_audio.stop());
    final answer = ListeningAnswer(st.question, outcome);
    _emit(
      st.copyWith(
        current: answer,
        answers: [...st.answers, answer],
        isPlaying: false,
      ),
    );
  }

  Future<void> _playCurrent() async {
    final st = state;
    if (st is! ListeningReviewInRound ||
        st.isPlaying ||
        st.isRecording ||
        st.isAnswered ||
        st.playsLeft <= 0) {
      return;
    }
    _emit(st.copyWith(isPlaying: true, playsUsed: st.playsUsed + 1));
    final played = await _audio.play(st.question.prompt);
    if (isClosed) return;
    final after = state;
    if (after is! ListeningReviewInRound ||
        after.index != st.index ||
        after.question != st.question) {
      return;
    }
    if (played || after.isAnswered) {
      // A failure after the learner already answered changes nothing.
      if (after.isPlaying) _emit(after.copyWith(isPlaying: false));
      return;
    }
    await _replaceUnplayable(after);
  }

  /// Swaps an unplayable question for a spare, or drops it when none is
  /// left. Never scored: an audio failure is not the learner's mistake.
  Future<void> _replaceUnplayable(ListeningReviewInRound st) async {
    final questions = [...st.questions];
    if (_spares.isNotEmpty) {
      questions[st.index] = _spares.first;
      _spares = _spares.skip(1).toList();
    } else {
      questions.removeAt(st.index);
    }
    if (questions.length < ListeningQuizEngine.minQuestions) {
      _emit(const ListeningReviewNotEnough());
      return;
    }
    if (st.index >= questions.length) {
      await _finish(st.mode, st.answers);
      return;
    }
    _emit(
      ListeningReviewInRound(
        mode: st.mode,
        questions: questions,
        index: st.index,
        answers: st.answers,
      ),
    );
    await _playCurrent();
  }

  Future<void> _advance(
    ListeningReviewInRound st,
    List<ListeningAnswer> answers,
  ) async {
    if (st.index + 1 >= st.questions.length) {
      await _finish(st.mode, answers);
      return;
    }
    _emit(
      ListeningReviewInRound(
        mode: st.mode,
        questions: st.questions,
        index: st.index + 1,
        answers: answers,
      ),
    );
    await _playCurrent();
  }

  Future<void> _finish(
    ListeningQuizMode mode,
    List<ListeningAnswer> answers,
  ) async {
    final result = ListeningRoundResult(answers);
    await _stats.record(result, mode: mode);
    _emit(ListeningReviewFinished(result));
  }

  @override
  Future<void> close() async {
    await _capture.cancel();
    await _audio.dispose();
    return super.close();
  }
}
