import 'package:equatable/equatable.dart';
import 'adult_journey_suggestion.dart';

enum DailyReviewTaskStatus {
  ready,
  noReviews,
  noDueReview,
  blockedByPriority,
  unavailable,
}

class DailyReviewTaskDecision extends Equatable {
  const DailyReviewTaskDecision({
    required this.status,
    required this.ownerId,
    required this.localDate,
    this.suggestion,
    this.decisionKey,
  });
  final DailyReviewTaskStatus status;
  final String ownerId;
  final String localDate;
  final AdultJourneySuggestion? suggestion;
  final String? decisionKey;
  int? get estimatedMinutes => suggestion?.estimatedMinutes;
  bool get exceedsBudget => suggestion?.exceedsBudget ?? false;
  AdultJourneySuggestionReason? get reason => suggestion?.reason;
  @override
  List<Object?> get props => [
    status,
    ownerId,
    localDate,
    suggestion,
    decisionKey,
  ];
}
