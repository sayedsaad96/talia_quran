import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/account_deletion_marker.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/identity/pending_checkpoint_recovery_marker.dart';
import '../../../../core/security/encrypted_account_preferences_store.dart';
import '../../../../core/services/app_session_service.dart';
import '../../domain/repositories/reading_checkpoint_repository.dart';

/// Uses the account barrier to serialize local writes across instances. Network
/// requests happen outside the barrier; only a matching mutation is acked.
class ReadingCheckpointRepositoryImpl implements ReadingCheckpointRepository {
  ReadingCheckpointRepositoryImpl({
    required this.prefs,
    required this.owner,
    required this.barrier,
    required this.secureStore,
    required this.remote,
  });
  final SharedPreferences prefs;
  final RecordOwnerProvider owner;
  final AccountDataBarrier barrier;
  final EncryptedAccountPreferencesStore secureStore;
  final ReadingCheckpointRemote remote;
  static const _key = 'reading_checkpoint_v1';
  static const guestStorageKey = '${_key}_guest';

  void _check(String id, AccountDataLease lease) {
    barrier.checkLease(lease);
    lease.checkOwner(id);
    if (AccountDeletionMarker.isOwnerBlocked(prefs, id)) {
      throw const AccountDataUnavailableException();
    }
  }

  Future<LocalReadingCheckpoint?> _read(
    String id,
    AccountDataLease lease,
  ) async {
    _check(id, lease);
    final raw = owner.isSignedIn
        ? await secureStore.read(id, _key)
        : prefs.getString('${_key}_guest');
    _check(id, lease);
    if (raw == null) {
      final legacyPage = prefs.get(AppSessionService.quranCheckpointKeyFor(id));
      if (legacyPage == null) return null;
      if (legacyPage is! int || legacyPage < 1 || legacyPage > 604) {
        throw const FormatException('Invalid owner-scoped legacy checkpoint');
      }
      final migrated = LocalReadingCheckpoint(
        pageNumber: legacyPage,
        serverRevision: 0,
        pendingMutationId: owner.isSignedIn ? const Uuid().v4() : null,
      );
      await _write(id, lease, migrated);
      return migrated;
    }
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['empty'] == true && map.length == 1) return null;
    final page = map['page'] as int;
    final revision = map['revision'] as int;
    final pending = map['pending'] as String?;
    if (page < 1 ||
        page > 604 ||
        revision < 0 ||
        (pending != null && pending.isEmpty)) {
      throw const FormatException('Invalid checkpoint');
    }
    if (owner.isSignedIn && pending != null) {
      await PendingCheckpointRecoveryMarker.mark(prefs, id);
      _check(id, lease);
    }
    return LocalReadingCheckpoint(
      pageNumber: page,
      serverRevision: revision,
      pendingMutationId: pending,
    );
  }

  Future<void> _write(
    String id,
    AccountDataLease lease,
    LocalReadingCheckpoint value,
  ) async {
    _check(id, lease);
    final raw = jsonEncode({
      'page': value.pageNumber,
      'revision': value.serverRevision,
      'pending': value.pendingMutationId,
    });
    if (owner.isSignedIn) {
      if (value.pendingMutationId != null) {
        await PendingCheckpointRecoveryMarker.mark(prefs, id);
        _check(id, lease);
      }
      await secureStore.write(id, _key, raw);
      _check(id, lease);
      if (value.pendingMutationId == null) {
        await PendingCheckpointRecoveryMarker.clear(prefs, id);
      }
    } else if (!await prefs.setString('${_key}_guest', raw)) {
      throw StateError('Checkpoint write failed');
    }
    _check(id, lease);
    if (!await prefs.setInt(
      AppSessionService.quranCheckpointKeyFor(id),
      value.pageNumber,
    )) {
      throw StateError('Checkpoint cache write failed');
    }
    _check(id, lease);
  }

  @override
  Future<LocalReadingCheckpoint?> readLocal({
    required String expectedOwnerId,
  }) => barrier.run((lease) => _read(expectedOwnerId, lease));

  /// Call only inside an operation already holding this repository's barrier.
  Future<LocalReadingCheckpoint?> readUnderLease({
    required String expectedOwnerId,
    required AccountDataLease lease,
  }) => _read(expectedOwnerId, lease);

  /// Rollback restores the entire old value, including pending mutation and
  /// revision. An explicit empty record avoids best-effort secure deletion.
  Future<void> restoreUnderLease({
    required String expectedOwnerId,
    required LocalReadingCheckpoint? snapshot,
    required AccountDataLease lease,
  }) async {
    _check(expectedOwnerId, lease);
    if (snapshot != null) {
      await _write(expectedOwnerId, lease, snapshot);
    } else if (owner.isSignedIn) {
      await secureStore.write(expectedOwnerId, _key, '{"empty":true}');
      await PendingCheckpointRecoveryMarker.clear(prefs, expectedOwnerId);
    } else if (!await prefs.setString('${_key}_guest', '{"empty":true}')) {
      throw StateError('Checkpoint rollback failed');
    }
    final restored = await _read(expectedOwnerId, lease);
    if (snapshot == null) {
      if (!await prefs.remove(
        AppSessionService.quranCheckpointKeyFor(expectedOwnerId),
      )) {
        throw StateError('Checkpoint rollback cache could not be cleared');
      }
      _check(expectedOwnerId, lease);
    }
    if (restored?.pageNumber != snapshot?.pageNumber ||
        restored?.serverRevision != snapshot?.serverRevision ||
        restored?.pendingMutationId != snapshot?.pendingMutationId) {
      throw StateError('Checkpoint rollback verification failed');
    }
  }

  /// Imported positions are new edits, never cloud acknowledgements.
  Future<void> writeUnderLease({
    required String expectedOwnerId,
    required int pageNumber,
    required AccountDataLease lease,
  }) async {
    if (pageNumber < 1 || pageNumber > 604) {
      throw RangeError.range(pageNumber, 1, 604);
    }
    final old = await _read(expectedOwnerId, lease);
    await _write(
      expectedOwnerId,
      lease,
      LocalReadingCheckpoint(
        pageNumber: pageNumber,
        serverRevision: old?.serverRevision ?? 0,
        pendingMutationId: owner.isSignedIn ? const Uuid().v4() : null,
      ),
    );
  }

  @override
  Future<void> saveLocal({
    required String expectedOwnerId,
    required int pageNumber,
  }) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw RangeError.range(pageNumber, 1, 604);
    }
    return barrier.run(
      (lease) => writeUnderLease(
        expectedOwnerId: expectedOwnerId,
        pageNumber: pageNumber,
        lease: lease,
      ),
    );
  }

  @override
  Future<CheckpointSyncResult> sync({required String expectedOwnerId}) async {
    try {
      final lease = barrier.capture();
      _check(expectedOwnerId, lease);
      if (!owner.isSignedIn) {
        return const CheckpointSyncResult(CheckpointSyncStatus.unavailable);
      }
      final local = await barrier.run(
        (l) => _read(expectedOwnerId, l),
        authority: lease,
      );
      if (local?.pendingMutationId == null) {
        return await _pullCheckpoint(expectedOwnerId, lease);
      }
      CheckpointRemoteResult result;
      try {
        result = await remote.put(
          expectedOwnerId: expectedOwnerId,
          pageNumber: local!.pageNumber,
          expectedRevision: local.serverRevision,
          mutationId: local.pendingMutationId!,
        );
      } catch (_) {
        _check(expectedOwnerId, lease);
        final latest = await barrier.run(
          (l) => _read(expectedOwnerId, l),
          authority: lease,
        );
        return CheckpointSyncResult(
          CheckpointSyncStatus.pending,
          local: latest,
        );
      }
      _check(expectedOwnerId, lease);
      RemoteCheckpoint? current;
      if (result.accepted) {
        try {
          current = await remote.get(expectedOwnerId: expectedOwnerId);
          _check(expectedOwnerId, lease);
        } catch (_) {
          _check(expectedOwnerId, lease);
        }
      }
      return await barrier.run(
        (l) =>
            _applyAcknowledgement(expectedOwnerId, l, local, result, current),
        authority: lease,
      );
    } catch (_) {
      return const CheckpointSyncResult(CheckpointSyncStatus.unavailable);
    }
  }

  Future<CheckpointSyncResult> _pullCheckpoint(
    String ownerId,
    AccountDataLease lease,
  ) async {
    final server = await remote.get(expectedOwnerId: ownerId);
    _check(ownerId, lease);
    return barrier.run((l) async {
      final latest = await _read(ownerId, l);
      if (latest?.pendingMutationId != null) {
        return CheckpointSyncResult(
          CheckpointSyncStatus.pending,
          local: latest,
          remote: server,
        );
      }
      if (server == null && latest != null) {
        return CheckpointSyncResult(
          CheckpointSyncStatus.unavailable,
          local: latest,
        );
      }
      if (server != null &&
          (latest == null || server.revision >= latest.serverRevision)) {
        await _write(
          ownerId,
          l,
          LocalReadingCheckpoint(
            pageNumber: server.pageNumber,
            serverRevision: server.revision,
          ),
        );
      }
      return CheckpointSyncResult(
        CheckpointSyncStatus.synced,
        local: await _read(ownerId, l),
        remote: server,
      );
    }, authority: lease);
  }

  Future<CheckpointSyncResult> _applyAcknowledgement(
    String expectedOwnerId,
    AccountDataLease l,
    LocalReadingCheckpoint local,
    CheckpointRemoteResult result,
    RemoteCheckpoint? current,
  ) async {
    final latest = await _read(expectedOwnerId, l);
    if (latest == null || (!result.accepted && result.checkpoint == null)) {
      return CheckpointSyncResult(
        CheckpointSyncStatus.unavailable,
        local: latest,
      );
    }
    if (!result.accepted) {
      return CheckpointSyncResult(
        CheckpointSyncStatus.conflict,
        local: latest,
        remote: result.checkpoint,
      );
    }
    final acknowledged = result.checkpoint;
    if (acknowledged == null) {
      throw const FormatException('Missing checkpoint acknowledgement');
    }
    if (current == null || current.revision < acknowledged.revision) {
      return CheckpointSyncResult(CheckpointSyncStatus.pending, local: latest);
    }
    if (current.revision < latest.serverRevision) {
      return CheckpointSyncResult(
        latest.pendingMutationId == null
            ? CheckpointSyncStatus.synced
            : CheckpointSyncStatus.pending,
        local: latest,
        remote: acknowledged,
      );
    }
    final same =
        latest.pendingMutationId == local.pendingMutationId ||
        latest.pendingMutationId == null;
    final updated = LocalReadingCheckpoint(
      pageNumber: same ? current.pageNumber : latest.pageNumber,
      serverRevision: same
          ? current.revision
          : (latest.serverRevision > acknowledged.revision
                ? latest.serverRevision
                : acknowledged.revision),
      pendingMutationId: same ? null : latest.pendingMutationId,
    );
    await _write(expectedOwnerId, l, updated);
    return CheckpointSyncResult(
      same ? CheckpointSyncStatus.synced : CheckpointSyncStatus.pending,
      local: updated,
      remote: current,
    );
  }

  @override
  Future<void> resolveConflict({
    required String expectedOwnerId,
    required String expectedMutationId,
    required int expectedLocalPage,
    required RemoteCheckpoint seenRemote,
    required bool useLocal,
  }) async {
    final lease = barrier.capture();
    final local = await barrier.run(
      (l) => _read(expectedOwnerId, l),
      authority: lease,
    );
    if (local == null ||
        local.pendingMutationId != expectedMutationId ||
        local.pageNumber != expectedLocalPage) {
      throw StateError('No pending checkpoint');
    }
    final current = await remote.get(expectedOwnerId: expectedOwnerId);
    _check(expectedOwnerId, lease);
    if (current == null ||
        current.revision != seenRemote.revision ||
        current.pageNumber != seenRemote.pageNumber) {
      throw StateError('Checkpoint conflict changed');
    }
    await barrier.run((l) async {
      final latest = await _read(expectedOwnerId, l);
      if (latest?.pendingMutationId != expectedMutationId ||
          latest?.pageNumber != expectedLocalPage) {
        throw StateError('Local checkpoint changed');
      }
      await _write(
        expectedOwnerId,
        l,
        LocalReadingCheckpoint(
          pageNumber: useLocal ? local.pageNumber : seenRemote.pageNumber,
          serverRevision: seenRemote.revision,
          pendingMutationId: useLocal ? const Uuid().v4() : null,
        ),
      );
    }, authority: lease);
  }
}
