part of 'parent_dashboard_cubit.dart';

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
  const ParentDashboardNeedsPin({required this.settings});
  final ParentSettings settings;

  @override
  List<Object?> get props => [settings];
}

class ParentDashboardLocked extends ParentDashboardState {
  const ParentDashboardLocked({
    required this.settings,
    required this.surahId,
    this.message,
  });

  final ParentSettings settings;
  final int surahId;
  final String? message;

  @override
  List<Object?> get props => [settings, surahId, message];
}

class ParentDashboardLoaded extends ParentDashboardState {
  const ParentDashboardLoaded({
    required this.dashboard,
    required this.remoteChildren,
    required this.surahId,
    this.message,
  });

  final ParentDashboard dashboard;
  final List<RemoteChildSummary> remoteChildren;
  final int surahId;
  final String? message;

  ParentDashboardLoaded copyWith({String? message}) => ParentDashboardLoaded(
    dashboard: dashboard,
    remoteChildren: remoteChildren,
    surahId: surahId,
    message: message,
  );

  @override
  List<Object?> get props => [dashboard, remoteChildren, surahId, message];
}

class ParentDashboardError extends ParentDashboardState {
  const ParentDashboardError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
