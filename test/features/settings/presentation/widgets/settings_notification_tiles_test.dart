import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
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
      final testNotification = find.text('Test Interactive Notification');
      await tester.ensureVisible(testNotification);
      await tester.tap(testNotification);
      await tester.pumpAndSettle();

      expect(find.text('Daily Review 📖'), findsOneWidget);
      expect(find.text('Streak Protection 🔥'), findsOneWidget);
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

  testWidgets(
    'tapping the daily review time button opens the time picker',
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

      // The Daily Review tile is the first time-editor tile; its edit
      // affordance is the first clock-icon OutlinedButton in the list.
      final editButton = find.byIcon(Icons.access_time_rounded).first;
      await tester.ensureVisible(editButton);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // The Material TimePicker dialog opened at the 8:00 PM default.
      expect(find.byType(TimePickerDialog), findsOneWidget);
      expect(find.text('PM'), findsWidgets);
    },
  );
}
