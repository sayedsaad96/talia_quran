import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';

abstract class ProgressLocalDatasource {
  int getStreakDays();
  DateTime? getLastActiveDate();
  Future<void> saveStreak(int days, DateTime date);
  List<int> getReadPages();
  Future<void> saveReadPage(int pageNumber);
}

class ProgressLocalDatasourceImpl implements ProgressLocalDatasource {
  ProgressLocalDatasourceImpl(this._prefs);
  final SharedPreferences _prefs;

  @override
  int getStreakDays() => _prefs.getInt(AppConstants.kStreakCount) ?? 0;

  @override
  DateTime? getLastActiveDate() {
    final raw = _prefs.getString(AppConstants.kLastActiveDate);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> saveStreak(int days, DateTime date) async {
    await _prefs.setInt(AppConstants.kStreakCount, days);
    await _prefs.setString(
        AppConstants.kLastActiveDate, date.toIso8601String());
  }

  @override
  List<int> getReadPages() {
    final raw = _prefs.getString(AppConstants.kReadPages);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as int).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveReadPage(int pageNumber) async {
    final pages = getReadPages();
    if (!pages.contains(pageNumber)) {
      pages.add(pageNumber);
      await _prefs.setString(AppConstants.kReadPages, jsonEncode(pages));
    }
  }
}
