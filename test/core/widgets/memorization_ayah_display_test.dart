import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/widgets/memorization_ayah_display.dart';

void main() {
  Widget host({
    required Locale locale,
    required Brightness brightness,
    required Widget child,
  }) => MaterialApp(
    locale: locale,
    theme: ThemeData(brightness: brightness),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: SingleChildScrollView(
          child: Center(child: SizedBox(width: 280, child: child)),
        ),
      ),
    ),
  );

  testWidgets('uses the Home ayah typography and localized English reference', (
    tester,
  ) async {
    const textColor = Color(0xFF102030);
    const decorationColor = Color(0xFF405060);
    const referenceColor = Color(0xFF708090);

    await tester.pumpWidget(
      host(
        locale: const Locale('en'),
        brightness: Brightness.light,
        child: const MemorizationAyahDisplay(
          text: 'Long display text Long display text Long display text',
          surahId: 2,
          ayahNumber: 255,
          textColor: textColor,
          decorationColor: decorationColor,
          referenceColor: referenceColor,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('﴿'), findsOneWidget);
    expect(find.text('﴾'), findsOneWidget);
    expect(find.text('Surah Al-Baqarah, Ayah 255'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('memorization-ayah-reference'))),
      ),
      TextDirection.ltr,
    );

    final ayah = tester.widget<Text>(
      find.byKey(const Key('memorization-ayah-text')),
    );
    expect(ayah.style?.fontFamily, 'Amiri');
    expect(ayah.style?.fontSize, 24);
    expect(ayah.style?.height, 2);
    expect(ayah.style?.color, textColor);
  });

  testWidgets('uses the localized Arabic reference and supplied dark colors', (
    tester,
  ) async {
    const textColor = Color(0xFFE0E8F0);
    const decorationColor = Color(0xFFB0C0D0);
    const referenceColor = Color(0xFF90A0B0);

    await tester.pumpWidget(
      host(
        locale: const Locale('ar'),
        brightness: Brightness.dark,
        child: const MemorizationAyahDisplay(
          text: 'نص عرض طويل نص عرض طويل نص عرض طويل',
          surahId: 2,
          ayahNumber: 255,
          textColor: textColor,
          decorationColor: decorationColor,
          referenceColor: referenceColor,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('سورة البقرة، آية ٢٥٥'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('memorization-ayah-reference'))),
      ),
      TextDirection.rtl,
    );

    final bracket = tester.widget<Text>(
      find.byKey(const Key('memorization-ayah-opening-bracket')),
    );
    final reference = tester.widget<Text>(
      find.byKey(const Key('memorization-ayah-reference')),
    );
    expect(bracket.style?.color, decorationColor);
    expect(reference.style?.color, referenceColor);
  });
}
