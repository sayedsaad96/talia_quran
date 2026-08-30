import 'dart:async';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/security/encrypted_account_preferences_store.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import 'package:talia_quran/features/auth/application/cloud_sync_coordinator.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_cloud_repository.dart';
import 'package:talia_quran/features/quran/data/datasources/bookmark_service.dart';
import 'package:talia_quran/features/quran/domain/entities/bookmark_entry.dart';

class _FakeAuthRepository implements AuthRepository {
  final events = <String>[];
  bool failPull = false;
  bool hasPendingPush = false;
  Future<void>? pushGate;
  Future<void>? pullGate;
  void Function()? onPullStarted;
  void Function(int call)? onPushStarted;
  AppUser? user = const AppUser(
    id: 'coordinator-user',
    email: 'coordinator@example.com',
    displayName: 'Coordinator',
  );

  int get pullCalls => events.where((event) => event == 'pull').length;
  int get syncCalls => events.where((event) => event == 'push').length;

  @override
  Future<Either<Failure, Unit>> pullProgressFromCloud() async {
    events.add('pull');
    onPullStarted?.call();
    await pullGate;
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
  AppUser? get currentUser => user;

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

  test('external owner switch aborts the remaining captured-owner sync',
      () async {
    final pullStarted = Completer<void>();
    final releasePull = Completer<void>();
    authRepository
      ..pullGate = releasePull.future
      ..onPullStarted = pullStarted.complete;
    final coordinator = CloudSyncCoordinator(
      authRepository: authRepository,
      memorizationCloudRepository: memorizationRepository,
    );

    final sync = coordinator.run();
    await pullStarted.future;
    authRepository.user = const AppUser(
      id: 'owner-b',
      email: 'b@example.com',
      displayName: 'B',
    );
    releasePull.complete();
    await sync;

    expect(authRepository.syncCalls, 0);
  });

  test('background execution leaves bookmark writes for foreground', () async {
    await _initializeIsarCoreForTests();
    final directory = await Directory.systemTemp.createTemp(
      'background_bookmark_sync_',
    );
    final isar = await Isar.open(
      [CloudSyncQueueItemSchema],
      directory: directory.path,
      name: 'background_bookmark_sync',
    );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final encrypted = _MemoryEncryptedAccountPreferencesStore();
    const owner = FixedRecordOwnerProvider('background-owner');
    final queue = CloudSyncQueue(isar, owner);
    var cloudCalls = 0;
    final bookmarks = BookmarkService(
      prefs,
      owner: owner,
      cloudSyncQueue: queue,
      encryptedAccountPreferences: encrypted,
      cloudRpc: (String function, {Map<String, dynamic>? params}) async {
        cloudCalls += 1;
        return const <dynamic>[];
      },
    );
    await bookmarks.toggle(
      BookmarkEntry(
        surahId: 2,
        surahName: 'البقرة',
        ayahNumber: 255,
        ayahText: 'آية الكرسي',
        savedAt: DateTime.utc(2026, 8, 25),
      ),
    );

    try {
      await CloudSyncCoordinator(
        authRepository: authRepository,
        memorizationCloudRepository: memorizationRepository,
        cloudSyncQueue: queue,
        bookmarkService: bookmarks,
        syncBookmarks: false,
      ).run();

      expect(cloudCalls, 0);
      expect(await bookmarks.hasPendingCloudWorkDurably(), isTrue);
      final queued = await queue.dueItems();
      expect(queued, hasLength(1));
      expect(queued.single.kind, CloudSyncQueueKind.bookmarkPush);
      expect(queued.single.attemptCount, 0);
    } finally {
      await isar.close(deleteFromDisk: true);
      await directory.delete(recursive: true);
    }
  });

  test('identity transition drains an in-flight owner bookmark push', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final encrypted = _MemoryEncryptedAccountPreferencesStore();
    final owner = _MutableRecordOwnerProvider('owner-a');
    final pushStarted = Completer<void>();
    final releasePush = Completer<void>();
    final ownersAtPush = <String>[];
    final bookmarks = BookmarkService(
      prefs,
      owner: owner,
      encryptedAccountPreferences: encrypted,
      cloudRpc: (function, {params}) async {
        if (function == 'pull_quran_bookmarks') return const <dynamic>[];
        ownersAtPush.add(owner.currentOwnerId);
        pushStarted.complete();
        await releasePush.future;
        return [
          {
            'surah_id': params!['p_surah_id'],
            'ayah_number': params['p_ayah_number'],
            'revision': params['p_revision'],
          },
        ];
      },
    );
    await bookmarks.toggle(
      BookmarkEntry(
        surahId: 2,
        surahName: 'البقرة',
        ayahNumber: 255,
        ayahText: 'آية الكرسي',
        savedAt: DateTime.utc(2026, 8, 25),
      ),
    );
    final coordinator = CloudSyncCoordinator(
      authRepository: authRepository,
      bookmarkService: bookmarks,
    );
    final sync = coordinator.run();
    await pushStarted.future;
    var transitionCompleted = false;
    final transition = coordinator.beginIdentityTransition().then((_) {
      transitionCompleted = true;
      owner.currentOwnerId = 'owner-b';
    });

    await Future<void>.delayed(Duration.zero);
    expect(transitionCompleted, isFalse);
    releasePush.complete();
    await transition;
    await sync;

    expect(owner.currentOwnerId, 'owner-b');
    expect(ownersAtPush, ['owner-a']);
    coordinator.endIdentityTransition();
  });

