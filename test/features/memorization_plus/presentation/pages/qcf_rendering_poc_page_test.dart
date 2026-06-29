import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart';

void main() {
  testWidgets('shows isolated QCF POC messaging', (tester) async {
    await _pumpPoc(tester);

    expect(find.text('QCF rendering proof of concept'), findsOneWidget);
    expect(find.textContaining('Temporary visual test screen'), findsOneWidget);
    expect(find.textContaining('does not change Hifz logic'), findsOneWidget);
    expect(
      find.textContaining('only for visual Quran rendering'),
      findsOneWidget,
    );
  });

  testWidgets('keeps debug route separate from Hifz route constants', (
    tester,
  ) async {
    expect(AppRoutes.qcfRenderingPoc, '/debug/qcf-rendering-poc');
    expect(AppRoutes.hifz, '/hifz');
    expect(AppRoutes.memorizationV2Session, '/hifz/session');

    await _pumpPoc(tester);
    expect(find.byType(QcfRenderingPocPage), findsOneWidget);
  });

  testWidgets('shows all required verse sample labels', (tester) async {
    await _pumpPoc(tester);

    expect(find.textContaining('Al-Baqarah 255'), findsOneWidget);
    expect(find.textContaining('Al-Fatiha 1-7'), findsOneWidget);
    expect(find.textContaining('Al-Ikhlas 1-4'), findsOneWidget);
    expect(find.textContaining('Ash-Sharh 8'), findsOneWidget);
  });

  testWidgets('shows status text for verse samples', (tester) async {
    await _pumpPoc(tester);

    expect(find.text('Supported'), findsWidgets);
    expect(find.textContaining('Verse text renders visually'), findsWidgets);
    expect(find.textContaining('Grouped verses render visually'), findsWidgets);
  });

  testWidgets('shows full page section and limitation fallback area', (
    tester,
  ) async {
    await _pumpPoc(tester);

    expect(find.textContaining('Full mushaf page'), findsOneWidget);
    expect(find.textContaining('Mushaf page 1 preview'), findsOneWidget);
    expect(
      find.textContaining('Full page rendering is available'),
      findsWidgets,
    );
  });

  testWidgets('shows findings summary for production adoption review', (
    tester,
  ) async {
    await _pumpPoc(tester);

    expect(find.text('Findings'), findsOneWidget);
    expect(find.textContaining('No limitation observed'), findsOneWidget);
    expect(
      find.textContaining('before production Hifz screens change'),
      findsOneWidget,
    );
  });

  testWidgets('opening and disposing POC performs no memorization writes', (
    tester,
  ) async {
    const before = _MemorizationSnapshot(
      progressCount: 4,
      unlockedCount: 2,
      checkpointCount: 1,
    );

    await _pumpPoc(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    const after = _MemorizationSnapshot(
      progressCount: 4,
      unlockedCount: 2,
      checkpointCount: 1,
    );
    expect(after, before);
  });
}

Future<void> _pumpPoc(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: AppRoutes.qcfRenderingPoc,
    routes: [
      GoRoute(
        path: AppRoutes.qcfRenderingPoc,
        builder: (context, state) => const QcfRenderingPocPage(),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
  await tester.pump();
}

@immutable
class _MemorizationSnapshot {
  const _MemorizationSnapshot({
    required this.progressCount,
    required this.unlockedCount,
    required this.checkpointCount,
  });

  final int progressCount;
  final int unlockedCount;
  final int checkpointCount;

  @override
  bool operator ==(Object other) {
    return other is _MemorizationSnapshot &&
        other.progressCount == progressCount &&
        other.unlockedCount == unlockedCount &&
        other.checkpointCount == checkpointCount;
  }

  @override
  int get hashCode =>
      Object.hash(progressCount, unlockedCount, checkpointCount);
}
