import 'package:isar_community/isar.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/memorization/review_record_identity.dart';
import '../../domain/entities/ayah_note.dart';
import '../../domain/repositories/ayah_note_repository.dart';
import '../../domain/services/ayah_note_policy.dart';
import '../models/isar_ayah_note.dart';

class IsarAyahNoteRepository implements AyahNoteRepository, AyahNoteClaimer {
  IsarAyahNoteRepository(
    this._isar,
    this._owner,
    this._barrier, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Isar _isar;
  final RecordOwnerProvider _owner;
  final AccountDataBarrier _barrier;
  final DateTime Function() _clock;

  @override
  Future<AyahNote?> get(int surahId, int ayahNumber) async {
    AyahNotePolicy.checkReference(surahId, ayahNumber);
    final ownerId = _owner.currentOwnerId;
    final lease = _barrier.capture();
    return _barrier.run((activeLease) async {
      _ensure(ownerId, activeLease);
      final row = await _isar.isarAyahNotes
          .filter()
          .ownerIdEqualTo(ownerId)
          .surahIdEqualTo(surahId)
          .ayahNumberEqualTo(ayahNumber)
          .findFirst();
      _ensure(ownerId, activeLease);
      return row == null ? null : _toDomain(row);
    }, authority: lease);
  }

  @override
  Future<List<AyahNote>> listAll() async {
    final ownerId = _owner.currentOwnerId;
    final lease = _barrier.capture();
    return _barrier.run((activeLease) async {
      _ensure(ownerId, activeLease);
      final rows = await _isar.isarAyahNotes
          .filter()
          .ownerIdEqualTo(ownerId)
          .findAll();
      _ensure(ownerId, activeLease);
      final result = rows.map(_toDomain).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return result;
    }, authority: lease);
  }

  @override
  Future<AyahNote> upsert(int surahId, int ayahNumber, String body) async {
    AyahNotePolicy.checkReference(surahId, ayahNumber);
    AyahNotePolicy.checkBody(body);
    final ownerId = _owner.currentOwnerId;
    final lease = _barrier.capture();
    return _barrier.run((activeLease) async {
      _ensure(ownerId, activeLease);
      late IsarAyahNote saved;
      await _isar.writeTxn(() async {
        _ensure(ownerId, activeLease);
        final existing = await _isar.isarAyahNotes
            .filter()
            .ownerIdEqualTo(ownerId)
            .surahIdEqualTo(surahId)
            .ayahNumberEqualTo(ayahNumber)
            .findFirst();
        _ensure(ownerId, activeLease);
        final now = _clock().toUtc();
        final existingUpdatedAt = existing?.updatedAt.toUtc();
        final updatedAt =
            existingUpdatedAt != null && existingUpdatedAt.isAfter(now)
            ? existingUpdatedAt
            : now;
        saved = IsarAyahNote()
          ..id = existing?.id ?? Isar.autoIncrement
          ..ownerId = ownerId
          ..surahId = surahId
          ..ayahNumber = ayahNumber
          ..body = body
          ..createdAt = existing?.createdAt ?? now
          ..updatedAt = updatedAt;
        await _isar.isarAyahNotes.put(saved);
        _ensure(ownerId, activeLease);
      });
      _ensure(ownerId, activeLease);
      return _toDomain(saved);
    }, authority: lease);
  }

  @override
  Future<void> delete(int surahId, int ayahNumber) async {
    AyahNotePolicy.checkReference(surahId, ayahNumber);
    final ownerId = _owner.currentOwnerId;
    final lease = _barrier.capture();
    await _barrier.run((activeLease) async {
      _ensure(ownerId, activeLease);
      await _isar.writeTxn(() async {
        _ensure(ownerId, activeLease);
        final row = await _isar.isarAyahNotes
            .filter()
            .ownerIdEqualTo(ownerId)
            .surahIdEqualTo(surahId)
            .ayahNumberEqualTo(ayahNumber)
            .findFirst();
        _ensure(ownerId, activeLease);
        if (row != null) await _isar.isarAyahNotes.delete(row.id);
      });
      _ensure(ownerId, activeLease);
    }, authority: lease);
  }

  /// Moves guest (`local`) notes to the signed-in owner. An existing note of
  /// the owner for the same ayah is never replaced by an older guest note: the
  /// newer `updatedAt` wins. Losing guest rows are left untouched.
  @override
  Future<int> claimLocalNotes() async {
    final ownerId = _owner.currentOwnerId;
    if (ownerId == ReviewRecordIdentity.localOwnerId) return 0;
    final lease = _barrier.capture();
    return _barrier.run((activeLease) async {
      _ensure(ownerId, activeLease);
      var claimed = 0;
      await _isar.writeTxn(() async {
        _ensure(ownerId, activeLease);
        final locals = await _isar.isarAyahNotes
            .filter()
            .ownerIdEqualTo(ReviewRecordIdentity.localOwnerId)
            .findAll();
        for (final local in locals) {
          final existing = await _isar.isarAyahNotes
              .filter()
              .ownerIdEqualTo(ownerId)
              .surahIdEqualTo(local.surahId)
              .ayahNumberEqualTo(local.ayahNumber)
              .findFirst();
          if (existing == null) {
            local.ownerId = ownerId;
            await _isar.isarAyahNotes.put(local);
            claimed++;
          } else if (local.updatedAt.isAfter(existing.updatedAt)) {
            existing
              ..body = local.body
              ..updatedAt = local.updatedAt
              ..createdAt = local.createdAt.isBefore(existing.createdAt)
                  ? local.createdAt
                  : existing.createdAt;
            await _isar.isarAyahNotes.put(existing);
            await _isar.isarAyahNotes.delete(local.id);
            claimed++;
          }
        }
        _ensure(ownerId, activeLease);
      });
      _ensure(ownerId, activeLease);
      return claimed;
    }, authority: lease);
  }

  void _ensure(String ownerId, AccountDataLease lease) {
    lease.check();
    if (_owner.currentOwnerId != ownerId) {
      throw const AccountDataUnavailableException();
    }
  }

  static AyahNote _toDomain(IsarAyahNote row) => AyahNote(
    surahId: row.surahId,
    ayahNumber: row.ayahNumber,
    body: row.body,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );
}
