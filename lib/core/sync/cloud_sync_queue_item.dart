import 'package:isar/isar.dart';

part 'cloud_sync_queue_item.g.dart';

/// One unit of deferred cloud work, owned by exactly one account.
///
/// The unique index spans `kind` and `ownerUserId` so account A's deferred
/// push is a different row from account B's. With `kind` alone, B would execute
/// work enqueued by A.
@collection
class CloudSyncQueueItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, composite: [CompositeIndex('ownerUserId')])
  late String kind;

  /// Supabase user id of the account that enqueued this item.
  late String ownerUserId;

  int attemptCount = 0;

  late DateTime nextRetryAt;

  late DateTime createdAt;
}
