import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/router/widget_wird_route.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';

void main() {
  final now = DateTime(2026, 10, 23, 22);

  KhatmahPlan plan({
    Set<int> completedPages = const {10},
    KhatmahStatus status = KhatmahStatus.active,
  }) {
    return KhatmahPlan(
      id: 'plan',
      title: 'plan',
      startPage: 1,
      completedPages: completedPages,
      targetPagesPerDay: 3,
      targetDays: 200,
      startDate: now.subtract(const Duration(days: 1)),
      expectedEndDate: now.add(const Duration(days: 200)),
      status: status,
      dailyTargetDate: now,
      dailyTargetStartPage: 10,
      dailyTargetEndPage: 12,
    );
  }

  test('opens the first unread page of today\'s wird', () {
    expect(
      widgetWirdReadingRoute(plan(), now),
      '/quran/page/11?mode=khatmah',
    );
    expect(
      widgetWirdReadingRoute(plan(completedPages: const {10, 11, 12}), now),
      '/quran/page/12?mode=khatmah',
    );
  });

  test('a missing plan opens setup and a paused plan opens the dashboard', () {
    expect(widgetWirdReadingRoute(null, now), AppRoutes.khatmahSetup);
    expect(
      widgetWirdReadingRoute(plan(status: KhatmahStatus.paused), now),
      AppRoutes.khatmahDashboard,
    );
  });
}
