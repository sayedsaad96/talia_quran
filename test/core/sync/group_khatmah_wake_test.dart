import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import '../../helpers/isar_test_core.dart';

void main() {
  late Isar isar;
  late AccountDataBarrier barrier;
  late CloudSyncQueue queue;
  final now = DateTime.utc(2026, 10, 23);
  setUp(() async {
    await initializeIsarCoreForTests();
    SharedPreferences.setMockInitialValues({});
    barrier = AccountDataBarrier.forPreferences(
      await SharedPreferences.getInstance(),
    )..owner = const FixedRecordOwnerProvider('a');
    final directory = await Directory.systemTemp.createTemp('group_wake_');
    isar = await Isar.open(
      [CloudSyncQueueItemSchema],
      directory: directory.path,
      name: 'group_wake_${DateTime.now().microsecondsSinceEpoch}',
    );
    queue = CloudSyncQueue(
      isar,
      const FixedRecordOwnerProvider('a'),
      now: () => now,
    );
    addTearDown(() async {
      await isar.close(deleteFromDisk: true);
      await directory.delete(recursive: true);
    });
  });

  Future<void> reconcile(DateTime? at, {AccountDataLease? lease}) =>
      queue.reconcileGroupWake(
        kind: CloudSyncQueueKind.groupKhatmahPush,
        ownerId: 'a',
        barrier: barrier,
        lease: lease ?? barrier.capture(),
        nextRetryAt: at,
      );

  test(
    'journal wake rearms exhausted aggregate without touching other account',
    () async {
      await queue.enqueue(CloudSyncQueueKind.groupKhatmahPush);
      for (var attempt = 0; attempt < CloudSyncQueue.maxAttempts; attempt++) {
        await queue.recordFailure(
          CloudSyncQueueKind.groupKhatmahPush,
          expectedOwner: 'a',
        );
      }
      final other = CloudSyncQueue(isar, const FixedRecordOwnerProvider('b'));
      await other.enqueue(CloudSyncQueueKind.groupKhatmahPush);
      await reconcile(now.add(const Duration(minutes: 5)));
      final rows = await isar.cloudSyncQueueItems.where().findAll();
      expect(rows.length, 2);
      final active = rows.singleWhere((row) => row.ownerUserId == 'a');
      expect(active.attemptCount, 0);
      expect(active.nextRetryAt.toUtc(), now.add(const Duration(minutes: 5)));
      expect(await queue.dueItems(), isEmpty);
      await reconcile(null);
      expect(await queue.hasPending(), isFalse);
      expect(await other.hasPending(), isTrue);
    },
  );

  test(
    'an invalidated lease cannot create a wake after account cleanup',
    () async {
      final lease = barrier.capture();
      await barrier.clear(() async {});
      await expectLater(
        reconcile(now, lease: lease),
        throwsA(isA<AccountDataUnavailableException>()),
      );
      expect(await isar.cloudSyncQueueItems.where().count(), 0);
    },
  );
}
