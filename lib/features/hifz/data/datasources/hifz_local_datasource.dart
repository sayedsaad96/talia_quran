import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/ayah_progress_model.dart';

abstract class HifzLocalDatasource {
  Future<List<AyahProgressModel>> getProgressForSurah(int surahId);
  Future<AyahProgressModel?> getAyahProgress(int surahId, int ayahNumber);
  Future<void> saveAyahProgress(AyahProgressModel progress);
  Future<List<AyahProgressModel>> getAllProgress();
  Future<Set<String>> getPassedCheckpointKeys(int surahId);
  Future<void> markCheckpointPassed(String checkpointKey);
  String? getHifzPath();
  Future<void> saveHifzPath(String path);
}

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

  String _checkpointKey(int surahId) =>
      '${AppConstants.kHifzCheckpointProgress}_$surahId';

  @override
  Future<Set<String>> getPassedCheckpointKeys(int surahId) async {
    return (_prefs.getStringList(_checkpointKey(surahId)) ?? const []).toSet();
  }

  @override
  Future<void> markCheckpointPassed(String checkpointKey) async {
    final parts = checkpointKey.split('_');
    if (parts.length < 3) {
      throw ArgumentError.value(
        checkpointKey,
        'checkpointKey',
        'Expected surah_start_end key',
      );
    }
    final surahId = int.parse(parts.first);
    final storageKey = _checkpointKey(surahId);
    final keys = (_prefs.getStringList(storageKey) ?? const []).toSet()
      ..add(checkpointKey);
    final saved = await _prefs.setStringList(storageKey, keys.toList()..sort());
    if (!saved) {
      throw StateError('Failed to save checkpoint progress for $checkpointKey');
    }
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
