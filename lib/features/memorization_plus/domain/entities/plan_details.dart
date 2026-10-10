import 'package:equatable/equatable.dart';

import '../../../../core/memorization/progress_metrics.dart';
import 'custom_memorization_plan.dart';
import 'daily_plan.dart';

class PlanSurahProgress extends Equatable {
  const PlanSurahProgress({
    required this.surahId,
    required this.totalAyahs,
    required this.startedAyahs,
    required this.memorizedAyahs,
  });

  final int surahId;
  final int totalAyahs;
  final int startedAyahs;
  final int memorizedAyahs;
  int get learningAyahs => startedAyahs - memorizedAyahs;
  double get progress => memorizedAyahs / totalAyahs;

  @override
  List<Object?> get props => [
    surahId,
    totalAyahs,
    startedAyahs,
    memorizedAyahs,
  ];
}

class PlanDetails extends Equatable {
  const PlanDetails({
    required this.plan,
    required this.metrics,
    required this.totalAyahs,
    required this.surahProgress,
    this.dailyPlan,
    this.nextReviewAt,
  });

  final CustomMemorizationPlan plan;
  final ProgressMetrics metrics;
  final int totalAyahs;
  final List<PlanSurahProgress> surahProgress;
  final DailyPlan? dailyPlan;
  final DateTime? nextReviewAt;

  int get unstartedAyahs => totalAyahs - metrics.startedAyahs;
  int get remainingAyahs => totalAyahs - metrics.memorizedAyahs;
  int get todayReviewAyahs =>
      dailyPlan?.requiredAyahs.where((ayah) => !ayah.isNew).length ?? 0;
  bool get canStartSession =>
      dailyPlan != null &&
      dailyPlan!.totalItems > 0 &&
      !dailyPlan!.isRequiredPlanCompleted;

  @override
  List<Object?> get props => [
    plan,
    metrics,
    totalAyahs,
    surahProgress,
    dailyPlan,
    nextReviewAt,
  ];
}
