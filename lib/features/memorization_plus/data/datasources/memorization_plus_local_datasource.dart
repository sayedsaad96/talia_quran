import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../../../core/memorization/review_record_cloud_merge.dart';
import '../../../../core/memorization/review_record_identity.dart';
import '../../domain/entities/memorization_entities.dart';
import '../models/isar_ayah_review_record.dart';
import '../models/memorization_models.dart';

part 'memorization_identity_storage.dart';
part 'memorization_kids_storage.dart';
part 'memorization_plans_storage.dart';
part 'memorization_review_records_storage.dart';

abstract class MemorizationPlusLocalDatasource {
  // Identity profile
  Future<MemorizationProfileModel> getMemorizationProfile();
  Future<void> saveMemorizationProfile(MemorizationProfileModel profile);
  Future<void> clearMemorizationProfile();

  // Pairing
  Future<PairingSessionModel?> getPairingSession();
  Future<void> savePairingSession(PairingSessionModel session);
  Future<void> clearPairingSession();

  // Track
  String? getSelectedTrack();
  Future<void> saveSelectedTrack(String track);
  Future<void> clearSelectedTrack();

  // Review records
  Future<void> migrateReviewRecordsToIsarIfNeeded();
  Future<void> migrateAudienceScopedReviewKeysIfNeeded();

  /// Re-keys every review row to `owner|audience|surah|ayah`. Idempotent.
  Future<void> migrateReviewRecordIdentityIfNeeded();

  /// Transfers `local`-owned review records to the signed-in account on first
  /// sign-in. Returns the number of records claimed.
  Future<int> claimLocalReviewRecords();

  Future<AyahReviewRecordModel?> getReviewRecord(
    int surahId,
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  });
  Future<List<AyahReviewRecordModel>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
    bool includeAllAudiences = false,
  });
  Future<void> saveReviewRecord(
    AyahReviewRecordModel record, {
    bool markCloudDirty = true,
  });

  /// Review records that still need uploading (cloudDirty true or legacy null).
  Future<List<AyahReviewRecordModel>> getCloudDirtyReviewRecords({
    bool includeAllAudiences = false,
  });

  /// Clears cloud dirty flags after a successful cloud upsert.
  Future<void> markReviewRecordsCloudSynced(Iterable<String> compositeKeys);

  /// Clears a dirty flag only when the row still has the mutation version that
  /// the server acknowledged. This prevents a delayed acknowledgement from
  /// erasing a newer local review written while the request was in flight.
  Future<void> markReviewRecordsCloudSyncedAtVersions(
    Map<String, int> acknowledgedVersions,
  );

  // Daily plan cache
  Future<DailyPlanModel?> getCachedDailyPlan();
  Future<void> saveDailyPlan(DailyPlanModel plan);
  Future<void> clearDailyPlanCache();

  // Kids progress
  Future<KidsProgressModel> getKidsProgress();
  Future<void> saveKidsProgress(KidsProgressModel progress);
  Future<List<KidsSessionLogModel>> getKidsSessionLogs();
  Future<void> saveKidsSessionLog(KidsSessionLogModel log);
  Future<void> saveKidsSessionLogs(List<KidsSessionLogModel> logs);
  Future<void> markKidsSessionLogsCloudSynced(Iterable<String> localIds);

  // Parent dashboard
  Future<ParentSettingsModel> getParentSettings();
  Future<void> saveParentSettings(ParentSettingsModel settings);
  Future<List<ParentRewardModel>> getParentRewards();
  Future<void> saveParentRewards(List<ParentRewardModel> rewards);

  // Custom memorization plan
  Future<CustomMemorizationPlanModel?> getCustomPlan();
  Future<void> saveCustomPlan(CustomMemorizationPlanModel plan);
  Future<void> deleteCustomPlan();

  // Smart memorization settings
  Future<SmartMemorizationSettingsModel> getSmartSettings();
  Future<void> saveSmartSettings(SmartMemorizationSettingsModel settings);

  // Parent mode toggle (for adults track)
  bool getIsParentMode();
  Future<void> setIsParentMode(bool value);
  Future<void> clearIsParentMode();
}

