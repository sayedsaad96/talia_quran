import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/core/widgets/talia_app_bar.dart';

GoRouter _router({required String initialLocation, String fallback = '/'}) {
  Widget page(String name) => Scaffold(
    appBar: TaliaAppBar(title: name, fallbackLocation: fallback),
    body: Text('page:$name'),
  );
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, _) => page('home')),
      GoRoute(path: '/azkar', builder: (_, _) => page('azkar')),
      GoRoute(path: '/azkar/morning', builder: (_, _) => page('morning')),
    ],
  );
}

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pops when there is history', (tester) async {
    final router = _router(initialLocation: '/azkar');
    await _pump(tester, router);
    unawaited(router.push('/azkar/morning'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TaliaBackButton));
    await tester.pumpAndSettle();

    expect(find.text('page:azkar'), findsOneWidget);
  });

  testWidgets('goes to the feature fallback when opened without history', (
    tester,
  ) async {
    // e.g. launched straight into a category from a notification.
    final router = _router(
      initialLocation: '/azkar/morning',
      fallback: AppRoutes.azkar,
    );
    await _pump(tester, router);

    await tester.tap(find.byType(TaliaBackButton));
    await tester.pumpAndSettle();

    expect(find.text('page:azkar'), findsOneWidget);
  });

  testWidgets('shows the title and hides back on tab roots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          appBar: TaliaAppBar(title: 'Azkar', showBackButton: false),
        ),
      ),
    );

    expect(find.text('Azkar'), findsOneWidget);
    expect(find.byType(TaliaBackButton), findsNothing);
  });

  testWidgets('back button has an accessible tooltip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(appBar: TaliaAppBar(title: 'x')),
      ),
    );

    final button = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(TaliaBackButton),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.tooltip, isNotEmpty);
  });

  test('isUnknownLocationError only matches unmatched locations', () {
    expect(
      AppRouter.isUnknownLocationError(
        GoException('no routes for location: /nope'),
      ),
      isTrue,
    );
    expect(
      AppRouter.isUnknownLocationError(GoException('redirect loop detected')),
      isFalse,
    );
    expect(AppRouter.isUnknownLocationError(Exception('network')), isFalse);
    expect(AppRouter.isUnknownLocationError(null), isFalse);
  });
}
