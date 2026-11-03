import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/memorization_plus/data/models/isar_confusion_pair.dart';
import '../../features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import '../../features/memorization_plus/data/models/isar_review_evidence_event.dart';
import '../../features/memorization_plus/data/models/isar_v2_session.dart';
import '../../features/prayer_review/data/models/isar_prayer_review_assignment.dart';
import '../../features/prayer_review/data/models/isar_prayer_review_receipt.dart';
import '../../features/quran/data/models/isar_ayah_note.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../memorization/review_record_identity.dart';
import '../sync/cloud_sync_queue.dart';
import '../sync/cloud_sync_queue_item.dart';

/// Queue kinds tied to the replaced review/production data. Bookmark,
/// certificate, auth and kids work of the owner stays queued.
const restoreReplacedQueueKinds = {
  CloudSyncQueueKind.productionPull,
  CloudSyncQueueKind.productionPush,
  CloudSyncQueueKind.reviewEvidencePull,
  CloudSyncQueueKind.reviewEvidencePush,
};

typedef _Rows = List<Map<String, dynamic>>;

/// Lossless JSON snapshot of the Isar rows a restore replaces, and the
/// matching rollback. Exporting through Isar keeps every field (including
/// sync flags and tombstones) without a hand-written mapper, so a snapshot can
/// hold evidence that never enters a backup file.
///
/// The scope is the owner's review rows (and legacy null-owner rows that are
/// not another owner's), V2 sessions, evidence, outbox, review/production
/// queue items, notes, confusion pairs and prayer review rows, plus the
/// unscoped single-profile collections in full.
class RestoreIsarSnapshot {
  const RestoreIsarSnapshot(this._isar);

  final Isar _isar;

  /// Reads the scope in one transaction and encodes it.
  Future<String> capture(String ownerId) async =>
      jsonEncode(await _isar.txn(() => _export(ownerId)));

  /// Replaces the current scope with [snapshot]. Idempotent.
  Future<void> rollback(String ownerId, String snapshot) async {
    final decoded = jsonDecode(snapshot);
    if (decoded is! Map) {
      throw const FormatException('Isar snapshot is not an object');
    }
    final rows = <String, _Rows>{
      for (final entry in decoded.entries)
        entry.key as String: [
          for (final row in entry.value as List)
            Map<String, dynamic>.from(row as Map),
        ],
    };
    await _isar.writeTxn(() async {
      final current = await _export(ownerId);
      await _deleteRows(current);
      await _importRows(rows);
    });
  }

  Future<Map<String, _Rows>> _export(String ownerId) async => {
    'reviews': _reviewsOf(
      ownerId,
      await _isar.isarAyahReviewRecords
          .filter()
          .group((q) => q.ownerUserIdEqualTo(ownerId).or().ownerUserIdIsNull())
          .exportJson(),
    ),
    'progress': await _isar.isarAyahProgress.where().exportJson(),
    'streak': await _isar.streakIsars.where().exportJson(),
    'xp': await _isar.xpIsars.where().exportJson(),
    'daily': await _isar.dailyActivityIsars.where().exportJson(),
    'sessions': await _isar.isarV2Sessions
        .filter()
        .group((q) => q.ownerIdEqualTo(ownerId).or().ownerIdIsNull())
        .exportJson(),
    'evidence': await _isar.isarReviewEvidenceEvents
        .filter()
        .ownerIdEqualTo(ownerId)
        .exportJson(),
    'outbox': await _isar.isarReviewEffectOutboxs
        .filter()
        .ownerIdEqualTo(ownerId)
        .exportJson(),
    'queue': [
      for (final row
          in await _isar.cloudSyncQueueItems
              .filter()
              .ownerUserIdEqualTo(ownerId)
              .exportJson())
        if (restoreReplacedQueueKinds.contains(row['kind'])) row,
    ],
    'notes': await _isar.isarAyahNotes
        .filter()
        .ownerIdEqualTo(ownerId)
        .exportJson(),
    'pairs': await _isar.isarConfusionPairs
        .filter()
        .ownerIdEqualTo(ownerId)
        .exportJson(),
    'prayerAssignments': await _isar.isarPrayerReviewAssignments
        .filter()
        .ownerIdEqualTo(ownerId)
        .exportJson(),
    'prayerReceipts': await _isar.isarPrayerReviewReceipts
        .filter()
        .ownerIdEqualTo(ownerId)
        .exportJson(),
  };

  /// A null-owner review row whose identity key names another owner is not
  /// this owner's (collect skips it too) and stays untouched.
  _Rows _reviewsOf(String ownerId, _Rows rows) => [
    for (final row in rows)
      if (row['ownerUserId'] != null ||
          (ReviewRecordIdentity.tryParse(
                    row['compositeKey'] as String? ?? '',
                  )?.ownerUserId ??
                  ownerId) ==
              ownerId)
        row,
  ];

  List<int> _ids(_Rows rows) => [for (final row in rows) row['id'] as int];

  Future<void> _deleteRows(Map<String, _Rows> rows) async {
    await _isar.isarAyahReviewRecords.deleteAll(_ids(rows['reviews']!));
    await _isar.isarAyahProgress.deleteAll(_ids(rows['progress']!));
    await _isar.streakIsars.deleteAll(_ids(rows['streak']!));
    await _isar.xpIsars.deleteAll(_ids(rows['xp']!));
    await _isar.dailyActivityIsars.deleteAll(_ids(rows['daily']!));
    await _isar.isarV2Sessions.deleteAll(_ids(rows['sessions']!));
    await _isar.isarReviewEvidenceEvents.deleteAll(_ids(rows['evidence']!));
    await _isar.isarReviewEffectOutboxs.deleteAll(_ids(rows['outbox']!));
    await _isar.cloudSyncQueueItems.deleteAll(_ids(rows['queue']!));
    await _isar.isarAyahNotes.deleteAll(_ids(rows['notes']!));
    await _isar.isarConfusionPairs.deleteAll(_ids(rows['pairs']!));
    await _isar.isarPrayerReviewAssignments.deleteAll(
      _ids(rows['prayerAssignments']!),
    );
    await _isar.isarPrayerReviewReceipts.deleteAll(
      _ids(rows['prayerReceipts']!),
    );
  }

  Future<void> _importRows(Map<String, _Rows> rows) async {
    await _isar.isarAyahReviewRecords.importJson(rows['reviews']!);
    await _isar.isarAyahProgress.importJson(rows['progress']!);
    await _isar.streakIsars.importJson(rows['streak']!);
    await _isar.xpIsars.importJson(rows['xp']!);
    await _isar.dailyActivityIsars.importJson(rows['daily']!);
    await _isar.isarV2Sessions.importJson(rows['sessions']!);
    await _isar.isarReviewEvidenceEvents.importJson(rows['evidence']!);
    await _isar.isarReviewEffectOutboxs.importJson(rows['outbox']!);
    await _isar.cloudSyncQueueItems.importJson(rows['queue']!);
    await _isar.isarAyahNotes.importJson(rows['notes']!);
    await _isar.isarConfusionPairs.importJson(rows['pairs']!);
    await _isar.isarPrayerReviewAssignments.importJson(
      rows['prayerAssignments']!,
    );
    await _isar.isarPrayerReviewReceipts.importJson(rows['prayerReceipts']!);
  }
}
