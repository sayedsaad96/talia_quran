// Thin Isar wrapper for owner-scoped Companion confirmation persistence.

import 'package:isar/isar.dart';

import '../../domain/entities/prayer_companion.dart';
import '../models/prayer_companion_record_isar.dart';

class PrayerCompanionLocalDatasource {
  const PrayerCompanionLocalDatasource(this._isar);

  final Isar _isar;

  /// Emits whenever the collection changes (save or clear).
  Stream<void> watchChanges() =>
      _isar.prayerCompanionRecordIsars.watchLazy().map((_) {});

  Future<PrayerCompanionRecord?> read(PrayerOccurrence occurrence) async {
    final row = await _isar.prayerCompanionRecordIsars
        .filter()
        .occurrenceKeyEqualTo(occurrence.occurrenceKey)
        .findFirst();
    return row?.toDomain();
  }

  Future<Map<PrayerKey, PrayerCompanionRecord>> readDay({
    required String ownerId,
    required DateTime localDate,
  }) async {
    final rows = await _isar.prayerCompanionRecordIsars
        .filter()
        .ownerIdEqualTo(ownerId)
        .localDayKeyEqualTo(PrayerCompanionRecordIsar.dayKeyFor(localDate))
        .findAll();
    return {
      for (final row in rows)
        PrayerKey.values[row.prayerKeyIndex]: row.toDomain(),
    };
  }

  /// Upserts [record] in place: the unique [PrayerCompanionRecordIsar.occurrenceKey]
  /// index replaces an existing row for the same owner/date/prayer.
  Future<PrayerCompanionRecord> save(PrayerCompanionRecord record) async {
    final row = PrayerCompanionRecordIsar.fromDomain(record);
    await _isar.writeTxn(() async {
      await _isar.prayerCompanionRecordIsars.put(row);
    });
    return record;
  }

  Future<void> clearOwner(String ownerId) async {
    await _isar.writeTxn(() async {
      await _isar.prayerCompanionRecordIsars
          .filter()
          .ownerIdEqualTo(ownerId)
          .deleteAll();
    });
  }
}
