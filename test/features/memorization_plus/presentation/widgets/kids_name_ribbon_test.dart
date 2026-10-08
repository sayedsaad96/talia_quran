import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/presentation/theme/kids_theme.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_mission_card.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_name_ribbon.dart';

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

bool _isRibbonImage(Widget w) =>
    w is Image &&
    w.image is AssetImage &&
    (w.image as AssetImage).assetName == KidsTheme.ribbonBannerAsset;

void main() {
  testWidgets('ribbon shows the child name', (tester) async {
    await tester.pumpWidget(_host(const KidsNameRibbon(name: 'يوسف')));

    expect(find.text('يوسف'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a very long name stays inside the ribbon', (tester) async {
    await tester.pumpWidget(
      _host(const KidsNameRibbon(name: 'عبد الرحمن بن محمد الأنصاري الكبير')),
    );

    expect(tester.takeException(), isNull);
    final ribbon = tester.getRect(find.byType(KidsNameRibbon));
    for (final text in find.byType(Text).evaluate()) {
      final rect = tester.getRect(find.byWidget(text.widget));
      expect(rect.width, lessThanOrEqualTo(ribbon.width));
    }
  });

  testWidgets('mission card shows the name instead of the Talia image', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const KidsMissionCard(stage: null, childName: 'مريم')),
    );

    expect(find.byType(KidsNameRibbon), findsOneWidget);
    expect(find.byWidgetPredicate(_isRibbonImage), findsNothing);
  });

  for (final empty in <String?>[null, '', '   ']) {
    testWidgets('mission card keeps the Talia image for name "$empty"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(KidsMissionCard(stage: null, childName: empty)),
      );

      expect(find.byType(KidsNameRibbon), findsNothing);
      expect(find.byWidgetPredicate(_isRibbonImage), findsOneWidget);
    });
  }
}
