import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/home_widget/home_widget_pin.dart';
import 'package:talia_quran/core/home_widget/widget_section_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/settings/presentation/widgets/home_widget_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppLocalizations> pump(
    WidgetTester tester, {
    required HomeWidgetPin pin,
    WidgetSectionPreferences? sections,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeWidgetOptions(pin: pin, sections: sections),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return l10n;
  }

  testWidgets('a launcher that can pin shows the add button', (tester) async {
    var requested = false;
    final l10n = await pump(
      tester,
      pin: HomeWidgetPin(
        isSupported: () async => true,
        request: () async {
          requested = true;
          return true;
        },
      ),
    );

    await tester.tap(find.text(l10n.settingsHomeWidgetAdd));
    await tester.pump();
    expect(requested, isTrue);
    expect(find.text(l10n.settingsHomeWidgetManualSteps), findsNothing);
    expect(find.text(l10n.settingsHomeWidgetPreviewPrayer), findsOneWidget);
  });

  testWidgets('an unsupported launcher shows a preview and the manual steps', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final sections = WidgetSectionPreferences(
      await SharedPreferences.getInstance(),
    );
    final l10n = await pump(
      tester,
      pin: HomeWidgetPin(
        isSupported: () async => false,
        request: () async => false,
      ),
      sections: sections,
    );

    expect(find.text(l10n.settingsHomeWidgetAdd), findsNothing);
    expect(find.text(l10n.settingsHomeWidgetUnsupported), findsOneWidget);
    expect(find.text(l10n.settingsHomeWidgetManualSteps), findsOneWidget);
    expect(find.text(l10n.settingsHomeWidgetPreviewPrayer), findsOneWidget);
    expect(find.text(l10n.settingsHomeWidgetShowPrayer), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(sections.showPrayer, isFalse);
    expect(find.text(l10n.settingsHomeWidgetPreviewPrayer), findsNothing);
    expect(find.text(l10n.settingsHomeWidgetPreviewReview), findsOneWidget);
    expect(find.text(l10n.settingsHomeWidgetPreviewWird), findsOneWidget);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pump();
    await tester.tap(find.byType(Switch).at(2));
    await tester.pump();
    expect(find.text(l10n.settingsHomeWidgetPreviewReview), findsNothing);
    expect(find.text(l10n.settingsHomeWidgetPreviewWird), findsNothing);

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(find.text(l10n.settingsHomeWidgetPreviewPrayer), findsOneWidget);
  });
}
