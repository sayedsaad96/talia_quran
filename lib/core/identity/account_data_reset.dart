import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../security/parent_pin_secure_store.dart';
import '../security/encrypted_account_preferences_store.dart';
import '../sync/cloud_sync_queue_item.dart';
import '../sync/background_sync_scheduler.dart';
import '../memorization/review_record_identity.dart';
import 'record_owner_provider.dart';
import 'pending_bookmark_recovery_marker.dart';
import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/memorization_plus/data/models/isar_v2_session.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/xp/data/models/xp_isar.dart';

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
  }) : _parentPinStore = parentPinStore,
       _encryptedAccountPreferences = encryptedAccountPreferences,
       _owner = owner,
       _backgroundSyncScheduler = backgroundSyncScheduler;

  final Isar _isar;
  final SharedPreferences _prefs;
  final ParentPinSecureStore? _parentPinStore;
  final EncryptedAccountPreferencesStore? _encryptedAccountPreferences;
  final RecordOwnerProvider? _owner;
  final BackgroundSyncScheduler? _backgroundSyncScheduler;

  /// Individual account-owned preference keys.
  static const Set<String> clearedPreferenceKeys = {
    // Copied from the authenticated Supabase display name on login.
    'user_profile',
    // Reading progress.
    'read_pages',
    // Cloud dirty flag for reading progress (pushed on next login/resume).
    'read_pages_cloud_dirty',
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
  };

  /// Prefixes covering the memorization and legacy Hifz key namespaces. This
  /// also removes `mem_plus_local_records_claimed_by` and every migration flag.
  static const Set<String> clearedPreferencePrefixes = {
    'mem_plus_',
    'hifz_',
    'quran_bookmarks_owner_',
  };

  /// Device-level preferences that must survive a logout.
  static const Set<String> retainedPreferenceKeys = {
    'theme_mode',
    'locale',
    'bookmarks',
    'onboarding_user_type',
    'unified_journey_enabled',
    'use_cloud_production_pull',
  };

  Future<void> clearAccountOwnedData({
    String? departingOwnerId,
    bool preservePendingBookmarkRecovery = true,
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
    await _clearPreferences(protectedOwners);
    await _clearCollections(protectedOwners);
    await _clearParentPin(ownerId);
    await _clearEncryptedAccountPreferences(
      ownerId,
      preserve: ownerId != null && protectedOwners.contains(ownerId),
    );
  }

  /// Converts the departing account's usable local progress into guest data.
  ///
  /// This is intentionally different from [clearAccountOwnedData]: cloud
  /// account deletion must remove credentials but must not erase Quran or
  /// memorization progress from this device. Cloud-specific cursors and dirty
  /// markers are cleared so a later, unrelated account cannot upload the
  /// deleted account's work without an explicit claim/import flow.
  Future<void> preserveDeletedAccountLocally({
    required String departingOwnerId,
  }) async {
    if (departingOwnerId.isEmpty ||
        departingOwnerId == ReviewRecordIdentity.localOwnerId) {
      return;
    }

    await _backgroundSyncScheduler?.cancelAccountSync(departingOwnerId);
    await _rehomeReviewRecordsAsGuest(departingOwnerId);
    await _copyBookmarksToGuest(departingOwnerId);

    await _isar.writeTxn(() async {
      final streak = await _isar.streakIsars.get(1);
      if (streak != null) {
        streak.cloudDirty = false;
        streak.lastSyncedAt = null;
        await _isar.streakIsars.put(streak);
      }
      final xp = await _isar.xpIsars.get(1);
      if (xp != null) {
        xp.cloudDirty = false;
        xp.lastSyncedAt = null;
        await _isar.xpIsars.put(xp);
      }
      final activities = await _isar.dailyActivityIsars.where().findAll();
      for (final activity in activities) {
        activity.cloudDirty = false;
        activity.lastSyncedAt = null;
        await _isar.dailyActivityIsars.put(activity);
      }
      // Queue records deliberately remain under the deleted owner. They are
      // preserved for recovery/export, but can never be delivered by a later
      // account because queue ownership is scoped to the active user id.
    });

    const cloudMetadata = <String>{
      'auth_last_signed_in_user_id',
      'ayah_review_pull_cursor',
      'ayah_review_pull_cursor_pulled_at',
      'synced_certificate_ids',
      'daily_plan_cloud_dirty',
      'custom_plan_cloud_dirty',
      'daily_plan_cloud_revision',
      'custom_plan_cloud_revision',
      'daily_plan_cloud_conflict',
      'custom_plan_cloud_conflict',
      'read_pages_cloud_dirty',
      'mem_plus_local_records_claimed_by',
    };
    for (final key in cloudMetadata) {
      await _prefs.remove(key);
    }
  }

  Future<void> _rehomeReviewRecordsAsGuest(String departingOwnerId) async {
    await _isar.writeTxn(() async {
      final rows = await _isar.isarAyahReviewRecords
          .filter()
          .ownerUserIdEqualTo(departingOwnerId)
          .findAll();
      for (final row in rows) {
        final audience = row.audience ?? 'adult';
        final guestKey =
            '${ReviewRecordIdentity.localOwnerId}|$audience|${row.surahId}|${row.ayahNumber}';
        final existing = await _isar.isarAyahReviewRecords.getByCompositeKey(
          guestKey,
        );
        if (existing != null && existing.id != row.id) {
          if (!row.lastReviewedAt.isAfter(existing.lastReviewedAt)) {
            await _isar.isarAyahReviewRecords.delete(row.id);
            continue;
          }
          await _isar.isarAyahReviewRecords.delete(existing.id);
        }
        row.compositeKey = guestKey;
        row.ownerUserId = ReviewRecordIdentity.localOwnerId;
        row.cloudDirty = false;
        row.lastSyncedAt = null;
        await _isar.isarAyahReviewRecords.put(row);
      }
    });
  }

  Future<void> _copyBookmarksToGuest(String departingOwnerId) async {
    const key = 'quran_bookmarks';
    final legacyKey = 'quran_bookmarks_owner_$departingOwnerId';
    const guestKey =
        'quran_bookmarks_owner_${ReviewRecordIdentity.localOwnerId}';
    final legacyValue = _prefs.getString(legacyKey);
    if (legacyValue != null) {
      await _prefs.setString(guestKey, legacyValue);
      await _prefs.remove(legacyKey);
    }

    final encrypted = _encryptedAccountPreferences;
    if (encrypted == null) return;
    final secureValue = await encrypted.read(departingOwnerId, key);
    if (secureValue == null) return;
    try {
      await encrypted.write(
        ReviewRecordIdentity.localOwnerId,
        key,
        secureValue,
      );
    } catch (_) {
      await PendingBookmarkRecoveryMarker.mark(_prefs, departingOwnerId);
      rethrow;
    }
    await encrypted.delete(departingOwnerId, key);
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
      await _prefs.remove(key);
    }
  }

  Future<void> _clearCollections(Set<String> protectedOwners) async {
    await _isar.writeTxn(() async {
      await _isar.isarAyahReviewRecords.clear();
      await _isar.isarAyahProgress.clear();
      await _isar.isarV2Sessions.clear();
      await _isar.streakIsars.clear();
      await _isar.xpIsars.clear();
      await _isar.dailyActivityIsars.clear();
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
}
