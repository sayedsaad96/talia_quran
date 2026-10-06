import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:talia_quran/features/home/data/models/activity_event_isar.dart';
import 'package:talia_quran/features/home/data/repositories/activity_feed_repository_impl.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import '../../../helpers/isar_test_core.dart';


Future<void> _initializeIsarCoreForTests() => initializeIsarCoreForTests();

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
