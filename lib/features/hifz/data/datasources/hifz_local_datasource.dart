import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
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

/// SharedPreferences-based implementation, superseded in production by
/// [IsarHifzLocalDatasourceImpl]. Retained here for test coverage only.
@visibleForTesting
class HifzLocalDatasourceImpl implements HifzLocalDatasource {
  HifzLocalDatasourceImpl(this._prefs);
  final SharedPreferences _prefs;

  String _key(int surahId, int ayahNum) =>
      '${AppConstants.kHifzProgress}_${surahId}_$ayahNum';

  AyahProgressModel? _tryReadProgress(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AyahProgressModel.fromJson(decoded);
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

  @override
  Future<List<AyahProgressModel>> getProgressForSurah(int surahId) async {
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith('${AppConstants.kHifzProgress}_${surahId}_'))
        .toList();
    return keys.map(_tryReadProgress).whereType<AyahProgressModel>().toList();
  }

  @override
  Future<AyahProgressModel?> getAyahProgress(
    int surahId,
    int ayahNumber,
  ) async {
    return _tryReadProgress(_key(surahId, ayahNumber));
  }

  @override
  Future<void> saveAyahProgress(AyahProgressModel progress) async {
    await _setStringOrThrow(
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
    return keys.map(_tryReadProgress).whereType<AyahProgressModel>().toList();
  }

  @override
  String? getHifzPath() {
    return _prefs.getString(AppConstants.kHifzPathMode);
  }

  @override
  Future<void> saveHifzPath(String path) async {
    if (path != 'forward' && path != 'backward') {
      throw ArgumentError.value(path, 'path', 'Unsupported hifz path');
    }
    await _setStringOrThrow(AppConstants.kHifzPathMode, path);
  }
}
