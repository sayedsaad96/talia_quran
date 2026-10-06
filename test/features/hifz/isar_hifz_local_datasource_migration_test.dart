import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/constants/app_constants.dart';
import 'package:talia_quran/features/hifz/data/datasources/isar_hifz_local_datasource_impl.dart';
import 'package:talia_quran/features/hifz/data/models/ayah_progress_model.dart';
import 'package:talia_quran/features/hifz/data/models/isar_ayah_progress.dart';
import '../../helpers/isar_test_core.dart';


Future<void> _prepareIsar() => initializeIsarCoreForTests();

void main() {
  test('preserves malformed legacy progress while migrating valid rows', () async {
    await _prepareIsar();
    const validKey = '${AppConstants.kHifzProgress}_1_1';
    const malformedKey = '${AppConstants.kHifzProgress}_1_2';
    SharedPreferences.setMockInitialValues({
      validKey: jsonEncode(AyahProgressModel.initial(1, 1).toJson()),
      malformedKey: '{not json',
    });
    final prefs = await SharedPreferences.getInstance();
    final directory = await Directory.systemTemp.createTemp('talia_hifz_migration_');
    final isar = await Isar.open(
      [IsarAyahProgressSchema],
      directory: directory.path,
      name: 'migration_${DateTime.now().microsecondsSinceEpoch}',
    );
    addTearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    final datasource = IsarHifzLocalDatasourceImpl(isar, prefs);
    await datasource.migrateFromSharedPreferencesIfNeeded();

    expect((await datasource.getAllProgress()).map((row) => row.ayahNumber), [1]);
    expect(prefs.getString(validKey), isNull);
    expect(prefs.getString(malformedKey), '{not json');
    expect(prefs.getBool('hifz_isar_migrated'), isNot(true));
  });
}
