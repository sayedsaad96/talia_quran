import 'dart:async';

import '../identity/record_owner_provider.dart';

/// The destination account is no longer the active one.
class RestoreOwnerChangedException implements Exception {
  const RestoreOwnerChangedException();

  @override
  String toString() => 'RestoreOwnerChangedException';
}

/// A previous restore could not be recovered; no new restore may start.
class RestoreBlockedException implements Exception {
  const RestoreBlockedException(this.reason);

  final String reason;

  @override
  String toString() => 'RestoreBlockedException($reason)';
}

/// An operation tried to enter the gate it is already running inside.
class RestoreGateReentryException implements Exception {
  const RestoreGateReentryException();

  @override
  String toString() => 'RestoreGateReentryException';
}

/// Process-wide admission for multi-store restores.
///
/// Lock order is fixed and documented here because the stores below it do not
/// know about each other:
///
/// 1. this gate (one restore at a time, owner pinned);
/// 2. the account barrier (`AccountDataBarrier.run`), which serializes resets
///    and every barrier-aware writer;
/// 3. per-store queues (for example a bookmark owner queue).
///
/// An operation must never call back into the gate; that is detected and
/// rejected instead of deadlocking.
class RestoreOperationGate {
  RestoreOperationGate(this._owner);

  final RecordOwnerProvider _owner;
  final Object _zoneKey = Object();
  Future<void> _tail = Future.value();
  int _active = 0;
  String? _blockedReason;

  /// True while a restore operation holds the gate. Writers that are not
  /// serialized by the barrier use this to defer their work.
  bool get isRunning => _active > 0;

  bool get isBlocked => _blockedReason != null;

  /// Set by startup recovery when it could not prove the stores safe.
  void blockUntilRecovered(String reason) => _blockedReason = reason;

  void clearRecoveryBlock() => _blockedReason = null;

  Future<T> run<T>({
    required String expectedOwnerId,
    required Future<T> Function() operation,
  }) async {
    if (Zone.current[_zoneKey] == true) {
      throw const RestoreGateReentryException();
    }
    final blocked = _blockedReason;
    if (blocked != null) throw RestoreBlockedException(blocked);
    _requireOwner(expectedOwnerId);
    _active++;
    final queued = _tail.then((_) {
      final queuedBlock = _blockedReason;
      if (queuedBlock != null) throw RestoreBlockedException(queuedBlock);
      _requireOwner(expectedOwnerId);
      return runZoned(operation, zoneValues: {_zoneKey: true});
    });
    final settled = queued.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _tail = settled;
    return queued.whenComplete(() => _active--);
  }

  void _requireOwner(String expectedOwnerId) {
    if (expectedOwnerId.isEmpty || _owner.currentOwnerId != expectedOwnerId) {
      throw const RestoreOwnerChangedException();
    }
  }
}
