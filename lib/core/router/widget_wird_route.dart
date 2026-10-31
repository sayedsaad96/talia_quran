import '../../features/khatmah/domain/entities/khatmah_plan.dart';
import 'app_router.dart';

/// Opens the first unread page of today's wird. The widget intent stays
/// `talia://widget/wird` with no page number, so a stale tap cannot name a
/// page and the account lease is checked before this runs.
String widgetWirdReadingRoute(KhatmahPlan? plan, DateTime now) {
  if (plan == null) return AppRoutes.khatmahSetup;
  if (plan.status != KhatmahStatus.active || plan.isComplete) {
    return AppRoutes.khatmahDashboard;
  }
  final range = plan.dailyTargetFor(now);
  final start = range.startPage;
  final end = range.endPage;
  if (start < 1 || end < start || end > 604) return AppRoutes.khatmahDashboard;
  var page = end;
  for (var candidate = start; candidate <= end; candidate++) {
    if (!plan.completedPages.contains(candidate)) {
      page = candidate;
      break;
    }
  }
  return '/quran/page/$page?mode=khatmah';
}
