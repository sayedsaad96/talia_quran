import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/router/open_location.dart';

void main() {
  test('tab roots are recognised, deeper screens are not', () {
    expect(isShellTabLocation(AppRoutes.quran), isTrue);
    expect(isShellTabLocation('${AppRoutes.memorizationHub}?x=1'), isTrue);
    expect(isShellTabLocation('/quran/page/4'), isFalse);
    expect(isShellTabLocation(AppRoutes.memorizationV2Session), isFalse);
  });

  testWidgets('a tab location replaces the stack instead of stacking', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => context.openLocation(AppRoutes.quran),
                  child: const Text('tab'),
                ),
                TextButton(
                  onPressed: () => context.openLocation('/quran/page/4'),
                  child: const Text('page'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.quran,
          builder: (_, _) => const Scaffold(body: Text('Quran tab')),
        ),
        GoRoute(
          path: '/quran/page/:page',
          builder: (_, _) => const Scaffold(body: Text('Reader')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('page'));
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    router.pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('tab'));
    await tester.pumpAndSettle();
    expect(find.text('Quran tab'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}
