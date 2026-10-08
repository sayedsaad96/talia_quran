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

    test('replace extends an entry with the same key', () async {
      ActivityEvent block(int end, int hour) => ActivityEvent(
        occurredAt: DateTime.utc(2026, 9, 9, hour),
        kind: ActivityEventKind.memorize,
        idempotencyKey: 'memorize|session-1|block',
        surahId: 1,
        startAyah: 1,
        endAyah: end,
      );

      await repository.append(block(1, 10));
      await repository.append(block(2, 11));
      expect((await repository.recent()).single.endAyah, 1);

      await repository.append(block(3, 12), replace: true);

      final recent = await repository.recent();
      expect(await isar.activityEventIsars.count(), 1);
      expect(recent.single.endAyah, 3);
      expect(recent.single.occurredAt, DateTime.utc(2026, 9, 9, 12).toLocal());
    });

    test('keeps the kids track out of the adult feed', () async {
      await repository.append(
        ActivityEvent(
          occurredAt: DateTime.utc(2026, 9, 9, 10),
          kind: ActivityEventKind.reading,
          idempotencyKey: 'reading|20260909|1',
          pageNumber: 1,
        ),
      );
      await repository.append(
        ActivityEvent(
          occurredAt: DateTime.utc(2026, 9, 9, 11),
          kind: ActivityEventKind.reading,
          idempotencyKey: 'reading|kids|20260909|2',
          pageNumber: 2,
          isKids: true,
        ),
      );
      // Written before the audience tag existed; recognised by its key.
      await isar.writeTxn(
        () => isar.activityEventIsars.put(
          ActivityEventIsar()
            ..occurredAt = DateTime.utc(2026, 9, 9, 12)
            ..kindIndex = ActivityEventKind.memorize.index
            ..surahId = 114
            ..startAyah = 1
            ..endAyah = 1
            ..idempotencyKey = 'memorize|kids|20260909|114:1',
        ),
      );

      final adult = await repository.recent();
      final kids = await repository.recent(kids: true);

      expect(adult.map((e) => e.idempotencyKey), ['reading|20260909|1']);
      expect(adult.single.isKids, isFalse);
      expect(kids.map((e) => e.idempotencyKey), [
        'memorize|kids|20260909|114:1',
        'reading|kids|20260909|2',
      ]);
      expect(kids.every((e) => e.isKids), isTrue);
      expect(
        await repository.kindsSince(DateTime.utc(2026, 9, 9)),
        {ActivityEventKind.reading},
      );
    });
  });
}
