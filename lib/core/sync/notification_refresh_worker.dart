import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../l10n/app_localizations.dart';
import '../services/notification_scheduler.dart';
import '../services/notification_service.dart';
import '../utils/talia_logger.dart';

/// Task name used when registering the periodic notification refresh.
const String kNotificationRefreshTaskName = 'talia.notification_refresh';

/// Unique WorkManager name for the periodic notification refresh task.
const String kNotificationRefreshUniqueName =
    'com.taliaquran.notification-refresh';

/// Runs a lightweight notification refresh in a background isolate.
///
/// Deliberately minimal: NO AppInitializer.initialize(), NO permission
/// requests (both need a foreground Activity). Only SharedPreferences, the
/// notification service and the scheduler are touched. RootBundle asset loads
/// (approved azkar corpus) work inside Workmanager headless engines on
/// workmanager 0.10.x. A failure is returned to WorkManager so Android can
/// retry with its configured backoff.
Future<bool> runNotificationRefreshTask() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('app_locale') ?? 'ar';
    final l10n = lookupAppLocalizations(Locale(languageCode));

    final scheduler = NotificationScheduler(TaliaNotificationService());
    return await scheduler.refreshNotificationsInBackground(l10n, force: true);
  } catch (error, stack) {
    TaliaLogger.w('Background notification refresh failed', error, stack);
    return false;
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
