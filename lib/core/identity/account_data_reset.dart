import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sync/cloud_sync_queue_item.dart';
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
  AccountDataReset(this._isar, this._prefs);

  final Isar _isar;
  final SharedPreferences _prefs;

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
    // Resume location may contain account-specific memorization state.
    'last_restorable_location',
  };

  /// Prefixes covering the memorization and legacy Hifz key namespaces. This
  /// also removes `mem_plus_local_records_claimed_by` and every migration flag.
  static const Set<String> clearedPreferencePrefixes = {'mem_plus_', 'hifz_'};

  /// Device-level preferences that must survive a logout.
  static const Set<String> retainedPreferenceKeys = {
    'theme_mode',
    'locale',
    'bookmarks',
    'onboarding_user_type',
    'unified_journey_enabled',
    'use_cloud_production_pull',
  };

  Future<void> clearAccountOwnedData() async {
    await _clearPreferences();
    await _clearCollections();
  }

  Future<void> _clearPreferences() async {
    final keys = _prefs
        .getKeys()
        .where(
          (key) =>
              clearedPreferenceKeys.contains(key) ||
              clearedPreferencePrefixes.any(key.startsWith),
        )
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  Future<void> _clearCollections() async {
    await _isar.writeTxn(() async {
      await _isar.isarAyahReviewRecords.clear();
      await _isar.isarAyahProgress.clear();
      await _isar.isarV2Sessions.clear();
      await _isar.streakIsars.clear();
      await _isar.xpIsars.clear();
      await _isar.dailyActivityIsars.clear();
      await _isar.cloudSyncQueueItems.clear();
    });
  }
}
