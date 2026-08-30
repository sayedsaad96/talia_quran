import 'dart:async';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/pending_bookmark_recovery_marker.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/security/encrypted_account_preferences_store.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import 'package:talia_quran/features/auth/application/cloud_sync_coordinator.dart';
import 'package:talia_quran/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/hifz/data/models/isar_ayah_progress.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/quran/data/datasources/bookmark_service.dart';
import 'package:talia_quran/features/quran/domain/entities/bookmark_entry.dart';
import 'package:talia_quran/features/streak/data/models/daily_activity_isar.dart';
import 'package:talia_quran/features/streak/data/models/streak_isar.dart';
import 'package:talia_quran/features/xp/data/models/xp_isar.dart';

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
  group('AuthRepositoryImpl offline auth behavior', () {
    late SharedPreferences prefs;
    late Isar isar;
    late Directory dir;
    late AuthRepositoryImpl repository;

    setUp(() async {
      await _initializeIsarCoreForTests();
      SharedPreferences.setMockInitialValues({
        'user_profile': '{"name":"Signed In User","age":null}',
        'read_pages': <String>['1', '2'],
        'bookmarks': 'local-bookmarks',
        'mem_plus_profile': '{"selectedPath":"adult"}',
        'theme_mode': 'dark',
        'locale': 'ar',
      });
      prefs = await SharedPreferences.getInstance();
      dir = await Directory.systemTemp.createTemp('talia_auth_repo_');
      isar = await Isar.open(
        [
          IsarAyahProgressSchema,
          IsarAyahReviewRecordSchema,
          IsarV2SessionSchema,
          StreakIsarSchema,
          XpIsarSchema,
          DailyActivityIsarSchema,
          CloudSyncQueueItemSchema,
        ],
        directory: dir.path,
        name: 'auth_repo_',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      repository = AuthRepositoryImpl(isar, AccountDataReset(isar, prefs));
    });

    test(
      'account reset removes the bookmark blob written by BookmarkService',
      () async {
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        const owner = FixedRecordOwnerProvider('reset-owner');
        final bookmarks = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        await bookmarks.toggle(
          BookmarkEntry(
            surahId: 18,
            surahName: 'الكهف',
            ayahNumber: 1,
            ayahText: 'الحمد لله',
            savedAt: DateTime.utc(2026, 8, 25),
          ),
        );

        await AccountDataReset(
          isar,
          prefs,
          encryptedAccountPreferences: encrypted,
          owner: owner,
        ).clearAccountOwnedData();

        final restored = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        await restored.migrateLegacyForCurrentOwner();
        expect(restored.getAll(), isEmpty);
      },
    );

    test(
      'clean reset removes canonical and previous encrypted bookmark keys',
      () async {
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        const ownerId = 'clean-reset-owner';
        await encrypted.write(ownerId, 'quran_bookmarks', '[]');
        await encrypted.write(ownerId, 'quran_bookmarks_owner_$ownerId', '[]');

        await AccountDataReset(
          isar,
          prefs,
          encryptedAccountPreferences: encrypted,
          owner: const FixedRecordOwnerProvider(ownerId),
        ).clearAccountOwnedData(departingOwnerId: ownerId);

        expect(await encrypted.read(ownerId, 'quran_bookmarks'), isNull);
        expect(
          await encrypted.read(ownerId, 'quran_bookmarks_owner_$ownerId'),
          isNull,
        );
      },
    );

    test(
      'forced A survives B login and restart then reconnects exactly once',
      () async {
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        final owner = _MutableRecordOwnerProvider('owner-a');
        final reset = AccountDataReset(
          isar,
          prefs,
          encryptedAccountPreferences: encrypted,
          owner: owner,
        );
        final authRepository = AuthRepositoryImpl(isar, reset, prefs);
        final queue = CloudSyncQueue(isar, owner);
        final bookmarksA = BookmarkService(
          prefs,
          owner: owner,
          cloudSyncQueue: queue,
          encryptedAccountPreferences: encrypted,
        );
        await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'owner-a');
        await bookmarksA.toggle(
          BookmarkEntry(
            surahId: 2,
            surahName: 'البقرة',
            ayahNumber: 255,
            ayahText: 'الله لا إله إلا هو',
            savedAt: DateTime.utc(2026, 8, 25),
          ),
        );
        final forceCubit = AuthCubit(
          authRepository,
          null,
          null,
          null,
          null,
          prefs,
          reset,
          CloudSyncCoordinator(
            authRepository: authRepository,
            cloudSyncQueue: queue,
            bookmarkService: bookmarksA,
          ),
        );
        addTearDown(() async {
          if (!forceCubit.isClosed) await forceCubit.close();
        });
        await forceCubit.signOut(force: true);

        owner.currentOwnerId = 'owner-b';
        await AuthCubit.resolveOwnerChange(
          prefs: prefs,
          userId: 'owner-b',
          onDepartingAccount: reset.clearAccountOwnedData,
          onDepartingOwner: (departingOwnerId) =>
              reset.clearAccountOwnedData(departingOwnerId: departingOwnerId),
        );
        final bookmarksB = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        expect(await bookmarksB.hasPendingCloudWorkDurably(), isFalse);

        // Process restart: close and reopen Isar, reconstruct services, then
        // relogin A against the same durable encrypted store.
        await forceCubit.close();
        await isar.close();
        isar = await Isar.open(
          [
            IsarAyahProgressSchema,
            IsarAyahReviewRecordSchema,
            IsarV2SessionSchema,
            StreakIsarSchema,
            XpIsarSchema,
            DailyActivityIsarSchema,
            CloudSyncQueueItemSchema,
          ],
          directory: dir.path,
          name: 'auth_repo_',
        );
        final restartedReset = AccountDataReset(
          isar,
          prefs,
          encryptedAccountPreferences: encrypted,
          owner: owner,
        );
        final restartedQueue = CloudSyncQueue(isar, owner);
        owner.currentOwnerId = 'owner-a';
        await AuthCubit.resolveOwnerChange(
          prefs: prefs,
          userId: 'owner-a',
          onDepartingAccount: restartedReset.clearAccountOwnedData,
          onDepartingOwner: (departingOwnerId) => restartedReset
              .clearAccountOwnedData(departingOwnerId: departingOwnerId),
        );
        final cloudRows = <String, Map<String, dynamic>>{};
        var upserts = 0;
        final restoredA = BookmarkService(
          prefs,
          owner: owner,
          cloudSyncQueue: restartedQueue,
          encryptedAccountPreferences: encrypted,
          cloudRpc: (String function, {Map<String, dynamic>? params}) async {
            if (function == 'pull_quran_bookmarks') {
              return cloudRows.values.toList();
            }
            upserts += 1;
            final row = <String, dynamic>{
              'surah_id': params!['p_surah_id'],
              'ayah_number': params['p_ayah_number'],
              'payload': params['p_payload'],
              'revision': params['p_revision'],
              'is_deleted': params['p_is_deleted'],
            };
            cloudRows['2_255'] = row;
            return [row];
          },
        );

        final reconnectCoordinator = CloudSyncCoordinator(
          authRepository: const _AuthenticatedSyncAuthRepository('owner-a'),
          cloudSyncQueue: restartedQueue,
          bookmarkService: restoredA,
        );
        await reconnectCoordinator.run();
        await reconnectCoordinator.run();

        expect(upserts, 1);
        expect(cloudRows, hasLength(1));
        expect(cloudRows['2_255']?['surah_id'], 2);
        expect(cloudRows['2_255']?['ayah_number'], 255);
        expect(cloudRows['2_255']?['is_deleted'], isFalse);
        expect(await restoredA.hasPendingCloudWorkDurably(), isFalse);
        expect(
          await isar.cloudSyncQueueItems
              .filter()
              .ownerUserIdEqualTo('owner-a')
              .count(),
          0,
        );

        // Convergence clears recovery protection; the next clean owner switch
        // can apply the normal privacy reset to A.
        owner.currentOwnerId = 'owner-b';
        await AuthCubit.resolveOwnerChange(
          prefs: prefs,
          userId: 'owner-b',
          onDepartingAccount: restartedReset.clearAccountOwnedData,
          onDepartingOwner: (departingOwnerId) => restartedReset
              .clearAccountOwnedData(departingOwnerId: departingOwnerId),
        );
        owner.currentOwnerId = 'owner-a';
        final afterCleanSwitch = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        expect(await afterCleanSwitch.hasPendingCloudWorkDurably(), isFalse);
        expect(afterCleanSwitch.getAll(), isEmpty);
      },
    );

    test(
      'forced sign-out preserves a failed bookmark push in owner storage',
      () async {
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        const owner = FixedRecordOwnerProvider('forced-sign-out-owner');
        final reset = AccountDataReset(
          isar,
          prefs,
          encryptedAccountPreferences: encrypted,
          owner: owner,
        );
        final authRepository = AuthRepositoryImpl(isar, reset, prefs);
        final bookmarks = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        await bookmarks.toggle(
          BookmarkEntry(
            surahId: 2,
            surahName: 'البقرة',
            ayahNumber: 255,
            ayahText: 'الله لا إله إلا هو',
            savedAt: DateTime.utc(2026, 8, 25),
          ),
        );
        final cubit = AuthCubit(
          authRepository,
          null,
          null,
          null,
          null,
          prefs,
          reset,
          CloudSyncCoordinator(
            authRepository: authRepository,
            bookmarkService: bookmarks,
          ),
        );
        addTearDown(cubit.close);

        await cubit.signOut(force: true);

        expect(bookmarks.isBookmarked(2, 255), isTrue);
        final restored = BookmarkService(
          prefs,
          owner: owner,
          encryptedAccountPreferences: encrypted,
        );
        await restored.migrateLegacyForCurrentOwner();
        expect(restored.isBookmarked(2, 255), isTrue);
        expect(restored.hasPendingCloudWork, isTrue);
      },
    );

    test(
      'signIn drains A before repository changes session then resets and syncs B',
      () async {
        final encrypted = _MemoryEncryptedAccountPreferencesStore();
        final owner = _MutableRecordOwnerProvider('owner-a');
        final reset = AccountDataReset(
          isar,
          prefs,
          encryptedAccountPreferences: encrypted,
          owner: owner,
        );
        await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'owner-a');
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
        final auth = _TransitionAuthRepository(
          onSignIn: () => owner.currentOwnerId = 'owner-b',
        );
        final coordinator = CloudSyncCoordinator(
          authRepository: auth,
          bookmarkService: bookmarks,
        );
        final cubit = AuthCubit(
          auth,
          null,
          null,
          null,
          null,
          prefs,
          reset,
          coordinator,
        );
        addTearDown(cubit.close);
        await pushStarted.future;

        final signIn = cubit.signIn(email: 'b@example.com', password: 'pass');
        await Future<void>.delayed(Duration.zero);
        expect(auth.signInCalls, 0);

        releasePush.complete();
        await signIn;
        await auth.bPullStarted.future;
        var ensureCompleted = false;
        final ensured = cubit.ensureCloudSyncComplete().then((_) {
          ensureCompleted = true;
        });
        await Future<void>.delayed(Duration.zero);
        expect(ensureCompleted, isFalse);
        auth.releaseBPull.complete();
        await ensured;

        expect(auth.currentUser?.id, 'owner-b');
        expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'owner-b');
        expect(auth.pullOwners, contains('owner-b'));
        expect(ownersAtPush, ['owner-a']);
      },
    );

    test(
      'signOut clears account-owned data when Supabase is not initialized',
      () async {
        final result = await repository.signOut();

        expect(result, const Right(unit));
        expect(prefs.getString('user_profile'), isNull);
        expect(prefs.getStringList('read_pages'), isNull);
        expect(prefs.getString('mem_plus_profile'), isNull);
        expect(prefs.getString('bookmarks'), 'local-bookmarks');
        expect(prefs.getString('theme_mode'), 'dark');
        expect(prefs.getString('locale'), 'ar');
      },
    );

    test(
      'deleteAccount fails safely offline without clearing local data',
      () async {
        final result = await repository.deleteAccount();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthConfigurationFailure>()),
          (_) =>
              fail('Expected deleteAccount to fail when Supabase is offline'),
        );
        expect(prefs.getString('user_profile'), isNotNull);
        expect(prefs.getStringList('read_pages'), <String>['1', '2']);
        expect(prefs.getString('bookmarks'), 'local-bookmarks');
        expect(prefs.getString('mem_plus_profile'), '{"selectedPath":"adult"}');
      },
    );

    test(
      'confirmed remote deletion remains success when guest bookmark copy fails',
      () async {
        final encrypted = _GuestWriteFailingEncryptedStore();
        await encrypted.write(
          'deleted-owner',
          'quran_bookmarks',
          '[{"revision":1,"isSynced":false}]',
        );
        encrypted.failGuestWrite = true;
        final afterRemoteDelete = AuthRepositoryImpl(
          isar,
          AccountDataReset(isar, prefs, encryptedAccountPreferences: encrypted),
          prefs,
        );

        final result = await afterRemoteDelete
            .finalizeDeletedAccountLocallyAfterRemoteDeletion('deleted-owner');

        expect(result, const Right(unit));
        expect(
          await encrypted.read('deleted-owner', 'quran_bookmarks'),
          '[{"revision":1,"isSynced":false}]',
        );
        expect(
          PendingBookmarkRecoveryMarker.contains(prefs, 'deleted-owner'),
          isTrue,
        );
      },
    );
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
  bool get isSignedIn => currentOwnerId != 'local';
}

