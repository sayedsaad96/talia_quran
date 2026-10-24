import 'khatmah_plan.dart';

/// Elapsed time cannot establish that the learner finished the final page.
bool requiresKhatmahReadConfirmation(
  KhatmahPlan plan,
  int pageNumber,
  DateTime date,
) {
  if (pageNumber < 1 ||
      pageNumber > 604 ||
      plan.completedPages.contains(pageNumber)) {
    return false;
  }
  if (plan.remainingPages == 1) return true;
  final target = plan.dailyTargetFor(date);
  if (pageNumber == target.endPage) return true;
  return pageNumber >= target.startPage &&
      pageNumber <= target.endPage &&
      plan.dailyCompletedPages(date) == target.endPage - target.startPage;
}
