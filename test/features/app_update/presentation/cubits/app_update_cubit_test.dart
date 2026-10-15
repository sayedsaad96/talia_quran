import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/app_version_service.dart';
import 'package:talia_quran/features/app_update/domain/repositories/app_update_repository.dart';
import 'package:talia_quran/features/app_update/domain/usecases/google_play_update_usecase.dart';
import 'package:talia_quran/features/app_update/presentation/cubits/app_update_cubit.dart';
import 'package:talia_quran/features/app_update/presentation/cubits/app_update_state.dart';

void main() {
  late SharedPreferences preferences;
  late _FakeUpdateRepository repository;
  late AppUpdateCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    repository = _FakeUpdateRepository();
    cubit = AppUpdateCubit(
      GooglePlayUpdateUseCase(repository),
      preferences,
      const _VersionInfoProvider(),
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.close();
  });

  test('no update leaves the app idle', () async {
    await cubit.checkForUpdate(canPrompt: _canPrompt);

    expect(repository.startCalls, 0);
    expect(cubit.state.status, AppUpdateUiStatus.idle);
  });

  for (final startResult in [
    AppUpdateStartResult.declined,
    AppUpdateStartResult.failed,
  ]) {
    test(
      'a ${startResult.name} prompt is throttled across app launches',
      () async {
        repository.result = const AppUpdateCheckResult(
          AppUpdateAvailability.flexibleUpdateAvailable,
          availableVersionCode: 42,
        );
        repository.startResult = startResult;
        await cubit.checkForUpdate(canPrompt: _canPrompt);
        await Future<void>.delayed(Duration.zero);
        await cubit.close();
        cubit = AppUpdateCubit(
          GooglePlayUpdateUseCase(repository),
          preferences,
          const _VersionInfoProvider(),
        );
        await cubit.checkForUpdate(canPrompt: _canPrompt);
        await Future<void>.delayed(Duration.zero);
        expect(repository.startCalls, 1);

        repository.result = const AppUpdateCheckResult(
          AppUpdateAvailability.flexibleUpdateAvailable,
          availableVersionCode: 43,
        );
        await cubit.checkForUpdate(canPrompt: _canPrompt);
        await Future<void>.delayed(Duration.zero);
        expect(repository.startCalls, 2);
      },
    );
  }

  test('check exception is ignored without changing visible state', () async {
    repository.checkError = PlatformException(code: 'unavailable');

    await cubit.checkForUpdate(canPrompt: _canPrompt);

    expect(cubit.state.status, AppUpdateUiStatus.idle);
  });

  test(
    'downloaded update prompts even when automatic consent is gated',
    () async {
      repository.result = const AppUpdateCheckResult(
        AppUpdateAvailability.downloaded,
      );

      await cubit.checkForUpdate(canPrompt: _cannotPrompt);

      expect(repository.startCalls, 0);
      expect(cubit.state.status, AppUpdateUiStatus.installReady);
    },
  );

  test(
    'download in background is remembered until returning to foreground',
    () async {
      cubit.setForeground(false);
      repository.downloadedController.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, AppUpdateUiStatus.idle);
      cubit.setForeground(true);
      expect(cubit.state.status, AppUpdateUiStatus.installReady);
    },
  );

  test('unsupported platforms do not call Google Play', () async {
    repository.isSupportedValue = false;

    await cubit.checkForUpdate(canPrompt: _canPrompt);

    expect(repository.checkCalls, 0);
  });

  test('completion failure keeps an explicit retry state', () async {
    repository.result = const AppUpdateCheckResult(
      AppUpdateAvailability.downloaded,
    );
    repository.completeError = PlatformException(code: 'failed');
    await cubit.checkForUpdate(canPrompt: _canPrompt);

    await cubit.completeDownloadedUpdate();

    expect(repository.completeCalls, 1);
    expect(cubit.state.status, AppUpdateUiStatus.completionFailed);
  });

  test('delayed check does not start consent after app backgrounds', () async {
    repository.result = const AppUpdateCheckResult(
      AppUpdateAvailability.flexibleUpdateAvailable,
    );
    final pendingCheck = Completer<AppUpdateCheckResult>();
    repository.pendingCheck = pendingCheck;

    final checking = cubit.checkForUpdate(canPrompt: _canPrompt);
    cubit.setForeground(false);
    pendingCheck.complete(repository.result);
    await checking;
    await Future<void>.delayed(Duration.zero);

    expect(repository.startCalls, 0);
  });

  test('pending download does not block resume recovery', () async {
    repository.result = const AppUpdateCheckResult(
      AppUpdateAvailability.flexibleUpdateAvailable,
    );
    repository.pendingStart = Completer<AppUpdateStartResult>();
    await cubit.checkForUpdate(canPrompt: _canPrompt);
    await Future<void>.delayed(Duration.zero);
    cubit.setForeground(false);
    cubit.setForeground(true);
    repository.result = const AppUpdateCheckResult(
      AppUpdateAvailability.downloaded,
    );
    await cubit.checkForUpdate(canPrompt: _canPrompt);

    expect(repository.startCalls, 1);
    expect(cubit.state.status, AppUpdateUiStatus.installReady);
    repository.pendingStart!.complete(AppUpdateStartResult.started);
    await Future<void>.delayed(Duration.zero);
  });

  test(
    'a delayed check does not prompt after the user changes route',
    () async {
      final pendingCheck = Completer<AppUpdateCheckResult>();
      repository.pendingCheck = pendingCheck;
      var onHome = true;
      final checking = cubit.checkForUpdate(canPrompt: () => onHome);
      onHome = false;
      pendingCheck.complete(
        const AppUpdateCheckResult(
          AppUpdateAvailability.flexibleUpdateAvailable,
        ),
      );
      await checking;
      await Future<void>.delayed(Duration.zero);
      expect(repository.startCalls, 0);
    },
  );

  test('closing during a delayed check prevents a native prompt', () async {
    final pendingCheck = Completer<AppUpdateCheckResult>();
    repository.pendingCheck = pendingCheck;
    final checking = cubit.checkForUpdate(canPrompt: _canPrompt);
    await cubit.close();
    pendingCheck.complete(
      const AppUpdateCheckResult(AppUpdateAvailability.flexibleUpdateAvailable),
    );
    await checking;
    expect(repository.startCalls, 0);
  });

  test('installation is ignored before a download is ready', () async {
    await cubit.completeDownloadedUpdate();
    expect(repository.completeCalls, 0);
  });

  test('a native install call that never resolves offers another choice', () {
    fakeAsync((async) {
      repository.downloadedController.add(null);
      async.flushMicrotasks();
      repository.pendingCompletion = Completer<void>();
      unawaited(cubit.completeDownloadedUpdate());
      async.flushMicrotasks();
      expect(cubit.state.status, AppUpdateUiStatus.completing);
      async.elapse(AppUpdateCubit.completeTimeout);
      async.flushMicrotasks();
      expect(cubit.state.status, AppUpdateUiStatus.completionFailed);
      repository.pendingCompletion!.complete();
      async.flushMicrotasks();
    });
  });
}

