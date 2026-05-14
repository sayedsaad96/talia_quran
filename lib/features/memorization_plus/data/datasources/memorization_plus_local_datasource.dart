import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/memorization_models.dart';

abstract class MemorizationPlusLocalDatasource {
  // Track
  String? getSelectedTrack();
  Future<void> saveSelectedTrack(String track);

  // Review records
  Future<AyahReviewRecordModel?> getReviewRecord(int surahId, int ayahNumber);
  Future<List<AyahReviewRecordModel>> getAllReviewRecords();
  Future<void> saveReviewRecord(AyahReviewRecordModel record);

  // Daily plan cache
  Future<DailyPlanModel?> getCachedDailyPlan();
  Future<void> saveDailyPlan(DailyPlanModel plan);

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

  // Parent mode toggle (for adults track)
  bool getIsParentMode();
  Future<void> setIsParentMode(bool value);
}

class MemorizationPlusLocalDatasourceImpl
    implements MemorizationPlusLocalDatasource {
  MemorizationPlusLocalDatasourceImpl(this._prefs);

  final SharedPreferences _prefs;

  // ─── Key namespace (isolated from existing features) ────────────────────────
  static const _kTrack = 'mem_plus_track';
  static const _kReviewPrefix = 'mem_plus_review';
  static const _kDailyPlan = 'mem_plus_daily_plan';
  static const _kKidsProgress = 'mem_plus_kids_progress';
  static const _kKidsSessionLogs = 'mem_plus_kids_session_logs';
  static const _kParentSettings = 'mem_plus_parent_settings';
  static const _kParentRewards = 'mem_plus_parent_rewards';
  static const _kCustomPlan = 'mem_plus_custom_plan';
  static const _kIsParentMode = 'mem_plus_is_parent_mode';

  String _reviewKey(int surahId, int ayahNumber) =>
      '${_kReviewPrefix}_${surahId}_$ayahNumber';

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

  // ─── Track ──────────────────────────────────────────────────────────────────
  @override
  String? getSelectedTrack() => _prefs.getString(_kTrack);

  @override
  Future<void> saveSelectedTrack(String track) =>
      _setStringOrThrow(_kTrack, track);

  // ─── Review records ─────────────────────────────────────────────────────────
  @override
  Future<AyahReviewRecordModel?> getReviewRecord(
    int surahId,
    int ayahNumber,
  ) async {
    final raw = _prefs.getString(_reviewKey(surahId, ayahNumber));
    if (raw == null) return null;
    return _tryParse(raw, AyahReviewRecordModel.fromJson);
  }

  @override
  Future<List<AyahReviewRecordModel>> getAllReviewRecords() async {
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith(_kReviewPrefix))
        .toList();
    return keys
        .map((k) {
          final raw = _prefs.getString(k);
          return raw == null
              ? null
              : _tryParse(raw, AyahReviewRecordModel.fromJson);
        })
        .whereType<AyahReviewRecordModel>()
        .toList();
  }

  @override
  Future<void> saveReviewRecord(AyahReviewRecordModel record) =>
      _setStringOrThrow(
        _reviewKey(record.surahId, record.ayahNumber),
        jsonEncode(record.toJson()),
      );

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
  Future<void> deleteCustomPlan() async {
    final removed = await _prefs.remove(_kCustomPlan);
    if (!removed) {
      throw StateError('Failed to delete custom plan');
    }
  }

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
}
