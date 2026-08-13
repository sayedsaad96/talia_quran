import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';

bool _isarCoreInitialized = false;

Future<void> _initializeIsarCoreForTests() async {
  if (_isarCoreInitialized) return;
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final dllPath =
          '$localAppData\\Pub\\Cache\\hosted\\pub.dev\\'
          'isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
      if (File(dllPath).existsSync()) {
        await Isar.initializeIsarCore(libraries: {Abi.current(): dllPath});
        _isarCoreInitialized = true;
        return;
      }
    }
  }
  await Isar.initializeIsarCore();
  _isarCoreInitialized = true;
}

void main() {
  group('CloudSyncQueue owner scoping', () {
    late Isar isar;
    late Directory dir;

    CloudSyncQueue queueFor(String ownerId) =>
        CloudSyncQueue(isar, FixedRecordOwnerProvider(ownerId));

    setUp(() async {
      await _initializeIsarCoreForTests();
      dir = await Directory.systemTemp.createTemp('talia_queue_');
      isar = await Isar.open(
        [CloudSyncQueueItemSchema],
        directory: dir.path,
        name: 'queue_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        if (await dir.exists()) await dir.delete(recursive: true);
      });
    });

    test('the same kind for two owners produces two rows', () async {
      await queueFor('user-a').enqueue(CloudSyncQueueKind.productionPush);
      await queueFor('user-b').enqueue(CloudSyncQueueKind.productionPush);
      expect(await isar.cloudSyncQueueItems.where().count(), 2);
    });

    test('one owner never sees another owner queued work', () async {
      await queueFor('user-a').enqueue(CloudSyncQueueKind.productionPush);
      expect(await queueFor('user-b').hasPending(), isFalse);
      expect(await queueFor('user-b').dueItems(), isEmpty);
      expect(await queueFor('user-a').hasPending(), isTrue);
    });

    test('markSuccess only removes the active owner item', () async {
      await queueFor('user-a').enqueue(CloudSyncQueueKind.productionPush);
      await queueFor('user-b').enqueue(CloudSyncQueueKind.productionPush);
      await queueFor('user-b').markSuccess(CloudSyncQueueKind.productionPush);
      expect(await queueFor('user-a').hasPending(), isTrue);
      expect(await queueFor('user-b').hasPending(), isFalse);
    });

    test('markFailure backs off only the active owner item', () async {
      await queueFor('user-a').enqueue(CloudSyncQueueKind.productionPush);
      await queueFor('user-b').enqueue(CloudSyncQueueKind.productionPush);
      await queueFor('user-a').markFailure(CloudSyncQueueKind.productionPush);
      final rows = await isar.cloudSyncQueueItems.where().findAll();
      final a = rows.firstWhere((r) => r.ownerUserId == 'user-a');
      final b = rows.firstWhere((r) => r.ownerUserId == 'user-b');
      expect(a.attemptCount, 1);
      expect(b.attemptCount, 0);
    });

    test('enqueue is ignored while signed out', () async {
      await queueFor('local').enqueue(CloudSyncQueueKind.productionPush);
      expect(await isar.cloudSyncQueueItems.where().count(), 0);
    });
  });
}
