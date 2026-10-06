
import 'dart:io';



import 'package:flutter_test/flutter_test.dart';

import 'package:isar_community/isar.dart';

import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';

import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import '../../helpers/isar_test_core.dart';






Future<void> _initializeIsarCoreForTests() => initializeIsarCoreForTests();



void main() {

  late Isar isar;

  late CloudSyncQueue queue;

  late Directory tempDir;



  setUp(() async {

    await _initializeIsarCoreForTests();

    tempDir = await Directory.systemTemp.createTemp('talia_cloud_sync_queue_');

    isar = await Isar.open(

      [CloudSyncQueueItemSchema],

      directory: tempDir.path,

      name: 'cloud_sync_queue_test',

    );

    queue = CloudSyncQueue(isar, const FixedRecordOwnerProvider('user-test'));

  });



  tearDown(() async {

    await isar.close(deleteFromDisk: true);

    if (await tempDir.exists()) {

      await tempDir.delete(recursive: true);

    }

  });



  test('enqueue and markSuccess removes item', () async {

    await queue.enqueue(CloudSyncQueueKind.authPush);

    expect(await queue.dueItems(), hasLength(1));



    await queue.markSuccess(CloudSyncQueueKind.authPush);

    expect(await queue.dueItems(), isEmpty);

  });



  test('enqueue preserves attemptCount on duplicate', () async {

    await queue.enqueue(CloudSyncQueueKind.authPull);

    await queue.markFailure(CloudSyncQueueKind.authPull);

    final afterFailure = await isar.cloudSyncQueueItems.where().findAll();

    expect(afterFailure.single.attemptCount, 1);



    await queue.enqueue(CloudSyncQueueKind.authPull);

    final afterRequeue = await isar.cloudSyncQueueItems.where().findAll();

    expect(afterRequeue.single.attemptCount, 1);

  });



  test('markFailure applies exponential backoff', () async {

    await queue.enqueue(CloudSyncQueueKind.authPull);

    await queue.markFailure(CloudSyncQueueKind.authPull);



    final items = await isar.cloudSyncQueueItems.where().findAll();

    expect(items.single.attemptCount, 1);

    expect(

      items.single.nextRetryAt.isAfter(DateTime.now().toUtc()),

      isTrue,

    );

    expect(await queue.dueItems(), isEmpty);

  });



  test('retains dead letters after max attempts', () async {

    await queue.enqueue(CloudSyncQueueKind.productionPush);

    for (var i = 0; i < CloudSyncQueue.maxAttempts; i++) {

      await queue.markFailure(CloudSyncQueueKind.productionPush);

    }



    final items = await isar.cloudSyncQueueItems.where().findAll();

    expect(items, hasLength(1));

    expect(items.single.attemptCount, CloudSyncQueue.maxAttempts);

    expect(await queue.dueItems(), isEmpty);

    expect(await queue.deadLetterItems(), hasLength(1));

  });



  test('recoverDeadLetter resets attempts', () async {

    await queue.enqueue(CloudSyncQueueKind.kidsProgressPull);

    for (var i = 0; i < CloudSyncQueue.maxAttempts; i++) {

      await queue.markFailure(CloudSyncQueueKind.kidsProgressPull);

    }

    final result = await queue.recoverDeadLetter(
      CloudSyncQueueKind.kidsProgressPull,
    );



    expect(await queue.dueItems(), hasLength(1));

    expect(result.rearmed, isTrue);

    expect(

      (await isar.cloudSyncQueueItems.where().findAll()).single.attemptCount,

      0,

    );

  });

  test('enqueue schedules owner-scoped background delivery', () async {
    String? scheduledOwner;
    queue = CloudSyncQueue(
      isar,
      const FixedRecordOwnerProvider('user-test'),
      scheduleBackgroundDelivery: (ownerId) async {
        scheduledOwner = ownerId;
      },
    );

    await queue.enqueue(CloudSyncQueueKind.bookmarkPush);

    expect(scheduledOwner, 'user-test');
  });

  test('signed-out local records do not schedule background delivery', () async {
    var scheduled = false;
    queue = CloudSyncQueue(
      isar,
      const FixedRecordOwnerProvider('local'),
      scheduleBackgroundDelivery: (_) async => scheduled = true,
    );

    await queue.enqueue(CloudSyncQueueKind.authPush);

    expect(scheduled, isFalse);
    expect(await queue.dueItems(), isEmpty);
  });

  test('explicit dead-letter recovery re-arms only the selected kind', () async {
    await queue.enqueue(CloudSyncQueueKind.authPull);
    await queue.enqueue(CloudSyncQueueKind.productionPull);
    for (var i = 0; i < CloudSyncQueue.maxAttempts; i++) {
      await queue.markFailure(CloudSyncQueueKind.authPull);
      await queue.markFailure(CloudSyncQueueKind.productionPull);
    }

    final result = await queue.recoverDeadLetter(CloudSyncQueueKind.authPull);

    final items = await isar.cloudSyncQueueItems.where().findAll();
    expect(items, hasLength(2));
    expect(result.rearmed, isTrue);
    expect(
      items.singleWhere((item) => item.kind == CloudSyncQueueKind.authPull)
          .attemptCount,
      0,
    );
    expect(
      items
          .singleWhere((item) => item.kind == CloudSyncQueueKind.productionPull)
          .attemptCount,
      CloudSyncQueue.maxAttempts,
    );
  });



  test('kidsProgressPush success does not clear kidsProgressPull', () async {

    await queue.enqueue(CloudSyncQueueKind.kidsProgressPull);

    await queue.enqueue(CloudSyncQueueKind.kidsProgressPush);



    // Simulate push succeeds

    await queue.markSuccess(CloudSyncQueueKind.kidsProgressPush);



    // Pull retry must still be pending

    final due = await queue.dueItems();

    expect(due, hasLength(1));

    expect(due.single.kind, CloudSyncQueueKind.kidsProgressPull);

  });

}
