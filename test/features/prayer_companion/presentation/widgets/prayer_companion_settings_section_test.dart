import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/prayer_serenity_watcher.dart';
import 'package:talia_quran/features/prayer_companion/data/datasources/prayer_companion_preferences.dart';
import 'package:talia_quran/features/prayer_companion/domain/repositories/prayer_companion_repository.dart';
import 'package:talia_quran/features/prayer_companion/presentation/widgets/prayer_companion_settings_section.dart';

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

class _MockRecordOwnerProvider extends Mock implements RecordOwnerProvider {}

class _MockPrayerCompanionRepository extends Mock
    implements PrayerCompanionRepository {}

class _FakeAppLocalizations extends Fake implements AppLocalizations {}

void main() {
  late SharedPreferences prefs;
  late _MockNotificationScheduler scheduler;
  late _MockRecordOwnerProvider owner;
  late _MockPrayerCompanionRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeAppLocalizations());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    scheduler = _MockNotificationScheduler();
    owner = _MockRecordOwnerProvider();
    repository = _MockPrayerCompanionRepository();
    when(() => owner.currentOwnerId).thenReturn('owner-a');
    when(
      () => scheduler.refreshNotifications(any(), force: true),
    ).thenAnswer((_) async {});
    when(() => repository.clearOwner('owner-a')).thenAnswer((_) async {});

    if (getIt.isRegistered<SharedPreferences>()) {
      await getIt.reset();
    }
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerSingleton<PrayerCompanionPreferences>(
      PrayerCompanionPreferences(prefs),
    );
    getIt.registerSingleton<NotificationScheduler>(scheduler);
    getIt.registerSingleton<RecordOwnerProvider>(owner);
    getIt.registerSingleton<PrayerCompanionRepository>(repository);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget harness() {
    return const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('ar'), Locale('en')],
      locale: Locale('ar'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: PrayerCompanionSettingsSection(isDark: false),
        ),
      ),
    );
  }

  testWidgets('Companion is off by default and enabling it reschedules', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('تفعيل مرافق الصلاة'), findsOneWidget);
    expect(find.text('مسح تأكيدات الصلاة'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'تفعيل مرافق الصلاة'),
    );
    await tester.pumpAndSettle();

    expect(prefs.getBool(PrayerCompanionPreferences.enabledKey), isTrue);
    verify(() => scheduler.refreshNotifications(any(), force: true)).called(1);
  });

  testWidgets('serenity toggle persists independently of the companion', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Default is ON.
    expect(
      prefs.getBool(PrayerSerenityWatcher.enabledKey) ?? true,
      isTrue,
    );
    expect(find.text('وضع سكينة الصلاة'), findsOneWidget);

    await tester.tap(find.widgetWithText(SwitchListTile, 'وضع سكينة الصلاة'));
    await tester.pumpAndSettle();

    expect(prefs.getBool(PrayerSerenityWatcher.enabledKey), isFalse);
    // Toggling serenity must never touch the Companion preference.
    expect(prefs.getBool(PrayerCompanionPreferences.enabledKey), isNull);
  });

  testWidgets('clear confirmations requires consent', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('مسح تأكيدات الصلاة'));
    await tester.pumpAndSettle();

    expect(
      find.text('هل تريد مسح التأكيدات المحفوظة على هذا الجهاز؟'),
      findsOneWidget,
    );
    verifyNever(() => repository.clearOwner(any()));

    await tester.tap(find.text('مسح'));
    await tester.pumpAndSettle();

    verify(() => repository.clearOwner('owner-a')).called(1);
    expect(prefs.getBool(PrayerCompanionPreferences.enabledKey), isNull);
  });
}
