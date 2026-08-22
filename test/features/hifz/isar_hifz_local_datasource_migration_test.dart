import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/constants/app_constants.dart';
import 'package:talia_quran/features/hifz/data/datasources/isar_hifz_local_datasource_impl.dart';
import 'package:talia_quran/features/hifz/data/models/ayah_progress_model.dart';
import 'package:talia_quran/features/hifz/data/models/isar_ayah_progress.dart';

bool _isarReady = false;

Future<void> _prepareIsar() async {
  if (_isarReady) return;
  if (Platform.isWindows) {
    final appData = Platform.environment['LOCALAPPDATA'];
    final path = appData == null
        ? null
        : '$appData\\Pub\\Cache\\hosted\\pub.dev\\'
            'isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
    if (path != null && File(path).existsSync()) {
      await Isar.initializeIsarCore(libraries: {Abi.current(): path});
      _isarReady = true;
      return;
    }
  }
  await Isar.initializeIsarCore();
  _isarReady = true;
}

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