/// Shared storage primitives for the domain mixins.
///
/// [MemorizationPlusLocalDatasourceImpl] owns the actual [SharedPreferences]
/// and [Isar] instances (and the key namespace) and composes the domain mixins
/// so every storage concern delegates to a single source of truth.
mixin MemorizationLocalStorageMixin {
  SharedPreferences get _prefs;
  Isar? get _isar;
  RecordOwnerProvider get _owner;

  /// Provided by [MemorizationPlansStorageMixin]; declared here so
  /// [MemorizationIdentityStorageMixin] can fall back to it when no smart
  /// settings are stored yet.
  Future<CustomMemorizationPlanModel?> getCustomPlan();

  Map<String, dynamic>? _tryDecodeMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  T? _tryParse<T>(String raw, T Function(Map<String, dynamic>) parser) {
    final decoded = _tryDecodeMap(raw);
    if (decoded == null) return null;
    try {
      return parser(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setStringOrThrow(String key, String value) async {
    final saved = await _prefs.setString(key, value);
    if (!saved) {
      throw StateError('Failed to save value for $key');
    }
  }

  Future<void> _removeOrThrow(String key) async {
    final removed = await _prefs.remove(key);
    if (!removed && _prefs.containsKey(key)) {
      throw StateError('Failed to remove value for $key');
    }
  }
}

class MemorizationPlusLocalDatasourceImpl
    with
        MemorizationLocalStorageMixin,
        MemorizationIdentityStorageMixin,
        MemorizationReviewRecordsStorageMixin,
        MemorizationKidsStorageMixin,
        MemorizationPlansStorageMixin
    implements MemorizationPlusLocalDatasource {
  MemorizationPlusLocalDatasourceImpl(
    this._prefs, {
    Isar? isar,
    RecordOwnerProvider owner = const SupabaseRecordOwnerProvider(),
  }) : _isar = isar,
       _owner = owner;

  @override
  final SharedPreferences _prefs;
  @override
  final Isar? _isar;
  @override
  final RecordOwnerProvider _owner;

  // ─── Key namespace (isolated from existing features) ────────────────────────
  /// Authoritative identity profile — single source of truth for path/identity.
  static const _kProfile = 'mem_plus_profile';
  static const _kPairingSession = 'mem_plus_pairing_session';

  /// LEGACY: Legacy track key — still written for backward compatibility.
  /// Read `_kProfile` (MemorizationProfile.selectedPath) as the authoritative
  /// source instead. Do NOT remove this key — existing installs depend on it
  /// for smooth migration paths.
  static const _kTrack = 'mem_plus_track';
  static const _kReviewPrefix = 'mem_plus_review';
  static const _kReviewIsarMigration = 'mem_plus_reviews_migrated_to_isar_v1';
  static const _kReviewIdentityMigration = 'mem_plus_review_identity_keys_v1';
  static const _kReviewSourceMigration = 'mem_plus_review_source_tags_v2';
  static const _kLocalRecordsClaimedBy = 'mem_plus_local_records_claimed_by';
  static const _kDailyPlan = 'mem_plus_daily_plan';
  static const _kKidsProgress = 'mem_plus_kids_progress';
  static const _kKidsSessionLogs = 'mem_plus_kids_session_logs';
  static const _kParentSettings = 'mem_plus_parent_settings';
  static const _kParentRewards = 'mem_plus_parent_rewards';
  static const _kCustomPlan = 'mem_plus_custom_plan';
  static const _kSmartSettings = 'mem_plus_smart_settings';

  /// LEGACY: Written in parallel with MemorizationProfile.isParentGuardian.
  /// Kept for backward compatibility — do NOT remove.
  static const _kIsParentMode = 'mem_plus_is_parent_mode';
}
