import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../security/encrypted_account_preferences_store.dart';
import '../utils/talia_logger.dart';

part 'restore_journal_format.dart';

/// Why [RestoreRecoveryJournal.prepare] refused to start a restore.
enum RestoreJournalRejection {
  /// A previous journal still exists (unfinished recovery or cleanup).
  busy,

  /// The combined snapshots exceed the journal capacity.
  capacity,

  /// The protected store could not write or verify the snapshots.
  storage,
}

/// Thrown by prepare; nothing outside the journal has been modified.
class RestoreJournalRejected implements Exception {
  const RestoreJournalRejected(this.reason, [this.detail]);

  final RestoreJournalRejection reason;
  final String? detail;

  @override
  String toString() => 'RestoreJournalRejected(${reason.name})';
}

/// The data decision is final but journal keys could not be verified deleted.
/// Cleanup is retried by [RestoreRecoveryJournal.recoverBeforeReady].
class RestoreJournalCleanupPending implements Exception {
  const RestoreJournalCleanupPending();

  @override
  String toString() => 'RestoreJournalCleanupPending';
}

enum RestoreRecoveryStatus {
  /// Nothing to recover.
  clean,

  /// A restore that never reached `prepared` left only orphan keys.
  discarded,

  /// An unfinished restore was fully rolled back.
  rolledBack,

  /// A committed restore only needed its cleanup finished.
  completed,

  /// Recovery could not be proven safe. The app must not show or sync
  /// progress until a later recovery succeeds.
  blocked,
}

class RestoreRecoveryResult {
  const RestoreRecoveryResult(this.status, [this.reason]);

  final RestoreRecoveryStatus status;

  /// A short code, never account data.
  final String? reason;

  bool get isBlocked => status == RestoreRecoveryStatus.blocked;

  @override
  String toString() => 'RestoreRecoveryResult(${status.name}, $reason)';
}

/// Puts one store's part of a snapshot back. Must be idempotent.
typedef RestoreRollback =
    Future<void> Function(String ownerId, String snapshot);

/// The unfinished-restore handle returned by [RestoreRecoveryJournal.prepare].
class RestoreTicket {
  const RestoreTicket._(this.restoreId, this.ownerId, this._snapshots);

  final String restoreId;
  final String ownerId;
  final Map<String, String> _snapshots;
}

/// Durable write-ahead journal for multi-store restores.
///
/// Snapshots of every store a restore touches are chunked into the protected
/// account store, read back and verified, and only then published
/// (`intent` → chunks → immutable `manifest` → `state=prepared`). Stores are
/// written only after that. `state` moves to `committed` after every write
/// succeeded; at startup `prepared` rolls everything back and `committed`
/// only finishes cleanup. The destination owner stored here, not the active
/// account, is the authority for recovery.
///
/// All journal keys live under one reserved scope of the protected store.
class RestoreRecoveryJournal {
  RestoreRecoveryJournal(
    this._store, {
    this.maxChunkBytes = 16 * 1024,
    this.maxTotalBytes = 50 * 1024 * 1024,
    String Function()? newRestoreId,
  }) : _newRestoreId = newRestoreId ?? _randomId;

  final EncryptedAccountPreferencesStore _store;
  final int maxChunkBytes;
  final int maxTotalBytes;
  final String Function() _newRestoreId;

  static const _scope = 'restore-journal.v1';
  static const _intentKey = 'intent';
  static const _manifestKey = 'manifest';
  static const _stateKey = 'state';
  static final _partName = RegExp(r'^[A-Za-z0-9_]{1,32}$');

  static const _prepared = 'prepared';
  static const _committed = 'committed';
  static const _rolledBack = 'rolledBack';
  static const _aborted = 'aborted';
  static const _finalStates = {_committed, _rolledBack, _aborted};

  /// Read-only admission probe. Workers may serve progress only when every
  /// durable journal marker is absent. Malformed/final-but-uncleaned markers
  /// and unavailable protected storage all require exclusive recovery first.
  Future<bool> isCleanForAdmission() async {
    try {
      final intent = await _store.read(_scope, _intentKey);
      final manifest = await _store.read(_scope, _manifestKey);
      final state = await _store.read(_scope, _stateKey);
      return intent == null && manifest == null && state == null;
    } catch (_) {
      return false;
    }
  }

