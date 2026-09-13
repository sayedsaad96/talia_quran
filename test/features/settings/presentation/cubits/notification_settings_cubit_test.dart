import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/features/settings/presentation/cubits/notification_settings_cubit.dart';

class MockTaliaNotificationService extends Mock
    implements TaliaNotificationService {}

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

class FakeAppLocalizations extends Fake implements AppLocalizations {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAppLocalizations());
  });

  late SharedPreferences prefs;
  late MockTaliaNotificationService mockNotificationService;
  late MockNotificationScheduler mockScheduler;
  late NotificationSettingsCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      TaliaNotificationService.dailyReviewPreferenceKey: true,
      TaliaNotificationService.streakAlertPreferenceKey: false,
      '${TaliaNotificationService.dailyReviewPreferenceKey}_hour': 21,
      '${TaliaNotificationService.dailyReviewPreferenceKey}_minute': 15,
    });
    prefs = await SharedPreferences.getInstance();
    mockNotificationService = MockTaliaNotificationService();
    mockScheduler = MockNotificationScheduler();

    when(() => mockNotificationService.areNotificationsGranted())
        .thenAnswer((_) async => true);
    when(
      () => mockNotificationService.showImmediateTestNotification(
        title: any(named: 'title'),
        body: any(named: 'body'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockScheduler.refreshNotifications(
        any(),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) async {});

    cubit = NotificationSettingsCubit(
      prefs,
      mockNotificationService,
      mockScheduler,
    );
  });

  tearDown(() => cubit.close());

  group('NotificationSettingsCubit', () {
    test('load() populates state from SharedPreferences and permissions', () async {
      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.hasSystemPermission, isTrue);
      expect(cubit.state.dailyReview, isTrue);
      expect(cubit.state.streakAlert, isFalse);
      expect(
        cubit.state.dailyReviewTime,
        const TimeOfDay(hour: 21, minute: 15),
      );
    });

    test('toggleReminder() updates prefs and triggers reschedule', () async {
      await cubit.load();

      final fakeL10n = FakeAppLocalizations();
      await cubit.toggleReminder(
        TaliaNotificationService.streakAlertPreferenceKey,
        true,
        l10n: fakeL10n,
      );

      expect(cubit.state.streakAlert, isTrue);
      expect(
        prefs.getBool(TaliaNotificationService.streakAlertPreferenceKey),
        isTrue,
      );
      verify(
        () => mockScheduler.refreshNotifications(fakeL10n, force: true),
      ).called(1);
    });

    test('updateReminderTime() updates prefs and triggers reschedule', () async {
      await cubit.load();

      final fakeL10n = FakeAppLocalizations();
      const newTime = TimeOfDay(hour: 19, minute: 45);

      await cubit.updateReminderTime(
        TaliaNotificationService.dailyReviewPreferenceKey,
        newTime,
        l10n: fakeL10n,
      );

      expect(cubit.state.dailyReviewTime, newTime);
      expect(
        prefs.getInt('${TaliaNotificationService.dailyReviewPreferenceKey}_hour'),
        19,
      );
      expect(
        prefs.getInt('${TaliaNotificationService.dailyReviewPreferenceKey}_minute'),
        45,
      );
      verify(
        () => mockScheduler.refreshNotifications(fakeL10n, force: true),
      ).called(1);
    });

    test('togglePrayer() updates individual prayer filter and triggers reschedule', () async {
      await cubit.load();

      final fakeL10n = FakeAppLocalizations();
      await cubit.togglePrayer(
        TaliaNotificationService.prayerFajrKey,
        false,
        l10n: fakeL10n,
      );

      expect(cubit.state.prayerFajr, isFalse);
      expect(prefs.getBool(TaliaNotificationService.prayerFajrKey), isFalse);
      verify(
        () => mockScheduler.refreshNotifications(fakeL10n, force: true),
      ).called(1);
    });

    test('checkPermission() updates state when permission changes', () async {
      await cubit.load();
      expect(cubit.state.hasSystemPermission, isTrue);

      when(() => mockNotificationService.areNotificationsGranted())
          .thenAnswer((_) async => false);

      await cubit.checkPermission();
      expect(cubit.state.hasSystemPermission, isFalse);
      expect(cubit.state.isSystemPermissionBlocked, isTrue);
    });

    test('showTestNotification() delegates to TaliaNotificationService', () async {
      await cubit.showTestNotification(
        title: 'Test Title',
        body: 'Test Body',
        type: 'friday_kahf',
      );

      verify(
        () => mockNotificationService.showImmediateTestNotification(
          title: 'Test Title',
          body: 'Test Body',
          type: 'friday_kahf',
        ),
      ).called(1);
    });
  });
}
