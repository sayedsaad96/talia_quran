import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_delivery_coordinator.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_delivery_scheduler.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_delivery_version.dart';
import 'package:talia_quran/core/prayer_delivery/prayer_scheduled_event.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';

class MockTaliaNotificationService extends Mock
    implements TaliaNotificationService {}

class MockPrayerTimesService extends Mock implements PrayerTimesService {}

class MockGetActiveKhatmahUsecase extends Mock
    implements GetActiveKhatmahUsecase {}

class FakeScheduledPrayerNotification extends Fake
    implements ScheduledPrayerNotification {}

class FakeAppLocalizations extends Fake implements AppLocalizations {}

class _FakeScheduler implements PrayerDeliveryScheduler {
  _FakeScheduler(this.result);
  PrayerDeliveryResult result;
  int scheduleCalls = 0;
  int cancelAllCalls = 0;

  @override
  Future<bool> canScheduleExact() async => true;

  @override
  Future<void> cancelPrayerEvent(PrayerScheduledEvent event) async {}

  @override
  Future<void> cancelPrayerEvents() async {
    cancelAllCalls++;
  }

  @override
  Future<PrayerDeliveryResult> schedulePrayerEvents(
    List<PrayerScheduledEvent> events,
  ) async {
    scheduleCalls++;
    return result;
  }
}

late MockTaliaNotificationService mockNotificationService;
late MockPrayerTimesService mockPrayerTimesService;
late MockGetActiveKhatmahUsecase mockGetActiveKhatmahUsecase;

void _stubCancellations() {
  final cancellations = <Future<void> Function()>[
    () => mockNotificationService.cancelDailyReviewReminder(),
    () => mockNotificationService.cancelStreakAlert(),
    () => mockNotificationService.cancelStreakGentleNudge(),
    () => mockNotificationService.cancelDailyAyahReminder(),
    () => mockNotificationService.cancelMorningAzkarReminder(),
    () => mockNotificationService.cancelEveningAzkarReminder(),
    () => mockNotificationService.cancelDailyDuaReminder(),
    () => mockNotificationService.cancelKidsReviewReminder(),
    () => mockNotificationService.cancelFridayKahfReminder(),
    () => mockNotificationService.cancelWeeklyImpactReminder(),
    () => mockNotificationService.cancelTahajjudReminder(),
    () => mockNotificationService.cancelKhatmahReminder(),
    () => mockNotificationService.cancelSmartReminder(),
    () => mockNotificationService.cancelPrayerTimesReminders(),
    () => mockNotificationService.cancelPrayerCompanionReminders(),
  ];
  for (final cancel in cancellations) {
    when(cancel).thenAnswer((_) async {});
  }
}

Future<void> _stubCommon() async {
  await getIt.reset();
  mockNotificationService = MockTaliaNotificationService();
  mockPrayerTimesService = MockPrayerTimesService();
  mockGetActiveKhatmahUsecase = MockGetActiveKhatmahUsecase();

  when(() => mockPrayerTimesService.isReadyForNotificationScheduling)
      .thenReturn(true);
  when(() => mockNotificationService.attachLocalization(any()))
      .thenAnswer((_) async {});
  when(() => mockNotificationService.configureLocalTimezone())
      .thenAnswer((_) async {});
  when(() => mockPrayerTimesService.cities()).thenAnswer(
    (_) async => const [
      PrayerCity(
        id: 'london',
        nameAr: 'لندن',
        nameEn: 'London',
        latitude: 51.5074,
        longitude: -0.1278,
        timeZone: 'Europe/London',
        countryId: 'uk',
        countryAr: 'المملكة المتحدة',
        countryEn: 'United Kingdom',
        defaultMethod: 'muslim_world_league',
      ),
    ],
  );
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
  when(() => mockPrayerTimesService.timesForDate(any())).thenAnswer((inv) async {
    final date = inv.positionalArguments[0] as DateTime;
    return [
      (key: 'fajr', nameAr: 'الفجر', nameEn: 'Fajr',
          time: date.add(const Duration(hours: 4))),
      (key: 'dhuhr', nameAr: 'الظهر', nameEn: 'Dhuhr',
          time: date.add(const Duration(hours: 12))),
      (key: 'asr', nameAr: 'العصر', nameEn: 'Asr',
          time: date.add(const Duration(hours: 15))),
      (key: 'maghrib', nameAr: 'المغرب', nameEn: 'Maghrib',
          time: date.add(const Duration(hours: 18))),
      (key: 'isha', nameAr: 'العشاء', nameEn: 'Isha',
          time: date.add(const Duration(hours: 20))),
    ];
  });
  _stubCancellations();
}

