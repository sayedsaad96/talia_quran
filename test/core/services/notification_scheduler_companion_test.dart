import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/prayer_companion/data/datasources/prayer_companion_preferences.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_scheduler_planner.dart';

class MockTaliaNotificationService extends Mock
    implements TaliaNotificationService {}

class MockPrayerTimesService extends Mock implements PrayerTimesService {}

class MockPrayerCompanionPlanner extends Mock
    implements PrayerCompanionPlanner {}

class FakeScheduledPrayerNotification extends Fake
    implements ScheduledPrayerNotification {}

class FakeScheduledPrayerCompanionNotification extends Fake
    implements ScheduledPrayerCompanionNotification {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeScheduledPrayerNotification());
    registerFallbackValue(<ScheduledPrayerNotification>[]);
    registerFallbackValue(<ScheduledPrayerCompanionNotification>[]);
    registerFallbackValue(FakeScheduledPrayerCompanionNotification());
    registerFallbackValue(DateTime(2026, 1, 1));
    registerFallbackValue(lookupAppLocalizations(const Locale('ar')));
  });

  late MockTaliaNotificationService service;
  late MockPrayerTimesService prayerTimes;
  late MockPrayerCompanionPlanner planner;
  late AppLocalizations l10n;

  PrayerOccurrence occurrence(PrayerKey prayerKey) => PrayerOccurrence(
    ownerId: 'local',
    localDate: DateTime(2026, 9, 20),
    prayerKey: prayerKey,
    scheduledAt: DateTime(2026, 9, 20, 12, 0),
  );

  final checkInReminder = ScheduledPrayerCompanionNotification(
    id: PrayerCompanionPlanner.plannedBaseId + 1,
    kind: PrayerCompanionNotificationKind.checkIn,
    occurrence: occurrence(PrayerKey.fajr),
    scheduledAt: DateTime(2026, 9, 20, 5, 30),
  );

  Future<NotificationScheduler> buildScheduler() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationScheduler(
      service,
      prayerTimesService: prayerTimes,
      prayerCompanionPlanner: planner,
      prayerCompanionPreferences: PrayerCompanionPreferences(prefs),
    );
  }

  setUp(() async {
    await getIt.reset();
    service = MockTaliaNotificationService();
    prayerTimes = MockPrayerTimesService();
    planner = MockPrayerCompanionPlanner();
    l10n = lookupAppLocalizations(const Locale('ar'));

    when(() => service.configureLocalTimezone()).thenAnswer((_) async {});
    when(() => service.attachLocalization(any())).thenReturn(null);
    when(() => service.cancelStreakAlert()).thenAnswer((_) async {});
    when(() => service.cancelStreakGentleNudge()).thenAnswer((_) async {});
    when(() => service.cancelSmartReminder()).thenAnswer((_) async {});
    when(() => service.cancelFridayKahfReminder()).thenAnswer((_) async {});
    when(() => service.cancelWeeklyImpactReminder()).thenAnswer((_) async {});
    when(
      () => service.scheduleWeeklyImpactReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(() => service.cancelTahajjudReminder()).thenAnswer((_) async {});
    when(() => service.cancelKhatmahReminder()).thenAnswer((_) async {});
    when(() => service.cancelPrayerTimesReminders()).thenAnswer((_) async {});
    when(
      () => service.cancelPrayerCompanionReminders(),
    ).thenAnswer((_) async {});
    when(() => service.cancelDailyReviewReminder()).thenAnswer((_) async {});
    when(
      () => service.scheduleDailyReviewReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(() => service.cancelDailyAyahReminder()).thenAnswer((_) async {});
    when(() => service.cancelMorningAzkarReminder()).thenAnswer((_) async {});
    when(() => service.cancelEveningAzkarReminder()).thenAnswer((_) async {});
    when(() => service.cancelDailyDuaReminder()).thenAnswer((_) async {});
    when(() => service.cancelKidsReviewReminder()).thenAnswer((_) async {});
    when(
      () => service.scheduleStreakProtectionAlert(
        title: any(named: 'title'),
        body: any(named: 'body'),
        currentStreak: any(named: 'currentStreak'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => service.scheduleStreakGentleNudge(
        title: any(named: 'title'),
        body: any(named: 'body'),
        currentStreak: any(named: 'currentStreak'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => service.scheduleDailyAyahReminders(
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
        reminderForDate: any(named: 'reminderForDate'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => service.scheduleMorningAzkarReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => service.scheduleEveningAzkarReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => service.scheduleDailyDuaReminder(
        title: any(named: 'title'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => service.scheduleFridayKahfReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => service.scheduleKhatmahReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => service.schedulePrayerTimesReminders(
        prayers: any(named: 'prayers'),
        athanEnabled: any(named: 'athanEnabled'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => service.schedulePrayerCompanionReminders(
        reminders: any(named: 'reminders'),
        titleFor: any(named: 'titleFor'),
        bodyFor: any(named: 'bodyFor'),
      ),
    ).thenAnswer((_) async {});
    when(() => prayerTimes.isReadyForNotificationScheduling).thenReturn(false);
    when(() => prayerTimes.timesForDate(any())).thenAnswer((_) async {
      return <({String key, String nameAr, String nameEn, DateTime time})>[];
    });
    when(
      () => planner.plan(now: any(named: 'now')),
    ).thenAnswer((_) async => const <ScheduledPrayerCompanionNotification>[]);
  });

  group('prayer companion scheduling', () {
    test(
      'adds Companion events without changing legacy prayer requests',
      () async {
        SharedPreferences.setMockInitialValues({
          TaliaNotificationService.prayerNotificationsPreferenceKey: true,
          PrayerCompanionPreferences.enabledKey: true,
        });
        when(
          () => prayerTimes.isReadyForNotificationScheduling,
        ).thenReturn(true);
        when(
          () => planner.plan(now: any(named: 'now')),
        ).thenAnswer((_) async => [checkInReminder]);

        final scheduler = await buildScheduler();
        await scheduler.refreshNotifications(l10n, force: true);

        verify(
          () => service.schedulePrayerTimesReminders(
            prayers: any(named: 'prayers'),
            athanEnabled: any(named: 'athanEnabled'),
          ),
        ).called(1);
        final captured = verify(
          () => service.schedulePrayerCompanionReminders(
            reminders: captureAny(named: 'reminders'),
            titleFor: any(named: 'titleFor'),
            bodyFor: captureAny(named: 'bodyFor'),
          ),
        ).captured;
        expect(captured[0] as List<ScheduledPrayerCompanionNotification>, [
          checkInReminder,
        ]);
        // Copy closures are localized: the check-in body carries the Arabic
        // prayer name, never an empty or theological string.
        final bodyFor =
            captured[1]
                as String Function(ScheduledPrayerCompanionNotification);
        expect(bodyFor(checkInReminder), contains('الفجر'));
        verifyNever(() => service.cancelPrayerCompanionReminders());
      },
    );

    test('disabled Companion cancels ONLY Companion events', () async {
      // Legacy prayer scheduling stays fully active; only the Companion
      // master switch is off.
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.prayerNotificationsPreferenceKey: true,
        PrayerCompanionPreferences.enabledKey: false,
      });
      when(() => prayerTimes.isReadyForNotificationScheduling).thenReturn(true);

      final scheduler = await buildScheduler();
      await scheduler.refreshNotifications(l10n, force: true);

      verify(() => service.cancelPrayerCompanionReminders()).called(1);
      verifyNever(() => service.cancelPrayerTimesReminders());
      verify(
        () => service.schedulePrayerTimesReminders(
          prayers: any(named: 'prayers'),
          athanEnabled: any(named: 'athanEnabled'),
        ),
      ).called(1);
      verifyNever(
        () => service.schedulePrayerCompanionReminders(
          reminders: any(named: 'reminders'),
          titleFor: any(named: 'titleFor'),
          bodyFor: any(named: 'bodyFor'),
        ),
      );
    });

    test(
      'prayer times not ready cancels Companion events without crashing',
      () async {
        // City/method not persisted -> the readiness check the legacy prayer
        // block uses is false even though the Companion is enabled.
        SharedPreferences.setMockInitialValues({
          PrayerCompanionPreferences.enabledKey: true,
        });

        final scheduler = await buildScheduler();
        await scheduler.refreshNotifications(l10n, force: true);

        verify(() => service.cancelPrayerCompanionReminders()).called(1);
        verifyNever(() => planner.plan(now: any(named: 'now')));
        verifyNever(
          () => service.schedulePrayerCompanionReminders(
            reminders: any(named: 'reminders'),
            titleFor: any(named: 'titleFor'),
            bodyFor: any(named: 'bodyFor'),
          ),
        );
      },
    );

    test('missing Companion dependencies cancel Companion events', () async {
      SharedPreferences.setMockInitialValues({
        PrayerCompanionPreferences.enabledKey: true,
      });
      when(() => prayerTimes.isReadyForNotificationScheduling).thenReturn(true);
      final bare = NotificationScheduler(
        service,
        prayerTimesService: prayerTimes,
      );

      await bare.refreshNotifications(l10n, force: true);

      verify(() => service.cancelPrayerCompanionReminders()).called(1);
    });

    group('quiet hours suppression', () {
      ScheduledPrayerCompanionNotification reminderAt(
        int id,
        DateTime scheduledAt,
      ) => ScheduledPrayerCompanionNotification(
        id: id,
        kind: PrayerCompanionNotificationKind.checkIn,
        occurrence: occurrence(PrayerKey.fajr),
        scheduledAt: scheduledAt,
      );

      List<ScheduledPrayerCompanionNotification> capturedReminders() {
        final captured = verify(
          () => service.schedulePrayerCompanionReminders(
            reminders: captureAny(named: 'reminders'),
            titleFor: any(named: 'titleFor'),
            bodyFor: any(named: 'bodyFor'),
          ),
        ).captured;
        return captured.single as List<ScheduledPrayerCompanionNotification>;
      }

      test(
        'check-in inside the quiet window is dropped before scheduling',
        () async {
          SharedPreferences.setMockInitialValues({
            PrayerCompanionPreferences.enabledKey: true,
            TaliaNotificationService.quietHoursPreferenceKey: true,
            TaliaNotificationService.quietHoursStartKey: 21,
            TaliaNotificationService.quietHoursEndKey: 5,
          });
          when(
            () => prayerTimes.isReadyForNotificationScheduling,
          ).thenReturn(true);
          final insideQuiet = reminderAt(
            PrayerCompanionPlanner.plannedBaseId + 1,
            DateTime(2026, 9, 20, 22, 30),
          );
          final outsideQuiet = reminderAt(
            PrayerCompanionPlanner.plannedBaseId + 2,
            DateTime(2026, 9, 20, 12, 0),
          );
          when(
            () => planner.plan(now: any(named: 'now')),
          ).thenAnswer((_) async => [insideQuiet, outsideQuiet]);

          final scheduler = await buildScheduler();
          await scheduler.refreshNotifications(l10n, force: true);

          expect(capturedReminders(), [outsideQuiet]);
        },
      );

      test('quiet hours disabled suppresses nothing', () async {
        SharedPreferences.setMockInitialValues({
          PrayerCompanionPreferences.enabledKey: true,
          TaliaNotificationService.quietHoursPreferenceKey: false,
          TaliaNotificationService.quietHoursStartKey: 21,
          TaliaNotificationService.quietHoursEndKey: 5,
        });
        when(
          () => prayerTimes.isReadyForNotificationScheduling,
        ).thenReturn(true);
        final insideWindowButAllowed = reminderAt(
          PrayerCompanionPlanner.plannedBaseId + 1,
          DateTime(2026, 9, 20, 22, 30),
        );
        when(
          () => planner.plan(now: any(named: 'now')),
        ).thenAnswer((_) async => [insideWindowButAllowed]);

        final scheduler = await buildScheduler();
        await scheduler.refreshNotifications(l10n, force: true);

        expect(capturedReminders(), [insideWindowButAllowed]);
      });

      test('overnight window boundaries: 04:50 suppressed, 05:10 kept '
          '(21:00-05:00)', () async {
        SharedPreferences.setMockInitialValues({
          PrayerCompanionPreferences.enabledKey: true,
          TaliaNotificationService.quietHoursPreferenceKey: true,
          TaliaNotificationService.quietHoursStartKey: 21,
          TaliaNotificationService.quietHoursEndKey: 5,
        });
        when(
          () => prayerTimes.isReadyForNotificationScheduling,
        ).thenReturn(true);
        final insideOvernight = reminderAt(
          PrayerCompanionPlanner.plannedBaseId + 1,
          DateTime(2026, 9, 20, 4, 50),
        );
        final afterWindow = reminderAt(
          PrayerCompanionPlanner.plannedBaseId + 2,
          DateTime(2026, 9, 20, 5, 10),
        );
        when(
          () => planner.plan(now: any(named: 'now')),
        ).thenAnswer((_) async => [insideOvernight, afterWindow]);

        final scheduler = await buildScheduler();
        await scheduler.refreshNotifications(l10n, force: true);

        expect(capturedReminders(), [afterWindow]);
      });
    });
  });
}
