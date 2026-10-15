import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import '../../domain/repositories/app_update_repository.dart';

/// Google Play's native in-app update bridge.
///
/// This deliberately has no fallback URL: Google Play decides availability for
/// the installed package and its current release track.
class GooglePlayAppUpdateRepository implements AppUpdateRepository {
  @override
  bool get isSupported => !kIsWeb && !kDebugMode && Platform.isAndroid;

  @override
  Stream<void> get downloadedUpdates {
    if (!isSupported) return const Stream<void>.empty();
    return InAppUpdate.installUpdateListener
        .where((status) => status == InstallStatus.downloaded)
        .map((_) {});
  }

  @override
  Future<AppUpdateCheckResult> checkForUpdate() async {
    if (!isSupported) return const AppUpdateCheckResult.noUpdate();
    final info = await InAppUpdate.checkForUpdate();
    if (info.installStatus == InstallStatus.downloaded) {
      return AppUpdateCheckResult(
        AppUpdateAvailability.downloaded,
        availableVersionCode: info.availableVersionCode,
      );
    }
    if (info.installStatus == InstallStatus.pending ||
        info.installStatus == InstallStatus.downloading ||
        info.installStatus == InstallStatus.installing) {
      return const AppUpdateCheckResult.noUpdate();
    }
    if (info.updateAvailability == UpdateAvailability.updateAvailable &&
        info.flexibleUpdateAllowed) {
      return AppUpdateCheckResult(
        AppUpdateAvailability.flexibleUpdateAvailable,
        availableVersionCode: info.availableVersionCode,
      );
    }
    return const AppUpdateCheckResult.noUpdate();
  }

  @override
  Future<AppUpdateStartResult> startFlexibleUpdate() async {
    if (!isSupported) return AppUpdateStartResult.failed;
    return switch (await InAppUpdate.startFlexibleUpdate()) {
      AppUpdateResult.success => AppUpdateStartResult.started,
      AppUpdateResult.userDeniedUpdate => AppUpdateStartResult.declined,
      AppUpdateResult.inAppUpdateFailed => AppUpdateStartResult.failed,
    };
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    if (!isSupported) return;
    await InAppUpdate.completeFlexibleUpdate();
  }
}
