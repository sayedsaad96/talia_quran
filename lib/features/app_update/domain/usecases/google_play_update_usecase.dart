import '../repositories/app_update_repository.dart';

class GooglePlayUpdateUseCase {
  const GooglePlayUpdateUseCase(this._repository);

  final AppUpdateRepository _repository;

  bool get isSupported => _repository.isSupported;

  Stream<void> get downloadedUpdates => _repository.downloadedUpdates;

  Future<AppUpdateCheckResult> check() => _repository.checkForUpdate();

  Future<AppUpdateStartResult> startFlexibleUpdate() =>
      _repository.startFlexibleUpdate();

  Future<void> completeFlexibleUpdate() => _repository.completeFlexibleUpdate();
}
