import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import '../../features/memorization_plus/data/models/isar_review_evidence_event.dart';
import '../../features/memorization_plus/data/models/isar_v2_session.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../progress/progress_changed_reason.dart';
import '../progress/progress_events_bus.dart';
import '../memorization/review_record_identity.dart';
import '../sync/cloud_sync_queue.dart';
import '../sync/cloud_sync_queue_item.dart';
import '../utils/talia_logger.dart';
import 'backup_file_format.dart';
import 'backup_sections.dart';

enum BackupRestoreResult { restored, invalidSections, writeFailed }

class _OwnerChanged implements Exception {
  const _OwnerChanged();
}

/// The Isar rows a restore replaces, kept so a failed restore can put them
/// back.
class _IsarScopeSnapshot {
  _IsarScopeSnapshot({
    required this.reviews,
    required this.progress,
    required this.streaks,
    required this.xps,
    required this.daily,
    required this.sessions,
    required this.evidence,
    required this.outbox,
    required this.queue,
  });

  final List<IsarAyahReviewRecord> reviews;
  final List<IsarAyahProgress> progress;
  final List<StreakIsar> streaks;
  final List<XpIsar> xps;
  final List<DailyActivityIsar> daily;
  final List<IsarV2Session> sessions;
  final List<IsarReviewEvidenceEvent> evidence;
  final List<IsarReviewEffectOutbox> outbox;
  final List<CloudSyncQueueItem> queue;
}

/// Replaces the current owner's backed-up data with a backup.
///
/// Every section is parsed and validated first; on any failure nothing is
/// written. The owner is read once at the start; that id is used for every
/// step, and a different current owner at any checkpoint aborts the restore.
///
/// The clear is restore-scoped (not `AccountDataReset`): only the backed-up
/// collections and this owner's state derived from them are replaced. The
/// parent PIN, bookmarks, Prayer Companion data, the activity feed, other
/// owners' rows, playback/resume state and device settings are untouched.
///
/// Isar is replaced in one transaction. If anything fails after it, the
/// result is [BackupRestoreResult.writeFailed]; while the owner is unchanged
/// the replaced Isar rows and touched preferences are put back best-effort
/// inside the barrier work (before any reset or writer queued behind it).
/// After an owner switch nothing is put back: the switch's reset cleans up.
class BackupRestorer {
  BackupRestorer(this._isar, this._prefs, this._owner, {this._events});

  final Isar _isar;
  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final ProgressEventsBus? _events;

  /// Review pull bookkeeping that would skip rows the restore replaced.
  static const derivedPreferenceKeys = {
    'ayah_review_pull_cursor',
    'ayah_review_pull_cursor_pulled_at',
  };

  static const _khatmahOwnerKey = 'khatmah_owner';

  /// Queue kinds tied to the replaced review/production data. Bookmark,
  /// certificate, auth and kids work of this owner stays queued.
  static const replacedQueueKinds = {
    CloudSyncQueueKind.productionPull,
    CloudSyncQueueKind.productionPush,
    CloudSyncQueueKind.reviewEvidencePull,
    CloudSyncQueueKind.reviewEvidencePush,
  };

