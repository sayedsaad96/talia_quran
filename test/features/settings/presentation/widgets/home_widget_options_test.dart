import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide
        GlobalCupertinoLocalizations,
        GlobalMaterialLocalizations,
        MaterialLocalizationAr;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/home_widget/home_widget_pin.dart';
import 'package:talia_quran/core/home_widget/widget_section_preferences.dart';
import 'package:talia_quran/core/home_widget/widget_snapshot.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/settings/presentation/widgets/home_widget_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppLocalizations> pump(
    WidgetTester tester, {
    required HomeWidgetPin pin,
    WidgetSectionPreferences? sections,
    WidgetSnapshot? previewSnapshot,
    Locale locale = const Locale('ar'),
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final l10n = await AppLocalizations.delegate.load(locale);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeWidgetOptions(
              pin: pin,
              sections: sections,
              previewSnapshot: previewSnapshot,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return l10n;
  }

  testWidgets('a launcher that can pin shows the add button and feedback', (
    tester,
  ) async {
    var requested = false;
    final l10n = await pump(
      tester,
      pin: HomeWidgetPin(
        isSupported: () async => true,
        installedCount: () async => 0,
        request: () async {
          requested = true;
          return true;
        },
      ),
    );

    await tester.tap(find.text(l10n.settingsHomeWidgetAdd));
    await tester.pump();
    await tester.pump();
    expect(requested, isTrue);
    expect(find.text(l10n.settingsHomeWidgetManualSteps), findsNothing);
    expect(find.text(l10n.settingsHomeWidgetPreviewPrayer), findsOneWidget);
    expect(find.text(l10n.settingsHomeWidgetPinRequested), findsOneWidget);
  });

  testWidgets('shows installed badge when widget is already on home screen', (
    tester,
  ) async {
    final l10n = await pump(
      tester,
      pin: HomeWidgetPin(
        isSupported: () async => true,
        installedCount: () async => 1,
        request: () async => true,
      ),
    );

    expect(find.text(l10n.settingsHomeWidgetInstalled), findsOneWidget);
    expect(find.text(l10n.settingsHomeWidgetAddAnother), findsOneWidget);
  });

  testWidgets(
    'an unsupported launcher shows preview, manual steps, and guards last section',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final sections = WidgetSectionPreferences(
        await SharedPreferences.getInstance(),
      );
      final l10n = await pump(
        tester,
        pin: HomeWidgetPin(
          isSupported: () async => false,
          installedCount: () async => 0,
          request: () async => false,
        ),
        sections: sections,
      );

      expect(find.text(l10n.settingsHomeWidgetAdd), findsNothing);
      expect(find.text(l10n.settingsHomeWidgetUnsupported), findsOneWidget);
      expect(find.text(l10n.settingsHomeWidgetManualSteps), findsOneWidget);
      expect(find.text(l10n.settingsHomeWidgetPreviewPrayer), findsOneWidget);
      expect(find.text(l10n.settingsHomeWidgetShowPrayer), findsOneWidget);
      expect(find.text(l10n.settingsHomeWidgetShowHijri), findsOneWidget);

      // Turn off prayer, reviews, and wird; hijri remains as the last visible section.
      await tester.tap(find.byType(Switch).at(0));
      await tester.pump();
      expect(sections.showPrayer, isFalse);
      expect(find.text(l10n.settingsHomeWidgetPreviewPrayer), findsNothing);

      await tester.tap(find.byType(Switch).at(1));
      await tester.pump();
      await tester.tap(find.byType(Switch).at(2));
      await tester.pump();
      expect(sections.showReviews, isFalse);
      expect(sections.showWird, isFalse);
      expect(sections.showHijri, isTrue);

      // Attempting to turn off the last remaining section is prevented.
      await tester.tap(find.byType(Switch).at(3));
      await tester.pump();
      expect(sections.showHijri, isTrue);
      expect(find.text(l10n.settingsHomeWidgetMinOneSection), findsOneWidget);

      // Re-enabling prayer restores it in the preview.
      await tester.tap(find.byType(Switch).at(0));
      await tester.pump();
      expect(sections.showPrayer, isTrue);
      expect(find.text(l10n.settingsHomeWidgetPreviewPrayer), findsOneWidget);
    },
  );

  testWidgets('size switcher updates preview across small, medium, and large', (
    tester,
  ) async {
    final l10n = await pump(
      tester,
      pin: HomeWidgetPin(
        isSupported: () async => true,
        installedCount: () async => 0,
        request: () async => true,
      ),
    );

    // Default medium shows prayer, review, wird, and hijri, but not the large action.
    expect(find.text(l10n.settingsHomeWidgetPreviewPrayer), findsOneWidget);
    expect(find.text(l10n.settingsHomeWidgetPreviewWird), findsOneWidget);
    expect(find.text(l10n.settingsHomeWidgetPreviewWirdAction), findsNothing);

    // Large adds range, progress indicator, and action button.
    await tester.tap(find.text(l10n.settingsHomeWidgetSizeLarge));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsHomeWidgetPreviewWirdRange), findsOneWidget);
    expect(find.text(l10n.settingsHomeWidgetPreviewWirdAction), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Small keeps only the next prayer line.
    await tester.tap(find.text(l10n.settingsHomeWidgetSizeSmall));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsHomeWidgetPreviewPrayer), findsOneWidget);
    expect(find.text(l10n.settingsHomeWidgetPreviewReview), findsNothing);
    expect(find.text(l10n.settingsHomeWidgetPreviewWird), findsNothing);
  });

  testWidgets('live snapshot preview renders user data in English too', (
    tester,
  ) async {
    final snapshot = WidgetSnapshot(
      nextPrayerKey: 'maghrib',
      nextPrayerAt: DateTime(2026, 11, 20, 17, 45),
      dueReviewCount: 3,
      wirdFromPage: 2,
      wirdToPage: 5,
      wirdDonePages: 1,
      wirdSurahName: 'البقرة',
      wirdSurahNumber: 2,
      hijriLabel: '10 Jumada Al-Thani 1448',
      languageCode: 'en',
    );
    final l10n = await pump(
      tester,
      locale: const Locale('en'),
      pin: HomeWidgetPin(
        isSupported: () async => true,
        installedCount: () async => 0,
        request: () async => true,
      ),
      previewSnapshot: snapshot,
    );

    expect(find.text(l10n.settingsHomeWidgetPreviewLiveBadge), findsOneWidget);
    expect(find.text('10 Jumada Al-Thani 1448'), findsOneWidget);
    expect(find.text('Maghrib · 5:45 PM'), findsOneWidget);
    expect(find.text('3 reviews due'), findsOneWidget);
    expect(find.text('Al-Baqarah · 1/4 pages'), findsOneWidget);
  });
}
