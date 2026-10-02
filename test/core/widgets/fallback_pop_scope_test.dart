import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/widgets/fallback_pop_scope.dart';

void main() {
  GoRouter buildRouter(String initialLocation) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/page'),
            child: const Text('Home'),
          ),
        ),
      ),
      GoRoute(
        path: '/page',
        builder: (_, _) => const FallbackPopScope(
          fallbackLocation: '/',
          child: Scaffold(body: Text('Page')),
        ),
      ),
    ],
  );

  testWidgets('without history, back goes to the fallback', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: buildRouter('/page')),
    );
    await tester.pumpAndSettle();

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('with history, back pops normally', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter('/')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Page'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Page'), findsNothing);
  });
}
