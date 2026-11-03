import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/repositories/reading_checkpoint_repository.dart';

class ReadingCheckpointState {
  const ReadingCheckpointState({
    this.result,
    this.busy = false,
    this.failed = false,
  });
  final CheckpointSyncResult? result;
  final bool busy, failed;
}

/// Sync and explicit conflict choices never update memorization or reading credit.
class ReadingCheckpointCubit extends Cubit<ReadingCheckpointState> {
  ReadingCheckpointCubit(this.repository, this.owner, this.barrier)
    : super(const ReadingCheckpointState()) {
    _changes = barrier.changes.listen((_) {
      _epoch++;
      _resultOwner = null;
      if (!isClosed) emit(const ReadingCheckpointState());
    });
  }
  late final StreamSubscription<void> _changes;
  int _epoch = 0;
  final ReadingCheckpointRepository repository;
  final RecordOwnerProvider owner;
  final AccountDataBarrier barrier;
  String? _resultOwner;

  Future<void> sync() => _run(false, false);
  Future<void> choose(bool useLocal) => _run(true, useLocal);

  Future<void> _run(bool resolving, bool useLocal) async {
    if (state.busy || !owner.isSignedIn) return;
    final epoch = ++_epoch;
    final ownerId = owner.currentOwnerId;
    final previous = _resultOwner == ownerId ? state.result : null;
    emit(ReadingCheckpointState(result: previous, busy: true));
    try {
      final lease = barrier.capture();
      lease.checkOwner(ownerId);
      if (resolving) {
        if (_resultOwner != ownerId ||
            previous?.status != CheckpointSyncStatus.conflict ||
            previous?.remote == null) {
          throw StateError('No current conflict');
        }
        final current = await repository.readLocal(expectedOwnerId: ownerId);
        lease.checkOwner(ownerId);
        if (current?.pendingMutationId != previous?.local?.pendingMutationId ||
            current?.pageNumber != previous?.local?.pageNumber) {
          throw StateError('Conflict changed');
        }
        await repository.resolveConflict(
          expectedOwnerId: ownerId,
          expectedMutationId: previous!.local!.pendingMutationId!,
          expectedLocalPage: previous.local!.pageNumber,
          seenRemote: previous.remote!,
          useLocal: useLocal,
        );
      }
      final result = await repository.sync(expectedOwnerId: ownerId);
      lease.checkOwner(ownerId);
      if (isClosed || epoch != _epoch || owner.currentOwnerId != ownerId) {
        return;
      }
      _resultOwner = ownerId;
      emit(
        ReadingCheckpointState(
          result: result,
          failed: result.status == CheckpointSyncStatus.unavailable,
        ),
      );
    } catch (_) {
      if (!isClosed && epoch == _epoch) {
        emit(const ReadingCheckpointState(failed: true));
      }
    }
  }

  @override
  Future<void> close() async {
    _epoch++;
    await _changes.cancel();
    return super.close();
  }
}
