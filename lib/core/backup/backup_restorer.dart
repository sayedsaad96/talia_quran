import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../identity/account_data_barrier.dart';
import '../identity/account_data_reset.dart';
import '../identity/record_owner_provider.dart';
import '../progress/progress_changed_reason.dart';
import '../progress/progress_events_bus.dart';
import '../utils/talia_logger.dart';
import 'backup_file_format.dart';
import 'backup_sections.dart';

enum BackupRestoreResult { restored, invalidSections, writeFailed }

/// Replaces the current owner's local data with a backup.
///
/// Every section is parsed and validated first; on any failure nothing is
/// written (not even the reset). Then the account data is reset, Isar is
/// written in one transaction, and the preferences are written. The owner is
/// read once at the start and used for every step.
class BackupRestorer {
  BackupRestorer(
    this._isar,
    this._prefs,
    this._owner,
    this._reset, {
    this._events,
  });

  final Isar _isar;
  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final AccountDataReset _reset;
  final ProgressEventsBus? _events;

  /// Validates every section first (types, ranges, surah 1..114, ayah >= 1)
  /// and writes nothing on failure.
  /// Then: reset.clearAccountOwnedData() → write Isar in one writeTxn → write
  /// prefs.
  Future<BackupRestoreResult> restore(BackupPayload p) async {
    final ownerId = _owner.currentOwnerId;

    final ParsedBackupSections parsed;
    try {
      if (p.schemaVersion < 1 || p.schemaVersion > kBackupSchemaVersion) {
        throw const BackupSectionInvalid('schemaVersion');
      }
      parsed = ParsedBackupSections.parse(p.sections, ownerId);
    } on BackupSectionInvalid catch (e) {
      TaliaLogger.w('Backup restore rejected: ${e.message}');
      return BackupRestoreResult.invalidSections;
    } catch (e, st) {
      TaliaLogger.w('Backup restore rejected', e, st);
      return BackupRestoreResult.invalidSections;
    }

    try {
      await _reset.clearAccountOwnedData(departingOwnerId: ownerId);
      // Serialized behind any account-data write accepted before the reset;
      // an owner switch during the write fails the lease instead of landing
      // this owner's data under the next account.
      await AccountDataBarrier.forPreferences(
        _prefs,
      ).run((_) => _write(parsed, ownerId));
    } catch (e, st) {
      TaliaLogger.e('Backup restore failed while writing', e, st);
      return BackupRestoreResult.writeFailed;
    }

    // `cloudPull` refreshes every progress listener (review, streak, XP,
    // kids, plans, certificates) without scheduling an immediate cloud push;
    // restored rows are dirty and upload with the next regular sync.
    _events?.notify(ProgressChangedReason.cloudPull);
    return BackupRestoreResult.restored;
  }

  Future<void> _write(ParsedBackupSections parsed, String ownerId) async {
    await _isar.writeTxn(() async {
      // The reset already emptied these; clearing again keeps "replace"
      // exact even if a writer slipped in between reset and this lease.
      await _isar.isarAyahReviewRecords.clear();
      await _isar.isarAyahProgress.clear();
      await _isar.streakIsars.clear();
      await _isar.xpIsars.clear();
      await _isar.dailyActivityIsars.clear();
      await _isar.isarAyahReviewRecords.putAll(parsed.reviewRecords);
      await _isar.isarAyahProgress.putAll(parsed.ayahProgress);
      final streak = parsed.streak;
      if (streak != null) await _isar.streakIsars.put(streak);
      final xp = parsed.xp;
      if (xp != null) await _isar.xpIsars.put(xp);
      await _isar.dailyActivityIsars.putAll(parsed.dailyActivity);
    });

    // Allowlisted keys the reset does not own (e.g. azkar counters) are
    // replaced too.
    final stale = _prefs
        .getKeys()
        .where((k) => BackupPreferencePolicy.backupKeyFor(k, ownerId) != null)
        .toList();
    for (final key in stale) {
      if (!await _prefs.remove(key)) {
        throw StateError('Failed to remove $key');
      }
    }

    for (final entry in parsed.prefs.entries) {
      final ok = switch (entry.value) {
        final String v => await _prefs.setString(entry.key, v),
        final int v => await _prefs.setInt(entry.key, v),
        final double v => await _prefs.setDouble(entry.key, v),
        final bool v => await _prefs.setBool(entry.key, v),
        final List<String> v => await _prefs.setStringList(entry.key, v),
        _ => false,
      };
      if (!ok) throw StateError('Failed to write ${entry.key}');
    }

    // The barrier attributes restored Khatmah data to its owner, the same
    // marker `AccountDataBarrier.stampOwner` writes.
    if (parsed.prefs.containsKey('khatmah_active_plan') ||
        parsed.prefs.containsKey('khatmah_history')) {
      if (!await _prefs.setString('khatmah_owner', ownerId)) {
        throw StateError('Failed to write khatmah_owner');
      }
    }
  }
}
