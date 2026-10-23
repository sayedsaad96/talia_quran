import '../../features/group_khatmah/data/group_khatmah_remote.dart';
import '../identity/account_data_barrier.dart';
import 'cloud_sync_queue.dart';

final class GroupKhatmahQueueWake implements GroupKhatmahWakeScheduler {
  const GroupKhatmahQueueWake(this.queue, this.barrier);
  final CloudSyncQueue queue;
  final AccountDataBarrier barrier;
  @override
  Future<void> reconcilePush({
    required String ownerId,
    required AccountDataLease lease,
    required DateTime? nextRetryAt,
  }) => queue.reconcileGroupWake(
    kind: CloudSyncQueueKind.groupKhatmahPush,
    ownerId: ownerId,
    barrier: barrier,
    lease: lease,
    nextRetryAt: nextRetryAt,
  );
  @override
  Future<void> requestPull({
    required String ownerId,
    required AccountDataLease lease,
  }) => queue.reconcileGroupWake(
    kind: CloudSyncQueueKind.groupKhatmahPull,
    ownerId: ownerId,
    barrier: barrier,
    lease: lease,
    nextRetryAt: DateTime.now().toUtc(),
  );
}
