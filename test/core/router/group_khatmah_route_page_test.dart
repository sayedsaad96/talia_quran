import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/router/group_khatmah_route_page.dart';
import '../../features/group_khatmah/data/group_khatmah_test_support.dart'
    as data;
import '../../features/group_khatmah/presentation/group_khatmah_detail_page_test.dart'
    as ui;

void main() {
  testWidgets('revocation removes nested group detail before the next frame', (
    tester,
  ) async {
    final environment = data.MutableEnvironment();
    final repository = ui.FakeGroupRepository(ui.sampleGroup());
    final owner = data.MutableOwner(ui.ownerId);
    final router = GoRouter(
      initialLocation: AppRoutes.groupKhatmah,
      routes: [
        GoRoute(
          path: AppRoutes.groupKhatmah,
          builder: (_, _) => GroupKhatmahRoutePage(
            environment: environment,
            owner: owner,
            repository: repository,
          ),
        ),
        GoRoute(
          path: AppRoutes.khatmahDashboard,
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await repository.dispose();
      await environment.dispose();
    });
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shared reading'));
    await tester.pumpAndSettle();
    expect(find.text('Owner Name'), findsWidgets);
    environment.setAdult(false);
    await tester.pump();
    expect(find.text('Owner Name'), findsNothing);
    expect(find.text('ABC234'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
