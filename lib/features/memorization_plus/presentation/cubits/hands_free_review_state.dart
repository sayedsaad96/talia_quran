import 'package:equatable/equatable.dart';
import '../../../../core/memorization/hands_free/hands_free_round_state.dart';

final class HandsFreeReviewState extends Equatable {
  const HandsFreeReviewState({
    this.round,
    this.micAvailable = false,
    this.firstUseWarningPending = true,
    this.loading = false,
    this.hasError = false,
  });
  final HandsFreeRoundState? round;
  final bool micAvailable, firstUseWarningPending, loading, hasError;
  HandsFreeRoundSummary get summary =>
      round?.summary ?? const HandsFreeRoundSummary.empty();

  HandsFreeReviewState copyWith({
    HandsFreeRoundState? round,
    bool? micAvailable,
    bool? firstUseWarningPending,
    bool? loading,
    bool? hasError,
  }) => HandsFreeReviewState(
    round: round ?? this.round,
    micAvailable: micAvailable ?? this.micAvailable,
    firstUseWarningPending:
        firstUseWarningPending ?? this.firstUseWarningPending,
    loading: loading ?? this.loading,
    hasError: hasError ?? this.hasError,
  );
  @override
  List<Object?> get props => [
    round,
    micAvailable,
    firstUseWarningPending,
    loading,
    hasError,
  ];
}
