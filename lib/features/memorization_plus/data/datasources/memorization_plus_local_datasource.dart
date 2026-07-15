import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/memorization/review_record_audience_scope.dart';
import '../../domain/entities/memorization_entities.dart';
import '../models/isar_ayah_review_record.dart';
import '../models/memorization_models.dart';

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

class MemorizationPlusLocalDatasourceImpl
    implements MemorizationPlusLocalDatasource {
  MemorizationPlusLocalDatasourceImpl(this._prefs, {Isar? isar}) : _isar = isar;

  final SharedPreferences _prefs;
  final Isar? _isar;

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

  String _reviewKey(int surahId, int ayahNumber) =>
      '${_kReviewPrefix}_${surahId}_$ayahNumber';

  bool get _audienceScopedReads => ReviewRecordAudienceScope.isEnabled(
    readBool: (key) => _prefs.getBool(key) ?? false,
  );

  @override
  Future<void> migrateAudienceScopedReviewKeysIfNeeded() async {
    if (!_audienceScopedReads) return;
    if (_prefs.getBool(ReviewRecordAudienceScope.migrationKey) == true) {
      return;
    }

    final isar = _isar;
    if (isar == null) {
      await _prefs.setBool(ReviewRecordAudienceScope.migrationKey, true);
      return;
    }

    await migrateReviewRecordsToIsarIfNeeded();
    final records = await isar.isarAyahReviewRecords.where().findAll();

    await isar.writeTxn(() async {
      for (final record in records) {
        if (!ReviewRecordAudienceScope.isLegacyCompositeKey(
          record.compositeKey,
        )) {
          continue;
        }
        final model = record.toModel();
        final scopedKey = ReviewRecordAudienceScope.storageKey(
          surahId: model.surahId,
          ayahNumber: model.ayahNumber,
          mode: model.createdByMode,
          scoped: true,
        );
        if (scopedKey == record.compositeKey) continue;

        final existing = await isar.isarAyahReviewRecords.getByCompositeKey(
          scopedKey,
        );
        if (existing != null) continue;

        final migrated = IsarAyahReviewRecord.fromModel(model)
          ..compositeKey = scopedKey;
        await isar.isarAyahReviewRecords.put(migrated);
      }
    });

    await _prefs.setBool(ReviewRecordAudienceScope.migrationKey, true);
  }

  Future<AyahReviewRecordModel?> _getIsarReviewRecord(
    int surahId,
    int ayahNumber, {
    required ReviewRecordReadScope scope,
  }) async {
    final isar = _isar;
    if (isar == null) return null;

    await migrateReviewRecordsToIsarIfNeeded();
    await migrateAudienceScopedReviewKeysIfNeeded();

    if (!_audienceScopedReads) {
      final record = await isar.isarAyahReviewRecords.getByCompositeKey(
        ReviewRecordAudienceScope.legacyKey(surahId, ayahNumber),
      );
      return record?.toModel();
    }

    final scopedKey = ReviewRecordAudienceScope.readKey(
      surahId: surahId,
      ayahNumber: ayahNumber,
      scope: scope,
      scoped: true,
    );
    final scoped = await isar.isarAyahReviewRecords.getByCompositeKey(
      scopedKey,
    );
    if (scoped != null) return scoped.toModel();

    if (scope == ReviewRecordReadScope.adult) {
      final legacy = await isar.isarAyahReviewRecords.getByCompositeKey(
        ReviewRecordAudienceScope.legacyKey(surahId, ayahNumber),
      );
      final legacyModel = legacy?.toModel();
      if (legacyModel != null &&
          ReviewRecordAudienceScope.matchesReadScope(
            legacyModel,
            ReviewRecordReadScope.adult,
          )) {
        return legacyModel;
      }
    }

    return null;
  }

  @override
  Future<AyahReviewRecordModel?> getReviewRecord(
    int surahId,
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
    final isar = _isar;
    if (isar != null) {
      return _getIsarReviewRecord(surahId, ayahNumber, scope: scope);
    }

    final raw = _prefs.getString(_reviewKey(surahId, ayahNumber));
    if (raw == null) return null;
    final model = _tryParse(raw, AyahReviewRecordModel.fromJson);
    if (model == null) return null;
    if (_audienceScopedReads &&
        !ReviewRecordAudienceScope.matchesReadScope(model, scope)) {
      return null;
    }
    return model;
  }

  @override
  Future<List<AyahReviewRecordModel>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
    bool includeAllAudiences = false,
  }) async {
    final isar = _isar;
    if (isar != null) {
      await migrateReviewRecordsToIsarIfNeeded();
      await migrateAudienceScopedReviewKeysIfNeeded();
      final records = await isar.isarAyahReviewRecords.where().findAll();
      final models = records.map((record) => record.toModel()).toList();
      if (!_audienceScopedReads || includeAllAudiences) return models;
      return models
          .where((m) => ReviewRecordAudienceScope.matchesReadScope(m, scope))
          .toList();
    }

    return _legacyReviewKeys()
        .map((k) {
          final raw = _prefs.getString(k);
          return raw == null
              ? null
              : _tryParse(raw, AyahReviewRecordModel.fromJson);
        })
        .whereType<AyahReviewRecordModel>()
        .where(
          (m) =>
              !_audienceScopedReads ||
              includeAllAudiences ||
              ReviewRecordAudienceScope.matchesReadScope(m, scope),
        )
        .toList();
  }

  @override
  Future<void> saveReviewRecord(
    AyahReviewRecordModel record, {
    bool markCloudDirty = true,
  }) async {
    final isar = _isar;
    if (isar != null) {
      await migrateReviewRecordsToIsarIfNeeded();
      await migrateAudienceScopedReviewKeysIfNeeded();
      final compositeKey = ReviewRecordAudienceScope.storageKey(
        surahId: record.surahId,
        ayahNumber: record.ayahNumber,
        mode: record.createdByMode,
        scoped: _audienceScopedReads,
      );
      final isarRecord = IsarAyahReviewRecord.fromModel(record)
        ..compositeKey = compositeKey;
      if (markCloudDirty) {
        isarRecord.cloudDirty = true;
      } else {
        isarRecord.cloudDirty = false;
        isarRecord.lastSyncedAt = DateTime.now().toUtc();
      }
      await isar.writeTxn(() async {
        await isar.isarAyahReviewRecords.put(isarRecord);
      });
      return;
    }

    await _setStringOrThrow(
      _reviewKey(record.surahId, record.ayahNumber),
      jsonEncode(record.toJson()),
    );
  }

  @override
  Future<List<AyahReviewRecordModel>> getCloudDirtyReviewRecords({
    bool includeAllAudiences = false,
  }) async {
    final isar = _isar;
    if (isar == null) {
      return getAllReviewRecords(includeAllAudiences: includeAllAudiences);
    }

    await migrateReviewRecordsToIsarIfNeeded();
    await migrateAudienceScopedReviewKeysIfNeeded();
    final records = await isar.isarAyahReviewRecords
        .filter()
        .group(
          (q) => q.cloudDirtyEqualTo(true).or().cloudDirtyIsNull(),
        )
        .findAll();
    final models = records.map((record) => record.toModel()).toList();
    if (!_audienceScopedReads || includeAllAudiences) return models;
    return models
        .where(
          (m) => ReviewRecordAudienceScope.matchesReadScope(
            m,
            ReviewRecordReadScope.adult,
          ),
        )
        .toList();
  }

  @override
  Future<void> markReviewRecordsCloudSynced(
    Iterable<String> compositeKeys,
  ) async {
    final isar = _isar;
    if (isar == null) return;

    final syncedAt = DateTime.now().toUtc();
    await isar.writeTxn(() async {
      for (final compositeKey in compositeKeys) {
        final record = await isar.isarAyahReviewRecords
            .filter()
            .compositeKeyEqualTo(compositeKey)
            .findFirst();
        if (record == null) continue;
        record.cloudDirty = false;
        record.lastSyncedAt = syncedAt;
        await isar.isarAyahReviewRecords.put(record);
      }
    });
  }

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

  // ─── Identity profile ──────────────────────────────────────────────────────
  @override
  Future<MemorizationProfileModel> getMemorizationProfile() async {
    final raw = _prefs.getString(_kProfile);
    if (raw == null) return MemorizationProfileModel.empty();
    return _tryParse(raw, MemorizationProfileModel.fromJson) ??
        MemorizationProfileModel.empty();
  }

  @override
  Future<void> saveMemorizationProfile(MemorizationProfileModel profile) =>
      _setStringOrThrow(_kProfile, jsonEncode(profile.toJson()));

  @override
  Future<void> clearMemorizationProfile() => _removeOrThrow(_kProfile);

  // ─── Pairing ────────────────────────────────────────────────────────────────
  @override
  Future<PairingSessionModel?> getPairingSession() async {
    final raw = _prefs.getString(_kPairingSession);
    if (raw == null) return null;
    return _tryParse(raw, PairingSessionModel.fromJson);
  }

  @override
  Future<void> savePairingSession(PairingSessionModel session) =>
      _setStringOrThrow(_kPairingSession, jsonEncode(session.toJson()));

  @override
  Future<void> clearPairingSession() => _removeOrThrow(_kPairingSession);

  // ─── Track ──────────────────────────────────────────────────────────────────
  @override
  String? getSelectedTrack() => _prefs.getString(_kTrack);

  @override
  Future<void> saveSelectedTrack(String track) =>
      _setStringOrThrow(_kTrack, track);

  @override
  Future<void> clearSelectedTrack() => _removeOrThrow(_kTrack);

  // ─── Review records ─────────────────────────────────────────────────────────
  @override
  Future<void> migrateReviewRecordsToIsarIfNeeded() async {
    final isar = _isar;
    if (isar == null || (_prefs.getBool(_kReviewIsarMigration) ?? false)) {
      return;
    }

    final legacyKeys = _legacyReviewKeys();
    if (legacyKeys.isEmpty) {
      await _prefs.setBool(_kReviewIsarMigration, true);
      return;
    }

    final records = legacyKeys
        .map((key) {
          final raw = _prefs.getString(key);
          return raw == null
              ? null
              : _tryParse(raw, AyahReviewRecordModel.fromJson);
        })
        .whereType<AyahReviewRecordModel>()
        // Migrated records enter the V2 source of truth.
        .map(
          (m) => AyahReviewRecordModel.fromEntity(
            m.copyWith(createdByMode: ReviewRecordCreatedByMode.v2Session),
          ),
        )
        .toList();

    await isar.writeTxn(() async {
      await isar.isarAyahReviewRecords.putAll(
        records.map(IsarAyahReviewRecord.fromModel).toList(),
      );
    });

    for (final key in legacyKeys) {
      await _removeOrThrow(key);
    }
    await _prefs.setBool(_kReviewIsarMigration, true);
  }

  List<String> _legacyReviewKeys() {
    return _prefs
        .getKeys()
        .where((key) => key.startsWith('${_kReviewPrefix}_'))
        .toList();
  }

  // ─── Daily plan cache ────────────────────────────────────────────────────────
  @override
  Future<DailyPlanModel?> getCachedDailyPlan() async {
    final raw = _prefs.getString(_kDailyPlan);
    if (raw == null) return null;
    return _tryParse(raw, DailyPlanModel.fromJson);
  }

  @override
  Future<void> saveDailyPlan(DailyPlanModel plan) =>
      _setStringOrThrow(_kDailyPlan, jsonEncode(plan.toJson()));

  @override
  Future<void> clearDailyPlanCache() async => _prefs.remove(_kDailyPlan);

  // ─── Kids progress ───────────────────────────────────────────────────────────
  @override
  Future<KidsProgressModel> getKidsProgress() async {
    final raw = _prefs.getString(_kKidsProgress);
    if (raw == null) return const KidsProgressModel.empty();
    return _tryParse(raw, KidsProgressModel.fromJson) ??
        const KidsProgressModel.empty();
  }

  @override
  Future<void> saveKidsProgress(KidsProgressModel progress) =>
      _setStringOrThrow(_kKidsProgress, jsonEncode(progress.toJson()));

  @override
  Future<List<KidsSessionLogModel>> getKidsSessionLogs() async {
    final raw = _prefs.getString(_kKidsSessionLogs);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(KidsSessionLogModel.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveKidsSessionLog(KidsSessionLogModel log) async {
    final logs = await getKidsSessionLogs();
    final next = [...logs.where((item) => item.id != log.id), log]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    await saveKidsSessionLogs(next);
  }

  @override
  Future<void> saveKidsSessionLogs(List<KidsSessionLogModel> logs) =>
      _setStringOrThrow(
        _kKidsSessionLogs,
        jsonEncode(logs.map((log) => log.toJson()).toList()),
      );

  // ─── Parent dashboard ──────────────────────────────────────────────────────
  @override
  Future<ParentSettingsModel> getParentSettings() async {
    final raw = _prefs.getString(_kParentSettings);
    if (raw == null) return const ParentSettingsModel.defaults();
    return _tryParse(raw, ParentSettingsModel.fromJson) ??
        const ParentSettingsModel.defaults();
  }

  @override
  Future<void> saveParentSettings(ParentSettingsModel settings) =>
      _setStringOrThrow(_kParentSettings, jsonEncode(settings.toJson()));

  @override
  Future<List<ParentRewardModel>> getParentRewards() async {
    final raw = _prefs.getString(_kParentRewards);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ParentRewardModel.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveParentRewards(List<ParentRewardModel> rewards) =>
      _setStringOrThrow(
        _kParentRewards,
        jsonEncode(rewards.map((reward) => reward.toJson()).toList()),
      );

  // ─── Custom memorization plan ───────────────────────────────────────────────
  @override
  Future<CustomMemorizationPlanModel?> getCustomPlan() async {
    final raw = _prefs.getString(_kCustomPlan);
    if (raw == null) return null;
    return _tryParse(raw, CustomMemorizationPlanModel.fromJson);
  }

  @override
  Future<void> saveCustomPlan(CustomMemorizationPlanModel plan) =>
      _setStringOrThrow(_kCustomPlan, jsonEncode(plan.toJson()));

  @override
  Future<void> deleteCustomPlan() => _removeOrThrow(_kCustomPlan);

  // ─── Smart memorization settings ───────────────────────────────────────────
  @override
  Future<SmartMemorizationSettingsModel> getSmartSettings() async {
    final raw = _prefs.getString(_kSmartSettings);
    if (raw == null) {
      final customPlan = await getCustomPlan();
      return SmartMemorizationSettingsModel(customPlan: customPlan);
    }
    final parsed = _tryParse(raw, SmartMemorizationSettingsModel.fromJson);
    if (parsed != null) return parsed;
    return const SmartMemorizationSettingsModel();
  }

  @override
  Future<void> saveSmartSettings(SmartMemorizationSettingsModel settings) =>
      _setStringOrThrow(_kSmartSettings, jsonEncode(settings.toJson()));

  // ─── Parent mode toggle ─────────────────────────────────────────────────────
  @override
  bool getIsParentMode() => _prefs.getBool(_kIsParentMode) ?? false;

  @override
  Future<void> setIsParentMode(bool value) async {
    final saved = await _prefs.setBool(_kIsParentMode, value);
    if (!saved) {
      throw StateError('Failed to save parent mode');
    }
  }

  @override
  Future<void> clearIsParentMode() => _removeOrThrow(_kIsParentMode);
}
