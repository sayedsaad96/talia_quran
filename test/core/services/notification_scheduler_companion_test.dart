import 'dart:ui';

import 'dart:async';
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

  Future<NotificationScheduler> buildScheduler({
    Future<String?> Function(PrayerOccurrence, AppLocalizations)? reviewBody,
    DateTime Function()? reviewNow,
    Future<int?> Function()? practiceDays,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationScheduler(
      service,
      prayerTimesService: prayerTimes,
      prayerCompanionPlanner: planner,
      prayerCompanionPreferences: PrayerCompanionPreferences(prefs),
      prayerReviewBodyLoader: reviewBody,
      prayerReviewNow: reviewNow,
      kidsPracticeDaysLoader: practiceDays,
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
    when(
      () => service.cancelForgettingForecastReminder(),
    ).thenAnswer((_) async {});
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
        invitationBody: any(named: 'invitationBody'),
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
      () => service.scheduleKhatmahReminders(
        title: any(named: 'title'),
        reminders: any(named: 'reminders'),
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
    test('remote practice days use weekly schedule and null keeps daily path', () async {
      SharedPreferences.setMockInitialValues({TaliaNotificationService.kidsReminderPreferenceKey: true});
      when(() => service.scheduleKidsPracticeReminders(
        title: any(named: 'title'), body: any(named: 'body'),
        practiceDays: any(named: 'practiceDays'),
        hour: any(named: 'hour'), minute: any(named: 'minute'))).thenAnswer((_) async {});
      when(() => service.scheduleKidsReviewReminder(
        title: any(named: 'title'), body: any(named: 'body'),
        hour: any(named: 'hour'), minute: any(named: 'minute'))).thenAnswer((_) async {});
      for (final mask in [65, 0, null]) {
        final scheduler = await buildScheduler(practiceDays: () async => mask);
        await scheduler.refreshNotifications(l10n, force: true);
        if (mask == null) {
          verify(() => service.scheduleKidsReviewReminder(
            title: any(named: 'title'), body: any(named: 'body'),
            hour: any(named: 'hour'), minute: any(named: 'minute'))).called(1);
        } else {
          verify(() => service.scheduleKidsPracticeReminders(
            title: any(named: 'title'), body: any(named: 'body'), practiceDays: mask,
            hour: any(named: 'hour'), minute: any(named: 'minute'))).called(1);
        }
      }
    });

    test('stalled review lookup falls back once and stops late lookups', () async {
      SharedPreferences.setMockInitialValues({PrayerCompanionPreferences.enabledKey: true});
      when(() => prayerTimes.isReadyForNotificationScheduling).thenReturn(true);
      final now = DateTime(2026, 9, 20, 11, 40);
      final plan = [
        for (final id in [2100, 2102])
          ScheduledPrayerCompanionNotification(id: id,
            kind: PrayerCompanionNotificationKind.preparation,
            occurrence: occurrence(PrayerKey.dhuhr),
            scheduledAt: DateTime(2026, 9, 20, 11, 50)),
      ];
      when(() => planner.plan(now: any(named: 'now'))).thenAnswer((_) async => plan);
      final stalled = Completer<String?>();
      var calls = 0;
      final scheduler = await buildScheduler(reviewNow: () => now,
        reviewBody: (_, _) { calls++; return stalled.future; });
      final refresh = scheduler.refreshNotifications(l10n, force: true);
      try {
        await refresh.timeout(const Duration(seconds: 4));
      } finally {
        stalled.complete('late suggestion');
      }
      await refresh;
      await Future<void>.delayed(Duration.zero);
      final values = verify(() => service.schedulePrayerCompanionReminders(
        reminders: captureAny(named: 'reminders'), titleFor: any(named: 'titleFor'),
        bodyFor: captureAny(named: 'bodyFor'))).captured;
      expect(values[0], plan);
      final body = values[1] as String Function(ScheduledPrayerCompanionNotification);
      expect(body(plan.first), l10n.notificationCompanionPreparationBody('الظهر'));
      expect(calls, 1);
      verifyNever(() => service.cancelPrayerCompanionReminders());
    });

    test('review text changes only preparation copy and errors keep original plan', () async {
      SharedPreferences.setMockInitialValues({PrayerCompanionPreferences.enabledKey: true});
      when(() => prayerTimes.isReadyForNotificationScheduling).thenReturn(true);
      final now = DateTime(2026, 9, 20, 11, 40);
      final selectedOccurrence = occurrence(PrayerKey.dhuhr);
      final preparation = ScheduledPrayerCompanionNotification(id: 2100,
        kind: PrayerCompanionNotificationKind.preparation,
        occurrence: selectedOccurrence, scheduledAt: DateTime(2026, 9, 20, 11, 50));
      final checkIn = ScheduledPrayerCompanionNotification(id: 2101,
        kind: PrayerCompanionNotificationKind.checkIn,
        occurrence: selectedOccurrence, scheduledAt: DateTime(2026, 9, 20, 12, 20));
      final plan = [preparation, checkIn];
      when(() => planner.plan(now: any(named: 'now'))).thenAnswer((_) async => plan);
      for (final mode in ['disabled', 'available', 'unavailable', 'failure']) {
        var lookups = 0;
        final scheduler = await buildScheduler(reviewNow: () => now,
          reviewBody: mode == 'disabled' ? null : (_, _) async {
            lookups++;
            if (mode == 'failure') throw StateError('unavailable');
            return mode == 'available' ? 'suggestion' : null;
          });
        await scheduler.refreshNotifications(l10n, force: true);
        final values = verify(() => service.schedulePrayerCompanionReminders(
          reminders: captureAny(named: 'reminders'), titleFor: any(named: 'titleFor'),
          bodyFor: captureAny(named: 'bodyFor'))).captured;
        expect(values[0], plan);
        final body = values[1] as String Function(ScheduledPrayerCompanionNotification);
        final base = l10n.notificationCompanionPreparationBody('الظهر');
        expect(body(preparation), mode == 'available' ? '$base\nsuggestion' : base);
        expect(body(checkIn), l10n.notificationCompanionCheckInBody('الظهر'));
        expect(lookups, mode == 'disabled' ? 0 : 1);
      }
      verifyNever(() => service.cancelPrayerCompanionReminders());
    });

    test('review lookup never runs after the prayer has started', () async {
      SharedPreferences.setMockInitialValues({PrayerCompanionPreferences.enabledKey: true});
      when(() => prayerTimes.isReadyForNotificationScheduling).thenReturn(true);
      final now = DateTime(2026, 9, 20, 12, 1);
      final preparation = ScheduledPrayerCompanionNotification(id: 2100,
        kind: PrayerCompanionNotificationKind.preparation,
        occurrence: occurrence(PrayerKey.dhuhr), scheduledAt: now.add(const Duration(minutes: 1)));
      when(() => planner.plan(now: any(named: 'now'))).thenAnswer((_) async => [preparation]);
      var lookups = 0;
      final scheduler = await buildScheduler(reviewNow: () => now,
        reviewBody: (_, _) async { lookups++; return 'suggestion'; });
      await scheduler.refreshNotifications(l10n, force: true);
      expect(lookups, 0);
    });

    test('review lookup skips occurrences more than 24h away', () async {
      SharedPreferences.setMockInitialValues({PrayerCompanionPreferences.enabledKey: true});
      when(() => prayerTimes.isReadyForNotificationScheduling).thenReturn(true);
      final now = DateTime(2026, 9, 18, 11, 40);
      final far = ScheduledPrayerCompanionNotification(id: 2100,
        kind: PrayerCompanionNotificationKind.preparation,
        occurrence: occurrence(PrayerKey.dhuhr), scheduledAt: DateTime(2026, 9, 20, 11, 50));
      when(() => planner.plan(now: any(named: 'now'))).thenAnswer((_) async => [far]);
      var lookups = 0;
      final scheduler = await buildScheduler(reviewNow: () => now,
        reviewBody: (_, _) async { lookups++; return 'suggestion'; });
      await scheduler.refreshNotifications(l10n, force: true);
      expect(lookups, 0);
      final values = verify(() => service.schedulePrayerCompanionReminders(
        reminders: any(named: 'reminders'), titleFor: any(named: 'titleFor'),
        bodyFor: captureAny(named: 'bodyFor'))).captured;
      final body = values.single as String Function(ScheduledPrayerCompanionNotification);
      expect(body(far), l10n.notificationCompanionPreparationBody('الظهر'));
    });

    test('kids practice-day loader failure keeps the legacy daily reminder', () async {
      SharedPreferences.setMockInitialValues({TaliaNotificationService.kidsReminderPreferenceKey: true});
      when(() => service.scheduleKidsPracticeReminders(
        title: any(named: 'title'), body: any(named: 'body'),
        practiceDays: any(named: 'practiceDays'),
        hour: any(named: 'hour'), minute: any(named: 'minute'))).thenAnswer((_) async {});
      when(() => service.scheduleKidsReviewReminder(
        title: any(named: 'title'), body: any(named: 'body'),
        hour: any(named: 'hour'), minute: any(named: 'minute'))).thenAnswer((_) async {});
      final scheduler = await buildScheduler(practiceDays: () async => throw StateError('x'));
      await scheduler.refreshNotifications(l10n, force: true);
      verify(() => service.scheduleKidsReviewReminder(
        title: any(named: 'title'), body: any(named: 'body'),
        hour: any(named: 'hour'), minute: any(named: 'minute'))).called(1);
      verifyNever(() => service.scheduleKidsPracticeReminders(
        title: any(named: 'title'), body: any(named: 'body'),
        practiceDays: any(named: 'practiceDays'),
        hour: any(named: 'hour'), minute: any(named: 'minute')));
    });

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
