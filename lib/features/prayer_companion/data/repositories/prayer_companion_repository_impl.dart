import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/entities/prayer_companion.dart';
import '../../domain/repositories/prayer_companion_repository.dart';
import '../datasources/prayer_companion_local_datasource.dart';

class PrayerCompanionRepositoryImpl implements PrayerCompanionRepository {
  const PrayerCompanionRepositoryImpl(
    this._datasource, {
    RecordOwnerProvider owner = const SupabaseRecordOwnerProvider(),
  }) : _owner = owner;

  final PrayerCompanionLocalDatasource _datasource;
  final RecordOwnerProvider _owner;

  @override
  Stream<void> get changes => _datasource.watchChanges();

  @override
  Future<PrayerCompanionRecord?> read(PrayerOccurrence occurrence) =>
      _datasource.read(occurrence);

  /// Owner scoping is mandatory: the requested [ownerId] must match the
  /// active owner, otherwise the query reads nothing.
  @override
  Future<Map<PrayerKey, PrayerCompanionRecord>> readDay({
    required String ownerId,
    required DateTime localDate,
  }) {
    if (ownerId != _owner.currentOwnerId) return Future.value(const {});
    return _datasource.readDay(ownerId: ownerId, localDate: localDate);
  }

  /// The record's own occurrence supplies the owner id, so a row can only
  /// ever be written under the owner it was created for.
  @override
  Future<PrayerCompanionRecord> save(PrayerCompanionRecord record) =>
      _datasource.save(record);

  @override
  Future<void> clearOwner(String ownerId) => _datasource.clearOwner(ownerId);
}