  // ─── prepare ──────────────────────────────────────────────────────────

  /// Stores [snapshots] (part name → payload) for [destinationOwner].
  ///
  /// Throws [RestoreJournalRejected] without having modified anything outside
  /// the journal; the journal's own keys are removed again.
  Future<RestoreTicket> prepare({
    required String destinationOwner,
    required Map<String, String> snapshots,
  }) async {
    if (destinationOwner.isEmpty ||
        snapshots.isEmpty ||
        !snapshots.keys.every(_partName.hasMatch)) {
      throw const RestoreJournalRejected(
        RestoreJournalRejection.storage,
        'invalid journal input',
      );
    }
    final encoded = {
      for (final entry in snapshots.entries)
        entry.key: utf8.encode(entry.value),
    };
    final total = encoded.values.fold<int>(0, (sum, b) => sum + b.length);
    if (total > maxTotalBytes) {
      throw RestoreJournalRejected(
        RestoreJournalRejection.capacity,
        '$total > $maxTotalBytes',
      );
    }
    await _requireNoJournal();

    final restoreId = _newRestoreId();
    final chunks = {
      for (final entry in encoded.entries) entry.key: _split(entry.value),
    };
    try {
      await _store.write(
        _scope,
        _intentKey,
        jsonEncode({
          'id': restoreId,
          'parts': {
            for (final entry in chunks.entries) entry.key: entry.value.length,
          },
        }),
      );
      for (final entry in chunks.entries) {
        for (var i = 0; i < entry.value.length; i++) {
          await _store.write(
            _scope,
            _chunkKey(restoreId, entry.key, i),
            entry.value[i],
          );
        }
      }
      await _verifyChunks(restoreId, chunks);
      final manifest = jsonEncode({
        'v': 1,
        'id': restoreId,
        'owner': destinationOwner,
        'parts': [
          for (final entry in encoded.entries)
            {
              'name': entry.key,
              'chunks': chunks[entry.key]!.length,
              'bytes': entry.value.length,
              'sha256': sha256.convert(entry.value).toString(),
            },
        ],
      });
      await _writeVerified(_manifestKey, manifest);
      await _writeVerified(_stateKey, _stateValue(restoreId, _prepared));
    } on Exception catch (error) {
      TaliaLogger.w('Restore journal prepare failed: ${error.runtimeType}');
      await _bestEffortCleanup(restoreId, {
        for (final entry in chunks.entries) entry.key: entry.value.length,
      });
      throw const RestoreJournalRejected(RestoreJournalRejection.storage);
    }
    return RestoreTicket._(restoreId, destinationOwner, Map.of(snapshots));
  }

  Future<void> _requireNoJournal() async {
    try {
      for (final key in const [_stateKey, _manifestKey, _intentKey]) {
        if (await _store.read(_scope, key) != null) {
          throw const RestoreJournalRejected(RestoreJournalRejection.busy);
        }
      }
    } on RestoreJournalRejected {
      rethrow;
    } on Exception {
      throw const RestoreJournalRejected(RestoreJournalRejection.storage);
    }
  }

