import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../identity/record_owner_provider.dart';
import '../memorization/review_record_identity.dart';
import '../utils/talia_logger.dart';
import 'backup_file_format.dart';
import 'backup_sections.dart';

/// Reads the current owner's local data into a [BackupPayload].
///
/// Owner ids never leave the device: keys and owner fields carry
/// [kBackupOwnerToken] instead, and data of any other owner is skipped.
class BackupCollector {
  BackupCollector(this._isar, this._prefs, this._owner);

  final Isar _isar;
  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  Future<BackupPayload> collect(DateTime now) async {
    final ownerId = _owner.currentOwnerId;

    final reviewRows = await _isar.isarAyahReviewRecords.where().findAll();
    final progressRows = await _isar.isarAyahProgress.where().findAll();
    final streak = await _isar.streakIsars.get(1);
    final xp = await _isar.xpIsars.get(1);
    final dailyRows = await _isar.dailyActivityIsars.where().findAll();

    return BackupPayload(
      schemaVersion: kBackupSchemaVersion,
      createdAt: now.toUtc(),
      sections: {
        BackupSections.reviewRecords: _reviews(reviewRows, ownerId),
        BackupSections.ayahProgress: _valid('ayahProgress', [
          for (final p in progressRows) AyahProgressBackupMapper.toJson(p),
        ], AyahProgressBackupMapper.fromJson),
        BackupSections.streak: _valid('streak', [
          if (streak != null) StreakBackupMapper.toJson(streak),
        ], StreakBackupMapper.fromJson).firstOrNull,
        BackupSections.xp: _valid('xp', [
          if (xp != null) XpBackupMapper.toJson(xp),
        ], XpBackupMapper.fromJson).firstOrNull,
        BackupSections.dailyActivity: _valid('dailyActivity', [
          for (final d in dailyRows) DailyActivityBackupMapper.toJson(d),
        ], DailyActivityBackupMapper.fromJson),
        BackupSections.prefs: _preferences(ownerId),
      },
    );
  }

  /// Current-owner rows. Identity-keyed rows win over a legacy (pre-identity)
  /// row that maps to the same identity.
  List<Map<String, Object?>> _reviews(
    List<IsarAyahReviewRecord> rows,
    String ownerId,
  ) {
    final byKey = <String, Map<String, Object?>>{};
    final legacy = <String, Map<String, Object?>>{};
    for (final row in rows) {
      final audience = ReviewRecordBackupMapper.audienceFor(row, ownerId);
      if (audience == null) continue;
      final key = ReviewRecordIdentity(
        ownerUserId: ownerId,
        audience: audience,
        surahId: row.surahId,
        ayahNumber: row.ayahNumber,
      ).storageKey;
      final json = ReviewRecordBackupMapper.toJson(row, audience);
      if (!_restorable(
        'reviewRecords',
        json,
        (j) => ReviewRecordBackupMapper.fromJson(j, ownerId),
      )) {
        continue;
      }
      if (ReviewRecordIdentity.tryParse(row.compositeKey) != null) {
        byKey[key] = json;
      } else {
        legacy.putIfAbsent(key, () => json);
      }
    }
    for (final entry in legacy.entries) {
      byKey.putIfAbsent(entry.key, () => entry.value);
    }
    final keys = byKey.keys.toList()..sort();
    return [for (final k in keys) byKey[k]!];
  }

  /// Drops rows the restorer would reject (e.g. a corrupt surah id), so one
  /// bad local row can never make the whole backup unrestorable.
  List<Map<String, Object?>> _valid(
    String section,
    List<Map<String, Object?>> rows,
    Object? Function(Object? json) parse,
  ) => [
    for (final row in rows)
      if (_restorable(section, row, parse)) row,
  ];

  bool _restorable(
    String section,
    Map<String, Object?> json,
    Object? Function(Object? json) parse,
  ) {
    try {
      parse(json);
      return true;
    } on BackupSectionInvalid catch (e) {
      TaliaLogger.w('Backup skipped an invalid $section row: ${e.message}');
      return false;
    }
  }

  Map<String, Object?> _preferences(String ownerId) {
    final out = <String, Object?>{};
    for (final key in _prefs.getKeys()) {
      final backupKey = BackupPreferencePolicy.backupKeyFor(key, ownerId);
      if (backupKey == null) continue;
      final encoded = BackupPreferencePolicy.encodeValue(_prefs.get(key));
      if (encoded != null) out[backupKey] = encoded;
    }
    return out;
  }
}
