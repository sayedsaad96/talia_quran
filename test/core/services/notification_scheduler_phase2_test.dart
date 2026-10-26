import 'dart:ui';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/seasons/season_preferences.dart';
import 'package:talia_quran/core/seasons/season_calendar.dart';
import 'package:talia_quran/features/seasons/domain/last_ten_reminder.dart';
import 'package:talia_quran/features/seasons/domain/season_windows.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/services/khatmah_reminder_policy.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart';

class MockTaliaNotificationService extends Mock
    implements TaliaNotificationService {}

class MockPrayerTimesService extends Mock implements PrayerTimesService {}

class MockGetActiveKhatmahUsecase extends Mock
    implements GetActiveKhatmahUsecase {}

class FakeScheduledPrayerNotification extends Fake
    implements ScheduledPrayerNotification {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeScheduledPrayerNotification());
    registerFallbackValue(<ScheduledPrayerNotification>[]);
    registerFallbackValue(<SeasonReminderRequest>[]);
    registerFallbackValue(DateTime(2000));
  });

  late MockTaliaNotificationService mockNotificationService;
  late MockPrayerTimesService mockPrayerTimesService;
  late MockGetActiveKhatmahUsecase mockGetActiveKhatmahUsecase;

  setUp(() async {
    await getIt.reset();
    mockNotificationService = MockTaliaNotificationService();
    mockPrayerTimesService = MockPrayerTimesService();
    mockGetActiveKhatmahUsecase = MockGetActiveKhatmahUsecase();

    when(
      () => mockPrayerTimesService.isReadyForNotificationScheduling,
    ).thenReturn(false);

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
      () => mockNotificationService.cancelSmartReminder(),
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
      () => mockNotificationService.cancelFridayKahfReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelWeeklyImpactReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelForgettingForecastReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelLastTenReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleLastTenReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        at: any(named: 'at'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleForgettingForecastReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        weekday: any(named: 'weekday'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
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
      () => mockNotificationService.cancelTahajjudReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelKhatmahReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelPrayerTimesReminders(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelPrayerCompanionReminders(),
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
      () => mockNotificationService.scheduleDailyReviewReminder(
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
      () => mockNotificationService.scheduleDailyAyahReminders(
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
        reminderForDate: any(named: 'reminderForDate'),
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
      () => mockNotificationService.scheduleKidsReviewReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});

    // Phase 2 stubbing
    when(
      () => mockNotificationService.cancelFridayKahfReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelWeeklyImpactReminder(),
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
      () => mockNotificationService.cancelTahajjudReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelKhatmahReminder(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.cancelPrayerTimesReminders(),
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
      () => mockNotificationService.scheduleTahajjudReminder(
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

    when(
      () => mockNotificationService.schedulePrayerTimesReminders(
        prayers: any(named: 'prayers'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() => getIt.reset());

  group('refresh ordering and outcome', () {
    test('a later refresh waits until the first refresh finishes', () async {
      SharedPreferences.setMockInitialValues({});
      final firstEntered = Completer<void>();
      final releaseFirst = Completer<void>();
      var timezoneCalls = 0;
      when(() => mockNotificationService.configureLocalTimezone()).thenAnswer((
        _,
      ) async {
        timezoneCalls++;
        if (timezoneCalls == 1) {
          firstEntered.complete();
          await releaseFirst.future;
        }
      });
      final scheduler = NotificationScheduler(mockNotificationService);
      final l10n = lookupAppLocalizations(const Locale('ar'));

      final first = scheduler.refreshNotificationsForSettings(
        l10n,
        force: true,
      );
      await firstEntered.future;
      final second = scheduler.refreshNotificationsForSettings(
        l10n,
        force: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(timezoneCalls, 1);

      releaseFirst.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(timezoneCalls, 2);
    });

    test(
      'a failed refresh reports failure and leaves the queue usable',
      () async {
        SharedPreferences.setMockInitialValues({});
        var attempts = 0;
        when(() => mockNotificationService.configureLocalTimezone()).thenAnswer(
          (_) async {
            attempts++;
            if (attempts == 1) throw StateError('timezone unavailable');
          },
        );
        final scheduler = NotificationScheduler(mockNotificationService);
        final l10n = lookupAppLocalizations(const Locale('ar'));

        expect(await scheduler.refreshNotificationsForSettings(l10n), isFalse);
        expect(await scheduler.refreshNotificationsForSettings(l10n), isTrue);
        expect(attempts, 2);
      },
    );
  });

  group('Friday Surah Al-Kahf reminder', () {
    test('schedules Friday Kahf reminder when enabled', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.fridayKahfPreferenceKey: true,
      });

      final scheduler = NotificationScheduler(mockNotificationService);
      final l10n = lookupAppLocalizations(const Locale('ar'));

      await scheduler.refreshNotifications(l10n);

      verify(
        () => mockNotificationService.scheduleFridayKahfReminder(
          title: l10n.notificationFridayKahfTitle,
          body: l10n.notificationFridayKahfBody,
          hour: 9,
          minute: 0,
        ),
      ).called(1);
    });

    test('cancels Friday Kahf reminder when disabled', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.fridayKahfPreferenceKey: false,
      });

      final scheduler = NotificationScheduler(mockNotificationService);
      final l10n = lookupAppLocalizations(const Locale('ar'));

      await scheduler.refreshNotifications(l10n);

      verify(
        () => mockNotificationService.cancelFridayKahfReminder(),
      ).called(1);
      verifyNever(
        () => mockNotificationService.scheduleFridayKahfReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
    });
  });

  group('Last-ten reminder', () {
    // Ramadan 1448 by the tabular calendar; asserted below, not assumed.
    final now = DateTime(2027, 2, 12, 9);
    final info = ramadanInfoAt(now, adjustmentDays: 0);

    NotificationScheduler scheduler({bool adult = true}) =>
        NotificationScheduler(
          mockNotificationService,
          forecastAudienceIsAdult: (_) async => adult,
          seasonNow: () => now,
          experienceFlags: (prefs) => ExperienceFlags.withUserPreferences(
            prefs,
            const FixedRecordOwnerProvider('a'),
          ),
          seasonPreferences: (prefs) =>
              SeasonPreferences(prefs, const FixedRecordOwnerProvider('a')),
        );

    // The last-ten reminder has its own consent: the card's opt-in only.
    const optedIn = <String, Object>{lastTenReminderPreferenceKey: true};
    final flagOn = <String, Object>{
      ExperienceFeature.seasonalRamadan.storageKey: true,
    };

    Future<void> refresh() => scheduler().refreshNotifications(
      lookupAppLocalizations(const Locale('ar')),
    );

    void expectCancelled() {
      verify(() => mockNotificationService.cancelLastTenReminder()).called(1);
      verifyNever(
        () => mockNotificationService.scheduleLastTenReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          at: any(named: 'at'),
        ),
      );
    }

    void expectScheduled() {
      verify(
        () => mockNotificationService.scheduleLastTenReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          at: any(named: 'at'),
        ),
      ).called(1);
    }

    test('hiding Ramadan cancels the reminder', () async {
      SharedPreferences.setMockInitialValues({
        ...optedIn,
        ...flagOn,
        'season_pref_ramadan|a': false,
      });
      await refresh();
      expectCancelled();
    });

    test('the seasons master switch off cancels the reminder', () async {
      SharedPreferences.setMockInitialValues({
        ...optedIn,
        ...flagOn,
        'season_pref_master|a': false,
      });
      await refresh();
      expectCancelled();
    });

    test('the shared seasonal reminders switch does not gate it', () async {
      for (final shared in <Object?>[false, true, null]) {
        clearInteractions(mockNotificationService);
        SharedPreferences.setMockInitialValues({
          ...optedIn,
          ...flagOn,
          'season_pref_reminders|a': ?shared,
        });
        await refresh();
        expectScheduled();
      }
    });

    test('the user turning the seasonal feature off cancels it', () async {
      SharedPreferences.setMockInitialValues({
        ...optedIn,
        ...flagOn,
        'feature_pref_seasonalRamadan|a': false,
      });
      await refresh();
      expectCancelled();
    });

    test('another owner hiding Ramadan does not affect this one', () async {
      SharedPreferences.setMockInitialValues({
        ...optedIn,
        ...flagOn,
        'season_pref_ramadan|b': false,
      });
      await refresh();
      expectScheduled();
    });

    test('an opted-in adult gets one reminder on the evening of day 20', () async {
      expect(info.phase, RamadanPhase.ramadan);
      SharedPreferences.setMockInitialValues({
        lastTenReminderPreferenceKey: true,
        ExperienceFeature.seasonalRamadan.storageKey: true,
      });
      await scheduler().refreshNotifications(
        lookupAppLocalizations(const Locale('ar')),
      );
      final first = info.firstDay!;
      // No prayer times without a city, so the fallback time applies.
      final expected = DateTime(first.year, first.month, first.day + 19, 17, 30);
      verify(
        () => mockNotificationService.scheduleLastTenReminder(
          title: 'العشر الأواخر',
          body: 'تبدأ العشر الأواخر الليلة بعد المغرب',
          at: expected,
        ),
      ).called(1);
    });

    for (final (label, prefs, adult) in [
      ('not opted in', {ExperienceFeature.seasonalRamadan.storageKey: true}, true),
      (
        'flag off',
        {
          lastTenReminderPreferenceKey: true,
          ExperienceFeature.seasonalRamadan.storageKey: false,
        },
        true,
      ),
      (
        'a child profile',
        {
          lastTenReminderPreferenceKey: true,
          ExperienceFeature.seasonalRamadan.storageKey: true,
        },
        false,
      ),
    ]) {
      test('$label cancels and never schedules', () async {
        SharedPreferences.setMockInitialValues(prefs);
        await scheduler(adult: adult).refreshNotifications(
          lookupAppLocalizations(const Locale('ar')),
        );
        verify(() => mockNotificationService.cancelLastTenReminder()).called(1);
        verifyNever(
          () => mockNotificationService.scheduleLastTenReminder(
            title: any(named: 'title'),
            body: any(named: 'body'),
            at: any(named: 'at'),
          ),
        );
      });
    }
  });

  group('Seasonal reminders', () {
    DateTime civil(int y, int m, int d) {
      final f = hijriMonthFirstCivilDay(y, m, 0);
      return DateTime(f.year, f.month, f.day + d - 1);
    }

    final flagOn = <String, Object>{
      ExperienceFeature.seasonalRamadan.storageKey: true,
    };

    setUp(() {
      when(
        () => mockNotificationService.replaceSeasonReminders(any()),
      ).thenAnswer((_) async {});
    });

    Future<List<SeasonReminderRequest>> run(
      DateTime now,
      Map<String, Object> prefs, {
      bool adult = true,
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      await NotificationScheduler(
        mockNotificationService,
        forecastAudienceIsAdult: (_) async => adult,
        seasonNow: () => now,
        experienceFlags: (p) => ExperienceFlags.withUserPreferences(
          p,
          const FixedRecordOwnerProvider('a'),
        ),
        seasonPreferences: (p) =>
            SeasonPreferences(p, const FixedRecordOwnerProvider('a')),
      ).refreshNotifications(lookupAppLocalizations(const Locale('ar')));
      final captured = verify(
        () => mockNotificationService.replaceSeasonReminders(captureAny()),
      ).captured;
      return captured.last as List<SeasonReminderRequest>;
    }

    final arafahMorning = civil(1448, 12, 8).add(const Duration(hours: 8));

    test('Arafah eve is scheduled in plain UI text at the fallback time', () async {
      final out = await run(arafahMorning, {
        ...flagOn,
        'season_pref_reminders|a': true,
      });
      final l10n = lookupAppLocalizations(const Locale('ar'));
      final first = out.first;
      expect(first.body, l10n.notificationSeasonArafah);
      expect(first.title, l10n.notificationSeasonTitle);
      final d = civil(1448, 12, 8);
      expect(first.at, DateTime(d.year, d.month, d.day, 20));
      final days = out.map((r) => DateTime(r.at.year, r.at.month, r.at.day));
      expect(days.toSet().length, out.length);
    });

    for (final (label, prefs, adult) in [
      ('reminders off', {...flagOn}, true),
      ('reminders explicitly off', {...flagOn, 'season_pref_reminders|a': false}, true),
      (
        'season hidden',
        {
          ...flagOn,
          'season_pref_reminders|a': true,
          'season_pref_dhulHijjahTen|a': false,
        },
        true,
      ),
      (
        'master off',
        {
          ...flagOn,
          'season_pref_reminders|a': true,
          'season_pref_master|a': false,
        },
        true,
      ),
      ('flag off', {ExperienceFeature.seasonalRamadan.storageKey: false, 'season_pref_reminders|a': true}, true),
      ('a child profile', {...flagOn, 'season_pref_reminders|a': true}, false),
      ('another owner opted in', {...flagOn, 'season_pref_reminders|b': true}, true),
    ]) {
      test('$label gives no Arafah reminder', () async {
        final out = await run(arafahMorning, prefs, adult: adult);
        final l10n = lookupAppLocalizations(const Locale('ar'));
        expect(
          out.where((r) => r.body == l10n.notificationSeasonArafah),
          isEmpty,
        );
      });
    }

    test('the last-ten opt-in alone does not enable the general reminders', () async {
      final out = await run(arafahMorning, {
        ...flagOn,
        lastTenReminderPreferenceKey: true,
      });
      expect(out, isEmpty);
    });

    test('there is no seasonal Friday reminder (the weekly one covers it)', () async {
      final out = await run(DateTime(2027, 4, 16, 7), {
        ...flagOn,
        'season_pref_reminders|a': true,
        TaliaNotificationService.fridayKahfPreferenceKey: false,
      });
      expect(out.where((r) => r.payload == '/quran/surah/18'), isEmpty);
    });
  });

  group('Headless refresh (ownerScopedRefresh: false)', () {
    NotificationScheduler worker(DateTime now) => NotificationScheduler(
      mockNotificationService,
      forecastAudienceIsAdult: (_) async => true,
      seasonNow: () => now,
      ownerScopedRefresh: false,
      // The worker cannot know the owner: these must never be consulted.
      experienceFlags: (_) => throw StateError('owner-scoped flags read'),
      seasonPreferences: (_) => throw StateError('owner-scoped seasons read'),
    );

    test(
      "a signed-in owner's season and feature choices are neither cancelled nor added",
      () async {
        SharedPreferences.setMockInitialValues({
          ExperienceFeature.seasonalRamadan.storageKey: true,
          lastTenReminderPreferenceKey: true,
          TaliaNotificationService.forgettingForecastPreferenceKey: true,
          ExperienceFeature.forgettingForecast.storageKey: true,
          'season_pref_reminders|owner-a': true,
          'season_pref_ramadan|owner-a': true,
          'feature_pref_forgettingForecast|owner-a': true,
        });
        await worker(DateTime(2027, 2, 12, 9)).refreshNotifications(
          lookupAppLocalizations(const Locale('ar')),
          force: true,
        );
        verifyNever(() => mockNotificationService.cancelLastTenReminder());
        verifyNever(
          () => mockNotificationService.scheduleLastTenReminder(
            title: any(named: 'title'),
            body: any(named: 'body'),
            at: any(named: 'at'),
          ),
        );
        verifyNever(() => mockNotificationService.replaceSeasonReminders(any()));
        verifyNever(
          () => mockNotificationService.cancelForgettingForecastReminder(),
        );
        verifyNever(
          () => mockNotificationService.scheduleForgettingForecastReminder(
            title: any(named: 'title'),
            body: any(named: 'body'),
            weekday: any(named: 'weekday'),
            hour: any(named: 'hour'),
            minute: any(named: 'minute'),
          ),
        );
      },
    );
  });

  group('Forgetting forecast reminder', () {
    test('the user turning the feature off cancels the reminder', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.forgettingForecastPreferenceKey: true,
        ExperienceFeature.forgettingForecast.storageKey: true,
        'feature_pref_forgettingForecast|a': false,
      });
      final scheduler = NotificationScheduler(
        mockNotificationService,
        forecastAudienceIsAdult: (_) async => true,
        experienceFlags: (prefs) => ExperienceFlags.withUserPreferences(
          prefs,
          const FixedRecordOwnerProvider('a'),
        ),
      );
      await scheduler.refreshNotifications(
        lookupAppLocalizations(const Locale('ar')),
      );
      verify(
        () => mockNotificationService.cancelForgettingForecastReminder(),
      ).called(1);
      verifyNever(
        () => mockNotificationService.scheduleForgettingForecastReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          weekday: any(named: 'weekday'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
    });

    test('schedules for an enabled adult without foreground DI', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.forgettingForecastPreferenceKey: true,
        ExperienceFeature.forgettingForecast.storageKey: true,
      });
      final scheduler = NotificationScheduler(
        mockNotificationService,
        forecastAudienceIsAdult: (_) async => true,
      );

      await scheduler.refreshNotifications(
        lookupAppLocalizations(const Locale('ar')),
      );

      verify(
        () => mockNotificationService.scheduleForgettingForecastReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          weekday: DateTime.monday,
          hour: 18,
          minute: 0,
        ),
      ).called(1);
    });

    test('cancels forecast reminder while independently disabled', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.forgettingForecastPreferenceKey: false,
      });
      final scheduler = NotificationScheduler(mockNotificationService);

      await scheduler.refreshNotifications(
        lookupAppLocalizations(const Locale('ar')),
      );

      verify(
        () => mockNotificationService.cancelForgettingForecastReminder(),
      ).called(1);
      verifyNever(
        () => mockNotificationService.scheduleForgettingForecastReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          weekday: any(named: 'weekday'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
    });
  });

  group('Tahajjud reminder', () {
    test('schedules Tahajjud reminder when enabled', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.tahajjudPreferenceKey: true,
      });

      final scheduler = NotificationScheduler(mockNotificationService);
      final l10n = lookupAppLocalizations(const Locale('ar'));

      await scheduler.refreshNotifications(l10n);

      verify(
        () => mockNotificationService.scheduleTahajjudReminder(
          title: l10n.notificationTahajjudTitle,
          body: l10n.notificationTahajjudBody,
          hour: 3,
          minute: 30,
        ),
      ).called(1);
    });

    test('cancels Tahajjud reminder when disabled', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.tahajjudPreferenceKey: false,
      });

      final scheduler = NotificationScheduler(mockNotificationService);
      final l10n = lookupAppLocalizations(const Locale('ar'));

      await scheduler.refreshNotifications(l10n);

      verify(() => mockNotificationService.cancelTahajjudReminder()).called(1);
      verifyNever(
        () => mockNotificationService.scheduleTahajjudReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
    });
  });

  group('Khatmah progress reminder', () {
    test(
      'schedules Khatmah reminder with smart target when active plan exists',
      () async {
        SharedPreferences.setMockInitialValues({
          TaliaNotificationService.khatmahReminderPreferenceKey: true,
        });

        final now = DateTime.now();
        final activePlan = KhatmahPlan(
          id: 'plan-1',
          title: 'Ramadan Khatmah',
          startDate: now.subtract(const Duration(days: 2)),
          expectedEndDate: now.add(const Duration(days: 28)),
          targetDays: 30,
          targetPagesPerDay: 20,
        );

        when(
          () => mockGetActiveKhatmahUsecase.call(),
        ).thenAnswer((_) async => activePlan);

        final scheduler = NotificationScheduler(
          mockNotificationService,
          getActiveKhatmah: mockGetActiveKhatmahUsecase,
        );
        final l10n = lookupAppLocalizations(const Locale('ar'));

        await scheduler.refreshNotifications(l10n);

        verify(
          () => mockNotificationService.scheduleKhatmahReminders(
            title: l10n.notificationKhatmahTitle,
            reminders: any(
              named: 'reminders',
              that: hasLength(KhatmahReminderPolicy.maxSlots),
            ),
          ),
        ).called(1);
      },
    );

    test('no active khatmah cancels reminders instead of nudging', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.khatmahReminderPreferenceKey: true,
      });
      when(
        () => mockGetActiveKhatmahUsecase.call(),
      ).thenAnswer((_) async => null);
      final scheduler = NotificationScheduler(
        mockNotificationService,
        getActiveKhatmah: mockGetActiveKhatmahUsecase,
      );

      await scheduler.refreshNotifications(
        lookupAppLocalizations(const Locale('ar')),
      );

      verify(() => mockNotificationService.cancelKhatmahReminder()).called(1);
      verifyNever(
        () => mockNotificationService.scheduleKhatmahReminders(
          title: any(named: 'title'),
          reminders: any(named: 'reminders'),
        ),
      );
    });

    test('cancels Khatmah reminder when disabled', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.khatmahReminderPreferenceKey: false,
      });

      final scheduler = NotificationScheduler(mockNotificationService);
      final l10n = lookupAppLocalizations(const Locale('ar'));

      await scheduler.refreshNotifications(l10n);

      verify(() => mockNotificationService.cancelKhatmahReminder()).called(1);
      verifyNever(
        () => mockNotificationService.scheduleKhatmahReminders(
          title: any(named: 'title'),
          reminders: any(named: 'reminders'),
        ),
      );
    });
  });

  group('Prayer times rolling reminders', () {
    test(
      'legacy prayer failure is reported and retried on the next refresh',
      () async {
        SharedPreferences.setMockInitialValues({
          TaliaNotificationService.prayerNotificationsPreferenceKey: true,
        });
        when(
          () => mockPrayerTimesService.isReadyForNotificationScheduling,
        ).thenReturn(true);
        when(
          () => mockPrayerTimesService.timesForDate(any()),
        ).thenAnswer((_) async => []);
        var attempts = 0;
        when(
          () => mockNotificationService.schedulePrayerTimesReminders(
            prayers: any(named: 'prayers'),
          ),
        ).thenAnswer((_) async {
          attempts++;
          if (attempts == 1) throw StateError('schedule failed');
        });
        final scheduler = NotificationScheduler(
          mockNotificationService,
          prayerTimesService: mockPrayerTimesService,
        );
        final l10n = lookupAppLocalizations(const Locale('ar'));

        expect(await scheduler.refreshNotificationsForSettings(l10n), isFalse);
        expect(await scheduler.refreshNotificationsForSettings(l10n), isTrue);
        expect(attempts, 2);
      },
    );

    test(
      'cancels prayer reminders until the prayer location is configured',
      () async {
        SharedPreferences.setMockInitialValues({
          TaliaNotificationService.prayerNotificationsPreferenceKey: true,
        });

        final scheduler = NotificationScheduler(
          mockNotificationService,
          prayerTimesService: mockPrayerTimesService,
        );

        await scheduler.refreshNotifications(
          lookupAppLocalizations(const Locale('ar')),
        );

        verify(
          () => mockNotificationService.cancelPrayerTimesReminders(),
        ).called(1);
        verifyNever(
          () => mockNotificationService.schedulePrayerTimesReminders(
            prayers: any(named: 'prayers'),
          ),
        );
      },
    );

    test('schedules prayer times for rolling window when enabled', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.prayerNotificationsPreferenceKey: true,
        TaliaNotificationService.prayerFajrKey: true,
        TaliaNotificationService.prayerDhuhrKey: true,
        TaliaNotificationService.prayerAsrKey: true,
        TaliaNotificationService.prayerMaghribKey: true,
        TaliaNotificationService.prayerIshaKey: true,
      });

      when(() => mockPrayerTimesService.timesForDate(any())).thenAnswer((
        inv,
      ) async {
        final date = inv.positionalArguments[0] as DateTime;
        return [
          (
            key: 'fajr',
            nameAr: 'الفجر',
            nameEn: 'Fajr',
            time: DateTime(date.year, date.month, date.day, 4, 30),
          ),
          (
            key: 'dhuhr',
            nameAr: 'الظهر',
            nameEn: 'Dhuhr',
            time: DateTime(date.year, date.month, date.day, 12, 15),
          ),
          (
            key: 'asr',
            nameAr: 'العصر',
            nameEn: 'Asr',
            time: DateTime(date.year, date.month, date.day, 15, 45),
          ),
          (
            key: 'maghrib',
            nameAr: 'المغرب',
            nameEn: 'Maghrib',
            time: DateTime(date.year, date.month, date.day, 18, 20),
          ),
          (
            key: 'isha',
            nameAr: 'العشاء',
            nameEn: 'Isha',
            time: DateTime(date.year, date.month, date.day, 19, 45),
          ),
        ];
      });
      when(
        () => mockPrayerTimesService.isReadyForNotificationScheduling,
      ).thenReturn(true);

      final scheduler = NotificationScheduler(
        mockNotificationService,
        prayerTimesService: mockPrayerTimesService,
      );
      final l10n = lookupAppLocalizations(const Locale('ar'));

      await scheduler.refreshNotifications(l10n);

      final captured = verify(
        () => mockNotificationService.schedulePrayerTimesReminders(
          prayers: captureAny(named: 'prayers'),
        ),
      ).captured;

      expect(captured.isNotEmpty, isTrue);
      final scheduledList = captured.first as List<ScheduledPrayerNotification>;
      expect(scheduledList.isNotEmpty, isTrue);
      // 7 days * 5 prayers = 35 prayers
      expect(scheduledList.length, 35);
    });

    test('respects individual prayer filters (e.g. Fajr disabled)', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.prayerNotificationsPreferenceKey: true,
        TaliaNotificationService.prayerFajrKey: false,
        TaliaNotificationService.prayerDhuhrKey: true,
        TaliaNotificationService.prayerAsrKey: true,
        TaliaNotificationService.prayerMaghribKey: true,
        TaliaNotificationService.prayerIshaKey: true,
      });

      when(() => mockPrayerTimesService.timesForDate(any())).thenAnswer((
        inv,
      ) async {
        final date = inv.positionalArguments[0] as DateTime;
        return [
          (
            key: 'fajr',
            nameAr: 'الفجر',
            nameEn: 'Fajr',
            time: DateTime(date.year, date.month, date.day, 4, 30),
          ),
          (
            key: 'dhuhr',
            nameAr: 'الظهر',
            nameEn: 'Dhuhr',
            time: DateTime(date.year, date.month, date.day, 12, 15),
          ),
          (
            key: 'asr',
            nameAr: 'العصر',
            nameEn: 'Asr',
            time: DateTime(date.year, date.month, date.day, 15, 45),
          ),
          (
            key: 'maghrib',
            nameAr: 'المغرب',
            nameEn: 'Maghrib',
            time: DateTime(date.year, date.month, date.day, 18, 20),
          ),
          (
            key: 'isha',
            nameAr: 'العشاء',
            nameEn: 'Isha',
            time: DateTime(date.year, date.month, date.day, 19, 45),
          ),
        ];
      });
      when(
        () => mockPrayerTimesService.isReadyForNotificationScheduling,
      ).thenReturn(true);

      final scheduler = NotificationScheduler(
        mockNotificationService,
        prayerTimesService: mockPrayerTimesService,
      );
      final l10n = lookupAppLocalizations(const Locale('ar'));

      await scheduler.refreshNotifications(l10n);

      final captured = verify(
        () => mockNotificationService.schedulePrayerTimesReminders(
          prayers: captureAny(named: 'prayers'),
        ),
      ).captured;

      final scheduledList = captured.first as List<ScheduledPrayerNotification>;
      // 7 days * 4 prayers = 28 prayers (Fajr excluded)
      expect(scheduledList.length, 28);
      final fajrNotifications = scheduledList.where(
        (p) => p.title.contains('الفجر') || p.title.contains('Fajr'),
      );
      expect(fajrNotifications, isEmpty);
    });

    test(
      'forwards city-zone prayer instants unchanged to the scheduler',
      () async {
        SharedPreferences.setMockInitialValues({
          TaliaNotificationService.prayerNotificationsPreferenceKey: true,
          TaliaNotificationService.prayerFajrKey: true,
          TaliaNotificationService.prayerDhuhrKey: true,
          TaliaNotificationService.prayerAsrKey: true,
          TaliaNotificationService.prayerMaghribKey: true,
          TaliaNotificationService.prayerIshaKey: true,
        });

        tz_data.initializeTimeZones();
        final london = getLocation('Europe/London');
        when(() => mockPrayerTimesService.timesForDate(any())).thenAnswer((
          inv,
        ) async {
          final date = inv.positionalArguments[0] as DateTime;
          final day = TZDateTime.from(date, london);
          DateTime at(int hour, int minute) =>
              TZDateTime(london, day.year, day.month, day.day, hour, minute);
          return [
            (key: 'fajr', nameAr: 'الفجر', nameEn: 'Fajr', time: at(2, 30)),
            (key: 'dhuhr', nameAr: 'الظهر', nameEn: 'Dhuhr', time: at(13, 5)),
            (key: 'asr', nameAr: 'العصر', nameEn: 'Asr', time: at(17, 40)),
            (
              key: 'maghrib',
              nameAr: 'المغرب',
              nameEn: 'Maghrib',
              time: at(21, 20),
            ),
            (key: 'isha', nameAr: 'العشاء', nameEn: 'Isha', time: at(23, 10)),
          ];
        });
        when(
          () => mockPrayerTimesService.isReadyForNotificationScheduling,
        ).thenReturn(true);

        final scheduler = NotificationScheduler(
          mockNotificationService,
          prayerTimesService: mockPrayerTimesService,
        );

        await scheduler.refreshNotifications(
          lookupAppLocalizations(const Locale('ar')),
        );

        final captured = verify(
          () => mockNotificationService.schedulePrayerTimesReminders(
            prayers: captureAny(named: 'prayers'),
          ),
        ).captured;
        final scheduledList =
            captured.first as List<ScheduledPrayerNotification>;
        expect(scheduledList.length, 35);
        expect(scheduledList.take(5).map((p) => p.prayerKey), [
          'fajr',
          'dhuhr',
          'asr',
          'maghrib',
          'isha',
        ]);
        for (final prayer in scheduledList) {
          final time = prayer.scheduledDate as TZDateTime;
          expect(
            time.location.name,
            'Europe/London',
            reason: 'scheduler must not reinterpret city times in device zone',
          );
        }
      },
    );

    test('cancels prayer reminders when overall switch is disabled', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.prayerNotificationsPreferenceKey: false,
      });

      final scheduler = NotificationScheduler(
        mockNotificationService,
        prayerTimesService: mockPrayerTimesService,
      );
      final l10n = lookupAppLocalizations(const Locale('ar'));

      await scheduler.refreshNotifications(l10n);

      verify(
        () => mockNotificationService.cancelPrayerTimesReminders(),
      ).called(1);
      verifyNever(
        () => mockNotificationService.schedulePrayerTimesReminders(
          prayers: any(named: 'prayers'),
        ),
      );
    });
  });
}
