import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/quran/data/datasources/bookmark_service.dart';
import '../../features/quran/data/datasources/quran_local_datasource.dart';
import '../../features/quran/data/repositories/reading_checkpoint_repository_impl.dart';
import '../../features/quran/data/services/quran_corpus_bookmark_resolver.dart';
import '../../features/quran/domain/repositories/reading_checkpoint_repository.dart';
import '../experience/experience_feature_flags.dart';
import '../identity/account_data_barrier.dart';
import '../identity/guest_store_ownership.dart';
import '../identity/record_owner_provider.dart';
import '../security/encrypted_account_preferences_store.dart';
import '../security/parent_pin_secure_store.dart';
import '../services/app_session_service.dart';
import '../storage/app_isar.dart';
import '../storage/data_admission.dart';
import 'backup_file_format.dart';
import 'backup_restorer.dart';
import 'portable_reading_backup_adapter.dart';
import 'portable_reading_data.dart';
import 'restore_operation_gate.dart';
import 'restore_parent_pin_guard.dart';
import 'restore_recovery_journal.dart';
import 'restore_request_store.dart';
import 'restore_store_rollbacks.dart';

/// Private guest graph: no auth client, DI container or progress subscriptions.
class RestoreMaintenanceSession {
  RestoreMaintenanceSession._({
    required this.permit,
    required this.prefs,
    required this.journal,
    required this.pin,
  });
  final DataAdmissionPermit permit;
  final SharedPreferences prefs;
  final RestoreRecoveryJournal journal;
  final RestoreParentPinGuard pin;
  Isar? _isar;
  BackupRestorer? _restorer;
  bool _pinVerified = false;
  bool _closed = false;
  bool _operationInProgress = false;
  RestoreRequestStore get requests => RestoreRequestStore(prefs);
  Future<bool> get canReplace async =>
      !_closed && _restorer != null && await _destinationIsSafe();

  static Future<RestoreMaintenanceSession> open(
    DataAdmissionPermit permit, {
    SharedPreferences? preferences,
    EncryptedAccountPreferencesStore? secureStore,
    String? directory,
    RestoreParentPinGuard? pinGuard,
    QuranLocalDatasource? corpus,
  }) async {
    if (permit.mode != DataAdmissionMode.maintenance ||
        !await permit.validate()) {
      throw StateError('Exclusive startup admission required');
    }
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final secure = secureStore ?? FlutterEncryptedAccountPreferencesStore();
    final session = RestoreMaintenanceSession._(
      permit: permit,
      prefs: prefs,
      journal: RestoreRecoveryJournal(secure),
      pin:
          pinGuard ??
          RestoreParentPinGuard(
            prefs: prefs,
            pinStore: FlutterParentPinSecureStore(),
          ),
    );
    // A signed-in/ambiguous destination may cancel a request, but no data
    // database is opened and no recovery writes are attempted for it.
    if (!await GuestStoreOwnership(prefs).canRestoreGuest()) return session;
    try {
      await session._openGuestGraph(secure, directory, corpus);
      return session;
    } catch (_) {
      await session._isar?.close();
      rethrow;
    }
  }

  Future<void> _openGuestGraph(
    EncryptedAccountPreferencesStore secure,
    String? directory,
    QuranLocalDatasource? corpus,
  ) async {
    const owner = FixedRecordOwnerProvider('local');
    final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    final isar = await openAppIsar(
      directory: directory ?? (await getApplicationDocumentsDirectory()).path,
      admission: permit,
    );
    _isar = isar;
    final reading = PortableReadingBackupAdapter(
      bookmarks: BookmarkService(
        prefs,
        owner: owner,
        encryptedAccountPreferences: secure,
      ),
      session: _checkpointSession(secure, barrier),
      resolve: QuranCorpusBookmarkResolver(
        corpus ?? QuranLocalDatasourceImpl(),
      ).call,
    );
    await _recover(isar, reading);
    _restorer = BackupRestorer(
      isar,
      prefs,
      owner,
      reading: reading,
      journal: journal,
      gate: RestoreOperationGate(owner),
      maintenancePermit: permit,
      destinationIsSafe: _destinationIsSafe,
    );
  }

  AppSessionService _checkpointSession(
    EncryptedAccountPreferencesStore secure,
    AccountDataBarrier barrier,
  ) {
    const owner = FixedRecordOwnerProvider('local');
    final checkpoints = ReadingCheckpointRepositoryImpl(
      prefs: prefs,
      owner: owner,
      barrier: barrier,
      secureStore: secure,
      remote: const _NoMaintenanceNetwork(),
    );
    return AppSessionService(
      prefs,
      owner: owner,
      checkpointPreferenceKeys: (_) => const [
        ReadingCheckpointRepositoryImpl.guestStorageKey,
      ],
      checkpointReader: (id, lease) async {
        final value = await checkpoints.readUnderLease(
          expectedOwnerId: id,
          lease: lease,
        );
        return value == null
            ? null
            : QuranReadingCheckpoint(pageNumber: value.pageNumber);
      },
      checkpointWriter: (id, page, lease) => checkpoints.writeUnderLease(
        expectedOwnerId: id,
        pageNumber: page,
        lease: lease,
      ),
    );
  }

  Future<void> _recover(Isar isar, PortableReadingBackupAdapter reading) async {
    if (!await permit.validate() ||
        !await GuestStoreOwnership(prefs).canRestoreGuest()) {
      throw StateError('Guest destination changed');
    }
    final result = await journal.recoverBeforeReady(
      activeOwnerId: 'local',
      rollbacks: RestoreStoreRollbacks(isar, prefs, reading).registry,
    );
    if (result.isBlocked) throw StateError('Startup recovery blocked');
  }

  Future<bool> _destinationIsSafe() async =>
      !_closed &&
      await permit.validate() &&
      await GuestStoreOwnership(prefs).canRestoreGuest() &&
      ExperienceFlags.fromPreferences(
        prefs,
      ).isEnabled(ExperienceFeature.recoverableBackupRestore);

  Future<bool> verifyPin(String value) async {
    if (_closed || _operationInProgress) return false;
    _pinVerified = await pin.verify(value);
    return _pinVerified;
  }

  Future<BackupRestoreResult> restore(
    String requestId,
    BackupPayload payload,
  ) async {
    if (_operationInProgress || _closed) {
      return BackupRestoreResult.protectionUnavailable;
    }
    _operationInProgress = true;
    final verified = _pinVerified;
    _pinVerified = false;
    try {
      if (!await canReplace ||
          (await pin.requiresPin() && !verified) ||
          !await requests.consume(requestId)) {
        return BackupRestoreResult.protectionUnavailable;
      }
      // Consumption is durable before preparing/writing any restore state.
      return await _restorer!.restore(payload);
    } finally {
      _operationInProgress = false;
    }
  }

  /// Caller keeps the exclusive permit until this future has completed.
  Future<void> closeForNormalStartup() async {
    if (_operationInProgress || _closed) throw StateError('Maintenance busy');
    _operationInProgress = true;
    try {
      if (!await permit.validate() || !await journal.isCleanForAdmission()) {
        throw StateError('Recovery must finish before normal startup');
      }
      await requests.clearForCancellation();
      await _isar?.close();
      _closed = true;
    } finally {
      _operationInProgress = false;
    }
  }
}

class _NoMaintenanceNetwork implements ReadingCheckpointRemote {
  const _NoMaintenanceNetwork();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('No network in maintenance');
}
