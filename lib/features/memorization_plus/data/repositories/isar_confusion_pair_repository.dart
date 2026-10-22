import 'package:isar_community/isar.dart';

import '../../../../core/constants/surah_names.dart';
import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/entities/confusion_pair.dart';
import '../models/isar_confusion_pair.dart';

/// Reads aggregates scoped to the active adult owner.
class IsarConfusionPairRepository {
  IsarConfusionPairRepository(this._isar, this._owner, this._barrier);

  final Isar _isar;
  final RecordOwnerProvider _owner;
  final AccountDataBarrier _barrier;

  Future<List<ConfusionPair>> list() async {
    final ownerId = _owner.currentOwnerId;
    final authority = _barrier.capture();
    return _barrier.run((lease) async {
      _ensure(ownerId, lease);
      final rows = await _isar.isarConfusionPairs
          .filter()
          .ownerIdEqualTo(ownerId)
          .audienceEqualTo(IsarConfusionPair.adultAudience)
          .findAll();
      _ensure(ownerId, lease);
      // One corrupt row is skipped, never the whole list.
      final pairs = [for (final row in rows) ?_tryToDomain(row)]
        ..sort((a, b) {
          final count = b.count.compareTo(a.count);
          if (count != 0) return count;
          final date = b.lastAt.compareTo(a.lastAt);
          if (date != 0) return date;
          final targetSurah = a.targetSurahId.compareTo(b.targetSurahId);
          if (targetSurah != 0) return targetSurah;
          final targetAyah = a.targetAyahNumber.compareTo(b.targetAyahNumber);
          if (targetAyah != 0) return targetAyah;
          final otherSurah = a.otherSurahId.compareTo(b.otherSurahId);
          return otherSurah != 0
              ? otherSurah
              : a.otherAyahNumber.compareTo(b.otherAyahNumber);
        });
      return pairs;
    }, authority: authority);
  }

  static ConfusionPair? _tryToDomain(IsarConfusionPair row) {
    try {
      return _toDomain(row);
    } on FormatException {
      return null;
    }
  }

  static ConfusionPair _toDomain(IsarConfusionPair row) {
    if (row.audience != IsarConfusionPair.adultAudience ||
        row.count < 1 ||
        row.count > ConfusionPairTransactionWriter.maxCount ||
        row.lastAt.isBefore(row.firstAt)) {
      throw const FormatException('Invalid confusion pair');
    }
    final target = _parseKey(row.targetKey);
    final other = _parseKey(row.otherKey);
    if (target == other) throw const FormatException('Invalid confusion pair');
    return ConfusionPair(
      targetSurahId: target.$1,
      targetAyahNumber: target.$2,
      otherSurahId: other.$1,
      otherAyahNumber: other.$2,
      count: row.count,
      firstAt: row.firstAt.toUtc(),
      lastAt: row.lastAt.toUtc(),
    );
  }

  static (int, int) _parseKey(String value) {
    final parts = value.split(':');
    if (parts.length != 2) throw const FormatException('Invalid ayah key');
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null || value != '$surah:$ayah') {
      throw const FormatException('Invalid ayah key');
    }
    ConfusionPairTransactionWriter.checkAyah(surah, ayah);
    return (surah, ayah);
  }

  void _ensure(String ownerId, AccountDataLease lease) {
    lease.check();
    if (_owner.currentOwnerId != ownerId) {
      throw const AccountDataUnavailableException();
    }
  }
}

/// Internal transaction helper for the existing deduplicated failure commit.
/// The caller owns both the active Isar transaction and the captured lease.
abstract final class ConfusionPairTransactionWriter {
  static const maxCount = 2147483647;

  static Future<void> record(
    Isar isar, {
    required String ownerId,
    required AccountDataLease lease,
    required int targetSurahId,
    required int targetAyahNumber,
    required int otherSurahId,
    required int otherAyahNumber,
    required DateTime occurredAt,
  }) async {
    _check(ownerId, lease);
    checkAyah(targetSurahId, targetAyahNumber);
    checkAyah(otherSurahId, otherAyahNumber);
    if (targetSurahId == otherSurahId && targetAyahNumber == otherAyahNumber) {
      throw const FormatException('Confusion pair cannot reference itself');
    }
    final targetKey = _key(targetSurahId, targetAyahNumber);
    final otherKey = _key(otherSurahId, otherAyahNumber);
    final existing = await isar.isarConfusionPairs
        .filter()
        .ownerIdEqualTo(ownerId)
        .targetKeyEqualTo(targetKey)
        .otherKeyEqualTo(otherKey)
        .findFirst();
    _check(ownerId, lease);
    final at = occurredAt.toUtc();
    final row = existing ?? _newRow(ownerId, targetKey, otherKey, at);
    if (row.audience != IsarConfusionPair.adultAudience ||
        (existing != null && row.count < 1) ||
        row.count >= maxCount ||
        row.lastAt.isBefore(row.firstAt) ||
        _parseExistingKey(row.targetKey) != targetKey ||
        _parseExistingKey(row.otherKey) != otherKey) {
      throw const FormatException('Invalid confusion pair');
    }
    row
      ..count += 1
      ..firstAt = row.firstAt.isAfter(at) ? at : row.firstAt.toUtc()
      ..lastAt = row.lastAt.isAfter(at) ? row.lastAt.toUtc() : at;
    await isar.isarConfusionPairs.put(row);
    _check(ownerId, lease);
  }

  static void checkAyah(int surahId, int ayahNumber) {
    if (surahId < 1 ||
        surahId > 114 ||
        ayahNumber < 1 ||
        ayahNumber > SurahNames.ayahCount(surahId)) {
      throw const FormatException('Invalid ayah reference');
    }
  }

  static String _key(int surahId, int ayahNumber) => '$surahId:$ayahNumber';

  static String _parseExistingKey(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid confusion pair');
    }
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null || value != '$surah:$ayah') {
      throw const FormatException('Invalid confusion pair');
    }
    checkAyah(surah, ayah);
    return value;
  }

  static IsarConfusionPair _newRow(
    String ownerId,
    String targetKey,
    String otherKey,
    DateTime at,
  ) => IsarConfusionPair()
    ..ownerId = ownerId
    ..audience = IsarConfusionPair.adultAudience
    ..targetKey = targetKey
    ..otherKey = otherKey
    ..count = 0
    ..firstAt = at
    ..lastAt = at;

  static void _check(String ownerId, AccountDataLease lease) {
    if (ownerId.isEmpty) throw const FormatException('Invalid owner');
    lease.checkOwner(ownerId);
  }
}
