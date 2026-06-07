part of 'daily_plan_cubit.dart';

@immutable
abstract class DailyPlanState extends Equatable {
  const DailyPlanState();
  @override
  List<Object?> get props => [];
}

class DailyPlanInitial extends DailyPlanState {
  const DailyPlanInitial();
}

class DailyPlanLoading extends DailyPlanState {
  const DailyPlanLoading();
}

class DailyPlanKidsRedirect extends DailyPlanState {
  const DailyPlanKidsRedirect();
}

class DailyPlanLoaded extends DailyPlanState {
  const DailyPlanLoaded({
    required this.plan,
    required this.surahId,
    this.lastEvaluatedAyah,
    this.lastRating,
    this.newAwards = const [],
  });
  final DailyPlan plan;
  final int surahId;
  final int? lastEvaluatedAyah;
  final PerformanceRating? lastRating;
  final List<CertificateAward> newAwards;

  bool get allDone => plan.completedCount >= plan.totalItems;

  @override
  List<Object?> get props => [
    plan,
    surahId,
    lastEvaluatedAyah,
    lastRating,
    newAwards,
  ];
}

class DailyPlanEvaluating extends DailyPlanState {
  const DailyPlanEvaluating({
    required this.plan,
    required this.surahId,
    required this.evaluatingAyah,
  });
  final DailyPlan plan;
  final int surahId;
  final int evaluatingAyah;

  @override
  List<Object?> get props => [plan, surahId, evaluatingAyah];
}

class DailyPlanError extends DailyPlanState {
  const DailyPlanError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
