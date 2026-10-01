import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'notification_refresh_worker.dart';

/// Workmanager uses one dispatcher for reminders and legacy cloud retries.
@pragma('vm:entry-point')
void cloudSyncCallbackDispatcher() {
  Workmanager().executeTask(dispatchBackgroundTask);
}

Future<bool> dispatchBackgroundTask(
  String task,
  Map<String, dynamic>? inputData,
) async {
  if (task == kNotificationRefreshTaskName) {
    return runNotificationRefreshTask();
  }
  // Retire old cloud jobs without opening account stores in a second engine.
  // Foreground reconciliation still delivers the durable account outbox.
  return true;
}

/// Registers the reminder dispatcher and cancels previously queued cloud jobs.
/// Cloud writes run only in the foreground until lifecycle locking spans engines.
class BackgroundSyncScheduler {
  static const _uniqueNamePrefix = 'talia-cloud-sync-';

  bool get _isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (!_isSupported) return;
    await Workmanager().initialize(cloudSyncCallbackDispatcher);
  }

  Future<void> cancelAccountSync(String ownerId) async {
    if (!_isSupported) return;
    await Workmanager().cancelByUniqueName('$_uniqueNamePrefix$ownerId');
  }
}
