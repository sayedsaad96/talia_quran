import 'package:equatable/equatable.dart';

import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/memorization/listening/listening_quiz_engine.dart';
import '../../../../core/memorization/listening/listening_round_result.dart';
import '../../data/listening/listening_review_stats_store.dart';

sealed class ListeningReviewState extends Equatable {
  const ListeningReviewState();

  @override
  List<Object?> get props => [];
}

final class ListeningReviewLoading extends ListeningReviewState {
  const ListeningReviewLoading();
}

final class ListeningReviewError extends ListeningReviewState {
  const ListeningReviewError();
}

/// Fewer than [ListeningQuizEngine.minQuestions] playable questions.
final class ListeningReviewNotEnough extends ListeningReviewState {
  const ListeningReviewNotEnough();
}

final class ListeningReviewIdle extends ListeningReviewState {
  const ListeningReviewIdle(this.stats);

  final ListeningReviewStats stats;

  @override
  List<Object?> get props => [stats];
}

final class ListeningReviewInRound extends ListeningReviewState {
  const ListeningReviewInRound({
    required this.mode,
    required this.questions,
    required this.index,
    this.answers = const [],
    this.current,
    this.playsUsed = 0,
    this.isPlaying = false,
    this.isRecording = false,
    this.recognizedText = '',
    this.emptyAttempts = 0,
    this.selfGradeMode = false,
    this.selfGradeRevealed = false,
  });

  final ListeningQuizMode mode;
  final List<ListeningQuestion> questions;
  final int index;
  final List<ListeningAnswer> answers;

  /// Answer to the current question once given (drives the reveal view).
  final ListeningAnswer? current;
  final int playsUsed;
  final bool isPlaying;
  final bool isRecording;
  final String recognizedText;
  final int emptyAttempts;

  /// Speech unavailable or declined → reveal + self-grade for this question.
  final bool selfGradeMode;
  final bool selfGradeRevealed;

  ListeningQuestion get question => questions[index];
  bool get isAnswered => current != null;
  int get playsLeft => ListeningQuizEngine.maxPlays - playsUsed;

  ListeningReviewInRound copyWith({
    int? index,
    List<ListeningAnswer>? answers,
    ListeningAnswer? current,
    bool clearCurrent = false,
    int? playsUsed,
    bool? isPlaying,
    bool? isRecording,
    String? recognizedText,
    int? emptyAttempts,
    bool? selfGradeMode,
    bool? selfGradeRevealed,
  }) => ListeningReviewInRound(
    mode: mode,
    questions: questions,
    index: index ?? this.index,
    answers: answers ?? this.answers,
    current: clearCurrent ? null : (current ?? this.current),
    playsUsed: playsUsed ?? this.playsUsed,
    isPlaying: isPlaying ?? this.isPlaying,
    isRecording: isRecording ?? this.isRecording,
    recognizedText: recognizedText ?? this.recognizedText,
    emptyAttempts: emptyAttempts ?? this.emptyAttempts,
    selfGradeMode: selfGradeMode ?? this.selfGradeMode,
    selfGradeRevealed: selfGradeRevealed ?? this.selfGradeRevealed,
  );

  @override
  List<Object?> get props => [
    mode,
    questions,
    index,
    answers,
    current,
    playsUsed,
    isPlaying,
    isRecording,
    recognizedText,
    emptyAttempts,
    selfGradeMode,
    selfGradeRevealed,
  ];
}

final class ListeningReviewFinished extends ListeningReviewState {
  const ListeningReviewFinished(this.result);

  final ListeningRoundResult result;

  @override
  List<Object?> get props => [result];
}
