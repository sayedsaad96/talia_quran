import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_scheduling_engine.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_hero_card.dart';

void main() {
  final testPlan = KhatmahPlan(
    id: 'khatmah-1',
    title: 'Ramadan Khatmah',
    startPage: 1,
    completedPages: {for (var page = 1; page <= 30; page++) page},
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
    status: KhatmahStatus.active,
    dedication: const KhatmahDedication(
      isDedicated: true,
      recipientName: 'Beloved Mother',
      relationship: 'Mother',
      condition: DedicationCondition.deceased,
    ),
  );

  Widget createWidgetUnderTest({
    required KhatmahPlan plan,
    bool isDark = false,
    ValueChanged<String>? onNavigate,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: KhatmahHeroCard(
              plan: plan,
              isDark: isDark,
            ),
          ),
        ),
        GoRoute(
          path: '/quran/page/:page',
          builder: (context, state) {
            final page = state.pathParameters['page'];
            final mode = state.uri.queryParameters['mode'];
            onNavigate?.call('/quran/page/$page?mode=$mode');
            return Scaffold(
              body: Text('Page: $page, Mode: $mode'),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  testWidgets('renders plan title, percentage and progress bar', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(plan: testPlan));
    await tester.pumpAndSettle();

    expect(find.text('Ramadan Khatmah'), findsOneWidget);
    final percentage = (testPlan.progressPercentage * 100).toStringAsFixed(0);
    expect(find.text('$percentage%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('renders today\'s wird page range correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(plan: testPlan));
    await tester.pumpAndSettle();

    final wird = KhatmahSchedulingEngine.todaysWird(
      testPlan.currentPage,
      testPlan.targetPagesPerDay,
    );
    expect(
      find.text('Today: pages ${wird.startPage} - ${wird.endPage}'),
      findsOneWidget,
    );
  });

  testWidgets('renders dedication when isDedicated is true and recipientName exists', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(plan: testPlan));
    await tester.pumpAndSettle();

    expect(find.text('Dedicated to: Beloved Mother'), findsOneWidget);
  });

  testWidgets('does not render dedication when dedication is none', (tester) async {
    final planWithoutDedication = testPlan.copyWith(
      dedication: const KhatmahDedication(isDedicated: false),
    );
    await tester.pumpWidget(createWidgetUnderTest(plan: planWithoutDedication));
    await tester.pumpAndSettle();

    expect(find.textContaining('Dedicated to:'), findsNothing);
  });

  testWidgets('tapping card navigates to /quran/page/{wird.startPage}?mode=khatmah', (tester) async {
    String? navigatedRoute;
    await tester.pumpWidget(
      createWidgetUnderTest(
        plan: testPlan,
        onNavigate: (route) => navigatedRoute = route,
      ),
    );
    await tester.pumpAndSettle();

    final wird = KhatmahSchedulingEngine.todaysWird(
      testPlan.currentPage,
      testPlan.targetPagesPerDay,
    );

    await tester.tap(find.byType(KhatmahHeroCard));
    await tester.pumpAndSettle();

    expect(navigatedRoute, '/quran/page/${wird.startPage}?mode=khatmah');
    expect(find.text('Page: ${wird.startPage}, Mode: khatmah'), findsOneWidget);
  });

  testWidgets('renders correctly in dark mode', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(plan: testPlan, isDark: true));
    await tester.pumpAndSettle();

    expect(find.text('Ramadan Khatmah'), findsOneWidget);
  });
}
