import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/app_version_service.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../../domain/usecases/google_play_update_usecase.dart';
import 'app_update_state.dart';

class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit(this._updates, this._preferences, this._versionInfoProvider)
    : super(const AppUpdateState()) {
    _downloadedUpdateSubscription = _updates.downloadedUpdates.listen(
      (_) => _handleDownloadedUpdate(),
      onError: (Object error, StackTrace stackTrace) {
        if (error is PlatformException || error is MissingPluginException) {
          return;
        }
        addError(error, stackTrace);
      },
    );
  }

  static const Duration promptThrottle = Duration(hours: 24);
  static const Duration completeTimeout = Duration(seconds: 4);
  static const String _promptedAtKeyPrefix = 'google_play_update.prompted_at.';

  final GooglePlayUpdateUseCase _updates;
  final SharedPreferences _preferences;
  final AppVersionInfoProvider _versionInfoProvider;
  late final StreamSubscription<void> _downloadedUpdateSubscription;
  bool _isChecking = false;
  bool _isStarting = false;
  bool _isCompleting = false;
  bool _isForeground = true;
  bool _hasDownloadedUpdate = false;

  void setForeground(bool isForeground) {
    final resumed = !_isForeground && isForeground;
    _isForeground = isForeground;
    if (resumed && _hasDownloadedUpdate && !_isCompleting && !isClosed) {
      emit(
        state.copyWith(
          status: AppUpdateUiStatus.installReady,
          promptRevision: state.promptRevision + 1,
        ),
      );
    }
  }

  Future<void> checkForUpdate({required bool Function() canPrompt}) async {
    if (!_updates.isSupported ||
        !_isForeground ||
        _isChecking ||
        _isCompleting ||
        isClosed) {
      return;
    }
    _isChecking = true;
    final AppUpdateCheckResult result;
    try {
      result = await _updates.check();
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    } finally {
      _isChecking = false;
    }
    if (isClosed || !_isForeground) return;
    if (result.availability == AppUpdateAvailability.downloaded) {
      _handleDownloadedUpdate();
      return;
    }
    if (result.availability == AppUpdateAvailability.flexibleUpdateAvailable) {
      unawaited(_startFlexibleUpdate(result.availableVersionCode, canPrompt));
    }
  }

  Future<void> completeDownloadedUpdate() async {
    if (!_updates.isSupported ||
        !_isForeground ||
        _isCompleting ||
        isClosed ||
        (state.status != AppUpdateUiStatus.installReady &&
            state.status != AppUpdateUiStatus.completionFailed)) {
      return;
    }
    _isCompleting = true;
    emit(state.copyWith(status: AppUpdateUiStatus.completing));
    try {
      await _updates.completeFlexibleUpdate().timeout(completeTimeout);
    } on TimeoutException {
      _emitCompletionFailure();
    } on PlatformException {
      _emitCompletionFailure();
    } on MissingPluginException {
      _emitCompletionFailure();
    } finally {
      _isCompleting = false;
    }
  }

  Future<void> _startFlexibleUpdate(
    int? availableVersionCode,
    bool Function() canPrompt,
  ) async {
    if (_isStarting || !_isForeground || !canPrompt() || isClosed) return;
    _isStarting = true;
    try {
      if (!await _mayPromptFor(availableVersionCode) ||
          !_isForeground ||
          !canPrompt() ||
          isClosed) {
        return;
      }
      await _recordPromptFor(availableVersionCode);
      if (!_isForeground || !canPrompt() || isClosed) return;
      final startResult = await _updates.startFlexibleUpdate();
      if (startResult == AppUpdateStartResult.started && !isClosed) {
        _handleDownloadedUpdate();
      }
    } on PlatformException {
      // Google Play is unavailable/offline; normal use continues.
    } on MissingPluginException {
      // The bridge is unavailable outside a Play-installed Android release.
    } finally {
      _isStarting = false;
    }
  }

  Future<bool> _mayPromptFor(int? availableVersionCode) async {
    final key = await _throttleKey(availableVersionCode);
    final lastPromptedAt = _preferences.getInt(key);
    if (lastPromptedAt == null) return true;
    return DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastPromptedAt),
        ) >=
        promptThrottle;
  }

  Future<void> _recordPromptFor(int? availableVersionCode) async {
    await _preferences.setInt(
      await _throttleKey(availableVersionCode),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<String> _throttleKey(int? availableVersionCode) async {
    final version = await _versionInfoProvider.getVersionInfo();
    return '$_promptedAtKeyPrefix${version.buildNumber}.'
        '${availableVersionCode ?? 'unknown'}';
  }

  void _handleDownloadedUpdate() {
    _hasDownloadedUpdate = true;
    if (_isForeground && !isClosed) _showInstallPrompt();
  }

  void _showInstallPrompt() {
    if (isClosed ||
        _isCompleting ||
        state.status == AppUpdateUiStatus.installReady) {
      return;
    }
    emit(
      state.copyWith(
        status: AppUpdateUiStatus.installReady,
        promptRevision: state.promptRevision + 1,
      ),
    );
  }

  void _emitCompletionFailure() {
    if (!isClosed && _isForeground) {
      emit(
        state.copyWith(
          status: AppUpdateUiStatus.completionFailed,
          promptRevision: state.promptRevision + 1,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    unawaited(_downloadedUpdateSubscription.cancel());
    return super.close();
  }
}
