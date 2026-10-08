import 'package:isar_community/isar.dart';

import '../../domain/entities/activity_event.dart';
import '../../domain/repositories/activity_feed_repository.dart';
import '../models/activity_event_isar.dart';

class ActivityFeedRepositoryImpl implements ActivityFeedRepository {
  const ActivityFeedRepositoryImpl(this._isar);

  final Isar _isar;

  /// Kids rows written before the [ActivityEventIsar.isKids] tag existed.
  static const _legacyKidsKeyPrefix = 'memorize|kids|';

  @override
  Future<void> append(ActivityEvent event, {bool replace = false}) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.activityEventIsars
          .filter()
          .idempotencyKeyEqualTo(event.idempotencyKey)
          .findFirst();
      if (existing != null && !replace) return;
      final row = ActivityEventIsar()
        ..id = existing?.id ?? Isar.autoIncrement
        ..occurredAt = event.occurredAt.toUtc()
        ..kindIndex = event.kind.index
        ..surahId = event.surahId
        ..startAyah = event.startAyah
        ..endAyah = event.endAyah
        ..pageNumber = event.pageNumber
        ..isKids = event.isKids
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
        if (!_isKidsRow(row)) _kindOf(row),
    };
  }

  @override
  Future<List<ActivityEvent>> recent({
    int limit = 20,
    bool kids = false,
  }) async {
    final query = kids
        ? _isar.activityEventIsars.filter().group(
            (q) => q
                .isKidsEqualTo(true)
                .or()
                .idempotencyKeyStartsWith(_legacyKidsKeyPrefix),
          )
        : _isar.activityEventIsars
              .filter()
              .not()
              .isKidsEqualTo(true)
              .and()
              .not()
              .idempotencyKeyStartsWith(_legacyKidsKeyPrefix);
    final rows = await query.sortByOccurredAtDesc().limit(limit).findAll();
    return [
      for (final row in rows)
        ActivityEvent(
          occurredAt: row.occurredAt.toLocal(),
          kind: _kindOf(row),
          idempotencyKey: row.idempotencyKey,
          surahId: row.surahId,
          startAyah: row.startAyah,
          endAyah: row.endAyah,
          pageNumber: row.pageNumber,
          isKids: _isKidsRow(row),
        ),
    ];
  }

  static bool _isKidsRow(ActivityEventIsar row) =>
      row.isKids == true || row.idempotencyKey.startsWith(_legacyKidsKeyPrefix);

  static ActivityEventKind _kindOf(ActivityEventIsar row) =>
      ActivityEventKind.values[row.kindIndex.clamp(
        0,
        ActivityEventKind.values.length - 1,
      )];
}
