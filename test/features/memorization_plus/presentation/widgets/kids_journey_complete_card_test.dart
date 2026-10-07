import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_journey_complete_card.dart';

void main() {
  testWidgets('journey completion renders a real celebration (W2)', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: KidsJourneyCompleteCard())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // A finished journey is the strongest milestone in the kids loop — the
    // trophy and confetti replace the previous generic empty state.
    expect(find.byIcon(TaliaKidsIcons.trophy), findsOneWidget);
    expect(find.byType(ConfettiWidget), findsOneWidget);
    // The path opens with Al-Fatiha, so the milestone names both (K27).
    expect(
      find.textContaining('Al-Fatiha and the whole Juz Amma'),
      findsOneWidget,
    );
  });
}
