import '../../../azkar/domain/entities/azkar_entities.dart';
import '../../../memorization_plus/domain/entities/daily_plan.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../entities/today_checklist.dart';

class TodayChecklistParams {
  const TodayChecklistParams({
    required this.progress,
    required this.wirdPage,
    required this.wirdComplete,
    required this.readingRoute,
    required this.memorizeRoute,
    required this.reviewRoute,
    required this.azkarRoute,
    required this.azkarComplete,
    this.dailyPlan,
    this.azkarCategory = AzkarCategory.morning,
    this.memorizedToday = false,
    this.reviewedToday = false,
  });

  final OverallProgress progress;
  final int wirdPage;
  final bool wirdComplete;
  final String readingRoute;
  final String memorizeRoute;
  final String reviewRoute;
  final String azkarRoute;
  final bool azkarComplete;
  final DailyPlan? dailyPlan;
  final AzkarCategory azkarCategory;

  /// A memorization session was logged during the current local day.
  final bool memorizedToday;

  /// A review session was logged during the current local day.
  final bool reviewedToday;
}

class GetTodayChecklistUsecase {
  const GetTodayChecklistUsecase();

  TodayChecklist call(TodayChecklistParams params) {
    // Reading task represents the daily wird exclusively.
    // Khatmah progress is tracked separately via its own hero card.
    final readingComplete = params.wirdComplete;
    final readingDetail = '${params.wirdPage}';

    // Lifetime memorization says nothing about today, so completion needs
    // either a finished daily plan or a session logged during this day.
    final plan = params.dailyPlan;
    final memorizeComplete = plan != null
        ? plan.isRequiredPlanCompleted
        : params.memorizedToday;
    final memorizeCurrent = plan?.requiredCompletedCount ?? 0;
    final memorizeTotal = plan?.totalItems ?? 0;

    // An empty due queue is not work the user performed today.
    final overdue = params.progress.overdueReviews;
    final reviewComplete = params.reviewedToday;

    return TodayChecklist(
      tasks: [
        TodayTask(
          kind: TodayTaskKind.reading,
          route: params.readingRoute,
          isComplete: readingComplete,
          current: readingComplete ? 1 : 0,
          total: 1,
          detail: readingDetail,
        ),
        TodayTask(
          kind: TodayTaskKind.memorize,
          route: params.memorizeRoute,
          isComplete: memorizeComplete,
          current: memorizeCurrent,
          total: memorizeTotal,
        ),
        TodayTask(
          kind: TodayTaskKind.review,
          route: params.reviewRoute,
          isComplete: reviewComplete,
          current: reviewComplete ? 1 : 0,
          total: 1,
          detail: overdue > 0 ? '$overdue' : null,
        ),
        TodayTask(
          kind: TodayTaskKind.azkar,
          route: params.azkarRoute,
          isComplete: params.azkarComplete,
          current: params.azkarComplete ? 1 : 0,
          total: 1,
          detail: params.azkarCategory.name,
        ),
      ],
    );
  }
}
