import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../../features/quran/data/models/isar_ayah_note.dart';
import '../../features/memorization_plus/data/models/isar_confusion_pair.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../memorization/review_record_identity.dart';
import '../utils/talia_logger.dart';
import 'backup_file_format.dart';
import 'backup_sections.dart';
import 'prayer_review_backup_mapper.dart';
import '../../features/prayer_review/data/models/isar_prayer_review_assignment.dart';
import '../../features/prayer_review/data/models/isar_prayer_review_receipt.dart';

/// Reads the current owner's local data into a [BackupPayload].
///
/// Owner ids never leave the device: keys and owner fields carry
/// [kBackupOwnerToken] instead, and data of any other owner is skipped.
class BackupCollector {
  BackupCollector(this._isar, this._prefs, this._owner);

  final Isar _isar;
  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;

  /// Runs inside the [AccountDataBarrier], so an account reset or owner
  /// switch cannot interleave with the reads: a reset queued meanwhile
  /// invalidates the lease and the collect throws
  /// [AccountDataUnavailableException] instead of returning a partial (yet
  /// validly checksummed) backup. Isar is read in one transaction for a
  /// consistent snapshot.
  Future<BackupPayload> collect(DateTime now) async {
    final ownerId = _owner.currentOwnerId;
    return AccountDataBarrier.forPreferences(_prefs).run((lease) async {
      _ensureOwner(ownerId);
      final rows = await _isar.txn(
        () async => (
          reviews: await _isar.isarAyahReviewRecords.where().findAll(),
          progress: await _isar.isarAyahProgress.where().findAll(),
          streak: await _isar.streakIsars.get(1),
          xp: await _isar.xpIsars.get(1),
          daily: await _isar.dailyActivityIsars.where().findAll(),
          notes: await _isar.isarAyahNotes
              .filter()
              .ownerIdEqualTo(ownerId)
              .findAll(),
          confusionPairs: await _isar.isarConfusionPairs
              .filter()
              .ownerIdEqualTo(ownerId)
              .findAll(),
          prayerAssignments: await _isar.isarPrayerReviewAssignments.filter().ownerIdEqualTo(ownerId).findAll(),
          prayerReceipts: await _isar.isarPrayerReviewReceipts.filter().ownerIdEqualTo(ownerId).findAll(),
        ),
      );
      lease.check();
      _ensureOwner(ownerId);
      final prefs = _preferences(ownerId);

      final payload = BackupPayload(
        schemaVersion: kBackupSchemaVersion,
        createdAt: now.toUtc(),
        sections: {
          BackupSections.reviewRecords: _reviews(rows.reviews, ownerId),
          BackupSections.ayahProgress: _valid('ayahProgress', [
            for (final p in rows.progress) AyahProgressBackupMapper.toJson(p),
          ], AyahProgressBackupMapper.fromJson),
          BackupSections.streak: _valid('streak', [
            if (rows.streak != null) StreakBackupMapper.toJson(rows.streak!),
          ], StreakBackupMapper.fromJson).firstOrNull,
          BackupSections.xp: _valid('xp', [
            if (rows.xp != null) XpBackupMapper.toJson(rows.xp!),
          ], XpBackupMapper.fromJson).firstOrNull,
          BackupSections.dailyActivity: _valid('dailyActivity', [
            for (final d in rows.daily) DailyActivityBackupMapper.toJson(d),
          ], DailyActivityBackupMapper.fromJson),
          BackupSections.ayahNotes: _notes(rows.notes, ownerId),
          BackupSections.confusionPairs: _confusionPairs(
            rows.confusionPairs,
            ownerId,
          ),
          BackupSections.prefs: prefs,
          BackupSections.prayerReviewAssignments: _prayerRows(rows.prayerAssignments, PrayerReviewBackupMapper.assignmentToJson),
          BackupSections.prayerReviewReceipts: _prayerRows(rows.prayerReceipts, PrayerReviewBackupMapper.receiptToJson),
        },
      );
      lease.check();
      _ensureOwner(ownerId);
      return payload;
    });
  }

  List<Map<String, Object?>> _prayerRows<T>(List<T> rows, Map<String, Object?> Function(T) encode) {
    try {
      return [for (final row in rows) encode(row)];
    } on FormatException {
      throw StateError('A local prayer review row cannot be backed up');
    }
  }

  List<Map<String, Object?>> _confusionPairs(
    List<IsarConfusionPair> pairs,
    String ownerId,
  ) {
    final encoded = <Map<String, Object?>>[];
    for (final pair in pairs) {
      try {
        final json = ConfusionPairBackupMapper.toJson(pair);
        ConfusionPairBackupMapper.fromJson(json, ownerId);
        encoded.add(json);
      } on BackupSectionInvalid {
        throw StateError('A local confusion pair cannot be backed up');
      }
    }
    return encoded;
  }

  List<Map<String, Object?>> _notes(List<IsarAyahNote> notes, String ownerId) {
    final encoded = <Map<String, Object?>>[];
    for (final note in notes) {
      try {
        final json = AyahNoteBackupMapper.toJson(note);
        AyahNoteBackupMapper.fromJson(json, ownerId);
        encoded.add(json);
      } on BackupSectionInvalid {
        throw StateError('A local note cannot be backed up');
      }
    }
    return encoded;
  }

  void _ensureOwner(String ownerId) {
    if (_owner.currentOwnerId != ownerId) {
      throw const AccountDataUnavailableException();
    }
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
      final raw = _prefs.get(key);
      final sanitized = raw == null
          ? null
          : BackupPreferencePolicy.sanitize(backupKey, raw);
      if (sanitized == null) continue;
      final value = BackupPreferencePolicy.dropInvalidListItems(
        backupKey,
        sanitized,
      );
      // A value the restorer would reject is skipped, so one corrupt local
      // value can never make the whole backup unrestorable.
      try {
        BackupPreferencePolicy.validate(backupKey, value);
      } on BackupSectionInvalid catch (e) {
        TaliaLogger.w('Backup skipped an invalid preference: ${e.message}');
        continue;
      }
      final encoded = BackupPreferencePolicy.encodeValue(value);
      if (encoded != null) out[backupKey] = encoded;
    }
    return out;
  }
}
