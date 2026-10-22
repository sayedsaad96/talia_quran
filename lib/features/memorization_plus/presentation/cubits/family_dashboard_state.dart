part of 'family_dashboard_cubit.dart';

/// Localized feedback codes for [FamilyDashboardCubit].
enum FamilyDashboardFeedbackType {
  pinInvalid,
  pinIncorrect,
  pinMismatch,
  childRemoved,
  nicknameSaved,
  childIdentitySaved,
  childLinked,
  rewardAdded,
  remoteRewardAdded,
  rewardUnlocked,
  rewardApproved,
  reminderSaved,
  houseSizeSaved,
  settingsSaved,
  accountPasswordIncorrect,
  accountCheckUnavailable,
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
  const FamilyDashboardFeedback.childIdentitySaved()
    : type = FamilyDashboardFeedbackType.childIdentitySaved,
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
  const FamilyDashboardFeedback.rewardUnlocked()
    : type = FamilyDashboardFeedbackType.rewardUnlocked,
      message = null;
  const FamilyDashboardFeedback.rewardApproved()
    : type = FamilyDashboardFeedbackType.rewardApproved,
      message = null;
  const FamilyDashboardFeedback.reminderSaved()
    : type = FamilyDashboardFeedbackType.reminderSaved,
      message = null;
  const FamilyDashboardFeedback.houseSizeSaved()
    : type = FamilyDashboardFeedbackType.houseSizeSaved,
      message = null;
  const FamilyDashboardFeedback.settingsSaved()
    : type = FamilyDashboardFeedbackType.settingsSaved,
      message = null;
  const FamilyDashboardFeedback.accountPasswordIncorrect()
    : type = FamilyDashboardFeedbackType.accountPasswordIncorrect,
      message = null;
  const FamilyDashboardFeedback.accountCheckUnavailable()
    : type = FamilyDashboardFeedbackType.accountCheckUnavailable,
      message = null;
  const FamilyDashboardFeedback.failure(this.message)
    : type = FamilyDashboardFeedbackType.failure;

  final FamilyDashboardFeedbackType type;
  final String? message;

  bool get isError =>
      type == FamilyDashboardFeedbackType.pinInvalid ||
      type == FamilyDashboardFeedbackType.pinIncorrect ||
      type == FamilyDashboardFeedbackType.accountPasswordIncorrect ||
      type == FamilyDashboardFeedbackType.accountCheckUnavailable ||
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
    this.canSkip = false,
  });

  final FamilyDashboardFeedback? feedback;
  final int feedbackEventId;

  /// True on the guardian's own phone, where the lock is optional.
  final bool canSkip;

  @override
  List<Object?> get props => [feedback, feedbackEventId, canSkip];
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

/// One «ما الجديد» line: a milestone the guardian has not seen for [child].
class GuardianNewsItem extends Equatable {
  const GuardianNewsItem({
    required this.childKey,
    required this.child,
    required this.milestone,
  });

  /// `local` for the child on this device, else the linked child's id.
  final String childKey;
  final FamilyChildEntry child;
  final GuardianMilestone milestone;

  @override
  List<Object?> get props => [childKey, child, milestone];
}

/// Dashboard is unlocked and data is loaded.
class FamilyDashboardLoaded extends FamilyDashboardState {
  const FamilyDashboardLoaded({
    required this.dashboard,
    this.feedback,
    this.feedbackEventId = 0,
    this.news = const [],
  });

  final FamilyDashboard dashboard;
  final FamilyDashboardFeedback? feedback;
  final int feedbackEventId;

  /// Unseen milestones; empty when the feature is off or nothing is new.
  final List<GuardianNewsItem> news;

  FamilyDashboardLoaded copyWith({
    FamilyDashboard? dashboard,
    FamilyDashboardFeedback? feedback,
    int feedbackEventId = 0,
    List<GuardianNewsItem>? news,
  }) => FamilyDashboardLoaded(
    dashboard: dashboard ?? this.dashboard,
    feedback: feedback,
    feedbackEventId: feedbackEventId,
    news: news ?? this.news,
  );

  @override
  List<Object?> get props => [dashboard, feedback, feedbackEventId, news];
}

class FamilyDashboardError extends FamilyDashboardState {
  const FamilyDashboardError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
