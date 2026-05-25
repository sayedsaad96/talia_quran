part of 'quiz_cubit.dart';

@immutable
abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {
  const QuizInitial();
}

class QuizLoading extends QuizState {
  const QuizLoading();
}

class QuizQuestion extends QuizState {
  const QuizQuestion({
    required this.surahId,
    required this.ayahNumber,
    required this.hint,
    required this.questionIndex,
    required this.totalQuestions,
    required this.passedSoFar,
  });

  final int surahId;
  final int ayahNumber;
  final String hint;
  final int questionIndex;
  final int totalQuestions;
  final int passedSoFar;

  @override
  List<Object?> get props => [
    surahId,
    ayahNumber,
    hint,
    questionIndex,
    totalQuestions,
  ];
}

class QuizAnswerResult extends QuizState {
  const QuizAnswerResult({
    required this.surahId,
    required this.ayahNumber,
    required this.correctText,
    required this.userText,
    required this.similarity,
    required this.passed,
    required this.questionIndex,
    required this.totalQuestions,
    this.newAwards = const [],
  });

  final int surahId;
  final int ayahNumber;
  final String correctText;
  final String userText;
  final double similarity;
  final bool passed;
  final int questionIndex;
  final int totalQuestions;
  final List<CertificateAward> newAwards;

  int get scorePercent => (similarity * 100).round();

  @override
  List<Object?> get props => [
    surahId,
    ayahNumber,
    similarity,
    passed,
    questionIndex,
    newAwards,
  ];
}

class QuizCompleted extends QuizState {
  const QuizCompleted({
    required this.totalQuestions,
    required this.passedCount,
    required this.failedCount,
    required this.overallScore,
  });

  final int totalQuestions;
  final int passedCount;
  final int failedCount;
  final double overallScore;

  int get scorePercent => (overallScore * 100).round();

  @override
  List<Object?> get props => [totalQuestions, passedCount, failedCount];
}

class QuizError extends QuizState {
  const QuizError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
