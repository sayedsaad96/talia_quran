import 'package:isar/isar.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/repositories/activity_feed_repository.dart';
import '../models/activity_event_isar.dart';

class ActivityFeedRepositoryImpl implements ActivityFeedRepository {
  const ActivityFeedRepositoryImpl(this._isar);

  final Isar _isar;

  @override
  Future<void> append(ActivityEvent event) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.activityEventIsars
          .filter()
          .idempotencyKeyEqualTo(event.idempotencyKey)
          .findFirst();
      if (existing != null) return;
      final row = ActivityEventIsar()
        ..occurredAt = event.occurredAt.toUtc()
        ..kindIndex = event.kind.index
        ..surahId = event.surahId
        ..startAyah = event.startAyah
        ..endAyah = event.endAyah
        ..pageNumber = event.pageNumber
        ..idempotencyKey = event.idempotencyKey;
      await _isar.activityEventIsars.put(row);
    });
  }

  @override
  Future<Set<ActivityEventKind>> kindsSince(DateTime start) async {
    final rows = await _isar.activityEventIsars
        .filter()
        .occurredAtGreaterThan(start.toUtc(), include: true)
        .findAll();
    return {
      for (final row in rows)
        ActivityEventKind.values[row.kindIndex.clamp(
          0,
          ActivityEventKind.values.length - 1,
        )],
    };
  }

  @override
  Future<List<ActivityEvent>> recent({int limit = 20}) async {
    final rows = await _isar.activityEventIsars
        .where()
        .sortByOccurredAtDesc()
        .limit(limit)
        .findAll();
    return [
      for (final row in rows)
        ActivityEvent(
          occurredAt: row.occurredAt.toLocal(),
          kind: ActivityEventKind.values[row.kindIndex.clamp(
            0,
            ActivityEventKind.values.length - 1,
          )],
          idempotencyKey: row.idempotencyKey,
          surahId: row.surahId,
          startAyah: row.startAyah,
          endAyah: row.endAyah,
          pageNumber: row.pageNumber,
        ),
    ];
  }
}
