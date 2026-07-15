import 'package:isar/isar.dart';

part 'cloud_sync_queue_item.g.dart';

/// Persistent retry queue for failed cloud sync operations.
@collection
class CloudSyncQueueItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String kind;

  int attemptCount = 0;

  late DateTime nextRetryAt;

  late DateTime createdAt;
}
