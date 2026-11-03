import '../repositories/reading_checkpoint_repository.dart';

class SaveReadingCheckpoint {
  const SaveReadingCheckpoint(this.repository);
  final ReadingCheckpointRepository repository;
  Future<void> call(String ownerId, int page) =>
      repository.saveLocal(expectedOwnerId: ownerId, pageNumber: page);
}

class SyncReadingCheckpoint {
  const SyncReadingCheckpoint(this.repository);
  final ReadingCheckpointRepository repository;
  Future<CheckpointSyncResult> call(String ownerId) =>
      repository.sync(expectedOwnerId: ownerId);
}
