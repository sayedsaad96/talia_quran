import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/experience/feature_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/settings/presentation/pages/subpages/features_settings_page.dart';

void main() {
  late FeaturePreferences store;

  Future<AppLocalizations> pumpPage(WidgetTester tester) async {
    // The page is a lazy ListView: a tall surface builds every row.
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: FeaturesSettingsPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    return l10n;
  }

  Future<void> register({Set<ExperienceFeature> off = const {}}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final flags = ExperienceFlags(
      (key) => !off.contains(
        ExperienceFeature.values.firstWhere((f) => f.storageKey == key),
      ),
    );
    store = FeaturePreferences(
      prefs,
      const FixedRecordOwnerProvider('a'),
      flags,
    );
    getIt.registerSingleton<FeaturePreferences>(store);
  }

  setUp(() async {});

  tearDown(() async {
    if (getIt.isRegistered<FeaturePreferences>()) {
      getIt.unregister<FeaturePreferences>();
    }
  });

  Finder rowSwitch(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Row)),
    matching: find.byType(Switch),
  );

  testWidgets('shows every available feature grouped', (tester) async {
    await register();
    final l10n = await pumpPage(tester);
    expect(find.text(l10n.settingsFeatureReaderRepeatTitle), findsOneWidget);
    expect(find.text(l10n.settingsFeatureAyahNotesTitle), findsOneWidget);
    expect(find.text(l10n.settingsFeatureAudioDownloadsTitle), findsOneWidget);
    expect(find.text(l10n.settingsFeatureStrengthOverlayTitle), findsOneWidget);
    expect(
      find.text(l10n.settingsFeatureForgettingForecastTitle),
      findsOneWidget,
    );
    expect(find.text(l10n.settingsFeaturePrayerReviewTitle), findsOneWidget);
    expect(find.text(l10n.settingsFeatureHandsFreeTitle), findsOneWidget);
    expect(
      find.text(l10n.settingsFeatureAfterPrayerAzkarTitle),
      findsOneWidget,
    );
    expect(find.text(l10n.settingsFeatureGroupKhatmahTitle), findsOneWidget);
    expect(find.text(l10n.settingsFeatureHomeWidgetTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a rollout-off feature never appears', (tester) async {
    await register(off: {ExperienceFeature.audioDownloads});
    final l10n = await pumpPage(tester);
    expect(find.text(l10n.settingsFeatureAudioDownloadsTitle), findsNothing);
    expect(find.text(l10n.settingsFeatureReaderRepeatTitle), findsOneWidget);
  });

  testWidgets('toggling a row persists the preference', (tester) async {
    await register();
    final l10n = await pumpPage(tester);
    expect(store.isEnabled(ExperienceFeature.readerRepeat), isTrue);
    await tester.tap(rowSwitch(l10n.settingsFeatureReaderRepeatTitle));
    await tester.pump(const Duration(milliseconds: 100));
    expect(store.isEnabled(ExperienceFeature.readerRepeat), isFalse);
  });

  testWidgets(
    'the strength row links to the reader instead of a second switch',
    (tester) async {
      await register();
      final l10n = await pumpPage(tester);
      final row = find.ancestor(
        of: find.text(l10n.settingsFeatureStrengthOverlayTitle),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: row, matching: find.byType(Switch)),
        findsNothing,
      );
      expect(
        find.descendant(of: row, matching: find.byType(TextButton)),
        findsOneWidget,
      );
    },
  );

  testWidgets('the try-it action disappears while a row is switched off', (
    tester,
  ) async {
    await register();
    final l10n = await pumpPage(tester);
    final tryButton = find.descendant(
      of: find.ancestor(
        of: find.text(l10n.settingsFeatureAyahNotesTitle),
        matching: find.byType(Row),
      ),
      matching: find.byType(TextButton),
    );
    expect(tryButton, findsOneWidget);
    await tester.tap(rowSwitch(l10n.settingsFeatureAyahNotesTitle));
    await tester.pump(const Duration(milliseconds: 100));
    expect(store.isEnabled(ExperienceFeature.ayahNotes), isFalse);
    expect(tryButton, findsNothing);
  });

  testWidgets('restore defaults turns everything back on', (tester) async {
    await register();
    final l10n = await pumpPage(tester);
    await store.setEnabled(ExperienceFeature.readerRepeat, false);
    await tester.tap(find.text(l10n.settingsRestoreDefaults));
    await tester.pump(const Duration(milliseconds: 100));
    expect(store.isEnabled(ExperienceFeature.readerRepeat), isTrue);
  });
}
