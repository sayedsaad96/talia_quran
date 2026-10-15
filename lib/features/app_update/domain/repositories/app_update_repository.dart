/// Google Play's current update state for this installation.
enum AppUpdateAvailability { noUpdate, flexibleUpdateAvailable, downloaded }

class AppUpdateCheckResult {
  const AppUpdateCheckResult(this.availability, {this.availableVersionCode});

  const AppUpdateCheckResult.noUpdate() : this(AppUpdateAvailability.noUpdate);

  final AppUpdateAvailability availability;
  final int? availableVersionCode;
}

// Google Play resolves the flexible-update operation after download completes.
enum AppUpdateStartResult { started, declined, failed }

abstract interface class AppUpdateRepository {
  bool get isSupported;

  Stream<void> get downloadedUpdates;

  Future<AppUpdateCheckResult> checkForUpdate();

  Future<AppUpdateStartResult> startFlexibleUpdate();

  Future<void> completeFlexibleUpdate();
}
