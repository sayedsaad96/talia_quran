import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/khatmah_reading_result.dart';
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
    } on KhatmahStorageException {
      rethrow;
    } catch (_) {
      return Future.error(
        const KhatmahStorageException('Active Khatmah plan data is corrupted.'),
      );
    }
  }

  Future<void> savePlan(KhatmahPlanModel plan) async {
    final saved = await _prefs.setString(_kActivePlan, jsonEncode(plan.toJson()));
    if (!saved) {
      throw const KhatmahStorageException('Failed to save the active Khatmah plan.');
    }
  }

  Future<bool> deletePlan({String? expectedPlanId}) async {
    if (expectedPlanId != null) {
      final activePlan = await getActivePlan();
      if (activePlan?.id != expectedPlanId) return false;
    }
    final removed = await _prefs.remove(_kActivePlan);
    if (!removed) {
      throw const KhatmahStorageException('Failed to delete the active Khatmah plan.');
    }
    return true;
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
    } on KhatmahStorageException {
      rethrow;
    } catch (_) {
      return Future.error(
        const KhatmahStorageException('Khatmah history data is corrupted.'),
      );
    }
  }

  Future<KhatmahHistoryModel> addHistoryEntry(KhatmahHistoryModel entry) async {
    final existing = await getHistory();
    for (final existingEntry in existing) {
      if (existingEntry.id == entry.id) return existingEntry;
    }
    existing.add(entry);
    final saved = await _prefs.setString(
      _kHistory,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
    if (!saved) {
      throw const KhatmahStorageException('Failed to save Khatmah history.');
    }
    return entry;
  }

  Future<int> getKhatmahCount() async {
    final history = await getHistory();
    return history.length;
  }
}
