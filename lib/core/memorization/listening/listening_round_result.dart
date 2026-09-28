import 'package:equatable/equatable.dart';

import 'listening_question.dart';

enum ListeningOutcome { correct, hesitant, wrong, skipped }

final class ListeningAnswer extends Equatable {
  const ListeningAnswer(this.question, this.outcome);

  final ListeningQuestion question;
  final ListeningOutcome outcome;

  /// The ayah the learner should review when this answer is weak: the heard
  /// ayah for "which surah", the missed continuation for "next ayah".
  ListeningAyahRef get reviewTarget => switch (question) {
    WhichSurahQuestion(:final prompt) => prompt,
    final NextAyahQuestion q => q.answer,
  };

  bool get isWeak =>
      outcome == ListeningOutcome.wrong || outcome == ListeningOutcome.hesitant;

  @override
  List<Object?> get props => [question, outcome];
}

final class ListeningRoundResult extends Equatable {
  const ListeningRoundResult(this.answers);

  final List<ListeningAnswer> answers;

  /// Answers that count toward the score (skipped audio failures do not).
  int get scored =>
      answers.where((a) => a.outcome != ListeningOutcome.skipped).length;

  int get correct =>
      answers.where((a) => a.outcome == ListeningOutcome.correct).length;

  /// Distinct review targets of weak answers, in round order.
  List<ListeningAyahRef> get weakLinks {
    final seen = <ListeningAyahRef>{};
    return [
      for (final answer in answers)
        if (answer.isWeak && seen.add(answer.reviewTarget)) answer.reviewTarget,
    ];
  }

  @override
  List<Object?> get props => [answers];
}
