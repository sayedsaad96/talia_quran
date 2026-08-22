import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../di/injection.dart';
import '../identity/record_owner_provider.dart';
import '../../features/auth/application/cloud_sync_coordinator.dart';
import '../services/app_initializer.dart';

const _cloudSyncTaskName = 'talia.cloud_sync';
const _ownerInputKey = 'owner_id';

/// Entrypoint retained by the VM so Workmanager can start an isolated Flutter
/// engine after the app has been terminated.
@pragma('vm:entry-point')
void cloudSyncCallbackDispatcher() {
  Workmanager().executeTask((_, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await AppInitializer.initialize(background: true);
      final scheduledOwner = inputData?[_ownerInputKey] as String?;
      final activeOwner = getIt<RecordOwnerProvider>().currentOwnerId;
      if (scheduledOwner == null || scheduledOwner != activeOwner) {
        return true;
      }
      await getIt<CloudSyncCoordinator>().run();
      return true;
    } catch (_) {
      // Returning false lets Android apply WorkManager backoff. iOS treats
      // delivery as best-effort and may choose the next execution window.
      return false;
    }
  });
}

/// Schedules owner-scoped, network-constrained retry delivery.
///
/// Foreground synchronization remains the primary path; this scheduler only
/// persists a best-effort operating-system retry for durable queue work.
class BackgroundSyncScheduler {
  static const _uniqueNamePrefix = 'talia-cloud-sync-';

  bool get _isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (!_isSupported) return;
    await Workmanager().initialize(cloudSyncCallbackDispatcher);
  }

  Future<void> scheduleAccountSync(String ownerId) async {
    if (!_isSupported) return;
    await Workmanager().registerOneOffTask(
      '$_uniqueNamePrefix$ownerId',
      _cloudSyncTaskName,
      inputData: {_ownerInputKey: ownerId},
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  }

  Future<void> cancelAccountSync(String ownerId) async {
    if (!_isSupported) return;
    await Workmanager().cancelByUniqueName('$_uniqueNamePrefix$ownerId');
  }
}
