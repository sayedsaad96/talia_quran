import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/core/seasons/season_preferences.dart';
import 'package:talia_quran/core/services/hijri_date_adjustment.dart';
import 'package:talia_quran/features/home/domain/services/home_occasion_service.dart';
import 'package:talia_quran/features/seasons/domain/last_ten_reminder.dart';
import 'package:talia_quran/features/settings/presentation/pages/subpages/seasons_settings_page.dart';

void main() {
  late SharedPreferences prefs;
  late SeasonPreferences seasons;

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
        home: SeasonsSettingsPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    return l10n;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    seasons = SeasonPreferences(prefs, const FixedRecordOwnerProvider('a'));
    getIt.registerSingleton<SeasonPreferences>(seasons);
    // HijriAdjustmentTile reads both from get_it.
    final adjustment = HijriDateAdjustment(prefs);
    getIt.registerSingleton<HijriDateAdjustment>(adjustment);
    getIt.registerSingleton<HomeOccasionService>(
      HomeOccasionService(hijriOffsetDays: () => adjustment.days),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('renders the master switch, every season and reminders', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);
    expect(find.text(l10n.settingsSeasonsMasterTitle), findsOneWidget);
    expect(find.text(l10n.settingsSeasonsShaban), findsOneWidget);
    expect(find.text(l10n.settingsSeasonsRamadan), findsOneWidget);
    expect(find.text(l10n.settingsSeasonsEid), findsOneWidget);
    expect(find.text(l10n.settingsSeasonsHajj), findsOneWidget);
    expect(find.text(l10n.settingsSeasonsNewYear), findsOneWidget);
    expect(find.text(l10n.settingsSeasonsAshura), findsOneWidget);
    expect(find.text(l10n.settingsSeasonsFriday), findsOneWidget);
    expect(find.text(l10n.settingsSeasonsWhiteDays), findsOneWidget);
    expect(find.text(l10n.settingsSeasonsMonThu), findsOneWidget);
    expect(find.text(l10n.settingsSeasonsRemindersTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Monday/Thursday defaults off, the Eid row drives both ids', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);
    expect(seasons.isSeasonEnabled(SeasonId.monThu), isFalse);

    // The switch sits in the same row: tap the switch nearest the label.
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text(l10n.settingsSeasonsEid),
          matching: find.byType(Row),
        ),
        matching: find.byType(Switch),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(seasons.isSeasonEnabled(SeasonId.eidFitr), isFalse);
    expect(seasons.isSeasonEnabled(SeasonId.shawwalSix), isFalse);
  });

  testWidgets('the master switch off disables rows but keeps choices', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text(l10n.settingsSeasonsMasterTitle),
          matching: find.byType(Row),
        ),
        matching: find.byType(Switch),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(seasons.masterEnabled, isFalse);

    final disabled = tester.widget<Switch>(
      find.descendant(
        of: find.ancestor(
          of: find.text(l10n.settingsSeasonsRamadan),
          matching: find.byType(Row),
        ),
        matching: find.byType(Switch),
      ),
    );
    expect(disabled.onChanged, isNull);
    expect(seasons.isSeasonEnabled(SeasonId.ramadan), isTrue);
  });

  testWidgets('reminders default off and the toggle persists', (tester) async {
    final l10n = await pumpPage(tester);
    expect(seasons.remindersEnabled, isFalse);
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text(l10n.settingsSeasonsRemindersTitle),
          matching: find.byType(Row),
        ),
        matching: find.byType(Switch),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(seasons.remindersEnabled, isTrue);
  });

  testWidgets('reminders off also clears the last-ten opt-in; on does not set it', (
    tester,
  ) async {
    getIt.registerSingleton<SharedPreferences>(prefs);
    final l10n = await pumpPage(tester);
    final toggle = find.descendant(
      of: find.ancestor(
        of: find.text(l10n.settingsSeasonsRemindersTitle),
        matching: find.byType(Row),
      ),
      matching: find.byType(Switch),
    );
    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 100));
    expect(seasons.remindersEnabled, isTrue);
    expect(prefs.getBool(lastTenReminderPreferenceKey), isNull);

    await prefs.setBool(lastTenReminderPreferenceKey, true);
    await tester.tap(toggle);
    await tester.pump(const Duration(milliseconds: 100));
    expect(seasons.remindersEnabled, isFalse);
    expect(prefs.getBool(lastTenReminderPreferenceKey), isFalse);
  });

  testWidgets('restore defaults keeps the guardian kids choice', (
    tester,
  ) async {
    final l10n = await pumpPage(tester);
    await seasons.setKidsSeasonsEnabled(false);
    await tester.tap(find.text(l10n.settingsRestoreDefaults));
    await tester.pump(const Duration(milliseconds: 100));
    expect(seasons.kidsSeasonsEnabled, isFalse);
  });

  testWidgets('restore defaults returns every stored choice', (tester) async {
    final l10n = await pumpPage(tester);
    await seasons.setMasterEnabled(false);
    await seasons.setSeasonEnabled(SeasonId.monThu, true);
    await tester.tap(find.text(l10n.settingsRestoreDefaults));
    await tester.pump(const Duration(milliseconds: 100));
    expect(seasons.masterEnabled, isTrue);
    expect(seasons.isSeasonEnabled(SeasonId.monThu), isFalse);
    expect(seasons.remindersEnabled, isFalse);
  });
}
