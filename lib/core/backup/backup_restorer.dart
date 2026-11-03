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
import '../../features/quran/data/models/isar_ayah_note.dart';
import '../../features/memorization_plus/data/models/isar_confusion_pair.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../services/app_session_service.dart';
import '../storage/data_admission.dart';
import '../progress/progress_changed_reason.dart';
import '../progress/progress_events_bus.dart';
import '../memorization/review_record_identity.dart';
import '../sync/cloud_sync_queue.dart';
import '../sync/cloud_sync_queue_item.dart';
import '../utils/talia_logger.dart';
import 'backup_file_format.dart';
import 'backup_sections.dart';
import 'in_memory_restore_journal_store.dart';
import 'portable_reading_backup_adapter.dart';
import 'portable_reading_data.dart';
import 'prayer_review_backup_mapper.dart';
import 'restore_isar_snapshot.dart';
import 'restore_operation_gate.dart';
import 'restore_preferences_snapshot.dart';
import 'restore_recovery_journal.dart';
import 'restore_store_rollbacks.dart';
import '../../features/prayer_review/data/models/isar_prayer_review_assignment.dart';
import '../../features/prayer_review/data/models/isar_prayer_review_receipt.dart';
import '../../features/quran/data/datasources/bookmark_service.dart';
import '../../features/quran/domain/entities/bookmark_entry.dart';

part 'backup_restore_transaction.dart';

enum BackupRestoreResult {
  restored,
  invalidSections,
  writeFailed,

  /// No durable rollback point could be stored (capacity, keystore, or an
  /// unfinished earlier restore), so nothing was changed.
  protectionUnavailable,

  /// A previous restore could not be recovered; restores stay disabled until
  /// the next startup recovery succeeds.
  recoveryBlocked,
}

class _OwnerChanged implements Exception {
  const _OwnerChanged();
}

class _RestoreAdmissionLost implements Exception {
  const _RestoreAdmissionLost();
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
    required this.notes,
    required this.confusionPairs,
    required this.prayerAssignments,
    required this.prayerReceipts,
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
  final List<IsarAyahNote> notes;
  final List<IsarConfusionPair> confusionPairs;
  final List<IsarPrayerReviewAssignment> prayerAssignments;
  final List<IsarPrayerReviewReceipt> prayerReceipts;
}

/// Replaces the current owner's backed-up data with a backup.
///
/// Every section is parsed and validated first; on any failure nothing is
/// written. The owner is read once at the start; that id is used for every
/// step, and a different current owner at any checkpoint aborts the restore.
///
/// The clear is restore-scoped (not `AccountDataReset`): only the backed-up
/// collections and this owner's state derived from them are replaced. The
/// parent PIN, Prayer Companion data, the activity feed, other
/// owners' rows, playback/resume state and device settings are untouched.
/// The device's PIN marker and guardian/child link state inside the parent
/// settings and memorization profile are kept (merged into the restored
/// values, or the device value left in place when the file lacks the key).
///
/// Version 5 adds missing bookmarks without reviving tombstones. Data absent
/// from older versions stays untouched. A verified journal precedes writes;
/// rollback failure or an ambiguous commit acknowledgement blocks recovery.
/// Production full replacement remains disabled until every writer, including
/// other isolates, is proven excluded from the restore transaction.
class BackupRestorer {
  BackupRestorer(
    this._isar,
    this._prefs,
    this._owner, {
    this._events,
    this._reading,
    this.fullReplacementAllowed = true,
    this.maintenancePermit,
    this.destinationIsSafe,
    RestoreRecoveryJournal? journal,
    RestoreOperationGate? gate,
  }) : _journal =
           journal ?? RestoreRecoveryJournal(InMemoryRestoreJournalStore()),
       _gate = gate ?? RestoreOperationGate(_owner);

  final Isar _isar;
  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final ProgressEventsBus? _events;

  /// Source of the v5 bookmark section. Without it bookmarks in a file are
  /// ignored and the device's are untouched.
  final PortableReadingBackupAdapter? _reading;
  final bool fullReplacementAllowed;
  final DataAdmissionPermit? maintenancePermit;
  final Future<bool> Function()? destinationIsSafe;

  /// Durable rollback point. Production passes one backed by the protected
  /// account store; the default is volatile (tests only).
  final RestoreRecoveryJournal _journal;
  final RestoreOperationGate _gate;

  /// Review pull bookkeeping that would skip rows the restore replaced.
  static const derivedPreferenceKeys = {
    'ayah_review_pull_cursor',
    'ayah_review_pull_cursor_pulled_at',
  };

  static const _khatmahOwnerKey = 'khatmah_owner';

