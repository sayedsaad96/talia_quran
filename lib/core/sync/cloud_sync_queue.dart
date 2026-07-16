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
  final _random = Random();

  /// Enqueues [kind] without resetting an existing item's [attemptCount].
  Future<void> enqueue(String kind) async {
    final now = DateTime.now().toUtc();
    await _isar.writeTxn(() async {
      final existing = await _isar.cloudSyncQueueItems
          .filter()
          .kindEqualTo(kind)
          .findFirst();

      if (existing != null) {
        // Dead letters stay until cleared; do not silently reset retries.
        if (existing.attemptCount >= maxAttempts) return;
        if (existing.nextRetryAt.isAfter(now)) {
          existing.nextRetryAt = now;
        }
        await _isar.cloudSyncQueueItems.put(existing);
        return;
      }

      final item = CloudSyncQueueItem()
        ..kind = kind
        ..attemptCount = 0
        ..nextRetryAt = now
        ..createdAt = now;
      await _isar.cloudSyncQueueItems.put(item);
    });
  }

  Future<bool> hasPending() async {
    final items = await _isar.cloudSyncQueueItems.where().findAll();
    return items.any((item) => item.attemptCount < maxAttempts);
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

  /// Exhausted items retained for user-visible recovery (never auto-deleted).
  Future<List<CloudSyncQueueItem>> deadLetterItems() async {
    final items = await _isar.cloudSyncQueueItems.where().findAll();
    return items.where((item) => item.attemptCount >= maxAttempts).toList();
  }

  Future<void> clearDeadLetter(String kind) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.cloudSyncQueueItems
          .filter()
          .kindEqualTo(kind)
          .findFirst();
      if (existing == null || existing.attemptCount < maxAttempts) return;
      await _isar.cloudSyncQueueItems.delete(existing.id);
    });
  }

  /// Re-arms a dead letter for another retry cycle (preserves history via
  /// resetting attempt count only when the user explicitly recovers).
  Future<void> requeueDeadLetter(String kind) async {
    final now = DateTime.now().toUtc();
    await _isar.writeTxn(() async {
      final existing = await _isar.cloudSyncQueueItems
          .filter()
          .kindEqualTo(kind)
          .findFirst();
      if (existing == null || existing.attemptCount < maxAttempts) return;
      existing.attemptCount = 0;
      existing.nextRetryAt = now;
      await _isar.cloudSyncQueueItems.put(existing);
    });
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
      final delaySeconds = min(
        3600,
        baseBackoffSeconds * pow(2, existing.attemptCount - 1).toInt(),
      );
      final jitter = _random.nextInt(max(1, delaySeconds ~/ 4 + 1));
      existing.nextRetryAt = DateTime.now().toUtc().add(
        Duration(seconds: delaySeconds + jitter),
      );
      // Retain exhausted items as dead letters (do not delete).
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
