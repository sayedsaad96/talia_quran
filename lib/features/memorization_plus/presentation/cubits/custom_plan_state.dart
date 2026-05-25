part of 'custom_plan_cubit.dart';

@immutable
abstract class CustomPlanState extends Equatable {
  const CustomPlanState();

  @override
  List<Object?> get props => [];
}

class CustomPlanInitial extends CustomPlanState {
  const CustomPlanInitial();
}

class CustomPlanLoading extends CustomPlanState {
  const CustomPlanLoading();
}

class CustomPlanEmpty extends CustomPlanState {
  const CustomPlanEmpty();
}

class CustomPlanLoaded extends CustomPlanState {
  const CustomPlanLoaded({required this.plan});
  final CustomMemorizationPlan plan;

  @override
  List<Object?> get props => [plan];
}

class CustomPlanSaved extends CustomPlanState {
  const CustomPlanSaved({required this.plan});
  final CustomMemorizationPlan plan;

  @override
  List<Object?> get props => [plan];
}

class CustomPlanError extends CustomPlanState {
  const CustomPlanError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
