import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_start_khatmah_card.dart';

void main() {
  Widget buildHarness({
    required Widget child,
    String locale = 'ar',
    double textScale = 1.0,
  }) {
    return MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    );
  }

  for (final locale in ['ar', 'en']) {
    testWidgets('HomeStartKhatmahCard renders copy properly in $locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildHarness(
          locale: locale,
          child: HomeStartKhatmahCard(
            skin: HomeSkin.forBrightness(Brightness.light),
            isDark: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(HomeStartKhatmahCard)),
      );
      expect(find.text(l10n.homeStartKhatmahTitle), findsOneWidget);
      expect(find.text(l10n.homeStartKhatmahSubtitle), findsOneWidget);
      expect(find.text(l10n.homeStartKhatmahCta), findsOneWidget);
    });
  }

  testWidgets('HomeStartKhatmahCard tapping CTA triggers onStart callback', (
    tester,
  ) async {
    var started = false;
    await tester.pumpWidget(
      buildHarness(
        child: HomeStartKhatmahCard(
          skin: HomeSkin.forBrightness(Brightness.dark),
          isDark: true,
          onStart: () => started = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeStartKhatmahCard)),
    );
    await tester.tap(find.text(l10n.homeStartKhatmahCta));
    await tester.pumpAndSettle();

    expect(started, isTrue);
  });

  testWidgets('HomeStartKhatmahCard does not overflow at text scale 2.0', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        textScale: 2.0,
        child: HomeStartKhatmahCard(
          skin: HomeSkin.forBrightness(Brightness.light),
          isDark: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
