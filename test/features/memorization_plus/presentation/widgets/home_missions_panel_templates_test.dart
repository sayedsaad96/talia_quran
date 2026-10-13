import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/home_missions_panel.dart';

void main() {
  Future<List<String>> pump(
    WidgetTester tester, {
    KidsAgeBand? band,
    List<String>? added,
  }) async {
    final out = added ?? <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeMissionsPanel(
            missions: const [],
            templateAgeBand: band,
            onAdd: out.add,
            onAcknowledge: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('child-detail-add-home-mission')),
    );
    await tester.pumpAndSettle();
    return out;
  }

  Finder chip(String id) => find.byKey(ValueKey('home-mission-template-$id'));

  testWidgets('without a band the dialog keeps the original four chips', (
    tester,
  ) async {
    await pump(tester);

    for (final id in ['tidyRoom', 'helpTable', 'kindWord', 'shareToy']) {
      expect(chip(id), findsOneWidget, reason: id);
    }
    expect(chip('tellLearning'), findsNothing);
    expect(chip('prepareBag'), findsNothing);
  });

  testWidgets('the 8-12 band offers the school-bag template, not the toy', (
    tester,
  ) async {
    await pump(tester, band: KidsAgeBand.eightToTwelve);

    expect(chip('prepareBag'), findsOneWidget);
    expect(chip('tellLearning'), findsOneWidget);
    expect(chip('shareToy'), findsNothing);
  });

  testWidgets('the 5-7 band offers the toy template, not the school bag', (
    tester,
  ) async {
    await pump(tester, band: KidsAgeBand.fiveToSeven);

    expect(chip('shareToy'), findsOneWidget);
    expect(chip('prepareBag'), findsNothing);
  });

  testWidgets('a template can be edited before it is assigned', (tester) async {
    final added = await pump(tester, band: KidsAgeBand.eightToTwelve);

    await tester.tap(chip('prepareBag'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Pack the blue bag');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(added, ['Pack the blue bag']);
  });

  testWidgets('a double tap on Save assigns once and keeps the page open', (
    tester,
  ) async {
    final added = await pump(tester, band: KidsAgeBand.eightToTwelve);

    await tester.tap(chip('tellLearning'));
    await tester.pump();
    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(added, ['Tell your family one thing you learned today']);
    expect(find.byType(HomeMissionsPanel), findsOneWidget);
  });
}
