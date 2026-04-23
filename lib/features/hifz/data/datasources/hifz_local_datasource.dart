import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/ayah_progress_model.dart';

abstract class HifzLocalDatasource {
  Future<List<AyahProgressModel>> getProgressForSurah(int surahId);
  Future<AyahProgressModel?> getAyahProgress(int surahId, int ayahNumber);
  Future<void> saveAyahProgress(AyahProgressModel progress);
  Future<List<AyahProgressModel>> getAllProgress();
  String? getHifzPath();
  Future<void> saveHifzPath(String path);
}

class HifzLocalDatasourceImpl implements HifzLocalDatasource {
  HifzLocalDatasourceImpl(this._prefs);
  final SharedPreferences _prefs;

  String _key(int surahId, int ayahNum) =>
      '${AppConstants.kHifzProgress}_${surahId}_$ayahNum';

  @override
  Future<List<AyahProgressModel>> getProgressForSurah(int surahId) async {
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith('${AppConstants.kHifzProgress}_${surahId}_'))
        .toList();
    return keys
        .map((k) {
          final raw = _prefs.getString(k);
          if (raw == null) return null;
          return AyahProgressModel.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
        })
        .whereType<AyahProgressModel>()
        .toList();
  }

  @override
  Future<AyahProgressModel?> getAyahProgress(
    int surahId,
    int ayahNumber,
  ) async {
    final raw = _prefs.getString(_key(surahId, ayahNumber));
    if (raw == null) return null;
    return AyahProgressModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveAyahProgress(AyahProgressModel progress) async {
    await _prefs.setString(
      _key(progress.surahId, progress.ayahNumber),
      jsonEncode(progress.toJson()),
    );
  }

  @override
  Future<List<AyahProgressModel>> getAllProgress() async {
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith(AppConstants.kHifzProgress))
        .toList();
    return keys
        .map((k) {
          final raw = _prefs.getString(k);
          if (raw == null) return null;
          return AyahProgressModel.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
        })
        .whereType<AyahProgressModel>()
        .toList();
  }

  @override
  String? getHifzPath() {
    return _prefs.getString(AppConstants.kHifzPathMode);
  }

  @override
  Future<void> saveHifzPath(String path) async {
    await _prefs.setString(AppConstants.kHifzPathMode, path);
  }
}
