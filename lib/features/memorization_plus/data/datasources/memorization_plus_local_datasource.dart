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

  // Custom memorization plan
  Future<CustomMemorizationPlanModel?> getCustomPlan();
  Future<void> saveCustomPlan(CustomMemorizationPlanModel plan);
  Future<void> deleteCustomPlan();
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
  static const _kCustomPlan = 'mem_plus_custom_plan';

  String _reviewKey(int surahId, int ayahNumber) =>
      '${_kReviewPrefix}_${surahId}_$ayahNumber';

  // ─── Track ──────────────────────────────────────────────────────────────────
  @override
  String? getSelectedTrack() => _prefs.getString(_kTrack);

  @override
  Future<void> saveSelectedTrack(String track) =>
      _prefs.setString(_kTrack, track);

  // ─── Review records ─────────────────────────────────────────────────────────
  @override
  Future<AyahReviewRecordModel?> getReviewRecord(
      int surahId, int ayahNumber) async {
    final raw = _prefs.getString(_reviewKey(surahId, ayahNumber));
    if (raw == null) return null;
    return AyahReviewRecordModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
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
          if (raw == null) return null;
          return AyahReviewRecordModel.fromJson(
              jsonDecode(raw) as Map<String, dynamic>);
        })
        .whereType<AyahReviewRecordModel>()
        .toList();
  }

  @override
  Future<void> saveReviewRecord(AyahReviewRecordModel record) =>
      _prefs.setString(
        _reviewKey(record.surahId, record.ayahNumber),
        jsonEncode(record.toJson()),
      );

  // ─── Daily plan cache ────────────────────────────────────────────────────────
  @override
  Future<DailyPlanModel?> getCachedDailyPlan() async {
    final raw = _prefs.getString(_kDailyPlan);
    if (raw == null) return null;
    return DailyPlanModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveDailyPlan(DailyPlanModel plan) =>
      _prefs.setString(_kDailyPlan, jsonEncode(plan.toJson()));

  // ─── Kids progress ───────────────────────────────────────────────────────────
  @override
  Future<KidsProgressModel> getKidsProgress() async {
    final raw = _prefs.getString(_kKidsProgress);
    if (raw == null) return const KidsProgressModel.empty();
    return KidsProgressModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveKidsProgress(KidsProgressModel progress) =>
      _prefs.setString(
          _kKidsProgress, jsonEncode(progress.toJson()));

  // ─── Custom memorization plan ───────────────────────────────────────────────
  @override
  Future<CustomMemorizationPlanModel?> getCustomPlan() async {
    final raw = _prefs.getString(_kCustomPlan);
    if (raw == null) return null;
    return CustomMemorizationPlanModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveCustomPlan(CustomMemorizationPlanModel plan) =>
      _prefs.setString(_kCustomPlan, jsonEncode(plan.toJson()));

  @override
  Future<void> deleteCustomPlan() => _prefs.remove(_kCustomPlan);
}
