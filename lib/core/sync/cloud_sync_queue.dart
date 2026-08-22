import 'dart:async';
import 'dart:math';

import 'package:isar/isar.dart';

import '../identity/record_owner_provider.dart';
import '../memorization/review_record_identity.dart';
import 'cloud_sync_queue_item.dart';
import 'sync_result.dart';

/// Retry kinds for deferred cloud sync work.
abstract final class CloudSyncQueueKind {
  static const authPull = 'auth_pull';
  static const authPush = 'auth_push';
  static const productionPull = 'production_pull';
  static const productionPush = 'production_push';
  static const certificatePush = 'certificate_push';
  static const certificatePull = 'certificate_pull';
  static const kidsProgress = 'kids_progress'; // legacy — kept to drain old Isar rows
  static const kidsProgressPull = 'kids_progress_pull';
  static const kidsProgressPush = 'kids_progress_push';
  static const bookmarkPull = 'bookmark_pull';
  static const bookmarkPush = 'bookmark_push';
}

class CloudSyncQueue {
  CloudSyncQueue(
    this._isar,
    this._owner, {
    Future<void> Function(String ownerId)? scheduleBackgroundDelivery,
    Future<void> Function()? requestForegroundSync,
  }) : _scheduleBackgroundDelivery = scheduleBackgroundDelivery,
       _requestForegroundSync = requestForegroundSync;

  static const maxAttempts = 8;
  static const baseBackoffSeconds = 30;

  final Isar _isar;
  final RecordOwnerProvider _owner;
  final Future<void> Function(String ownerId)? _scheduleBackgroundDelivery;
  final Future<void> Function()? _requestForegroundSync;
  final _random = Random();

  String get _ownerUserId => _owner.currentOwnerId;

  /// False while signed out: there is no account to defer work for, and an
  /// item enqueued under the local owner could later be executed by whoever
  /// signs in next.
  bool get _canQueue => _ownerUserId != ReviewRecordIdentity.localOwnerId;

  Future<CloudSyncQueueItem?> _find(String kind) =>
      _isar.cloudSyncQueueItems.getByKindOwnerUserId(kind, _ownerUserId);

  Future<List<CloudSyncQueueItem>> _ownedItems() => _isar.cloudSyncQueueItems
      .filter()
      .ownerUserIdEqualTo(_ownerUserId)
      .findAll();

  /// Enqueues [kind] for the active account without resetting an existing
  /// item's [attemptCount].
  Future<void> enqueue(String kind) async {
    if (!_canQueue) return;
    final now = DateTime.now().toUtc();
    final ownerUserId = _ownerUserId;
    await _isar.writeTxn(() async {
      final existing = await _isar.cloudSyncQueueItems.getByKindOwnerUserId(
        kind,
        ownerUserId,
      );

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
        ..ownerUserId = ownerUserId
        ..attemptCount = 0
        ..nextRetryAt = now
        ..createdAt = now;
      await _isar.cloudSyncQueueItems.put(item);
    });
    await _scheduleBackgroundDelivery?.call(ownerUserId);
    final requestForegroundSync = _requestForegroundSync;
    if (requestForegroundSync != null) {
      unawaited(requestForegroundSync());
    }
  }

  Future<bool> hasPending() async {
    final items = await _ownedItems();
    return items.any((item) => item.attemptCount < maxAttempts);
  }

  Future<List<CloudSyncQueueItem>> dueItems() async {
    final now = DateTime.now().toUtc();
    final items = await _ownedItems();
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
    final items = await _ownedItems();
    return items.where((item) => item.attemptCount >= maxAttempts).toList();
  }

  Future<void> clearDeadLetter(String kind) async {
    await _isar.writeTxn(() async {
      final existing = await _find(kind);
      if (existing == null || existing.attemptCount < maxAttempts) return;
      await _isar.cloudSyncQueueItems.delete(existing.id);
    });
  }

  /// Re-arms a dead letter for another retry cycle (preserves history via
  /// resetting attempt count only when the user explicitly recovers).
  Future<void> _requeueDeadLetter(String kind) async {
    final now = DateTime.now().toUtc();
    await _isar.writeTxn(() async {
      final existing = await _find(kind);
      if (existing == null || existing.attemptCount < maxAttempts) return;
      existing.attemptCount = 0;
      existing.nextRetryAt = now;
      await _isar.cloudSyncQueueItems.put(existing);
    });
  }

  /// Explicit recovery API for UI or support tooling. Lifecycle callbacks must
  /// not call this; exhausted work remains a dead letter until requested.
  Future<DeadLetterRecoveryResult> recoverDeadLetter(String kind) async {
    final before = await _find(kind);
    if (before == null || before.attemptCount < maxAttempts) {
      return DeadLetterRecoveryResult(kind: kind, rearmed: false);
    }
    await _requeueDeadLetter(kind);
    return DeadLetterRecoveryResult(kind: kind, rearmed: true);
  }

  Future<void> markSuccess(String kind) async {
    await _isar.writeTxn(() async {
      final existing = await _find(kind);
      if (existing != null) {
        await _isar.cloudSyncQueueItems.delete(existing.id);
      }
    });
  }

  Future<void> markFailure(String kind) async {
    await _isar.writeTxn(() async {
      final existing = await _find(kind);
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