  /// Validates every section first (types, ranges, surah 1..114, ayah >= 1)
  /// and writes nothing on failure.
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
      _ensureOwner(ownerId);
      await AccountDataBarrier.forPreferences(_prefs).run((lease) async {
        Map<String, Object?>? prefsSnapshot;
        _IsarScopeSnapshot? isarSnapshot;
        try {
          _ensureOwner(ownerId);
          prefsSnapshot = _snapshotPreferences(parsed, ownerId);
          isarSnapshot = await _replaceIsar(parsed, ownerId);
          _ensureOwner(ownerId);
          lease.check();
          await _replacePreferences(parsed, ownerId);
          _ensureOwner(ownerId);
        } catch (_) {
          // Rolled back inside the barrier work, so it completes before any
          // reset queued behind this restore. After an owner switch there is
          // no rollback: putting the previous owner's unscoped data back
          // would hand it to the new account, and the switch's queued reset
          // owns the cleanup.
          if (_owner.currentOwnerId == ownerId) {
            await _rollback(ownerId, prefsSnapshot, isarSnapshot);
          }
          rethrow;
        }
      });
    } catch (e, st) {
      // Also reached when the work succeeded but the final lease check failed
      // (owner switch or reset queued meanwhile): no rollback then either.
      TaliaLogger.e('Backup restore failed while writing', e, st);
      _events?.notify(ProgressChangedReason.cloudPull);
      return BackupRestoreResult.writeFailed;
    }

    // `cloudPull` refreshes every progress listener (review, streak, XP,
    // kids, plans, certificates) without scheduling an immediate cloud push;
    // restored rows are dirty and upload with the next regular sync.
    _events?.notify(ProgressChangedReason.cloudPull);
    return BackupRestoreResult.restored;
  }

  void _ensureOwner(String ownerId) {
    if (_owner.currentOwnerId != ownerId) throw const _OwnerChanged();
  }

  Set<String> _touchedKeys(ParsedBackupSections parsed, String ownerId) => {
    ..._prefs.getKeys().where(
      (k) => BackupPreferencePolicy.backupKeyFor(k, ownerId) != null,
    ),
    ...parsed.prefs.keys,
    ...derivedPreferenceKeys,
    _khatmahOwnerKey,
  };

  Map<String, Object?> _snapshotPreferences(
    ParsedBackupSections parsed,
    String ownerId,
  ) {
    final snapshot = <String, Object?>{};
    for (final key in _touchedKeys(parsed, ownerId)) {
      final value = _prefs.get(key);
      snapshot[key] = value is List ? List<String>.of(value.cast()) : value;
    }
    return snapshot;
  }

  Future<_IsarScopeSnapshot> _replaceIsar(
    ParsedBackupSections parsed,
    String ownerId,
  ) async {
    late _IsarScopeSnapshot snapshot;
    await _isar.writeTxn(() async {
      snapshot = await _readScope(ownerId);
      await _clearScope(snapshot);
      await _isar.isarAyahReviewRecords.putAll(parsed.reviewRecords);
      await _isar.isarAyahProgress.putAll(parsed.ayahProgress);
      final streak = parsed.streak;
      if (streak != null) await _isar.streakIsars.put(streak);
      final xp = parsed.xp;
      if (xp != null) await _isar.xpIsars.put(xp);
      await _isar.dailyActivityIsars.putAll(parsed.dailyActivity);
      // Restored rows are dirty; queue their upload like a local write would
      // (`CloudSyncQueue.enqueue` never queues for the local owner).
      if (ownerId != ReviewRecordIdentity.localOwnerId) {
        final now = DateTime.now().toUtc();
        await _isar.cloudSyncQueueItems.put(
          CloudSyncQueueItem()
            ..kind = CloudSyncQueueKind.productionPush
            ..ownerUserId = ownerId
            ..attemptCount = 0
            ..nextRetryAt = now
            ..createdAt = now,
        );
      }
    });
    return snapshot;
  }

  /// Rows the restore replaces: this owner's (and legacy null-owner) review
  /// rows and V2 sessions, this owner's evidence, outbox and review/production
  /// queue items, and the unscoped single-profile collections in full. A
  /// null-owner review row whose identity key names another owner is not
  /// this owner's (collect skips it too) and is kept.
  Future<_IsarScopeSnapshot> _readScope(String ownerId) async =>
      _IsarScopeSnapshot(
        reviews: [
          for (final row
              in await _isar.isarAyahReviewRecords
                  .filter()
                  .group(
                    (q) =>
                        q.ownerUserIdEqualTo(ownerId).or().ownerUserIdIsNull(),
                  )
                  .findAll())
            if (row.ownerUserId != null ||
                (ReviewRecordIdentity.tryParse(row.compositeKey)?.ownerUserId ??
                        ownerId) ==
                    ownerId)
              row,
        ],
        progress: await _isar.isarAyahProgress.where().findAll(),
        streaks: await _isar.streakIsars.where().findAll(),
        xps: await _isar.xpIsars.where().findAll(),
        daily: await _isar.dailyActivityIsars.where().findAll(),
        sessions: await _isar.isarV2Sessions
            .filter()
            .group((q) => q.ownerIdEqualTo(ownerId).or().ownerIdIsNull())
            .findAll(),
        evidence: await _isar.isarReviewEvidenceEvents
            .filter()
            .ownerIdEqualTo(ownerId)
            .findAll(),
        outbox: await _isar.isarReviewEffectOutboxs
            .filter()
            .ownerIdEqualTo(ownerId)
            .findAll(),
        queue: [
          for (final item
              in await _isar.cloudSyncQueueItems
                  .filter()
                  .ownerUserIdEqualTo(ownerId)
                  .findAll())
            if (replacedQueueKinds.contains(item.kind)) item,
        ],
      );

  Future<void> _clearScope(_IsarScopeSnapshot s) async {
    await _isar.isarAyahReviewRecords.deleteAll([
      for (final r in s.reviews) r.id,
    ]);
    await _isar.isarAyahProgress.clear();
    await _isar.streakIsars.clear();
    await _isar.xpIsars.clear();
    await _isar.dailyActivityIsars.clear();
    await _isar.isarV2Sessions.deleteAll([for (final r in s.sessions) r.id]);
    await _isar.isarReviewEvidenceEvents.deleteAll([
      for (final r in s.evidence) r.id,
    ]);
    await _isar.isarReviewEffectOutboxs.deleteAll([
      for (final r in s.outbox) r.id,
    ]);
    await _isar.cloudSyncQueueItems.deleteAll([for (final r in s.queue) r.id]);
  }

  Future<void> _replacePreferences(
    ParsedBackupSections parsed,
    String ownerId,
  ) async {
    final stale = [
      ..._prefs.getKeys().where(
        (k) => BackupPreferencePolicy.backupKeyFor(k, ownerId) != null,
      ),
      ...derivedPreferenceKeys.where(_prefs.containsKey),
    ];
    for (final key in stale) {
      if (!await _prefs.remove(key)) {
        throw StateError('Failed to remove $key');
      }
    }

    for (final entry in parsed.prefs.entries) {
      if (!await _setTyped(entry.key, entry.value)) {
        throw StateError('Failed to write ${entry.key}');
      }
    }

    // The barrier attributes restored Khatmah data to its owner, the same
    // marker `AccountDataBarrier.stampOwner` writes.
    if (parsed.prefs.containsKey('khatmah_active_plan') ||
        parsed.prefs.containsKey('khatmah_history')) {
      if (!await _prefs.setString(_khatmahOwnerKey, ownerId)) {
        throw StateError('Failed to write $_khatmahOwnerKey');
      }
    }
  }

  Future<bool> _setTyped(String key, Object value) => switch (value) {
    final String v => _prefs.setString(key, v),
    final int v => _prefs.setInt(key, v),
    final double v => _prefs.setDouble(key, v),
    final bool v => _prefs.setBool(key, v),
    final List<String> v => _prefs.setStringList(key, v),
    _ => Future.value(false),
  };

  /// Best effort: every step runs even if an earlier one fails.
  Future<void> _rollback(
    String ownerId,
    Map<String, Object?>? prefsSnapshot,
    _IsarScopeSnapshot? isarSnapshot,
  ) async {
    if (isarSnapshot != null) {
      try {
        await _isar.writeTxn(() async {
          await _clearScope(await _readScope(ownerId));
          await _isar.isarAyahReviewRecords.putAll(isarSnapshot.reviews);
          await _isar.isarAyahProgress.putAll(isarSnapshot.progress);
          await _isar.streakIsars.putAll(isarSnapshot.streaks);
          await _isar.xpIsars.putAll(isarSnapshot.xps);
          await _isar.dailyActivityIsars.putAll(isarSnapshot.daily);
          await _isar.isarV2Sessions.putAll(isarSnapshot.sessions);
          await _isar.isarReviewEvidenceEvents.putAll(isarSnapshot.evidence);
          await _isar.isarReviewEffectOutboxs.putAll(isarSnapshot.outbox);
          await _isar.cloudSyncQueueItems.putAll(isarSnapshot.queue);
        });
      } catch (e, st) {
        TaliaLogger.e('Backup restore rollback of Isar failed', e, st);
      }
    }
    if (prefsSnapshot != null) {
      for (final entry in prefsSnapshot.entries) {
        try {
          final value = entry.value;
          if (value == null) {
            if (_prefs.containsKey(entry.key)) await _prefs.remove(entry.key);
          } else if (_prefs.get(entry.key) != value || value is List) {
            await _setTyped(entry.key, value);
          }
        } catch (e, st) {
          TaliaLogger.e(
            'Backup restore rollback of ${entry.key} failed',
            e,
            st,
          );
        }
      }
    }
  }
}
