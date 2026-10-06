import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../security/parent_pin_secure_store.dart';
import '../security/encrypted_account_preferences_store.dart';
import '../sync/cloud_sync_queue_item.dart';
import '../sync/background_sync_scheduler.dart';
import '../services/audio_resume_store.dart';
import 'record_owner_provider.dart';
import 'account_data_barrier.dart';
import 'pending_bookmark_recovery_marker.dart';
import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import '../../features/memorization_plus/data/models/isar_review_evidence_event.dart';
import '../../features/memorization_plus/data/models/isar_v2_session.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/home/data/models/activity_event_isar.dart';
import '../../features/prayer_companion/data/models/prayer_companion_record_isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/xp/data/models/xp_isar.dart';

class AccountDataResetException implements Exception {
  const AccountDataResetException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'AccountDataResetException: $message';
}

/// Clears every store that belongs to the departing account.
///
/// This is a single explicit inventory rather than prefix matching alone.
/// Prefix-only matching is how `ayah_review_pull_cursor` and
/// `synced_certificate_ids` previously survived logout and corrupted the next
/// account's restore: neither key matched a cleared prefix.
///
/// When adding an account-owned preference key, add it to
/// [clearedPreferenceKeys]. When adding a device preference, add it to
/// [retainedPreferenceKeys]. A test asserts the two sets never overlap.
class AccountDataReset {
  AccountDataReset(
    this._isar,
    this._prefs, {
    ParentPinSecureStore? parentPinStore,
    EncryptedAccountPreferencesStore? encryptedAccountPreferences,
    RecordOwnerProvider? owner,
    BackgroundSyncScheduler? backgroundSyncScheduler,
    AudioResumeStore? audioResumeStore,
    Future<void> Function(String ownerId)? deleteBookmarksForOwner,
    Future<Directory> Function()? documentsDirectory,
    Future<void> Function()? cancelAccountNotifications,
  }) : _parentPinStore = parentPinStore,
       _encryptedAccountPreferences = encryptedAccountPreferences,
       _owner = owner,
       _backgroundSyncScheduler = backgroundSyncScheduler,
       _audioResumeStore = audioResumeStore,
       _deleteBookmarksForOwner = deleteBookmarksForOwner,
       _documentsDirectory = documentsDirectory ?? getApplicationDocumentsDirectory,
       _cancelAccountNotifications = cancelAccountNotifications;

  final Isar _isar;
  final SharedPreferences _prefs;
  final ParentPinSecureStore? _parentPinStore;
  final EncryptedAccountPreferencesStore? _encryptedAccountPreferences;
  final RecordOwnerProvider? _owner;
  final BackgroundSyncScheduler? _backgroundSyncScheduler;
  final AudioResumeStore? _audioResumeStore;
  final Future<void> Function(String ownerId)? _deleteBookmarksForOwner;
  final Future<Directory> Function() _documentsDirectory;
  final Future<void> Function()? _cancelAccountNotifications;

  /// Individual account-owned preference keys.
  static const Set<String> clearedPreferenceKeys = {
    // Copied from the authenticated Supabase display name on login.
    'user_profile',
    // Reading progress.
    'read_pages',
    // Cloud dirty flag for reading progress (pushed on next login/resume).
    'read_pages_cloud_dirty',
    // Last Quran playback position is account-owned.
    'audio_resume_position',
    // Delta-pull bookkeeping. Retaining these made the next account resume
    // from the previous account's cursor and restore an incomplete dataset.
    'ayah_review_pull_cursor',
    'ayah_review_pull_cursor_pulled_at',
    // Certificate bookkeeping and earned lists.
    'synced_certificate_ids',
    'earned_certificates_v2',
    'earned_certificates_v2_kids',
    'has_new_certificate',
    'has_new_certificate_kids',
    // Plan dirty flags.
    'daily_plan_cloud_dirty',
    'custom_plan_cloud_dirty',
    'daily_plan_cloud_revision',
    'custom_plan_cloud_revision',
    'daily_plan_cloud_conflict',
    'custom_plan_cloud_conflict',
    // Account-owned bookmark records and their durable tombstones.
    'quran_bookmarks',
    // Resume location may contain account-specific memorization state.
    'last_restorable_location',
    // Khatmah plans, their completed-history archive, and the retired
    // cloud-sync marker belong exclusively to the signed-in account.
    'khatmah_active_plan',
    'khatmah_history',
    'khatmah_cloud_dirty',
    'khatmah_owner',
  };

  /// Prefixes covering the memorization and legacy Hifz key namespaces. This
  /// also removes `mem_plus_local_records_claimed_by` and every migration flag.
  static const Set<String> clearedPreferencePrefixes = {
    'mem_plus_',
    'hifz_',
    'quran_bookmarks_owner_',
    // Day-scoped reading proof and its fixed ordinary-wird target.
    'daily_read_pages_',
    'daily_wird_target_',
    // Kids «قرأت هذه الصفحة» receipts (owner-scoped, per day).
    'kids_reading_receipts_',
    // Opt-in Prayer Companion settings are account-owned device data.
    'prayer_companion_',
  };

