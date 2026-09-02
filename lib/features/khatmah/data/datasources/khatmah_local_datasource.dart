import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/khatmah_history_model.dart';
import '../models/khatmah_plan_model.dart';

class KhatmahLocalDatasource {
  KhatmahLocalDatasource(this._prefs);

  final SharedPreferences _prefs;

  static const _kActivePlan = 'khatmah_active_plan';
  static const _kHistory = 'khatmah_history';
  static const _kCloudDirty = 'khatmah_cloud_dirty';

  Future<KhatmahPlanModel?> getActivePlan() {
    final raw = _prefs.getString(_kActivePlan);
    if (raw == null) return Future.value(null);
    try {
      return Future.value(
        KhatmahPlanModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } catch (_) {
      return Future.value(null);
    }
  }

  Future<void> savePlan(KhatmahPlanModel plan) async {
    await _prefs.setString(_kActivePlan, jsonEncode(plan.toJson()));
    await _prefs.setBool(_kCloudDirty, true);
  }

  Future<void> deletePlan() async {
    await _prefs.remove(_kActivePlan);
    await _prefs.setBool(_kCloudDirty, true);
  }

  Future<List<KhatmahHistoryModel>> getHistory() {
    final raw = _prefs.getString(_kHistory);
    if (raw == null) return Future.value([]);
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return Future.value(
        list
            .map((e) =>
                KhatmahHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return Future.value([]);
    }
  }

  Future<void> addHistoryEntry(KhatmahHistoryModel entry) async {
    final existing = await getHistory();
    existing.add(entry);
    await _prefs.setString(
      _kHistory,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
    await _prefs.setBool(_kCloudDirty, true);
  }

  Future<int> getKhatmahCount() async {
    final history = await getHistory();
    return history.length;
  }
}
