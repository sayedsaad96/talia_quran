import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/settings/presentation/pages/sources_licenses_page.dart';

Future<void> _pump(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SourcesLicensesPage(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets('shows the Tanzil notice and link (${locale.languageCode})', (
      tester,
    ) async {
      await _pump(tester, locale);

      expect(
        find.text(SourcesLicensesPage.tanzilNotice),
        findsOneWidget,
        reason: 'Tanzil license requires its notice verbatim',
      );
      expect(find.textContaining('tanzil.net'), findsOneWidget);
      expect(find.textContaining('Tanzil'), findsWidgets);
    });
  }

  testWidgets('opens the open-source licenses page', (tester) async {
    await _pump(tester, const Locale('en'));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-source-licenses')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('open-source-licenses')));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