class _TransitionAuthRepository implements AuthRepository {
  _TransitionAuthRepository({required this.onSignIn});

  final void Function() onSignIn;
  final _authChanges = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser = const AppUser(
    id: 'owner-a',
    email: 'a@example.com',
    displayName: 'A',
  );
  int signInCalls = 0;
  final List<String> pullOwners = [];
  final bPullStarted = Completer<void>();
  final releaseBPull = Completer<void>();

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _authChanges.stream;

  @override
  Stream<void> get passwordRecoveryChanges => const Stream.empty();

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    onSignIn();
    const user = AppUser(
      id: 'owner-b',
      email: 'b@example.com',
      displayName: 'B',
    );
    _currentUser = user;
    _authChanges.add(user);
    return const Right(user);
  }

  @override
  Future<Either<Failure, Unit>> pullProgressFromCloud() async {
    final ownerId = _currentUser?.id ?? 'none';
    pullOwners.add(ownerId);
    if (ownerId == 'owner-b') {
      if (!bPullStarted.isCompleted) bPullStarted.complete();
      await releaseBPull.future;
    }
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> syncProgressToCloud() async =>
      const Right(unit);

  @override
  Future<bool> hasPendingCloudPush() async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthenticatedSyncAuthRepository implements AuthRepository {
  const _AuthenticatedSyncAuthRepository(this.ownerId);

  final String ownerId;

  @override
  AppUser get currentUser => AppUser(
    id: ownerId,
    email: '$ownerId@example.com',
    displayName: ownerId,
  );

  @override
  Future<Either<Failure, Unit>> pullProgressFromCloud() async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> syncProgressToCloud() async =>
      const Right(unit);

  @override
  Future<bool> hasPendingCloudPush() async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GuestWriteFailingEncryptedStore
    implements EncryptedAccountPreferencesStore {
  final Map<String, String> _values = {};
  bool failGuestWrite = false;

  @override
  Future<void> delete(String ownerId, String key) async {
    _values.remove('$ownerId/$key');
  }

  @override
  Future<String?> read(String ownerId, String key) async =>
      _values['$ownerId/$key'];

  @override
  Future<void> write(String ownerId, String key, String value) async {
    if (failGuestWrite && ownerId == 'local') {
      throw Exception('guest secure write failed');
    }
    _values['$ownerId/$key'] = value;
  }
}
