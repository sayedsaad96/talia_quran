import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_scheduling_engine.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_hero_card.dart';

void main() {
  for (final locale in ['ar', 'en']) {
    testWidgets(
      'Home Khatmah error in $locale is distinct from no plan and retryable',
      (tester) async {
        var failed = true;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: KhatmahHeroCard(
                  isDark: false,
                  error: failed ? const FormatException('corrupt') : null,
                  onRetry: () => setState(() => failed = false),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('khatmah_hero_start_button')),
          findsNothing,
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(KhatmahHeroCard)),
        );
        expect(find.text(l10n.khatmahUnableToLoadYourKhatmah), findsOneWidget);
        await tester.tap(find.text(l10n.khatmahRetry));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('khatmah_hero_start_button')),
          findsOneWidget,
        );
      },
    );
  }
  testWidgets(
    'retained Home target rolls to next day without explicit reload',
    (tester) async {
      var now = DateTime(2026, 9, 4, 23, 59);
      final plan = KhatmahPlan(
        id: 'p',
        title: 'P',
        completedPages: {1, 2, 3, 4},
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 9, 1),
        expectedEndDate: DateTime(2027, 1, 1),
        dailyTargetDate: DateTime(2026, 9, 4),
        dailyTargetStartPage: 1,
        dailyTargetEndPage: 4,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: KhatmahHeroCard(plan: plan, isDark: false, now: () => now),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1 - 4'), findsOneWidget);
      now = DateTime(2026, 9, 5);
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('Today: pages 5 - 8'), findsOneWidget);
    },
  );
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
    KhatmahPlan? plan,
    bool isDark = false,
    ValueChanged<String>? onNavigate,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: KhatmahHeroCard(plan: plan, isDark: isDark),
          ),
        ),
        GoRoute(
          path: '/khatmah/dashboard',
          builder: (context, state) {
            onNavigate?.call('/khatmah/dashboard');
            return const Scaffold(body: Text('Khatmah Dashboard'));
          },
        ),
        GoRoute(
          path: '/khatmah/setup',
          builder: (context, state) {
            onNavigate?.call('/khatmah/setup');
            return const Scaffold(body: Text('Khatmah Setup'));
          },
        ),
        GoRoute(
          path: '/quran/page/:page',
          builder: (context, state) {
            final page = state.pathParameters['page'];
            final mode = state.uri.queryParameters['mode'];
            onNavigate?.call('/quran/page/$page?mode=$mode');
            return Scaffold(body: Text('Page: $page, Mode: $mode'));
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  testWidgets('renders plan title, percentage and progress bar', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest(plan: testPlan));
    await tester.pumpAndSettle();

    expect(find.text('Ramadan Khatmah'), findsOneWidget);
    final percentage = (testPlan.progressPercentage * 100).toStringAsFixed(0);
    expect(find.text('$percentage%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'completed daily range stays visible and extra reading starts unread',
    (tester) async {
      final anchored = testPlan.copyWith(
        dailyTargetDate: DateTime.now(),
        dailyTargetStartPage: 27,
        dailyTargetEndPage: 30,
      );
      String? destination;
      await tester.pumpWidget(
        createWidgetUnderTest(
          plan: anchored,
          onNavigate: (value) => destination = value,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('27 - 30'), findsOneWidget);
      expect(find.textContaining('completed'), findsOneWidget);
      await tester.tap(find.text('Ramadan Khatmah'));
      await tester.pumpAndSettle();
      expect(destination, '/quran/page/31?mode=khatmah');
    },
  );

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

  testWidgets(
    'renders dedication when isDedicated is true and recipientName exists',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(plan: testPlan));
      await tester.pumpAndSettle();

      expect(find.text('Dedicated to: Beloved Mother'), findsOneWidget);
    },
  );

  testWidgets('does not render dedication when dedication is none', (
    tester,
  ) async {
    final planWithoutDedication = testPlan.copyWith(
      dedication: const KhatmahDedication(isDedicated: false),
    );
    await tester.pumpWidget(createWidgetUnderTest(plan: planWithoutDedication));
    await tester.pumpAndSettle();

    expect(find.textContaining('Dedicated to:'), findsNothing);
  });

  testWidgets(
    'tapping card navigates to /quran/page/{wird.startPage}?mode=khatmah',
    (tester) async {
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
      expect(
        find.text('Page: ${wird.startPage}, Mode: khatmah'),
        findsOneWidget,
      );
    },
  );

  testWidgets('renders correctly in dark mode', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(plan: testPlan, isDark: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ramadan Khatmah'), findsOneWidget);
  });

  testWidgets('paused Khatmah offers Resume without opening the reader', (
    tester,
  ) async {
    String? navigatedRoute;
    await tester.pumpWidget(
      createWidgetUnderTest(
        plan: testPlan.copyWith(status: KhatmahStatus.paused),
        onNavigate: (route) => navigatedRoute = route,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('khatmah_hero_resume_button')));
    await tester.pumpAndSettle();

    expect(navigatedRoute, '/khatmah/dashboard');
  });

  testWidgets('completed Khatmah routes to setup, never to the reader', (
    tester,
  ) async {
    String? navigatedRoute;
    await tester.pumpWidget(
      createWidgetUnderTest(
        plan: testPlan.copyWith(status: KhatmahStatus.completed),
        onNavigate: (route) => navigatedRoute = route,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('khatmah_hero_start_button')));
    await tester.pumpAndSettle();
    expect(navigatedRoute, '/khatmah/setup');
  });

  testWidgets('no Khatmah plan exposes Start Khatmah and routes to setup', (
    tester,
  ) async {
    String? navigatedRoute;
    await tester.pumpWidget(
      createWidgetUnderTest(onNavigate: (route) => navigatedRoute = route),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('khatmah_hero_start_button')));
    await tester.pumpAndSettle();

    expect(navigatedRoute, '/khatmah/setup');
  });
}
