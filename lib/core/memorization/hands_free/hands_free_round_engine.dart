import '../../../features/memorization_plus/domain/entities/ayah_review_record.dart';
import '../listening/listening_corpus.dart';
import '../listening/listening_question.dart';
import '../review_due_evaluator.dart';
import '../review_record_filters.dart';
import 'hands_free_round_state.dart';

/// Pure, synchronous state transitions for a hands-free practice round.
final class HandsFreeRoundEngine {
  const HandsFreeRoundEngine({
    required ListeningCorpus corpus,
    ReviewDueEvaluator dueEvaluator = const ReviewDueEvaluator(),
  }) : _corpus = corpus,
       _dueEvaluator = dueEvaluator;

  static const defaultMaxItems = 10;

  final ListeningCorpus _corpus;
  final ReviewDueEvaluator _dueEvaluator;

  HandsFreeRoundState start({
    required List<AyahReviewRecord> due,
    required DateTime now,
    int maxItems = defaultMaxItems,
  }) {
    if (maxItems < 1) return _finished();

    final eligible =
        due.where((record) => _isEligible(record, now)).toList(growable: false)
          ..sort(_compareRecords);
    if (eligible.isEmpty) return _finished();

    final selectedSurah = eligible.first.surahId;
    final refs = <ListeningAyahRef>[];
    final seen = <ListeningAyahRef>{};
    for (final record in eligible) {
      if (record.surahId != selectedSurah || refs.length == maxItems) continue;
      final ref = ListeningAyahRef(record.surahId, record.ayahNumber);
      if (seen.add(ref)) refs.add(ref);
    }
    if (refs.isEmpty) return _finished();

    return HandsFreeRoundState(
      phase: HandsFreePhase.prompt,
      items: refs,
      currentIndex: 0,
      grades: List<HandsFreeGrade?>.filled(refs.length, null),
    );
  }

  HandsFreeRoundState onPromptFinished(HandsFreeRoundState state) {
    if (state.phase != HandsFreePhase.prompt) return state;
    return _withPhase(state, HandsFreePhase.userTurn);
  }

  HandsFreeRoundState grade(HandsFreeRoundState state, HandsFreeGrade grade) {
    if (state.phase != HandsFreePhase.userTurn || state.currentAyah == null) {
      return state;
    }
    final grades = List<HandsFreeGrade?>.from(state.grades)
      ..[state.currentIndex] = grade;
    return HandsFreeRoundState(
      phase: HandsFreePhase.feedback,
      items: state.items,
      currentIndex: state.currentIndex,
      grades: grades,
    );
  }

  HandsFreeRoundState next(HandsFreeRoundState state) {
    if (state.phase != HandsFreePhase.feedback) return state;
    if (state.currentIndex + 1 == state.items.length) {
      return _withPhase(state, HandsFreePhase.finished);
    }
    return HandsFreeRoundState(
      phase: HandsFreePhase.prompt,
      items: state.items,
      currentIndex: state.currentIndex + 1,
      grades: state.grades,
    );
  }

  HandsFreeRoundState interrupt(HandsFreeRoundState state) {
    if (state.isTerminal) return state;
    return _withPhase(state, HandsFreePhase.paused);
  }

  HandsFreeRoundSummary summarize(HandsFreeRoundState state) {
    var correctCount = 0;
    final reviewAyahs = <ListeningAyahRef>[];
    for (var index = 0; index < state.grades.length; index++) {
      switch (state.grades[index]) {
        case HandsFreeGrade.correct:
          correctCount++;
        case HandsFreeGrade.review:
          reviewAyahs.add(state.items[index]);
        case null:
          break;
      }
    }
    return HandsFreeRoundSummary(
      correctCount: correctCount,
      reviewCount: reviewAyahs.length,
      reviewAyahs: List.unmodifiable(reviewAyahs),
    );
  }

  bool _isEligible(AyahReviewRecord record, DateTime now) {
    final ref = ListeningAyahRef(record.surahId, record.ayahNumber);
    return ReviewRecordFilters.isAdultCompatible(record) &&
        record.totalReviews > 0 &&
        _corpus.textOf(ref) != null &&
        _dueEvaluator.isDue(
          now: now,
          scheduledAt: record.nextReviewDate,
          policy: ReviewDuePolicy.onOrAfterScheduledTime,
        );
  }

  int _compareRecords(AyahReviewRecord first, AyahReviewRecord second) {
    final dueComparison = first.nextReviewDate.compareTo(second.nextReviewDate);
    if (dueComparison != 0) return dueComparison;
    final surahComparison = first.surahId.compareTo(second.surahId);
    if (surahComparison != 0) return surahComparison;
    return first.ayahNumber.compareTo(second.ayahNumber);
  }

  HandsFreeRoundState _finished() => HandsFreeRoundState(
    phase: HandsFreePhase.finished,
    items: const [],
    currentIndex: -1,
    grades: const [],
  );

  HandsFreeRoundState _withPhase(
    HandsFreeRoundState state,
    HandsFreePhase phase,
  ) => HandsFreeRoundState(
    phase: phase,
    items: state.items,
    currentIndex: state.currentIndex,
    grades: state.grades,
  );
}

/// Returns half of an ayah's duration, clamped to the practice prompt range.
Duration promptClipLength(Duration ayahDuration) {
  const minimum = Duration(seconds: 1);
  const maximum = Duration(seconds: 3);
  final half = Duration(microseconds: ayahDuration.inMicroseconds ~/ 2);
  if (half < minimum) return minimum;
  if (half > maximum) return maximum;
  return half;
}
