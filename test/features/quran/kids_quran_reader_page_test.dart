import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/quran/presentation/pages/kids_quran_reader_page.dart';

void main() {
  testWidgets('Kids Quran mode can return to Kids Home', (tester) async {
    var returned = false;

    await tester.pumpWidget(
      _TestApp(
        child: KidsQuranReaderContent(
          pageNumber: 604,
          surahName: 'An-Nas',
          onBack: () => returned = true,
          reader: const Center(child: Text('kids quran page content')),
        ),
      ),
    );

    expect(find.text('Kids Quran'), findsOneWidget);
    expect(find.text('kids quran page content'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to Kids Home'));
    await tester.pump();

    expect(returned, isTrue);
  });

  testWidgets('Kids Quran mode does not show adult-only reader controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: KidsQuranReaderContent(
          pageNumber: 604,
          onBack: () {},
          reader: const Center(child: Text('kids quran page content')),
        ),
      ),
    );

    expect(find.text('Copy'), findsNothing);
    expect(find.text('Bookmark'), findsNothing);
    expect(find.text('Tafsir'), findsNothing);
    expect(find.text('Kids Quran'), findsOneWidget);
  });

  testWidgets('Adult Quran route remains separate from Kids Quran route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.quran,
      routes: [
        GoRoute(
          path: AppRoutes.quran,
          builder: (_, _) => const Scaffold(body: Text('adult quran route')),
        ),
        GoRoute(
          path: AppRoutes.memorizationPlusKidsQuran,
          builder: (_, _) => const Scaffold(body: Text('kids quran route')),
        ),
      ],
    );

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('adult quran route'), findsOneWidget);
    expect(find.text('kids quran route'), findsNothing);

    router.go(AppRoutes.memorizationPlusKidsQuran);
    await tester.pumpAndSettle();

    expect(find.text('kids quran route'), findsOneWidget);
    expect(find.text('adult quran route'), findsNothing);
  });

  testWidgets('Kids Quran mode supports Arabic RTL layout', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        locale: const Locale('ar'),
        child: KidsQuranReaderContent(
          pageNumber: 604,
          surahName: 'الناس',
          onBack: () {},
          reader: const Center(child: Text('محتوى القرآن')),
        ),
      ),
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    expect(find.text('قرآن الأطفال'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child, this.locale = const Locale('en')});

  final Widget child;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

class _RouterTestApp extends StatelessWidget {
  const _RouterTestApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
