import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
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
    queue = CloudSyncQueue(isar);
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

  test('drops item after max attempts', () async {
    await queue.enqueue(CloudSyncQueueKind.productionPush);
    for (var i = 0; i < CloudSyncQueue.maxAttempts; i++) {
      await queue.markFailure(CloudSyncQueueKind.productionPush);
    }

    expect(await isar.cloudSyncQueueItems.where().findAll(), isEmpty);
  });
}