  /// Device-level preferences that must survive a logout.
  static const Set<String> retainedPreferenceKeys = {
    'theme_mode',
    'locale',
    'bookmarks',
    'onboarding_user_type',
    'unified_journey_enabled',
    'use_cloud_production_pull',
    'use_review_evidence_transport',
  };

  Future<void> clearAccountOwnedData({
    String? departingOwnerId,
    bool preservePendingBookmarkRecovery = true,
  }) => AccountDataBarrier.forPreferences(_prefs).clear(
    () => _clearAccountOwnedData(
      departingOwnerId: departingOwnerId,
      preservePendingBookmarkRecovery: preservePendingBookmarkRecovery,
    ),
  );

  Future<void> _clearAccountOwnedData({
    String? departingOwnerId,
    required bool preservePendingBookmarkRecovery,
  }) async {
    final ownerId = departingOwnerId ?? _owner?.currentOwnerId;
    if (!preservePendingBookmarkRecovery && ownerId != null) {
      await PendingBookmarkRecoveryMarker.clear(_prefs, ownerId);
    }
    final protectedOwners = preservePendingBookmarkRecovery
        ? PendingBookmarkRecoveryMarker.ownerIds(_prefs)
        : const <String>{};
    if (ownerId != null) {
      await _backgroundSyncScheduler?.cancelAccountSync(ownerId);
    }
    await _audioResumeStore?.stopPlaybackForAccountReset();
    await _clearPreferences(protectedOwners);
    await _clearCollections(protectedOwners);
    await _clearParentPin(ownerId);
    await _clearEncryptedAccountPreferences(
      ownerId,
      preserve: ownerId != null && protectedOwners.contains(ownerId),
    );
  }


  /// Erases data attributable to a deleted account. This is deliberately
  /// separate from guest preservation: deletion must never rehome the former
  /// account's progress into a local guest identity.
  Future<void> eraseDeletedAccountLocally({
    required String departingOwnerId,
  }) => AccountDataBarrier.forPreferences(_prefs).clear(
    () => _eraseDeletedAccountLocally(departingOwnerId),
  );

  Future<void> _eraseDeletedAccountLocally(String ownerId) async {
    await _backgroundSyncScheduler?.cancelAccountSync(ownerId);
    await _audioResumeStore?.stopPlaybackForAccountReset();
    await _deleteBookmarksForOwner?.call(ownerId);
    await _cancelAccountNotifications?.call();
    await _clearParentPin(ownerId);
    await _clearEncryptedAccountPreferences(ownerId, preserve: false);
    await PendingBookmarkRecoveryMarker.clear(_prefs, ownerId);
    await _deleteHifzMigrationBackup();
    await _clearDeletedAccountPreferences(ownerId);
    await _eraseDeletedAccountCollections(ownerId);
  }

  Future<void> _deleteHifzMigrationBackup() async {
    final dir = await _documentsDirectory();
    final backup = File('${dir.path}${Platform.pathSeparator}hifz_migration_backup.json');
    if (await backup.exists()) {
      await backup.delete();
    }
  }

  Future<void> _clearDeletedAccountPreferences(String ownerId) async {
    final keys = _prefs.getKeys().where((key) {
      if (key.startsWith('quran_bookmarks_owner_')) {
        return key == 'quran_bookmarks_owner_$ownerId' ||
            key == 'quran_bookmarks_owner_${ownerId}_migrated';
      }
      return key == 'auth_last_signed_in_user_id' ||
          clearedPreferenceKeys.contains(key) ||
          clearedPreferencePrefixes.any(key.startsWith);
    }).toList();
    for (final key in keys) {
      await _removePreference(key);
    }
  }

  Future<void> _eraseDeletedAccountCollections(String ownerId) async {
    await _isar.writeTxn(() async {
      final reviews = await _isar.isarAyahReviewRecords
          .filter()
          .group((q) => q.ownerUserIdEqualTo(ownerId).or().ownerUserIdIsNull())
          .findAll();
      await _isar.isarAyahReviewRecords.deleteAll(
        reviews.map((row) => row.id).toList(),
      );
      final sessions = await _isar.isarV2Sessions
          .filter()
          .group((q) => q.ownerIdEqualTo(ownerId).or().ownerIdIsNull())
          .findAll();
      await _isar.isarV2Sessions.deleteAll(sessions.map((row) => row.id).toList());
      final queue = await _isar.cloudSyncQueueItems
          .filter()
          .ownerUserIdEqualTo(ownerId)
          .findAll();
      await _isar.cloudSyncQueueItems.deleteAll(queue.map((row) => row.id).toList());
      // These legacy stores contain only the active, unscoped profile. They
      // must be erased, while explicitly owner-scoped records above survive.
      await _isar.isarAyahProgress.clear();
      await _isar.streakIsars.clear();
      await _isar.xpIsars.clear();
      await _isar.dailyActivityIsars.clear();
      await _runWhenCollectionSchemaAvailable(
        () => _eraseReviewEvidenceForOwner(ownerId),
      );
      await _runWhenCollectionSchemaAvailable(
        () => _isar.activityEventIsars.clear(),
      );
      await _runWhenCollectionSchemaAvailable(() async {
        await _isar.prayerCompanionRecordIsars
            .filter()
            .ownerIdEqualTo(ownerId)
            .deleteAll();
      });
    });
  }

