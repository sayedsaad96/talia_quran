part of 'parent_dashboard_cubit.dart';

/// Localized, UI-mapped feedback codes emitted by [ParentDashboardCubit].
/// The cubit stays free of `BuildContext`/l10n; the page maps these to strings.
enum ParentDashboardFeedbackType {
  pinInvalid,
  pinIncorrect,
  rewardAdded,
  remoteRewardAdded,
  childLinked,
  childRemoved,
  reminderSaved,
  failure,
}

class ParentDashboardFeedback extends Equatable {
  const ParentDashboardFeedback(this.type, {this.message});

  const ParentDashboardFeedback.pinInvalid()
    : type = ParentDashboardFeedbackType.pinInvalid,
      message = null;
  const ParentDashboardFeedback.pinIncorrect()
    : type = ParentDashboardFeedbackType.pinIncorrect,
      message = null;
  const ParentDashboardFeedback.rewardAdded()
    : type = ParentDashboardFeedbackType.rewardAdded,
      message = null;
  const ParentDashboardFeedback.remoteRewardAdded()
    : type = ParentDashboardFeedbackType.remoteRewardAdded,
      message = null;
  const ParentDashboardFeedback.childLinked()
    : type = ParentDashboardFeedbackType.childLinked,
      message = null;
  const ParentDashboardFeedback.childRemoved()
    : type = ParentDashboardFeedbackType.childRemoved,
      message = null;
  const ParentDashboardFeedback.reminderSaved()
    : type = ParentDashboardFeedbackType.reminderSaved,
      message = null;
  const ParentDashboardFeedback.failure(this.message)
    : type = ParentDashboardFeedbackType.failure;

  final ParentDashboardFeedbackType type;
  final String? message;

  bool get isError =>
      type == ParentDashboardFeedbackType.pinInvalid ||
      type == ParentDashboardFeedbackType.pinIncorrect ||
      type == ParentDashboardFeedbackType.failure;

  @override
  List<Object?> get props => [type, message];
}

@immutable
abstract class ParentDashboardState extends Equatable {
  const ParentDashboardState();

  @override
  List<Object?> get props => [];
}

class ParentDashboardInitial extends ParentDashboardState {
  const ParentDashboardInitial();
}

class ParentDashboardLoading extends ParentDashboardState {
  const ParentDashboardLoading();
}

class ParentDashboardNeedsPin extends ParentDashboardState {
  const ParentDashboardNeedsPin({
    required this.settings,
    this.feedback,
    this.feedbackEventId = 0,
  });

  final ParentSettings settings;
  final ParentDashboardFeedback? feedback;

  /// Monotonic id so repeated identical notices still reach the UI listener.
  final int feedbackEventId;

  @override
  List<Object?> get props => [settings, feedback, feedbackEventId];
}

class ParentDashboardLocked extends ParentDashboardState {
  const ParentDashboardLocked({
    required this.settings,
    required this.surahId,
    this.feedback,
    this.feedbackEventId = 0,
  });

  final ParentSettings settings;
  final int surahId;
  final ParentDashboardFeedback? feedback;
  final int feedbackEventId;

  @override
  List<Object?> get props => [settings, surahId, feedback, feedbackEventId];
}

class ParentDashboardLoaded extends ParentDashboardState {
  const ParentDashboardLoaded({
    required this.dashboard,
    required this.remoteChildren,
    required this.surahId,
    this.feedback,
    this.feedbackEventId = 0,
  });

  final ParentDashboard dashboard;
  final List<RemoteChildSummary> remoteChildren;
  final int surahId;

  /// Transient success/validation/failure feedback mapped by the page.
  final ParentDashboardFeedback? feedback;
  final int feedbackEventId;

  ParentDashboardLoaded copyWith({
    ParentDashboardFeedback? feedback,
    int feedbackEventId = 0,
  }) => ParentDashboardLoaded(
    dashboard: dashboard,
    remoteChildren: remoteChildren,
    surahId: surahId,
    feedback: feedback,
    feedbackEventId: feedbackEventId,
  );

  @override
  List<Object?> get props => [
    dashboard,
    remoteChildren,
    surahId,
    feedback,
    feedbackEventId,
  ];
}

class ParentDashboardError extends ParentDashboardState {
  const ParentDashboardError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── T054: New states for typed feedback during linking / unlinking ────────────

/// Emitted while the parent is entering or scanning a child pairing code.
/// Replaces the generic [ParentDashboardLoading] for this specific action so
/// the UI can show targeted progress feedback (e.g. "Verifying pairing code…").
class ParentDashboardLinking extends ParentDashboardState {
  const ParentDashboardLinking({required this.surahId});
  final int surahId;

  @override
  List<Object?> get props => [surahId];
}

/// Emitted while parent mode is being disabled and the child link is severed.
/// Replaces the generic [ParentDashboardLoading] for this specific action so
/// the UI can show targeted feedback (e.g. "Removing guardian link…").
class ParentDashboardUnlinking extends ParentDashboardState {
  const ParentDashboardUnlinking({required this.surahId});
  final int surahId;

  @override
  List<Object?> get props => [surahId];
}
