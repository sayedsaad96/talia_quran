import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/prayer_companion/data/datasources/prayer_companion_local_datasource.dart';
import '../../features/prayer_companion/data/datasources/prayer_companion_preferences.dart';
import '../../features/prayer_companion/data/models/prayer_companion_record_isar.dart';
import '../../features/prayer_companion/data/repositories/prayer_companion_repository_impl.dart';
import '../../features/prayer_companion/domain/services/prayer_companion_scheduler_planner.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_scheduler.dart';
import '../services/notification_service.dart';
import '../services/prayer_times_service.dart';
import '../utils/talia_logger.dart';

/// Task name used when registering the periodic notification refresh.
const String kNotificationRefreshTaskName = 'talia.notification_refresh';

/// Unique WorkManager name for the periodic notification refresh task.
const String kNotificationRefreshUniqueName =
    'com.taliaquran.notification-refresh';

/// Test seam for [runNotificationRefreshTask]: receives the fully assembled
/// local prayer + Companion dependency graph and returns the scheduler to
/// run. The production default is [_createLocalScheduler].
typedef NotificationSchedulerFactory =
    NotificationScheduler Function({
      required TaliaNotificationService service,
      PrayerTimesService? prayerTimesService,
      PrayerCompanionPlanner? prayerCompanionPlanner,
      PrayerCompanionPreferences? prayerCompanionPreferences,
    });

/// Test-only override for the Companion planner builder. Null in production.
/// Lets a test supply a local planner when Isar's native library is
/// unavailable (unit tests) while still exercising the real production
/// wiring of every other dependency.
Future<PrayerCompanionPlanner?> Function(SharedPreferences prefs)?
debugCompanionPlannerBuilder;

/// Runs a lightweight notification refresh in a background isolate.
///
/// Deliberately minimal: NO AppInitializer.initialize(), NO permission
/// requests (both need a foreground Activity), NO Supabase, NO Workmanager
/// registration. Only SharedPreferences, the local Isar instance, the
/// notification service and the scheduler are touched. RootBundle asset
/// loads (approved azkar corpus) work inside Workmanager headless engines on
/// workmanager 0.10.x. A failure is returned to WorkManager so Android can
/// retry with its configured backoff.
Future<bool> runNotificationRefreshTask({
  NotificationSchedulerFactory createScheduler = _createLocalScheduler,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('app_locale') ?? 'ar';
    final l10n = lookupAppLocalizations(Locale(languageCode));

    final scheduler = createScheduler(
      service: TaliaNotificationService(),
      prayerTimesService: PrayerTimesService(prefs),
      prayerCompanionPreferences: PrayerCompanionPreferences(prefs),
      prayerCompanionPlanner:
          await (debugCompanionPlannerBuilder ?? _createLocalCompanionPlanner)(
            prefs,
          ),
    );
    return await scheduler.refreshNotificationsInBackground(l10n, force: true);
  } catch (error, stack) {
    TaliaLogger.w('Background notification refresh failed', error, stack);
    return false;
  }
}

/// Production factory: wires the explicitly built local dependencies into
/// the scheduler. Kept as a named function so it is the visible default of
/// [runNotificationRefreshTask].
NotificationScheduler _createLocalScheduler({
  required TaliaNotificationService service,
  PrayerTimesService? prayerTimesService,
  PrayerCompanionPlanner? prayerCompanionPlanner,
  PrayerCompanionPreferences? prayerCompanionPreferences,
}) {
  return NotificationScheduler(
    service,
    prayerTimesService: prayerTimesService,
    prayerCompanionPlanner: prayerCompanionPlanner,
    prayerCompanionPreferences: prayerCompanionPreferences,
  );
}

/// Builds the Companion planner from local storage only.
///
/// Uses the already-open Isar instance when present (the app isolate) and
/// otherwise opens one with just the Companion schema in the headless
/// isolate. Returns null if Isar cannot be opened — the scheduler then
/// cancels Companion events instead of crashing the background task.
Future<PrayerCompanionPlanner?> _createLocalCompanionPlanner(
  SharedPreferences prefs,
) async {
  try {
    final isar =
        Isar.getInstance() ??
        await Isar.open([
          PrayerCompanionRecordIsarSchema,
        ], directory: (await getApplicationDocumentsDirectory()).path);
    final datasource = PrayerCompanionLocalDatasource(isar);
    final repository = PrayerCompanionRepositoryImpl(datasource);
    final preferences = PrayerCompanionPreferences(prefs);
    return PrayerCompanionPlanner(
      prayerTimesService: PrayerTimesService(prefs),
      preferences: preferences,
      repository: repository,
      prefs: Future.value(prefs),
    );
  } catch (error, stack) {
    TaliaLogger.w('Failed to build headless companion planner', error, stack);
    return null;
  }
}

/// Standalone entry-point dispatcher for the notification refresh task.
///
/// NOTE: Workmanager supports a single registered dispatcher per app, so in
/// production the shared `cloudSyncCallbackDispatcher` routes
/// [kNotificationRefreshTaskName] to [runNotificationRefreshTask]. This
/// top-level dispatcher exists so the task can also be executed standalone
/// (e.g. during testing or if registration is moved to its own
/// `Workmanager().initialize` call).
@pragma('vm:entry-point')
void notificationRefreshCallbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task == kNotificationRefreshTaskName) {
      return runNotificationRefreshTask();
    }
    return false;
  });
}
