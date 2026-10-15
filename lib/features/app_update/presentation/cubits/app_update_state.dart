import 'package:equatable/equatable.dart';

enum AppUpdateUiStatus { idle, installReady, completing, completionFailed }

class AppUpdateState extends Equatable {
  const AppUpdateState({
    this.status = AppUpdateUiStatus.idle,
    this.promptRevision = 0,
  });

  final AppUpdateUiStatus status;
  final int promptRevision;

  AppUpdateState copyWith({AppUpdateUiStatus? status, int? promptRevision}) =>
      AppUpdateState(
        status: status ?? this.status,
        promptRevision: promptRevision ?? this.promptRevision,
      );

  @override
  List<Object> get props => [status, promptRevision];
}