  test(
    'nested identity transitions keep sync gated until the final end',
    () async {
      final coordinator = CloudSyncCoordinator(authRepository: authRepository);
      await coordinator.beginIdentityTransition();
      await coordinator.beginIdentityTransition();

      coordinator.endIdentityTransition();
      await coordinator.run();
      expect(authRepository.pullCalls, 0);

      coordinator.endIdentityTransition();
      await coordinator.run();
      expect(authRepository.pullCalls, 1);
    },
  );

  test(
    'identity transition token is releasable from a finally block',
    () async {
      final coordinator = CloudSyncCoordinator(authRepository: authRepository);
      try {
        await coordinator.beginIdentityTransition();
        throw StateError('controlled auth failure');
      } on StateError {
        // Expected: the caller's finally must balance the transition token.
      } finally {
        coordinator.endIdentityTransition();
      }

      await coordinator.run();
      expect(authRepository.pullCalls, 1);
    },
  );

  group('flushBeforeSignOut (V1-M5 bookmark safety)', () {
    Future<BookmarkService> createBookmarkService(String ownerId) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      return BookmarkService(prefs, owner: FixedRecordOwnerProvider(ownerId));
    }

    test(
      'cold-cache encrypted pending bookmark blocks the sign-out flush',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        const owner = FixedRecordOwnerProvider('cold-cache-owner');
        final writer = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        await writer.toggle(
          BookmarkEntry(
            surahId: 36,
            surahName: 'يس',
            ayahNumber: 1,
            ayahText: 'يس',
            savedAt: DateTime.utc(2026, 8, 25),
          ),
        );

        final coldService = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        final flushed = await CloudSyncCoordinator(
          authRepository: authRepository,
          memorizationCloudRepository: memorizationRepository,
          bookmarkService: coldService,
        ).flushBeforeSignOut();

        expect(flushed, isFalse);
        await coldService.migrateLegacyForCurrentOwner();
        expect(coldService.isBookmarked(36, 1), isTrue);
        expect(coldService.hasPendingCloudWork, isTrue);
      },
    );

    test('corrupt encrypted bookmark blob fails closed during flush', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final encrypted = _MemoryEncryptedAccountPreferencesStore();
      const owner = FixedRecordOwnerProvider('corrupt-owner');
      await encrypted.write(owner.currentOwnerId, 'quran_bookmarks', '{broken');
      final bookmarks = BookmarkService(
        prefs,
        owner: owner,
        encryptedAccountPreferences: encrypted,
      );

      final flushed = await CloudSyncCoordinator(
        authRepository: authRepository,
        memorizationCloudRepository: memorizationRepository,
        bookmarkService: bookmarks,
      ).flushBeforeSignOut();

      expect(flushed, isFalse);
      expect(await bookmarks.hasPendingCloudWorkDurably(), isTrue);
    });

    test(
      'an offline pending bookmark blocks the normal sign-out flush',
      () async {
        final bookmarks = await createBookmarkService('signout-user');
        // A locally-created bookmark is unsynced; cloud push cannot succeed
        // in this offline test environment.
        await bookmarks.toggle(
          BookmarkEntry(
            surahId: 2,
            surahName: 'البقرة',
            ayahNumber: 255,
            ayahText: 'آية',
            savedAt: DateTime.now(),
          ),
        );
        expect(bookmarks.hasPendingCloudWork, isTrue);

        final flushed = await CloudSyncCoordinator(
          authRepository: authRepository,
          memorizationCloudRepository: memorizationRepository,
          bookmarkService: bookmarks,
        ).flushBeforeSignOut();

        expect(
          flushed,
          isFalse,
          reason: 'sign-out must be blocked while a bookmark push failed',
        );
        // Durable state must remain recoverable for reconnect/re-login.
        expect(bookmarks.isBookmarked(2, 255), isTrue);
        expect(bookmarks.hasPendingCloudWork, isTrue);
      },
    );

    test(
      'the flush gate treats bookmarks as authoritative pending work',
      () async {
        final bookmarks = await createBookmarkService('signout-user-2');
        await bookmarks.toggle(
          BookmarkEntry(
            surahId: 18,
            surahName: 'الكهف',
            ayahNumber: 1,
            ayahText: 'آية',
            savedAt: DateTime.now(),
          ),
        );

        // Simulate a successful push by clearing the dirty flag through the
        // same code path the coordinator uses after pushing.
        await bookmarks.pushToCloud();
        // Push fails offline → still pending → flush must stay false.
        final flushed = await CloudSyncCoordinator(
          authRepository: authRepository,
          memorizationCloudRepository: memorizationRepository,
          bookmarkService: bookmarks,
        ).flushBeforeSignOut();

        expect(flushed, isFalse);
      },
    );

    test('a fully synced account flushes cleanly', () async {
      final flushed = await CloudSyncCoordinator(
        authRepository: authRepository,
        memorizationCloudRepository: memorizationRepository,
      ).flushBeforeSignOut();

      expect(flushed, isTrue);
    });
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

class _MemoryEncryptedAccountPreferencesStore
    implements EncryptedAccountPreferencesStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String ownerId, String key) async {
    _values.remove('$ownerId/$key');
  }

  @override
  Future<String?> read(String ownerId, String key) async =>
      _values['$ownerId/$key'];

  @override
  Future<void> write(String ownerId, String key, String value) async {
    _values['$ownerId/$key'] = value;
  }
}

class _MutableRecordOwnerProvider implements RecordOwnerProvider {
  _MutableRecordOwnerProvider(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}
