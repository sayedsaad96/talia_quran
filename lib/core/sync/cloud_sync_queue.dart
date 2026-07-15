import 'dart:math';

import 'package:isar/isar.dart';

import 'cloud_sync_queue_item.dart';

/// Retry kinds for deferred cloud sync work.
abstract final class CloudSyncQueueKind {
  static const authPull = 'auth_pull';
  static const authPush = 'auth_push';
  static const productionPull = 'production_pull';
  static const productionPush = 'production_push';
  static const certificatePush = 'certificate_push';
  static const kidsProgress = 'kids_progress';
}

class CloudSyncQueue {
  CloudSyncQueue(this._isar);

  static const maxAttempts = 8;
  static const baseBackoffSeconds = 30;

  final Isar _isar;

  Future<void> enqueue(String kind) async {
    final now = DateTime.now().toUtc();
    final item = CloudSyncQueueItem()
      ..kind = kind
      ..attemptCount = 0
      ..nextRetryAt = now
      ..createdAt = now;

    await _isar.writeTxn(() async {
      await _isar.cloudSyncQueueItems.put(item);
    });
  }

  Future<List<CloudSyncQueueItem>> dueItems() async {
    final now = DateTime.now().toUtc();
    final items = await _isar.cloudSyncQueueItems.where().findAll();
    return items
        .where(
          (item) =>
              item.attemptCount < maxAttempts &&
              !item.nextRetryAt.isAfter(now),
        )
        .toList();
  }

  Future<void> markSuccess(String kind) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.cloudSyncQueueItems
          .filter()
          .kindEqualTo(kind)
          .findFirst();
      if (existing != null) {
        await _isar.cloudSyncQueueItems.delete(existing.id);
      }
    });
  }

  Future<void> markFailure(String kind) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.cloudSyncQueueItems
          .filter()
          .kindEqualTo(kind)
          .findFirst();
      if (existing == null) return;

      existing.attemptCount += 1;
      if (existing.attemptCount >= maxAttempts) {
        await _isar.cloudSyncQueueItems.delete(existing.id);
        return;
      }

      final delaySeconds = min(
        3600,
        baseBackoffSeconds * pow(2, existing.attemptCount - 1).toInt(),
      );
      existing.nextRetryAt = DateTime.now().toUtc().add(
        Duration(seconds: delaySeconds),
      );
      await _isar.cloudSyncQueueItems.put(existing);
    });
  }

  static Duration backoffForAttempt(int attemptCount) {
    final delaySeconds = min(
      3600,
      baseBackoffSeconds * pow(2, max(0, attemptCount - 1)).toInt(),
    );
    return Duration(seconds: delaySeconds);
  }
}