  Future<void> _verifyChunks(
    String restoreId,
    Map<String, List<String>> chunks,
  ) async {
    for (final entry in chunks.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        final stored = await _store.read(
          _scope,
          _chunkKey(restoreId, entry.key, i),
        );
        if (stored != entry.value[i]) {
          throw const _JournalStoreException();
        }
      }
    }
  }

  Future<void> _writeVerified(String key, String value) async {
    await _store.write(_scope, key, value);
    if (await _store.read(_scope, key) != value) {
      throw const _JournalStoreException();
    }
  }

  // ─── transitions ──────────────────────────────────────────────────────

  /// Publishes that every store write succeeded. Throws if it cannot be
  /// verified. An uncertain acknowledgement MUST NOT trigger rollback: startup
  /// recovery must resolve the persisted prepared/committed decision first.
  Future<void> markCommitted(RestoreTicket ticket) =>
      _writeVerified(_stateKey, _stateValue(ticket.restoreId, _committed));

  /// Rolls every part back from the in-memory snapshots, then cleans up.
  /// Throws if a rollback fails; the journal stays `prepared` so the next
  /// startup retries it.
  Future<void> rollback(
    RestoreTicket ticket,
    Map<String, RestoreRollback> rollbacks,
  ) async {
    final state = _parseState(await _store.read(_scope, _stateKey) ?? '');
    if (state == null ||
        state.id != ticket.restoreId ||
        state.state != _prepared) {
      throw StateError('Rollback requires a verified prepared decision');
    }
    for (final entry in ticket._snapshots.entries) {
      final rollback = rollbacks[entry.key];
      if (rollback == null) {
        throw StateError('No rollback registered for ${entry.key}');
      }
      await rollback(ticket.ownerId, entry.value);
    }
    await _writeVerified(_stateKey, _stateValue(ticket.restoreId, _rolledBack));
    await complete(ticket);
  }

  /// Deletes the journal after the data decision is final. Throws
  /// [RestoreJournalCleanupPending] when deletion cannot be verified.
  Future<void> complete(RestoreTicket ticket) => _cleanup(ticket.restoreId, {
    for (final entry in ticket._snapshots.entries)
      entry.key: _split(utf8.encode(entry.value)).length,
  });

  /// Whether any journal key exists. Read-only: a background isolate uses it
  /// to stay away from stores while the foreground may be mid-restore, since
  /// only the foreground startup may recover.
  Future<bool> hasUnfinished() async {
    for (final key in const [_stateKey, _manifestKey, _intentKey]) {
      if (await _store.read(_scope, key) != null) return true;
    }
    return false;
  }

  // ─── startup recovery ─────────────────────────────────────────────────

  /// Resolves any unfinished restore before the app shows or syncs progress.
  /// Never throws for an unprovable state: it returns
  /// [RestoreRecoveryStatus.blocked] instead.
  Future<RestoreRecoveryResult> recoverBeforeReady({
    required String activeOwnerId,
    required Map<String, RestoreRollback> rollbacks,
  }) async {
    try {
      return await _recover(activeOwnerId, rollbacks);
    } on Exception catch (error) {
      TaliaLogger.w('Restore recovery blocked: ${error.runtimeType}');
      return const RestoreRecoveryResult(
        RestoreRecoveryStatus.blocked,
        'recovery_failed',
      );
    }
  }

  Future<RestoreRecoveryResult> _recover(
    String activeOwnerId,
    Map<String, RestoreRollback> rollbacks,
  ) async {
    final stateRaw = await _store.read(_scope, _stateKey);
    final manifestRaw = await _store.read(_scope, _manifestKey);
    final intentRaw = await _store.read(_scope, _intentKey);
    if (stateRaw == null) {
      if (manifestRaw == null && intentRaw == null) {
        return const RestoreRecoveryResult(RestoreRecoveryStatus.clean);
      }
      // Never reached `prepared`: no store was written yet.
      await _cleanupOrphan(intentRaw);
      return const RestoreRecoveryResult(RestoreRecoveryStatus.discarded);
    }

    final state = _parseState(stateRaw);
    final manifest = manifestRaw == null ? null : _parseManifest(manifestRaw);
    if (state == null || manifest == null || manifest.id != state.id) {
      return const RestoreRecoveryResult(
        RestoreRecoveryStatus.blocked,
        'journal_unreadable',
      );
    }

    if (state.state == _prepared) {
      final blocked = await _rollbackPrepared(
        manifest,
        activeOwnerId,
        rollbacks,
      );
      if (blocked != null) return blocked;
      await _writeVerified(_stateKey, _stateValue(manifest.id, _rolledBack));
      return _finishCleanup(
        manifest,
        const RestoreRecoveryResult(RestoreRecoveryStatus.rolledBack),
      );
    }
    if (!_finalStates.contains(state.state)) {
      return const RestoreRecoveryResult(
        RestoreRecoveryStatus.blocked,
        'journal_unreadable',
      );
    }
    return _finishCleanup(
      manifest,
      RestoreRecoveryResult(switch (state.state) {
        _committed => RestoreRecoveryStatus.completed,
        _rolledBack => RestoreRecoveryStatus.rolledBack,
        _ => RestoreRecoveryStatus.discarded,
      }),
    );
  }

  Future<RestoreRecoveryResult?> _rollbackPrepared(
    _Manifest manifest,
    String activeOwnerId,
    Map<String, RestoreRollback> rollbacks,
  ) async {
    if (manifest.owner != activeOwnerId) {
      // Putting A's unscoped stores back into B's session would hand A's data
      // to B; stay blocked rather than guess.
      return const RestoreRecoveryResult(
        RestoreRecoveryStatus.blocked,
        'owner_mismatch',
      );
    }
    if (!manifest.parts.every((part) => rollbacks.containsKey(part.name))) {
      return const RestoreRecoveryResult(
        RestoreRecoveryStatus.blocked,
        'unknown_part',
      );
    }
    final payloads = <String, String>{};
    for (final part in manifest.parts) {
      final payload = await _readPart(manifest.id, part);
      if (payload == null) {
        return const RestoreRecoveryResult(
          RestoreRecoveryStatus.blocked,
          'snapshot_unverified',
        );
      }
      payloads[part.name] = payload;
    }
    for (final part in manifest.parts) {
      await rollbacks[part.name]!(manifest.owner, payloads[part.name]!);
    }
    return null;
  }

  Future<String?> _readPart(String restoreId, _PartInfo part) async {
    final bytes = BytesBuilder(copy: false);
    for (var i = 0; i < part.chunks; i++) {
      final chunk = await _store.read(
        _scope,
        _chunkKey(restoreId, part.name, i),
      );
      if (chunk == null) return null;
      bytes.add(utf8.encode(chunk));
    }
    final all = bytes.takeBytes();
    if (all.length != part.bytes ||
        sha256.convert(all).toString() != part.sha256) {
      return null;
    }
    return utf8.decode(all);
  }

  Future<RestoreRecoveryResult> _finishCleanup(
    _Manifest manifest,
    RestoreRecoveryResult success,
  ) async {
    try {
      await _cleanup(manifest.id, {
        for (final part in manifest.parts) part.name: part.chunks,
      });
      return success;
    } on RestoreJournalCleanupPending {
      // The data decision is final and safe; only deletion is outstanding.
      return success;
    }
  }

  Future<void> _cleanupOrphan(String? intentRaw) async {
    final intent = intentRaw == null ? null : _parseIntent(intentRaw);
    try {
      await _cleanup(intent?.id ?? '', intent?.parts ?? const {});
    } on RestoreJournalCleanupPending {
      // Orphans hold no authority; the next startup retries.
    }
  }

  // ─── account deletion ─────────────────────────────────────────────────

  /// Records a durable cancel decision for [ownerId]'s unfinished restore and
  /// removes the journal. A deleted account is never recreated from it.
  /// Another owner's journal is left untouched.
  Future<void> abortForOwner(String ownerId) async {
    final stateRaw = await _store.read(_scope, _stateKey);
    final manifestRaw = await _store.read(_scope, _manifestKey);
    final state = stateRaw == null ? null : _parseState(stateRaw);
    final manifest = manifestRaw == null ? null : _parseManifest(manifestRaw);
    if (state == null || manifest == null || manifest.owner != ownerId) return;
    if (state.state == _prepared) {
      await _writeVerified(_stateKey, _stateValue(manifest.id, _aborted));
    }
    await _cleanup(manifest.id, {
      for (final part in manifest.parts) part.name: part.chunks,
    });
  }

  // ─── cleanup ──────────────────────────────────────────────────────────

  Future<void> _cleanup(String restoreId, Map<String, int> parts) async {
    try {
      for (final entry in parts.entries) {
        for (var i = 0; i < entry.value; i++) {
          await _deleteVerified(_chunkKey(restoreId, entry.key, i));
        }
      }
      // All data chunks are gone. Removing state first leaves an orphan whose
      // intent still describes cleanup; never leave a state without a manifest.
      await _deleteVerified(_stateKey);
      await _deleteVerified(_manifestKey);
      await _deleteVerified(_intentKey);
    } on Exception {
      throw const RestoreJournalCleanupPending();
    }
  }

  Future<void> _deleteVerified(String key) async {
    await _store.delete(_scope, key);
    if (await _store.read(_scope, key) != null) {
      throw const _JournalStoreException();
    }
  }

  Future<void> _bestEffortCleanup(
    String restoreId,
    Map<String, int> parts,
  ) async {
    try {
      await _cleanup(restoreId, parts);
    } on Exception {
      // Orphans are removed by the next startup recovery.
    }
  }

  static String _randomId() {
    final random = Random.secure();
    return [
      for (var i = 0; i < 16; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }
}
