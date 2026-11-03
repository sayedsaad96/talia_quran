import 'dart:ui';
import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/core/storage/data_admission.dart';
import 'package:talia_quran/core/sync/notification_refresh_worker.dart'
    show debugCompanionPlannerBuilder, runNotificationRefreshTask;
import 'package:talia_quran/features/prayer_companion/data/datasources/prayer_companion_preferences.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_scheduler_planner.dart';

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

class MockPrayerCompanionPlanner extends Mock
    implements PrayerCompanionPlanner {}

class WorkerAdmission implements DataAdmissionPlatform {
  bool allow = true;
  bool valid = true;
  bool released = false;
  @override
  Future<String?> acquire(DataAdmissionMode mode) async =>
      allow && mode == DataAdmissionMode.worker ? 'worker' : null;
  @override
  Future<bool> validate(String token) async => valid && !released;
  @override
  Future<bool> release(String token) async {
    released = true;
    return true;
  }
}

/// Records which local dependencies the headless production factory hands to
/// the scheduler, so the test can assert the prayer + Companion graph is
/// built instead of the legacy bare `NotificationScheduler(service)`.
class RecordingSchedulerFactory {
  PrayerTimesService? receivedPrayerTimesService;
  PrayerCompanionPlanner? receivedCompanionPlanner;
  PrayerCompanionPreferences? receivedCompanionPreferences;
  late final MockNotificationScheduler scheduler = MockNotificationScheduler();

  NotificationScheduler call({
    required TaliaNotificationService service,
    PrayerTimesService? prayerTimesService,
    PrayerCompanionPlanner? prayerCompanionPlanner,
    PrayerCompanionPreferences? prayerCompanionPreferences,
  }) {
    receivedPrayerTimesService = prayerTimesService;
    receivedCompanionPlanner = prayerCompanionPlanner;
    receivedCompanionPreferences = prayerCompanionPreferences;
    return scheduler;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(lookupAppLocalizations(const Locale('ar')));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Isar's native library is unavailable in unit tests; stand in for the
    // planner builder while the production wiring builds every other dep.
    debugCompanionPlannerBuilder = (prefs) async =>
        MockPrayerCompanionPlanner();
  });

  tearDown(() {
    debugCompanionPlannerBuilder = null;
  });

  test(
    'headless refresh builds local prayer and Companion dependencies',
    () async {
      final factory = RecordingSchedulerFactory();
      when(
        () => factory.scheduler.refreshNotificationsInBackground(
          any(),
          force: any(named: 'force'),
        ),
      ).thenAnswer((_) async => true);

      final result = await runNotificationRefreshTask(
        createScheduler: factory.call,
        admission: DataAdmission(platform: WorkerAdmission()),
        journalIsClean: () async => true,
      );

      expect(result, isTrue);
      expect(factory.receivedPrayerTimesService, isNotNull);
      expect(factory.receivedCompanionPlanner, isNotNull);
      expect(factory.receivedCompanionPreferences, isNotNull);
      verify(
        () => factory.scheduler.refreshNotificationsInBackground(
          any(),
          force: true,
        ),
      ).called(1);
    },
  );

  test(
    'non-Android refresh does not require an Android-only channel',
    () async {
      final factory = RecordingSchedulerFactory();
      when(
        () => factory.scheduler.refreshNotificationsInBackground(
          any(),
          force: any(named: 'force'),
        ),
      ).thenAnswer((_) async => true);
      expect(
        await runNotificationRefreshTask(
          createScheduler: factory.call,
          journalIsClean: () async => true,
        ),
        isTrue,
      );
      expect(factory.receivedCompanionPlanner, isNotNull);
    },
    skip: Platform.isAndroid,
  );

  test('headless refresh returns false when the refresh throws', () async {
    final factory = RecordingSchedulerFactory();
    when(
      () => factory.scheduler.refreshNotificationsInBackground(
        any(),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) async => false);

    final result = await runNotificationRefreshTask(
      createScheduler: factory.call,
      admission: DataAdmission(platform: WorkerAdmission()),
      journalIsClean: () async => true,
    );

    expect(result, isFalse);
  });

  test(
    'denied worker does not inspect journal or construct scheduler',
    () async {
      final worker = WorkerAdmission()..allow = false;
      var inspected = false;
      var constructed = false;
      final result = await runNotificationRefreshTask(
        admission: DataAdmission(platform: worker),
        journalIsClean: () async {
          inspected = true;
          return true;
        },
        createScheduler:
            ({
              required service,
              prayerTimesService,
              prayerCompanionPlanner,
              prayerCompanionPreferences,
            }) {
              constructed = true;
              throw StateError('must not construct');
            },
      );
      expect(result, isFalse);
      expect(inspected, isFalse);
      expect(constructed, isFalse);
    },
  );

  test(
    'pending journal releases admission without touching scheduler',
    () async {
      final worker = WorkerAdmission();
      var constructed = false;
      final result = await runNotificationRefreshTask(
        admission: DataAdmission(platform: worker),
        journalIsClean: () async => false,
        createScheduler:
            ({
              required service,
              prayerTimesService,
              prayerCompanionPlanner,
              prayerCompanionPreferences,
            }) {
              constructed = true;
              throw StateError('must not construct');
            },
      );
      expect(result, isFalse);
      expect(constructed, isFalse);
      expect(worker.released, isTrue);
    },
  );

  test(
    'headless forecast audience reads the adult profile without DI',
    () async {
      SharedPreferences.setMockInitialValues({
        'mem_plus_profile': '{"selectedPath":"adult","schemaVersion":1}',
      });
      final prefs = await SharedPreferences.getInstance();

      expect(await forecastAudienceIsAdultFromPreferences(prefs), isTrue);
    },
  );

  test(
    'headless forecast audience fails closed for unknown profile state',
    () async {
      final prefs = await SharedPreferences.getInstance();

      expect(await forecastAudienceIsAdultFromPreferences(prefs), isFalse);
    },
  );
}
