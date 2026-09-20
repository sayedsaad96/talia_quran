import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/notification_scheduler.dart';
import 'package:talia_quran/core/services/notification_service.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/core/sync/notification_refresh_worker.dart'
    show debugCompanionPlannerBuilder, runNotificationRefreshTask;
import 'package:talia_quran/features/prayer_companion/data/datasources/prayer_companion_preferences.dart';
import 'package:talia_quran/features/prayer_companion/domain/services/prayer_companion_scheduler_planner.dart';

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

class MockPrayerCompanionPlanner extends Mock
    implements PrayerCompanionPlanner {}

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
    );

    expect(result, isFalse);
  });
}