Map<String, Object> _prayerPrefs([Map<String, Object> extra = const {}]) => {
      TaliaNotificationService.dailyReviewPreferenceKey: false,
      TaliaNotificationService.streakAlertPreferenceKey: false,
      TaliaNotificationService.morningAzkarPreferenceKey: false,
      TaliaNotificationService.eveningAzkarPreferenceKey: false,
      TaliaNotificationService.dailyDuaPreferenceKey: false,
      TaliaNotificationService.dailyAyahPreferenceKey: false,
      TaliaNotificationService.kidsReminderPreferenceKey: false,
      TaliaNotificationService.fridayKahfPreferenceKey: false,
      TaliaNotificationService.weeklyImpactPreferenceKey: false,
      TaliaNotificationService.tahajjudPreferenceKey: false,
      TaliaNotificationService.khatmahReminderPreferenceKey: false,
      TaliaNotificationService.smartReminderPreferenceKey: false,
      TaliaNotificationService.prayerNotificationsPreferenceKey: true,
      ...extra,
    };

void main() {
  setUpAll(() {
    registerFallbackValue(FakeScheduledPrayerNotification());
    registerFallbackValue(<ScheduledPrayerNotification>[]);
    registerFallbackValue(FakeAppLocalizations());
  });

  test('no FLN prayer scheduling when native V2 is the active owner',
      () async {
    await _stubCommon();
    SharedPreferences.setMockInitialValues(
      _prayerPrefs({
        PrayerDeliveryVersion.prefsKey: PrayerDeliveryVersion.nativeAndroidV2,
      }),
    );
    final fakeScheduler = _FakeScheduler(
      const PrayerDeliveryResult(success: true, scheduledCount: 35),
    );
    final scheduler = NotificationScheduler(
      mockNotificationService,
      prayerTimesService: mockPrayerTimesService,
      prayerDeliveryCoordinator: PrayerDeliveryCoordinator(
        fakeScheduler,
        isAndroid: () => true,
      ),
    );

    await scheduler.refreshNotifications(
      lookupAppLocalizations(const Locale('ar')),
    );

    expect(fakeScheduler.scheduleCalls, 1);
    // Golden rule: FLN legacy prayer scheduling must not run.
    verifyNever(
      () => mockNotificationService.schedulePrayerTimesReminders(
        prayers: any(named: 'prayers'),
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
      PrayerDeliveryVersion.read(prefs),
      PrayerDeliveryVersion.nativeAndroidV2,
    );
  });

  test('V2 is dormant on non-Android: legacy FLN path keeps ownership',
      () async {
    await _stubCommon();
    SharedPreferences.setMockInitialValues(_prayerPrefs());
    final fakeScheduler = _FakeScheduler(
      const PrayerDeliveryResult(success: true, scheduledCount: 35),
    );
    final scheduler = NotificationScheduler(
      mockNotificationService,
      prayerTimesService: mockPrayerTimesService,
      prayerDeliveryCoordinator: PrayerDeliveryCoordinator(
        fakeScheduler,
        isAndroid: () => false,
      ),
    );

    await scheduler.refreshNotifications(
      lookupAppLocalizations(const Locale('ar')),
    );

    expect(fakeScheduler.scheduleCalls, 0);
    verify(
      () => mockNotificationService.schedulePrayerTimesReminders(
        prayers: any(named: 'prayers'),
      ),
    ).called(1);
  });

  test('migration failure rebuilds the legacy schedule in the same refresh',
      () async {
    await _stubCommon();
    SharedPreferences.setMockInitialValues(_prayerPrefs());
    final fakeScheduler = _FakeScheduler(
      const PrayerDeliveryResult(
        success: false,
        scheduledCount: 0,
        error: 'denied',
      ),
    );
    final scheduler = NotificationScheduler(
      mockNotificationService,
      prayerTimesService: mockPrayerTimesService,
      prayerDeliveryCoordinator: PrayerDeliveryCoordinator(
        fakeScheduler,
        isAndroid: () => true,
      ),
    );

    await scheduler.refreshNotifications(
      lookupAppLocalizations(const Locale('ar')),
    );

    expect(fakeScheduler.scheduleCalls, 1, reason: 'migration attempt');
    verify(
      () => mockNotificationService.cancelPrayerTimesReminders(),
    ).called(1);
    verify(
      () => mockNotificationService.schedulePrayerTimesReminders(
        prayers: any(named: 'prayers'),
      ),
    ).called(1);
    final prefs = await SharedPreferences.getInstance();
    expect(PrayerDeliveryVersion.read(prefs), PrayerDeliveryVersion.legacy);
  });

  test('disabling prayer notifications clears both delivery owners',
      () async {
    await _stubCommon();
    SharedPreferences.setMockInitialValues(
      _prayerPrefs({
        TaliaNotificationService.prayerNotificationsPreferenceKey: false,
        PrayerDeliveryVersion.prefsKey: PrayerDeliveryVersion.nativeAndroidV2,
      }),
    );
    final fakeScheduler = _FakeScheduler(
      const PrayerDeliveryResult(success: true, scheduledCount: 0),
    );
    final scheduler = NotificationScheduler(
      mockNotificationService,
      prayerTimesService: mockPrayerTimesService,
      prayerDeliveryCoordinator: PrayerDeliveryCoordinator(
        fakeScheduler,
        isAndroid: () => true,
      ),
    );

    await scheduler.refreshNotifications(
      lookupAppLocalizations(const Locale('ar')),
    );

    verify(
      () => mockNotificationService.cancelPrayerTimesReminders(),
    ).called(1);
    expect(fakeScheduler.cancelAllCalls, 1);
    expect(fakeScheduler.scheduleCalls, 0);
  });

  test(
    'golden rule: a native-owner refresh skipped by the rolling guard still '
    'cancels legacy FLN alarms (no dual ownership after app restart)',
    () async {
      await _stubCommon();
      SharedPreferences.setMockInitialValues(
        _prayerPrefs({
          PrayerDeliveryVersion.prefsKey: PrayerDeliveryVersion.nativeAndroidV2,
        }),
      );
      final fakeScheduler = _FakeScheduler(
        const PrayerDeliveryResult(success: true, scheduledCount: 35),
      );
      final scheduler = NotificationScheduler(
        mockNotificationService,
        prayerTimesService: mockPrayerTimesService,
        prayerDeliveryCoordinator: PrayerDeliveryCoordinator(
          fakeScheduler,
          isAndroid: () => true,
        ),
      );

      // First refresh: rolling window builds the native schedule.
      await scheduler.refreshNotifications(
        lookupAppLocalizations(const Locale('ar')),
      );
      expect(fakeScheduler.scheduleCalls, 1);

      // Second refresh: the rolling guard skips re-scheduling, but the legacy
      // ids (still armed from the pre-migration session) must be cancelled.
      await scheduler.refreshNotifications(
        lookupAppLocalizations(const Locale('ar')),
      );
      verify(
        () => mockNotificationService.cancelPrayerTimesReminders(),
      ).called(greaterThan(0));
      verifyNever(
        () => mockNotificationService.schedulePrayerTimesReminders(
          prayers: any(named: 'prayers'),
        ),
      );
    },
  );
}