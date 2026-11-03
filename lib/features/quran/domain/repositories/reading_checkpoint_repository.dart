class RemoteCheckpoint {
  const RemoteCheckpoint(this.pageNumber, this.revision);
  final int pageNumber;
  final int revision;
}

class LocalReadingCheckpoint {
  const LocalReadingCheckpoint({
    required this.pageNumber,
    required this.serverRevision,
    this.pendingMutationId,
  });
  final int pageNumber;
  final int serverRevision;
  final String? pendingMutationId;
}

enum CheckpointSyncStatus { synced, pending, conflict, unavailable }

class CheckpointSyncResult {
  const CheckpointSyncResult(this.status, {this.local, this.remote});
  final CheckpointSyncStatus status;
  final LocalReadingCheckpoint? local;
  final RemoteCheckpoint? remote;
}

class CheckpointRemoteResult {
  const CheckpointRemoteResult.accepted(this.checkpoint) : accepted = true;
  const CheckpointRemoteResult.conflict(this.checkpoint) : accepted = false;
  final bool accepted;
  final RemoteCheckpoint? checkpoint;
}

abstract interface class ReadingCheckpointRemote {
  Future<RemoteCheckpoint?> get({required String expectedOwnerId});
  Future<CheckpointRemoteResult> put({
    required String expectedOwnerId,
    required int pageNumber,
    required int expectedRevision,
    required String mutationId,
  });
}

abstract interface class ReadingCheckpointRepository {
  Future<LocalReadingCheckpoint?> readLocal({required String expectedOwnerId});
  Future<void> saveLocal({
    required String expectedOwnerId,
    required int pageNumber,
  });
  Future<CheckpointSyncResult> sync({required String expectedOwnerId});
  Future<void> resolveConflict({
    required String expectedOwnerId,
    required String expectedMutationId,
    required int expectedLocalPage,
    required RemoteCheckpoint seenRemote,
    required bool useLocal,
  });
}
