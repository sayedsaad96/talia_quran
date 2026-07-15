part of 'family_dashboard_cubit.dart';

/// Localized feedback codes for [FamilyDashboardCubit].
enum FamilyDashboardFeedbackType {
  pinInvalid,
  pinIncorrect,
  pinMismatch,
  childRemoved,
  nicknameSaved,
  childLinked,
  rewardAdded,
  remoteRewardAdded,
  reminderSaved,
  failure,
}

class FamilyDashboardFeedback extends Equatable {
  const FamilyDashboardFeedback(this.type, {this.message});

  const FamilyDashboardFeedback.pinInvalid()
      : type = FamilyDashboardFeedbackType.pinInvalid,
        message = null;
  const FamilyDashboardFeedback.pinIncorrect()
      : type = FamilyDashboardFeedbackType.pinIncorrect,
        message = null;
  const FamilyDashboardFeedback.childRemoved()
      : type = FamilyDashboardFeedbackType.childRemoved,
        message = null;
  const FamilyDashboardFeedback.nicknameSaved()
      : type = FamilyDashboardFeedbackType.nicknameSaved,
        message = null;
  const FamilyDashboardFeedback.childLinked()
      : type = FamilyDashboardFeedbackType.childLinked,
        message = null;
  const FamilyDashboardFeedback.rewardAdded()
      : type = FamilyDashboardFeedbackType.rewardAdded,
        message = null;
  const FamilyDashboardFeedback.remoteRewardAdded()
      : type = FamilyDashboardFeedbackType.remoteRewardAdded,
        message = null;
  const FamilyDashboardFeedback.reminderSaved()
      : type = FamilyDashboardFeedbackType.reminderSaved,
        message = null;
  const FamilyDashboardFeedback.failure(this.message)
      : type = FamilyDashboardFeedbackType.failure;

  final FamilyDashboardFeedbackType type;
  final String? message;

  bool get isError =>
      type == FamilyDashboardFeedbackType.pinInvalid ||
      type == FamilyDashboardFeedbackType.pinIncorrect ||
      type == FamilyDashboardFeedbackType.failure;

  @override
  List<Object?> get props => [type, message];
}

@immutable
abstract class FamilyDashboardState extends Equatable {
  const FamilyDashboardState();

  @override
  List<Object?> get props => [];
}

class FamilyDashboardInitial extends FamilyDashboardState {
  const FamilyDashboardInitial();
}

class FamilyDashboardLoading extends FamilyDashboardState {
  const FamilyDashboardLoading();
}

/// Parent has not created a PIN yet.
class FamilyDashboardNeedsPin extends FamilyDashboardState {
  const FamilyDashboardNeedsPin({
    this.feedback,
    this.feedbackEventId = 0,
  });

  final FamilyDashboardFeedback? feedback;
  final int feedbackEventId;

  @override
  List<Object?> get props => [feedback, feedbackEventId];
}

/// Parent has a PIN but it hasn't been entered yet.
class FamilyDashboardLocked extends FamilyDashboardState {
  const FamilyDashboardLocked({
    required this.settings,
    this.feedback,
    this.feedbackEventId = 0,
  });

  final ParentSettings settings;
  final FamilyDashboardFeedback? feedback;
  final int feedbackEventId;

  @override
  List<Object?> get props => [settings, feedback, feedbackEventId];
}

/// Dashboard is unlocked and data is loaded.
class FamilyDashboardLoaded extends FamilyDashboardState {
  const FamilyDashboardLoaded({
    required this.dashboard,
    this.feedback,
    this.feedbackEventId = 0,
  });

  final FamilyDashboard dashboard;
  final FamilyDashboardFeedback? feedback;
  final int feedbackEventId;

  FamilyDashboardLoaded copyWith({
    FamilyDashboard? dashboard,
    FamilyDashboardFeedback? feedback,
    int feedbackEventId = 0,
  }) =>
      FamilyDashboardLoaded(
        dashboard: dashboard ?? this.dashboard,
        feedback: feedback,
        feedbackEventId: feedbackEventId,
      );

  @override
  List<Object?> get props => [dashboard, feedback, feedbackEventId];
}

class FamilyDashboardError extends FamilyDashboardState {
  const FamilyDashboardError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
