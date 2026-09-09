import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:talia_quran/features/home/data/models/activity_event_isar.dart';
import 'package:talia_quran/features/home/data/repositories/activity_feed_repository_impl.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';

bool _isarCoreInitialized = false;

Future<void> _initializeIsarCoreForTests() async {
  if (_isarCoreInitialized) return;
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final dllPath =
          '$localAppData\\Pub\\Cache\\hosted\\pub.dev\\isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
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
  group('ActivityFeedRepositoryImpl — real Isar', () {
    late Directory tempDir;
    late Isar isar;
    late ActivityFeedRepositoryImpl repository;

    setUp(() async {
      await _initializeIsarCoreForTests();
      tempDir = await Directory.systemTemp.createTemp('talia_activity_feed_');
      isar = await Isar.open(
        [ActivityEventIsarSchema],
        directory: tempDir.path,
        name: 'activity_feed_${DateTime.now().microsecondsSinceEpoch}',
      );
      repository = ActivityFeedRepositoryImpl(isar);
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('append is idempotent and recent returns newest first', () async {
      final older = ActivityEvent(
        occurredAt: DateTime.utc(2026, 9, 8, 10),
        kind: ActivityEventKind.reading,
        idempotencyKey: 'reading|20260908|1',
        pageNumber: 1,
        surahId: 1,
        startAyah: 1,
        endAyah: 7,
      );
      final newer = ActivityEvent(
        occurredAt: DateTime.utc(2026, 9, 9, 11),
        kind: ActivityEventKind.khatmah,
        idempotencyKey: 'khatmah|20260909|12',
        pageNumber: 12,
      );

      await repository.append(older);
      await repository.append(newer);
      await repository.append(older);

      expect(await isar.activityEventIsars.count(), 2);
      final recent = await repository.recent(limit: 10);
      expect(recent.map((event) => event.idempotencyKey), [
        'khatmah|20260909|12',
        'reading|20260908|1',
      ]);
      expect(recent.first.kind, ActivityEventKind.khatmah);
      expect(recent.last.surahId, 1);
    });
  });
}