bool _canPrompt() => true;
bool _cannotPrompt() => false;

class _VersionInfoProvider implements AppVersionInfoProvider {
  const _VersionInfoProvider();

  @override
  Future<AppVersionInfo> getVersionInfo() async =>
      const AppVersionInfo(version: '1.0.1', buildNumber: '2');
}

class _FakeUpdateRepository implements AppUpdateRepository {
  final downloadedController = StreamController<void>.broadcast();
  bool isSupportedValue = true;
  AppUpdateCheckResult result = const AppUpdateCheckResult.noUpdate();
  Object? checkError;
  Object? completeError;
  Completer<AppUpdateCheckResult>? pendingCheck;
  Completer<AppUpdateStartResult>? pendingStart;
  Completer<void>? pendingCompletion;
  AppUpdateStartResult startResult = AppUpdateStartResult.started;
  int checkCalls = 0;
  int startCalls = 0;
  int completeCalls = 0;

  @override
  bool get isSupported => isSupportedValue;

  @override
  Stream<void> get downloadedUpdates => downloadedController.stream;

  @override
  Future<AppUpdateCheckResult> checkForUpdate() async {
    checkCalls++;
    if (checkError != null) throw checkError!;
    if (pendingCheck != null) return pendingCheck!.future;
    return result;
  }

  @override
  Future<AppUpdateStartResult> startFlexibleUpdate() async {
    startCalls++;
    if (pendingStart != null) return pendingStart!.future;
    return startResult;
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    completeCalls++;
    if (completeError != null) throw completeError!;
    if (pendingCompletion != null) await pendingCompletion!.future;
  }

  Future<void> close() => downloadedController.close();
}
