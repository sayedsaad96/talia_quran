import 'package:isar/isar.dart';

import '../../domain/entities/prayer_companion.dart';

part 'prayer_companion_record_isar.g.dart';

/// Isar row for one self-reported prayer occurrence.
///
/// Local-only: no cloud dirty flags, no sync cursor, no migration source.
/// [occurrenceKey] (`owner|yyyy-mm-dd|prayer`) is the unique, replaceable
/// identity, so re-saving the same owner/date/prayer upserts in place.
@collection
class PrayerCompanionRecordIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String occurrenceKey;

  @Index()
  late String ownerId;

  /// Local civil day as `yyyymmdd` for efficient day-range queries.
  @Index()
  late int localDayKey;

  late int prayerKeyIndex;
  late DateTime scheduledAt;
  late int statusIndex;
  late DateTime statusUpdatedAt;
  DateTime? followUpAt;
  int followUpCount = 0;
  late DateTime createdAt;
  late DateTime updatedAt;

  static int dayKeyFor(DateTime localDate) =>
      localDate.year * 10000 + localDate.month * 100 + localDate.day;

  PrayerCompanionRecord toDomain() {
    final day = DateTime(
      localDayKey ~/ 10000,
      (localDayKey ~/ 100) % 100,
      localDayKey % 100,
    );
    return PrayerCompanionRecord(
      occurrence: PrayerOccurrence(
        ownerId: ownerId,
        localDate: day,
        prayerKey: PrayerKey.values[prayerKeyIndex],
        scheduledAt: scheduledAt,
      ),
      status: PrayerCompanionStatus.values[statusIndex],
      statusUpdatedAt: statusUpdatedAt,
      followUpAt: followUpAt,
      followUpCount: followUpCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static PrayerCompanionRecordIsar fromDomain(PrayerCompanionRecord record) {
    final occurrence = record.occurrence;
    return PrayerCompanionRecordIsar()
      ..occurrenceKey = occurrence.occurrenceKey
      ..ownerId = occurrence.ownerId
      ..localDayKey = dayKeyFor(occurrence.localDate)
      ..prayerKeyIndex = occurrence.prayerKey.index
      ..scheduledAt = occurrence.scheduledAt
      ..statusIndex = record.status.index
      ..statusUpdatedAt = record.statusUpdatedAt
      ..followUpAt = record.followUpAt
      ..followUpCount = record.followUpCount
      ..createdAt = record.createdAt
      ..updatedAt = record.updatedAt;
  }
}
