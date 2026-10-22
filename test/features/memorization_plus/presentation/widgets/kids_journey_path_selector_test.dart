import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_journey_path_selector.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('shows three options and reports the tapped one', (tester) async {
    KidsJourneyPathId? reported;
    await tester.pumpWidget(
      app(
        KidsJourneyPathSelector(
          value: KidsJourneyPathId.juzAmmaAdventure,
          onChanged: (id) => reported = id,
        ),
      ),
    );

    expect(find.byType(RadioListTile<KidsJourneyPathId>), findsNWidgets(3));
    expect(find.text('Memorization path'), findsOneWidget);
    expect(find.text('Juz Amma adventure'), findsOneWidget);

    await tester.tap(find.text('Quran journey: An-Nas to Al-Baqarah'));
    await tester.pump();

    expect(reported, KidsJourneyPathId.quranFromNas);
  });
}
