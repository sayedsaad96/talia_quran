import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/khatmah_history_model.dart';
import '../models/khatmah_plan_model.dart';

class KhatmahLocalDatasource {
  KhatmahLocalDatasource(this._prefs);

  final SharedPreferences _prefs;

  static const _kActivePlan = 'khatmah_active_plan';
  static const _kHistory = 'khatmah_history';

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
  }

  Future<void> deletePlan() async {
    await _prefs.remove(_kActivePlan);
  }

  Future<List<KhatmahHistoryModel>> getHistory() {
    final raw = _prefs.getString(_kHistory);
    if (raw == null) return Future.value([]);
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return Future.value(
        list
            .map((e) => KhatmahHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return Future.value([]);
    }
  }

  Future<KhatmahHistoryModel> addHistoryEntry(KhatmahHistoryModel entry) async {
    final existing = await getHistory();
    for (final existingEntry in existing) {
      if (existingEntry.id == entry.id) return existingEntry;
    }
    existing.add(entry);
    await _prefs.setString(
      _kHistory,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
    return entry;
  }

  Future<int> getKhatmahCount() async {
    final history = await getHistory();
    return history.length;
  }
}
