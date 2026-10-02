import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/settings/presentation/cubits/notification_settings_cubit.dart';
import 'package:talia_quran/features/settings/presentation/widgets/settings_prayer_notification_tiles.dart';
import 'package:talia_quran/features/settings/presentation/widgets/settings_prayer_tiles.dart';

class _MockNotificationService extends Mock
    implements TaliaNotificationService {}

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

class _FakeL10n extends Fake implements AppLocalizations {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeL10n()));

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notificationService = _MockNotificationService();
    final scheduler = _MockNotificationScheduler();
    when(
      () => notificationService.areNotificationsGranted(),
    ).thenAnswer((_) async => false);
    when(
      () => scheduler.refreshNotificationsForSettings(
        any(),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) async => true);

    getIt
      ..registerSingleton<SharedPreferences>(prefs)
      ..registerSingleton<PrayerTimesService>(PrayerTimesService(prefs))
      ..registerSingleton<NotificationSettingsCubit>(
        NotificationSettingsCubit(prefs, notificationService, scheduler),
      );
  });

  tearDown(() => getIt.reset());

  testWidgets(
    'shows permission recovery and routes unavailable prayer alerts to times setup',
    (tester) async {
      var configureTimesCalls = 0;
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
            body: SingleChildScrollView(
              child: PrayerNotificationSettingsSection(
                isDark: false,
                onConfigurePrayerTimes: () => configureTimesCalls += 1,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configure prayer times'), findsOneWidget);
      expect(
        find.text(
          'Prayer alerts will not arrive until notifications are allowed in phone settings.',
        ),
        findsOneWidget,
      );
      expect(find.text('Open phone settings'), findsOneWidget);

      await tester.tap(find.text('Configure prayer times'));
      expect(configureTimesCalls, 1);
    },
  );

  testWidgets('requires a chosen city before prayer alerts can be enabled', (
    tester,
  ) async {
    await getIt<PrayerTimesService>().setEnabled(true);
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
        home: Scaffold(body: PrayerNotificationSettingsSection(isDark: false)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configure prayer times'), findsOneWidget);
    final prayerSwitch = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile).first,
    );
    expect(prayerSwitch.onChanged, isNull);
  });

  testWidgets('choosing a city unlocks prayer alerts without reopening', (
    tester,
  ) async {
    await getIt<PrayerTimesService>().setEnabled(true);
    // Mirrors PrayerSettingsPage: the times section rebuilds the page.
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
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                children: [
                  PrayerTimesSettingsSection(
                    isDark: false,
                    onChanged: () => setState(() {}),
                  ),
                  // Not const, like the page (it passes a callback), so
                  // the parent's rebuild reaches it.
                  PrayerNotificationSettingsSection(
                    isDark: false,
                    onConfigurePrayerTimes: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Configure prayer times'), findsOneWidget);

    final cityDropdowns = find.byType(DropdownButton<String>);
    tester
        .widget<DropdownButton<String>>(cityDropdowns.first)
        .onChanged
        ?.call('eg');
    await tester.pumpAndSettle();
    tester
        .widget<DropdownButton<String>>(cityDropdowns.at(1))
        .onChanged
        ?.call('cairo');
    await tester.pumpAndSettle();

    final service = getIt<PrayerTimesService>();
    expect(service.selectedCityId, 'cairo');
    expect(service.isReadyForNotificationScheduling, isTrue);
    expect(find.text('Configure prayer times'), findsNothing);

    // The first location switches prayer alerts on (never set before).
    expect(
      getIt<SharedPreferences>().getBool(
        TaliaNotificationService.prayerNotificationsPreferenceKey,
      ),
      isTrue,
    );
  });

  testWidgets('a prayer-alerts choice the user already made is kept', (
    tester,
  ) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool(
      TaliaNotificationService.prayerNotificationsPreferenceKey,
      false,
    );
    await getIt<PrayerTimesService>().setEnabled(true);
    await prefs.setString(PrayerTimesService.cityIdKey, 'cairo');
    await prefs.setString(PrayerTimesService.methodKey, 'egyptian');

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
            child: PrayerNotificationSettingsSection(isDark: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      prefs.getBool(TaliaNotificationService.prayerNotificationsPreferenceKey),
      isFalse,
    );
  });
}

