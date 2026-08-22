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
  static const _quarantinePrefix = 'hifz_isar_migration_quarantine_';

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

    var allRecordsHandled = true;
    for (final k in keys) {
      final raw = _prefs.getString(k);
      if (raw == null) {
        allRecordsHandled = false;
        continue;
      }
      try {
        final model = AyahProgressModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        await _isar.writeTxn(() async {
          // The unique composite key makes a retry an upsert, not a duplicate.
          await _isar.isarAyahProgress.put(IsarAyahProgress.fromModel(model));
        });
        if (!await _prefs.remove(k)) {
          allRecordsHandled = false;
        }
      } catch (_) {
        allRecordsHandled = false;
        // Preserve the original payload for repair/support. The source key is
        // intentionally retained, so retrying this migration cannot lose it.
        await _prefs.setString('$_quarantinePrefix$k', raw);
      }
    }

    // Completion is durable only after every source record was persisted and
    // removed. A malformed or interrupted record keeps migration retryable.
    if (allRecordsHandled) {
      await _prefs.setBool(_migrationKey, true);
    }
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