  /// Queue kinds tied to the replaced review/production data. Bookmark,
  /// certificate, auth and kids work of this owner stays queued.
  static const replacedQueueKinds = restoreReplacedQueueKinds;

  /// Validates every section first (types, ranges, surah 1..114, ayah >= 1)
  /// and writes nothing on failure.
  Future<BackupRestoreResult> restore(BackupPayload p) async {
    if (!fullReplacementAllowed || !await _hasMaintenanceAdmission()) {
      return BackupRestoreResult.protectionUnavailable;
    }
    final ownerId = _owner.currentOwnerId;

    final ParsedBackupSections parsed;
    try {
      if (p.schemaVersion < 1 || p.schemaVersion > kBackupSchemaVersion) {
        throw const BackupSectionInvalid('schemaVersion');
      }
      parsed = ParsedBackupSections.parse(p.sections, ownerId, p.schemaVersion);
    } on BackupSectionInvalid catch (e) {
      TaliaLogger.w('Backup restore rejected: ${e.message}');
      return BackupRestoreResult.invalidSections;
    } catch (e, st) {
      TaliaLogger.w('Backup restore rejected', e, st);
      return BackupRestoreResult.invalidSections;
    }

    final List<BookmarkEntry> bookmarkEntries;
    if (p.schemaVersion >= 5 && _reading == null) {
      return BackupRestoreResult.protectionUnavailable;
    }
    try {
      bookmarkEntries = await _resolveBookmarks(p.schemaVersion, parsed);
    } on PortableReadingDataException catch (e) {
      TaliaLogger.w('Backup restore rejected: ${e.message}');
      return BackupRestoreResult.invalidSections;
    }

    try {
      _ensureOwner(ownerId);
      await _gate.run(
        expectedOwnerId: ownerId,
        operation: () =>
            _restoreStores(ownerId, parsed, p.schemaVersion, bookmarkEntries),
      );
    } on RestoreJournalRejected catch (e) {
      TaliaLogger.w('Backup restore refused: ${e.reason.name}');
      return BackupRestoreResult.protectionUnavailable;
    } on RestoreBlockedException catch (e) {
      TaliaLogger.w('Backup restore blocked: ${e.reason}');
      return BackupRestoreResult.recoveryBlocked;
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

  Future<bool> _hasMaintenanceAdmission() async =>
      maintenancePermit?.mode == DataAdmissionMode.maintenance &&
      await maintenancePermit!.validate() &&
      (destinationIsSafe == null || await destinationIsSafe!());

  Future<void> _ensureMaintenanceAdmission() async {
    if (!await _hasMaintenanceAdmission()) throw const _RestoreAdmissionLost();
  }

  Set<String> _touchedKeys(ParsedBackupSections parsed, String ownerId) => {
    ..._prefs.getKeys().where(
      (k) => BackupPreferencePolicy.backupKeyFor(k, ownerId) != null,
    ),
    ...parsed.prefs.keys,
    ...derivedPreferenceKeys,
    _khatmahOwnerKey,
    AppSessionService.quranCheckpointKeyFor(ownerId),
    ...?_reading?.checkpointKeysForOwner(ownerId),
  };

  Future<void> _replaceIsar(
    ParsedBackupSections parsed,
    String ownerId,
    int schemaVersion,
  ) async {
    // Data the file's version predates (notes, confusion pairs, prayer
    // reviews) is kept, never wiped by an older backup that cannot carry it.
    final carried = BackupSections.forVersion(schemaVersion);
    await _isar.writeTxn(() async {
      final snapshot = await _readScope(ownerId);
      await _clearScope(snapshot);
      await _isar.isarAyahReviewRecords.putAll(parsed.reviewRecords);
      await _isar.isarAyahProgress.putAll(parsed.ayahProgress);
      final streak = parsed.streak;
      if (streak != null) await _isar.streakIsars.put(streak);
      final xp = parsed.xp;
      if (xp != null) await _isar.xpIsars.put(xp);
      await _isar.dailyActivityIsars.putAll(parsed.dailyActivity);
      await _isar.isarAyahNotes.putAll(
        carried.contains(BackupSections.ayahNotes)
            ? parsed.ayahNotes
            : snapshot.notes,
      );
      await _isar.isarConfusionPairs.putAll(
        carried.contains(BackupSections.confusionPairs)
            ? parsed.confusionPairs
            : snapshot.confusionPairs,
      );
      await _isar.isarPrayerReviewAssignments.putAll(
        carried.contains(BackupSections.prayerReviewAssignments)
            ? parsed.prayerAssignments
            : snapshot.prayerAssignments,
      );
      await _isar.isarPrayerReviewReceipts.putAll(
        carried.contains(BackupSections.prayerReviewReceipts)
            ? _mergePrayerReceipts(
                parsed.prayerReceipts,
                snapshot.prayerReceipts,
              )
            : snapshot.prayerReceipts,
      );
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
  }

  /// Retain today's device fence even when importing an older backup. The
  /// first accepted device decision wins a conflicting imported decision.
  List<IsarPrayerReviewReceipt> _mergePrayerReceipts(
    List<IsarPrayerReviewReceipt> imported,
    List<IsarPrayerReviewReceipt> device,
  ) {
    final now = DateTime.now();
    final day =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final merged = {for (final row in imported) row.receiptKey: row};
    for (final row in device) {
      if (row.localDayKey != day) continue;
      // Reject a corrupt fence instead of silently reopening daily scheduling.
      PrayerReviewBackupMapper.receiptToJson(row);
      merged[row.receiptKey] = row;
    }
    return merged.values.toList();
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
        notes: await _isar.isarAyahNotes
            .filter()
            .ownerIdEqualTo(ownerId)
            .findAll(),
        confusionPairs: await _isar.isarConfusionPairs
            .filter()
            .ownerIdEqualTo(ownerId)
            .findAll(),
        prayerAssignments: await _isar.isarPrayerReviewAssignments
            .filter()
            .ownerIdEqualTo(ownerId)
            .findAll(),
        prayerReceipts: await _isar.isarPrayerReviewReceipts
            .filter()
            .ownerIdEqualTo(ownerId)
            .findAll(),
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
    await _isar.isarAyahNotes.deleteAll([for (final r in s.notes) r.id]);
    await _isar.isarConfusionPairs.deleteAll([
      for (final r in s.confusionPairs) r.id,
    ]);
    await _isar.isarPrayerReviewAssignments.deleteAll([
      for (final row in s.prayerAssignments) row.id,
    ]);
    await _isar.isarPrayerReviewReceipts.deleteAll([
      for (final row in s.prayerReceipts) row.id,
    ]);
  }

  Future<void> _replacePreferences(
    ParsedBackupSections parsed,
    String ownerId,
    AccountDataLease lease,
  ) async {
    // The device's PIN marker and guardian/child link state are never taken
    // from a file: read them before anything is removed.
    final deviceState = {
      for (final key in parsed.prefs.keys)
        if (BackupPreferencePolicy.keepsDeviceState(key))
          key: _deviceStateValue(key, ownerId),
    };
    final stale = [
      ..._prefs.getKeys().where(
        (k) =>
            BackupPreferencePolicy.backupKeyFor(k, ownerId) != null &&
            // A backup without these keeps the device's value.
            (parsed.prefs.containsKey(k) ||
                !BackupPreferencePolicy.keepsDeviceState(k)),
      ),
      ...derivedPreferenceKeys.where(_prefs.containsKey),
    ];
    for (final key in stale) {
      if (!await _prefs.remove(key)) {
        throw StateError('Failed to remove $key');
      }
    }

    for (final entry in parsed.prefs.entries) {
      final restored = entry.value;
      final value = restored is String && deviceState.containsKey(entry.key)
          ? BackupPreferencePolicy.mergeDeviceState(
              entry.key,
              restored,
              deviceState[entry.key],
            )
          : restored;
      if (!await _setTyped(entry.key, value)) {
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

    // Only a v5 file with a position carries one; otherwise the device keeps
    // its own.
    final checkpoint = parsed.readingCheckpoint;
    if (checkpoint != null) {
      final reading = _reading;
      if (reading == null) throw StateError('Checkpoint authority unavailable');
      await reading.writeCheckpoint(ownerId, checkpoint.pageNumber, lease);
    }
  }

  /// The device's current value of a [BackupPreferencePolicy.keepsDeviceState]
  /// key, read the way its owner reads it: the guest owner's parent settings
  /// fall back to the unscoped legacy key, which the restored scoped key
  /// would otherwise shadow.
  String? _deviceStateValue(String key, String ownerId) {
    try {
      final current = _prefs.getString(key);
      if (current != null) return current;
      final base = key.split('|').first;
      if (base != key && ownerId == ReviewRecordIdentity.localOwnerId) {
        return _prefs.getString(base);
      }
    } catch (e, st) {
      TaliaLogger.w('Backup restore: unreadable device value of $key', e, st);
    }
    return null;
  }

  Future<bool> _setTyped(String key, Object value) => switch (value) {
    final String v => _prefs.setString(key, v),
    final int v => _prefs.setInt(key, v),
    final double v => _prefs.setDouble(key, v),
    final bool v => _prefs.setBool(key, v),
    final List<String> v => _prefs.setStringList(key, v),
    _ => Future.value(false),
  };
}
