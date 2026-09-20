import '../entities/prayer_companion.dart';

/// Owner-scoped local persistence for Companion confirmation records.
///
/// Local-only by design: there is no cloud sync, queue, or migration here.
/// Every query is filtered by owner id so one account can never observe
/// another account's self-reported state.
abstract interface class PrayerCompanionRepository {
  /// Emits whenever a record is saved or an owner's rows are cleared.
  Stream<void> get changes;

  /// The stored record for [occurrence], or null when the user has never
  /// acted on it.
  Future<PrayerCompanionRecord?> read(PrayerOccurrence occurrence);

  /// All records for [ownerId] on the local civil day of [localDate],
  /// keyed by prayer.
  Future<Map<PrayerKey, PrayerCompanionRecord>> readDay({
    required String ownerId,
    required DateTime localDate,
  });

  /// Idempotently upserts [record] by its occurrence key. Saving the same
  /// owner/date/prayer twice replaces the row instead of duplicating it.
  Future<PrayerCompanionRecord> save(PrayerCompanionRecord record);

  /// Removes every row belonging to [ownerId] and no one else.
  Future<void> clearOwner(String ownerId);
}
