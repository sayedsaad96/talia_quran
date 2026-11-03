import '../identity/record_owner_provider.dart';
import 'restore_operation_gate.dart';
import 'restore_recovery_journal.dart';
import 'restore_store_rollbacks.dart';

/// Resolves an unfinished restore before the app shows or syncs progress.
///
/// Only the foreground startup recovers: a background isolate may start while
/// the foreground is mid-restore, so it may only look
/// ([hasUnfinished]) and stay away from the stores.
class RestoreStartupRecovery {
  const RestoreStartupRecovery({
    required this._journal,
    required this._rollbacks,
    required this._owner,
    required this._gate,
  });

  final RestoreRecoveryJournal _journal;
  final RestoreStoreRollbacks _rollbacks;
  final RecordOwnerProvider _owner;
  final RestoreOperationGate _gate;

  /// A failed recovery is a startup failure, not a successful partial startup.
  Future<void> requireReady({bool background = false}) async {
    final blocked = background
        ? await hasUnfinished()
        : (await recover()).isBlocked;
    if (blocked) {
      throw const RestoreBlockedException('startup_recovery_required');
    }
  }

  /// Rolls back or finishes the journal, then opens or keeps closed the gate
  /// that admits new restores and sync.
  Future<RestoreRecoveryResult> recover() async {
    final result = await _journal.recoverBeforeReady(
      activeOwnerId: _owner.currentOwnerId,
      rollbacks: _rollbacks.registry,
    );
    if (result.isBlocked) {
      _gate.blockUntilRecovered(result.reason ?? 'recovery_failed');
    } else {
      _gate.clearRecoveryBlock();
    }
    return result;
  }

  /// Read-only: whether a journal exists. Treats an unreadable store as
  /// unfinished, because it cannot be proven otherwise.
  Future<bool> hasUnfinished() async {
    try {
      final unfinished = await _journal.hasUnfinished();
      if (unfinished) _gate.blockUntilRecovered('journal_present');
      return unfinished;
    } on Exception {
      _gate.blockUntilRecovered('journal_unreadable');
      return true;
    }
  }
}
