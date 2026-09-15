import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';

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
  });

  late MockTaliaNotificationService mockNotificationService;
  late MockPrayerTimesService mockPrayerTimesService;
  late MockGetActiveKhatmahUsecase mockGetActiveKhatmahUsecase;

  setUp(() async {
    await getIt.reset();
    mockNotificationService = MockTaliaNotificationService();
    mockPrayerTimesService = MockPrayerTimesService();
    mockGetActiveKhatmahUsecase = MockGetActiveKhatmahUsecase();

    when(() => mockPrayerTimesService.isReadyForNotificationScheduling)
        .thenReturn(false);

    when(() => mockNotificationService.configureLocalTimezone())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelStreakAlert())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelStreakGentleNudge())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelSmartReminder())
        .thenAnswer((_) async {});
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
    when(() => mockNotificationService.cancelFridayKahfReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelTahajjudReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelKhatmahReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelPrayerTimesReminders())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelDailyReviewReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelDailyAyahReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelMorningAzkarReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelEveningAzkarReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelDailyDuaReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelKidsReviewReminder())
        .thenAnswer((_) async {});

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
    when(() => mockNotificationService.cancelFridayKahfReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelTahajjudReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelKhatmahReminder())
        .thenAnswer((_) async {});
    when(() => mockNotificationService.cancelPrayerTimesReminders())
        .thenAnswer((_) async {});

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
      () => mockNotificationService.scheduleKhatmahReminder(
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockNotificationService.schedulePrayerTimesReminders(
        prayers: any(named: 'prayers'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() => getIt.reset());

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

      verify(() => mockNotificationService.cancelFridayKahfReminder()).called(1);
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
    test('schedules Khatmah reminder with smart target when active plan exists', () async {
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

      when(() => mockGetActiveKhatmahUsecase.call())
          .thenAnswer((_) async => activePlan);

      final scheduler = NotificationScheduler(
        mockNotificationService,
        getActiveKhatmah: mockGetActiveKhatmahUsecase,
      );
      final l10n = lookupAppLocalizations(const Locale('ar'));

      await scheduler.refreshNotifications(l10n);

      verify(
        () => mockNotificationService.scheduleKhatmahReminder(
          title: l10n.notificationKhatmahTitle,
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          hour: 17,
          minute: 0,
        ),
      ).called(1);
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
        () => mockNotificationService.scheduleKhatmahReminder(
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          hour: any(named: 'hour'),
          minute: any(named: 'minute'),
        ),
      );
    });
  });

  group('Prayer times rolling reminders', () {
    test('cancels prayer reminders until the prayer location is configured', () async {
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

      verify(() => mockNotificationService.cancelPrayerTimesReminders())
          .called(1);
      verifyNever(
        () => mockNotificationService.schedulePrayerTimesReminders(
          prayers: any(named: 'prayers'),
        ),
      );
    });

    test('schedules prayer times for rolling window when enabled', () async {
      SharedPreferences.setMockInitialValues({
        TaliaNotificationService.prayerNotificationsPreferenceKey: true,
        TaliaNotificationService.prayerFajrKey: true,
        TaliaNotificationService.prayerDhuhrKey: true,
        TaliaNotificationService.prayerAsrKey: true,
        TaliaNotificationService.prayerMaghribKey: true,
        TaliaNotificationService.prayerIshaKey: true,
      });

      when(() => mockPrayerTimesService.timesForDate(any())).thenAnswer((inv) async {
        final date = inv.positionalArguments[0] as DateTime;
        return [
          (key: 'fajr', nameAr: 'الفجر', nameEn: 'Fajr', time: DateTime(date.year, date.month, date.day, 4, 30)),
          (key: 'dhuhr', nameAr: 'الظهر', nameEn: 'Dhuhr', time: DateTime(date.year, date.month, date.day, 12, 15)),
          (key: 'asr', nameAr: 'العصر', nameEn: 'Asr', time: DateTime(date.year, date.month, date.day, 15, 45)),
          (key: 'maghrib', nameAr: 'المغرب', nameEn: 'Maghrib', time: DateTime(date.year, date.month, date.day, 18, 20)),
          (key: 'isha', nameAr: 'العشاء', nameEn: 'Isha', time: DateTime(date.year, date.month, date.day, 19, 45)),
        ];
      });
      when(() => mockPrayerTimesService.isReadyForNotificationScheduling)
          .thenReturn(true);

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

      when(() => mockPrayerTimesService.timesForDate(any())).thenAnswer((inv) async {
        final date = inv.positionalArguments[0] as DateTime;
        return [
          (key: 'fajr', nameAr: 'الفجر', nameEn: 'Fajr', time: DateTime(date.year, date.month, date.day, 4, 30)),
          (key: 'dhuhr', nameAr: 'الظهر', nameEn: 'Dhuhr', time: DateTime(date.year, date.month, date.day, 12, 15)),
          (key: 'asr', nameAr: 'العصر', nameEn: 'Asr', time: DateTime(date.year, date.month, date.day, 15, 45)),
          (key: 'maghrib', nameAr: 'المغرب', nameEn: 'Maghrib', time: DateTime(date.year, date.month, date.day, 18, 20)),
          (key: 'isha', nameAr: 'العشاء', nameEn: 'Isha', time: DateTime(date.year, date.month, date.day, 19, 45)),
        ];
      });
      when(() => mockPrayerTimesService.isReadyForNotificationScheduling)
          .thenReturn(true);

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

      verify(() => mockNotificationService.cancelPrayerTimesReminders()).called(1);
      verifyNever(
        () => mockNotificationService.schedulePrayerTimesReminders(
          prayers: any(named: 'prayers'),
        ),
      );
    });
  });
}
