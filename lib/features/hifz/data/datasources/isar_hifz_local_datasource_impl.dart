import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/ayah_progress_model.dart';
import '../models/isar_ayah_progress.dart';
import 'hifz_local_datasource.dart';

class IsarHifzLocalDatasourceImpl implements HifzLocalDatasource {
  IsarHifzLocalDatasourceImpl(this._isar, this._prefs);

  final Isar _isar;
  final SharedPreferences _prefs;

  static const _migrationKey = 'hifz_isar_migrated';

  /// Performs a one-time migration from SharedPreferences to Isar
  Future<void> migrateFromSharedPreferencesIfNeeded() async {
    final migrated = _prefs.getBool(_migrationKey) ?? false;
    if (migrated) return;

    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith(AppConstants.kHifzProgress))
        .toList();

    if (keys.isEmpty) {
      await _prefs.setBool(_migrationKey, true);
      return;
    }

    final modelsToMigrate = <AyahProgressModel>[];
    for (final k in keys) {
      final raw = _prefs.getString(k);
      if (raw != null) {
        try {
          modelsToMigrate.add(
            AyahProgressModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
          );
        } catch (_) {}
      }
    }

    if (modelsToMigrate.isNotEmpty) {
      final isarModels = modelsToMigrate
          .map(IsarAyahProgress.fromModel)
          .toList();
      await _isar.writeTxn(() async {
        await _isar.isarAyahProgress.putAll(isarModels);
      });
    }

    // Remove legacy keys to free space and prevent accidental re-migration
    for (final k in keys) {
      await _prefs.remove(k);
    }

    // Mark as migrated
    await _prefs.setBool(_migrationKey, true);
  }

  @override
  Future<List<AyahProgressModel>> getProgressForSurah(int surahId) async {
    final results = await _isar.isarAyahProgress
        .filter()
        .surahIdEqualTo(surahId)
        .findAll();
    return results.map((e) => e.toModel()).toList();
  }

  @override
  Future<AyahProgressModel?> getAyahProgress(
    int surahId,
    int ayahNumber,
  ) async {
    final compositeKey = '${surahId}_$ayahNumber';
    final result = await _isar.isarAyahProgress
        .filter()
        .compositeKeyEqualTo(compositeKey)
        .findFirst();
    return result?.toModel();
  }

  @override
  Future<void> saveAyahProgress(AyahProgressModel progress) async {
    final isarModel = IsarAyahProgress.fromModel(progress);
    await _isar.writeTxn(() async {
      await _isar.isarAyahProgress.put(isarModel);
    });
  }

  @override
  Future<List<AyahProgressModel>> getAllProgress() async {
    final results = await _isar.isarAyahProgress.where().findAll();
    return results.map((e) => e.toModel()).toList();
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
    final saved = await _prefs.setString(AppConstants.kHifzPathMode, path);
    if (!saved) {
      throw StateError('Failed to save hifz path');
    }
  }
}
