import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations, GlobalMaterialLocalizations, MaterialLocalizationAr;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/features/settings/presentation/widgets/settings_notification_tiles.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    getIt.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
  });

  tearDown(() => getIt.reset());

  for (final language in ['ar', 'en']) {
    testWidgets('calm mode can be changed in $language settings', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(Locale(language));
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: NotificationSettingTile(isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tile = find.widgetWithText(
        SwitchListTile,
        l10n.notificationCalmModeTitle,
      );
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);
      expect(find.text(l10n.notificationCalmModeDescription), findsOneWidget);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
      expect(
        getIt<SharedPreferences>().getBool(
          TaliaNotificationService.calmModePreferenceKey,
        ),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'notification test picker excludes unapproved Azkar and Dua previews',
    (tester) async {
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: NotificationSettingTile(isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final testNotification = find.text('Try a notification');
      await tester.ensureVisible(testNotification);
      await tester.tap(testNotification);
      await tester.pumpAndSettle();

      expect(find.text('A moment to review'), findsOneWidget);
      expect(find.text('A small step today'), findsOneWidget);
      expect(find.text('Morning Azkar ☀️'), findsNothing);
      expect(find.text('Daily Dua 🤲'), findsNothing);
    },
  );

  testWidgets('offers a configurable daily ayah reminder', (tester) async {
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
        home: Scaffold(
          body: SingleChildScrollView(
            child: NotificationSettingTile(isDark: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily Ayah'), findsOneWidget);
  });

  testWidgets(
    'renders configurable azkar and daily review time tiles with default times',
    (tester) async {
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: NotificationSettingTile(isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Review Reminder'), findsOneWidget);
      expect(find.text('Morning Azkar Reminder'), findsOneWidget);
      expect(find.text('Evening Azkar Reminder'), findsOneWidget);
    },
  );

  testWidgets('tapping the daily review time button opens the time picker', (
    tester,
  ) async {
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
        home: Scaffold(
          body: SingleChildScrollView(
            child: NotificationSettingTile(isDark: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The Daily Review tile is the first time-editor tile; its edit
    // affordance is the first clock-icon OutlinedButton in the list.
    final editButton = find.byIcon(TaliaIcons.clock).first;
    await tester.ensureVisible(editButton);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // The Material TimePicker dialog opened at the 8:00 PM default.
    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(find.text('PM'), findsWidgets);
  });
}
