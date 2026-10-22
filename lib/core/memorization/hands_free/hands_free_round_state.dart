import 'package:equatable/equatable.dart';

import '../listening/listening_question.dart';

/// The lifecycle stage for one hands-free practice round.
enum HandsFreePhase { prompt, userTurn, feedback, finished, paused }

/// A self-reported outcome for the current prompt.
enum HandsFreeGrade { correct, review }

/// Immutable state for a synchronous hands-free practice round.
final class HandsFreeRoundState extends Equatable {
  HandsFreeRoundState({
    required this.phase,
    required List<ListeningAyahRef> items,
    required this.currentIndex,
    required List<HandsFreeGrade?> grades,
  }) : items = List.unmodifiable(items),
       grades = List.unmodifiable(grades);

  final HandsFreePhase phase;
  final List<ListeningAyahRef> items;
  final int currentIndex;
  final List<HandsFreeGrade?> grades;

  ListeningAyahRef? get currentAyah =>
      currentIndex >= 0 && currentIndex < items.length
      ? items[currentIndex]
      : null;

  bool get isTerminal =>
      phase == HandsFreePhase.finished || phase == HandsFreePhase.paused;

  @override
  List<Object?> get props => [phase, items, currentIndex, grades];
}

/// Read-only totals from graded items in a hands-free practice round.
final class HandsFreeRoundSummary extends Equatable {
  HandsFreeRoundSummary({
    required this.correctCount,
    required this.reviewCount,
    required List<ListeningAyahRef> reviewAyahs,
  }) : reviewAyahs = List.unmodifiable(reviewAyahs);

  const HandsFreeRoundSummary.empty()
    : correctCount = 0,
      reviewCount = 0,
      reviewAyahs = const [];

  final int correctCount;
  final int reviewCount;
  final List<ListeningAyahRef> reviewAyahs;

  @override
  List<Object?> get props => [correctCount, reviewCount, reviewAyahs];
}
