import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/features/memorization_plus/application/guardian_session_controller.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/guardian_session_scope.dart';

const _kids = '/kids?surahId=78';

GoRouter _router() => GoRouter(
  initialLocation: _kids,
  routes: [
    GoRoute(
      path: '/kids',
      builder: (context, state) => Scaffold(
        body: TextButton(
          onPressed: () => context.push('/family'),
          child: Text('kids ${state.uri.queryParameters['surahId']}'),
        ),
      ),
    ),
    GoRoute(
      path: '/family',
      builder: (context, state) => const GuardianSessionScope(
        ownsSession: true,
        child: Scaffold(body: Center(child: Text('dashboard'))),
      ),
    ),
  ],
);

void main() {
  late GuardianSessionController session;
  late DateTime now;

  setUp(() {
    now = DateTime.utc(2026, 10, 5, 9);
    session = GuardianSessionController(clock: () => now);
    getIt.registerSingleton<GuardianSessionController>(session);
  });

  tearDown(() async {
    session.dispose();
    await getIt.reset();
  });

  Future<GoRouter> openDashboard(WidgetTester tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    session.start(returnLocation: _kids);
    await tester.tap(find.text('kids 78'));
    await tester.pumpAndSettle();
    expect(find.text('dashboard'), findsOneWidget);
    return router;
  }

  testWidgets('an ended session returns to the same kids screen', (
    tester,
  ) async {
    await openDashboard(tester);

    session.end();
    await tester.pumpAndSettle();

    expect(find.text('dashboard'), findsNothing);
    expect(find.text('kids 78'), findsOneWidget);
  });

  testWidgets('leaving the dashboard ends the session', (tester) async {
    final router = await openDashboard(tester);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.text('kids 78'), findsOneWidget);
    expect(session.isActive, isFalse);
  });

  Future<void> sleepFor(WidgetTester tester, Duration away) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(away);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  testWidgets('a long stay in the background closes the dashboard', (
    tester,
  ) async {
    await openDashboard(tester);

    await sleepFor(tester, const Duration(minutes: 3));

    expect(session.isActive, isFalse);
    expect(find.text('kids 78'), findsOneWidget);
  });

  testWidgets('a short stay in the background keeps the dashboard', (
    tester,
  ) async {
    await openDashboard(tester);

    await sleepFor(tester, const Duration(minutes: 1));

    expect(session.isActive, isTrue);
    expect(find.text('dashboard'), findsOneWidget);
    session.end();
    await tester.pumpAndSettle();
  });

  testWidgets('without a session the scope changes nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GuardianSessionScope(ownsSession: true, child: Text('plain')),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: Text('gone')));

    expect(session.isActive, isFalse);
    expect(find.text('gone'), findsOneWidget);
  });
}