  Future<void> _eraseReviewEvidenceForOwner(String ownerId) async {
    final events = await _isar.isarReviewEvidenceEvents
        .filter()
        .ownerIdEqualTo(ownerId)
        .findAll();
    await _isar.isarReviewEvidenceEvents.deleteAll(events.map((row) => row.id).toList());
    final effects = await _isar.isarReviewEffectOutboxs
        .filter()
        .ownerIdEqualTo(ownerId)
        .findAll();
    await _isar.isarReviewEffectOutboxs.deleteAll(effects.map((row) => row.id).toList());
  }


  Future<void> _clearParentPin(String? ownerId) async {
    final secureStore = _parentPinStore;
    if (secureStore == null || ownerId == null) return;
    await secureStore.clearVerifier(ownerId);
    await secureStore.writeBlockedUntil(ownerId, null);
    await secureStore.writeFailureCount(ownerId, 0);
  }

  Future<void> _clearEncryptedAccountPreferences(
    String? ownerId, {
    required bool preserve,
  }) async {
    if (ownerId == null || preserve) return;
    final encrypted = _encryptedAccountPreferences;
    await encrypted?.delete(ownerId, 'quran_bookmarks');
    await encrypted?.delete(ownerId, 'quran_bookmarks_owner_$ownerId');
  }

  Future<void> _clearPreferences(Set<String> protectedOwners) async {
    final keys = _prefs
        .getKeys()
        .where(
          (key) =>
              clearedPreferenceKeys.contains(key) ||
              clearedPreferencePrefixes.any(key.startsWith),
        )
        .where(
          (key) => !protectedOwners.any(
            (ownerId) => key.startsWith('quran_bookmarks_owner_$ownerId'),
          ),
        )
        .toList();
    for (final key in keys) {
      await _removePreference(key);
    }
  }

  Future<void> _removePreference(String key) async {
    try {
      final removed = await _prefs.remove(key);
      if (!removed) {
        throw AccountDataResetException('Failed to remove account data: $key');
      }
    } catch (error) {
      try {
        await _prefs.reload();
      } catch (_) {
        // Preserve the authoritative removal failure.
      }
      if (error is AccountDataResetException) rethrow;
      throw AccountDataResetException(
        'Failed to remove account data: $key',
        error,
      );
    }
  }

  Future<void> _clearCollections(Set<String> protectedOwners) async {
    await _isar.writeTxn(() async {
      await _isar.isarAyahReviewRecords.clear();
      // These collections were introduced after the original account-reset
      // schema. An in-flight upgrade (and older test/database schemas) may
      // not contain them yet. In that case there is nothing to clear; every
      // other Isar failure remains fatal so logout never pretends to have
      // removed account data when it has not.
      await _runWhenCollectionSchemaAvailable(
        () => _isar.isarReviewEvidenceEvents.clear(),
      );
      await _runWhenCollectionSchemaAvailable(
        () => _isar.isarReviewEffectOutboxs.clear(),
      );
      await _isar.isarAyahProgress.clear();
      await _isar.isarV2Sessions.clear();
      await _isar.streakIsars.clear();
      await _isar.xpIsars.clear();
      await _isar.dailyActivityIsars.clear();
      await _runWhenCollectionSchemaAvailable(
        () => _isar.activityEventIsars.clear(),
      );
      await _runWhenCollectionSchemaAvailable(
        () => _isar.prayerCompanionRecordIsars.clear(),
      );
      if (protectedOwners.isEmpty) {
        await _isar.cloudSyncQueueItems.clear();
      } else {
        final queueItems = await _isar.cloudSyncQueueItems.where().findAll();
        final removableIds = queueItems
            .where((item) => !protectedOwners.contains(item.ownerUserId))
            .map((item) => item.id)
            .toList();
        await _isar.cloudSyncQueueItems.deleteAll(removableIds);
      }
    });
  }

  Future<void> _runWhenCollectionSchemaAvailable(
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on IsarError catch (error) {
      if (!error.toString().contains('Missing TypeSchema')) rethrow;
    }
  }
}
