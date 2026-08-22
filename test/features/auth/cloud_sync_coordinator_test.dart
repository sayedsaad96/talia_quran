import 'dart:async';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import 'package:talia_quran/features/auth/application/cloud_sync_coordinator.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_cloud_repository.dart';

class _FakeAuthRepository implements AuthRepository {
  final events = <String>[];
  bool failPull = false;
  bool hasPendingPush = false;
  Future<void>? pushGate;
  void Function(int call)? onPushStarted;

  int get pullCalls => events.where((event) => event == 'pull').length;
  int get syncCalls => events.where((event) => event == 'push').length;

  @override
  Future<Either<Failure, Unit>> pullProgressFromCloud() async {
    events.add('pull');
    if (failPull) throw StateError('offline');
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> syncProgressToCloud() async {
    events.add('push');
    onPushStarted?.call(syncCalls);
    await pushGate;
    return const Right(unit);
  }

  @override
  Future<bool> hasPendingCloudPush() async => hasPendingPush;

  @override
  AppUser? get currentUser => const AppUser(
    id: 'coordinator-user',
    email: 'coordinator@example.com',
    displayName: 'Coordinator',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMemorizationCloudRepository implements MemorizationCloudRepository {
  @override
  Future<Either<Failure, void>> pullIdentityFromCloud() async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> pullProductionDataFromCloud() async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> pullKidsProgressFromCloud() async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> resyncProductionDataToCloud() async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> syncKidsProgressToCloud() async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> pushIdentityToCloud() async =>
      const Right(null);

  @override
  Future<bool> hasPendingCloudWork() async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

bool _isarCoreInitialized = false;

Future<void> _initializeIsarCoreForTests() async {
  if (_isarCoreInitialized) return;
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final dllPath =
          '$localAppData\\Pub\\Cache\\hosted\\pub.dev\\'
          'isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
      if (File(dllPath).existsSync()) {
        await Isar.initializeIsarCore(libraries: {Abi.current(): dllPath});
        _isarCoreInitialized = true;
        return;
      }
    }
  }
  await Isar.initializeIsarCore();
  _isarCoreInitialized = true;
}

void main() {
  late _FakeAuthRepository authRepository;
  late _FakeMemorizationCloudRepository memorizationRepository;

  setUp(() {
    authRepository = _FakeAuthRepository();
    memorizationRepository = _FakeMemorizationCloudRepository();
  });

  test('run pulls cloud progress before pushing local progress', () async {
    await CloudSyncCoordinator(
      authRepository: authRepository,
      memorizationCloudRepository: memorizationRepository,
    ).run();

    expect(authRepository.events, ['pull', 'push']);
  });

  test(
    'resume preserves dead-letter queue work until explicit recovery',
    () async {
      await _initializeIsarCoreForTests();
      final directory = await Directory.systemTemp.createTemp(
        'cloud_sync_coord_',
      );
      final isar = await Isar.open(
        [CloudSyncQueueItemSchema],
        directory: directory.path,
        name: 'cloud_sync_coordinator_test',
      );
      final queue = CloudSyncQueue(
        isar,
        const FixedRecordOwnerProvider('coordinator-user'),
      );
      await queue.enqueue(CloudSyncQueueKind.authPull);
      for (var i = 0; i < CloudSyncQueue.maxAttempts; i++) {
        await queue.markFailure(CloudSyncQueueKind.authPull);
      }

      try {
        await CloudSyncCoordinator(
          authRepository: authRepository,
          memorizationCloudRepository: memorizationRepository,
          cloudSyncQueue: queue,
        ).resumeIfNeeded();

        expect(authRepository.pullCalls, 0);
        expect(await queue.deadLetterItems(), hasLength(1));
      } finally {
        await isar.close(deleteFromDisk: true);
        await directory.delete(recursive: true);
      }
    },
  );

  test('run contains unexpected cloud failures', () async {
    authRepository.failPull = true;

    await expectLater(
      CloudSyncCoordinator(
        authRepository: authRepository,
        memorizationCloudRepository: memorizationRepository,
      ).run(),
      completes,
    );
    expect(authRepository.syncCalls, 0);
  });

  test(
    'local progress events coalesce into a push without a full cloud pull',
    () async {
      final progressEvents = ProgressEventsBus();
      final pushStarted = Completer<void>();
      authRepository
        ..hasPendingPush = true
        ..onPushStarted = (_) => pushStarted.complete();
      final coordinator = CloudSyncCoordinator(
        authRepository: authRepository,
        progressEvents: progressEvents,
        localChangeDebounce: Duration.zero,
      );

      progressEvents.notify(ProgressChangedReason.xp);
      await pushStarted.future.timeout(const Duration(seconds: 1));

      expect(authRepository.pullCalls, 0);
      expect(authRepository.syncCalls, 1);

      await coordinator.dispose();
      progressEvents.dispose();
    },
  );

  test('a local mutation arriving during a push remains scheduled', () async {
    final progressEvents = ProgressEventsBus();
    final firstPushStarted = Completer<void>();
    final secondPushStarted = Completer<void>();
    final firstPushGate = Completer<void>();
    authRepository
      ..hasPendingPush = true
      ..pushGate = firstPushGate.future
      ..onPushStarted = (call) {
        if (call == 1) {
          firstPushStarted.complete();
        } else if (call == 2) {
          secondPushStarted.complete();
        }
      };
    final coordinator = CloudSyncCoordinator(
      authRepository: authRepository,
      progressEvents: progressEvents,
      localChangeDebounce: Duration.zero,
    );

    progressEvents.notify(ProgressChangedReason.streak);
    await firstPushStarted.future.timeout(const Duration(seconds: 1));
    progressEvents.notify(ProgressChangedReason.xp);
    firstPushGate.complete();
    await secondPushStarted.future.timeout(const Duration(seconds: 1));

    expect(authRepository.pullCalls, 0);
    expect(authRepository.syncCalls, 2);

    await coordinator.dispose();
    progressEvents.dispose();
  });
}
