import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/core/services/streak_risk_evaluator.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

class MockTaliaNotificationService extends Mock
    implements TaliaNotificationService {}

class MockStreakReader extends Mock implements StreakReader {}

void main() {
  late MockTaliaNotificationService mockNotificationService;
  late MockStreakReader mockStreakReader;

  Future<void> stubAllServiceMethods() async {
    when(
      () => mockNotificationService.configureLocalTimezone(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelStreakAlert(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelStreakGentleNudge(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelPrayerCompanionReminders(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelSmartReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelForgettingForecastReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelLastTenReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelDailyReviewReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelDailyAyahReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelMorningAzkarReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelEveningAzkarReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelDailyDuaReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelKidsReviewReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelFridayKahfReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleWeeklyImpactReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelWeeklyImpactReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelTahajjudReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelKhatmahReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelPrayerTimesReminders(),
    ).thenAnswer((_) async {});

    when(
      () => mockNotificationService.scheduleDailyReviewReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleMorningAzkarReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleEveningAzkarReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleDailyDuaReminder(
        title: any(named: 'title'),
        invitationBody: any(named: 'invitationBody'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleDailyAyahReminders(
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
        reminderForDate: any(named: 'reminderForDate'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleKidsReviewReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleTahajjudReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockNotificationService.scheduleStreakProtectionAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
        currentStreak: any(named: 'currentStreak'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleStreakGentleNudge(
        title: any(named: 'title'),
        body: any(named: 'body'),
        currentStreak: any(named: 'currentStreak'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleSmartReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleFridayKahfReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleKhatmahReminders(
        title: any(named: 'title'),
        reminders: any(named: 'reminders'),
      ),
    ).thenAnswer((_) async {});
  }

  StreakEntity streakWithoutActivityToday() {
    final now = DateTime.now();
    return StreakEntity(
      currentStreak: 5,
      longestStreak: 10,
      lastActivityDate: now.subtract(const Duration(days: 1)),
    );
  }

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({
      TaliaNotificationService.dailyReviewPreferenceKey: false,
      TaliaNotificationService.morningAzkarPreferenceKey: false,
      TaliaNotificationService.eveningAzkarPreferenceKey: false,
      TaliaNotificationService.dailyDuaPreferenceKey: false,
      TaliaNotificationService.dailyAyahPreferenceKey: false,
      TaliaNotificationService.kidsReminderPreferenceKey: false,
      TaliaNotificationService.fridayKahfPreferenceKey: false,
      TaliaNotificationService.tahajjudPreferenceKey: false,
      TaliaNotificationService.khatmahReminderPreferenceKey: false,
      TaliaNotificationService.prayerNotificationsPreferenceKey: false,
      TaliaNotificationService.streakAlertPreferenceKey: true,
      TaliaNotificationService.smartReminderPreferenceKey: false,
    });

    mockNotificationService = MockTaliaNotificationService();
    mockStreakReader = MockStreakReader();
    await stubAllServiceMethods();

    getIt.registerSingleton<StreakReader>(mockStreakReader);
  });

  tearDown(() => getIt.reset());

  test(
    'does not invent a streak reminder when activity data is unavailable',
    () async {
      await getIt.unregister<StreakReader>();
      final success = await NotificationScheduler(mockNotificationService)
          .refreshNotificationsInBackground(
            lookupAppLocalizations(const Locale('ar')),
          );

      expect(success, isTrue);
      verify(() => mockNotificationService.cancelStreakAlert()).called(1);
      verifyNever(
        () => mockNotificationService.scheduleStreakProtectionAlert(
          title: any(named: 'title'),
          body: any(named: 'body'),
          currentStreak: any(named: 'currentStreak'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
    },
  );

  group('single streak reminder', () {
    test(
      'schedules one alert and cancels the old gentle nudge when there is no '
      'activity today',
      () async {
        final now = DateTime.now();
        when(
          () => mockStreakReader.getStreak(),
        ).thenAnswer((_) async => streakWithoutActivityToday());

        final scheduler = NotificationScheduler(
          mockNotificationService,
          streakRiskEvaluator: StreakRiskEvaluator(now: () => now),
        );

        final l10n = lookupAppLocalizations(const Locale('ar'));
        await scheduler.refreshNotifications(l10n);

        verifyNever(
          () => mockNotificationService.scheduleStreakGentleNudge(
            title: any(named: 'title'),
            body: any(named: 'body'),
            currentStreak: any(named: 'currentStreak'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
          ),
        );
        verify(
          () => mockNotificationService.scheduleStreakProtectionAlert(
            title: any(named: 'title'),
            body: any(named: 'body'),
            currentStreak: 5,
            hour: 22,
            minute: 0,
          ),
        ).called(1);
        verifyNever(() => mockNotificationService.cancelStreakAlert());
        verify(
          () => mockNotificationService.cancelStreakGentleNudge(),
        ).called(1);
      },
    );

    test('skips gentle nudge when alert hour is 0', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.streakAlertPreferenceKey: true,
        '${TaliaNotificationService.streakAlertPreferenceKey}_hour': 0,
        '${TaliaNotificationService.streakAlertPreferenceKey}_minute': 30,
      });
      when(
        () => mockStreakReader.getStreak(),
      ).thenAnswer((_) async => streakWithoutActivityToday());

      final scheduler = NotificationScheduler(
        mockNotificationService,
        streakRiskEvaluator: StreakRiskEvaluator(now: () => now),
      );

      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      verifyNever(
        () => mockNotificationService.scheduleStreakGentleNudge(
          title: any(named: 'title'),
          body: any(named: 'body'),
          currentStreak: any(named: 'currentStreak'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
      verify(
        () => mockNotificationService.scheduleStreakProtectionAlert(
          title: any(named: 'title'),
          body: any(named: 'body'),
          currentStreak: any(named: 'currentStreak'),
          hour: 0,
          minute: 30,
        ),
      ).called(1);
    });

    test('moves streak reminder outside quiet hours', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        TaliaNotificationService.quietHoursPreferenceKey,
        true,
      );
      await prefs.setInt(TaliaNotificationService.quietHoursStartKey, 22);
      await prefs.setInt(TaliaNotificationService.quietHoursEndKey, 8);
      when(
        () => mockStreakReader.getStreak(),
      ).thenAnswer((_) async => streakWithoutActivityToday());

      await NotificationScheduler(
        mockNotificationService,
      ).refreshNotifications(lookupAppLocalizations(const Locale('ar')));

      verify(
        () => mockNotificationService.scheduleStreakProtectionAlert(
          title: any(named: 'title'),
          body: any(named: 'body'),
          currentStreak: 5,
          hour: 8,
          minute: 0,
        ),
      ).called(1);
      verify(() => mockNotificationService.cancelStreakGentleNudge()).called(1);
    });

    test('cancels both when user already has activity today', () async {
      final now = DateTime.now();
      final withActivity = StreakEntity(
        currentStreak: 5,
        longestStreak: 10,
        lastActivityDate: now,
      );
      when(
        () => mockStreakReader.getStreak(),
      ).thenAnswer((_) async => withActivity);

      final scheduler = NotificationScheduler(
        mockNotificationService,
        streakRiskEvaluator: StreakRiskEvaluator(now: () => now),
      );

      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      verify(() => mockNotificationService.cancelStreakAlert()).called(1);
      verify(() => mockNotificationService.cancelStreakGentleNudge()).called(1);
      verifyNever(
        () => mockNotificationService.scheduleStreakProtectionAlert(
          title: any(named: 'title'),
          body: any(named: 'body'),
          currentStreak: any(named: 'currentStreak'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
      verifyNever(
        () => mockNotificationService.scheduleStreakGentleNudge(
          title: any(named: 'title'),
          body: any(named: 'body'),
          currentStreak: any(named: 'currentStreak'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
    });
  });

  group('smart reminder', () {
    void stubStreak({required bool activityToday}) {
      final now = DateTime.now();
      final entity = activityToday
          ? StreakEntity(
              currentStreak: 5,
              longestStreak: 10,
              lastActivityDate: now,
            )
          : StreakEntity(
              currentStreak: 5,
              longestStreak: 10,
              lastActivityDate: now.subtract(const Duration(days: 1)),
            );
      when(() => mockStreakReader.getStreak()).thenAnswer((_) async => entity);
    }

    test('standard mode schedules at the mode hour with >= 3 open hours and '
        'no activity today', () async {
      stubStreak(activityToday: false);
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.calmModePreferenceKey: false,
        TaliaNotificationService.streakAlertPreferenceKey: false,
        TaliaNotificationService.smartReminderPreferenceKey: true,
        'smart_reminder_open_hours': <String>['20', '20', '9', '20', '9', '20'],
      });

      final scheduler = NotificationScheduler(mockNotificationService);
      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      final capturedHours = verify(
        () => mockNotificationService.scheduleSmartReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          hour: captureAny(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      ).captured;
      expect(capturedHours, [20]);
      verifyNever(() => mockNotificationService.cancelSmartReminder());
    });

    test(
      'calm smart timing adjusts review without an extra notification',
      () async {
        stubStreak(activityToday: false);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
          TaliaNotificationService.dailyReviewPreferenceKey,
          true,
        );
        await prefs.setBool(
          TaliaNotificationService.smartReminderPreferenceKey,
          true,
        );
        await prefs.setInt(
          '${TaliaNotificationService.dailyReviewPreferenceKey}_hour',
          18,
        );
        await prefs.setStringList('smart_reminder_open_hours', [
          '20',
          '20',
          '9',
          '20',
          '9',
          '20',
        ]);

        await NotificationScheduler(
          mockNotificationService,
        ).refreshNotifications(lookupAppLocalizations(const Locale('ar')));

        verify(() => mockNotificationService.setCalmMode(true)).called(1);
        verify(
          () => mockNotificationService.scheduleDailyReviewReminder(
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: 20,
            minute: 0,
          ),
        ).called(1);
        verify(() => mockNotificationService.cancelSmartReminder()).called(1);
        verifyNever(
          () => mockNotificationService.scheduleSmartReminder(
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
          ),
        );
      },
    );

    test(
      'standalone smart reminder respects quiet hours when review is disabled',
      () async {
        stubStreak(activityToday: false);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
          TaliaNotificationService.smartReminderPreferenceKey,
          true,
        );
        await prefs.setBool(
          TaliaNotificationService.quietHoursPreferenceKey,
          true,
        );
        await prefs.setInt(TaliaNotificationService.quietHoursStartKey, 22);
        await prefs.setInt(TaliaNotificationService.quietHoursEndKey, 8);
        await prefs.setStringList('smart_reminder_open_hours', [
          '23',
          '23',
          '23',
          '9',
          '23',
          '23',
        ]);

        await NotificationScheduler(
          mockNotificationService,
        ).refreshNotifications(lookupAppLocalizations(const Locale('ar')));

        verify(
          () => mockNotificationService.scheduleSmartReminder(
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: 8,
            minute: 0,
          ),
        ).called(1);
        verifyNever(
          () => mockNotificationService.scheduleDailyReviewReminder(
            title: any(named: 'title'),
            body: any(named: 'body'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
          ),
        );
      },
    );

    test('headless refresh does not record a user app-open hour', () async {
      stubStreak(activityToday: false);
      final prefs = await SharedPreferences.getInstance();
      const hours = ['20', '9', '20'];
      await prefs.setStringList('smart_reminder_open_hours', hours);
      final scheduler = NotificationScheduler(
        mockNotificationService,
        ownerScopedRefresh: false,
      );

      final success = await scheduler.refreshNotificationsInBackground(
        lookupAppLocalizations(const Locale('ar')),
      );

      expect(success, isTrue);
      expect(prefs.getStringList('smart_reminder_open_hours'), hours);
    });

    test('cancelled when disabled', () async {
      stubStreak(activityToday: false);
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.streakAlertPreferenceKey: false,
        TaliaNotificationService.smartReminderPreferenceKey: false,
        'smart_reminder_open_hours': <String>['20', '20', '9', '20', '9', '20'],
      });

      final scheduler = NotificationScheduler(mockNotificationService);
      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      verify(() => mockNotificationService.cancelSmartReminder()).called(1);
      verifyNever(
        () => mockNotificationService.scheduleSmartReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
    });

    test('cancelled when fewer than 3 open hours are recorded', () async {
      stubStreak(activityToday: false);
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.streakAlertPreferenceKey: false,
        TaliaNotificationService.smartReminderPreferenceKey: true,
        'smart_reminder_open_hours': <String>['9'],
      });

      final scheduler = NotificationScheduler(mockNotificationService);
      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      verify(() => mockNotificationService.cancelSmartReminder()).called(1);
    });

    test('cancelled when there is activity today', () async {
      stubStreak(activityToday: true);
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.streakAlertPreferenceKey: false,
        TaliaNotificationService.smartReminderPreferenceKey: true,
        'smart_reminder_open_hours': <String>['20', '20', '9', '20', '9', '20'],
      });

      final scheduler = NotificationScheduler(mockNotificationService);
      final l10n = lookupAppLocalizations(const Locale('ar'));
      await scheduler.refreshNotifications(l10n);

      verify(() => mockNotificationService.cancelSmartReminder()).called(1);
    });

    test(
      'recordAppOpen collapses consecutive duplicates and keeps last 7',
      () async {
        SharedPreferences.setMockInitialValues({
          'smart_reminder_open_hours': <String>[
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
          ],
        });

        final scheduler = NotificationScheduler(mockNotificationService);
        await scheduler.recordAppOpen(now: DateTime(2026, 1, 1, 8));

        var prefs = await SharedPreferences.getInstance();
        expect(prefs.getStringList('smart_reminder_open_hours'), [
          '2',
          '3',
          '4',
          '5',
          '6',
          '7',
          '8',
        ]);

        // Same hour again: collapsed, no growth.
        await scheduler.recordAppOpen(now: DateTime(2026, 1, 1, 8, 30));
        prefs = await SharedPreferences.getInstance();
        expect(prefs.getStringList('smart_reminder_open_hours'), [
          '2',
          '3',
          '4',
          '5',
          '6',
          '7',
          '8',
        ]);
      },
    );
  });

  test('weekly impact respects quiet hours', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(TaliaNotificationService.quietHoursPreferenceKey, true);
    await prefs.setInt(TaliaNotificationService.quietHoursStartKey, 15);
    await prefs.setInt(TaliaNotificationService.quietHoursEndKey, 18);
    when(
      () => mockStreakReader.getStreak(),
    ).thenAnswer((_) async => streakWithoutActivityToday());

    await NotificationScheduler(
      mockNotificationService,
    ).refreshNotifications(lookupAppLocalizations(const Locale('ar')));

    verify(
      () => mockNotificationService.scheduleWeeklyImpactReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: 18,
        minute: 0,
      ),
    ).called(1);
  });
}
