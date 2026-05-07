import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/constants/app_constants.dart';
import 'package:talia_quran/features/hifz/data/datasources/hifz_local_datasource.dart';
import 'package:talia_quran/features/hifz/data/models/ayah_progress_model.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';

void main() {
  late SharedPreferences prefs;
  late HifzLocalDatasourceImpl datasource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    datasource = HifzLocalDatasourceImpl(prefs);
  });

  group('HifzLocalDatasourceImpl', () {
    test('saves and loads ayah progress by surah and ayah', () async {
      final progress = AyahProgressModel.initial(
        2,
        255,
      ).advanceWithSpacedRepetition();

      await datasource.saveAyahProgress(progress);

      final loaded = await datasource.getAyahProgress(2, 255);
      expect(loaded, isNotNull);
      expect(loaded!.surahId, 2);
      expect(loaded.ayahNumber, 255);
      expect(loaded.status, AyahStatus.review);
      expect(loaded.repetitions, 1);
    });

    test('ignores corrupted stored progress instead of throwing', () async {
      await prefs.setString('${AppConstants.kHifzProgress}_1_1', '{bad json');
      await prefs.setString(
        '${AppConstants.kHifzProgress}_1_2',
        jsonEncode(AyahProgressModel.initial(1, 2).toJson()),
      );

      final progress = await datasource.getProgressForSurah(1);

      expect(progress, hasLength(1));
      expect(progress.single.ayahNumber, 2);
    });

    test('rejects unsupported hifz path values', () async {
      expect(
        () => datasource.saveHifzPath('sideways'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('saves supported hifz path values', () async {
      await datasource.saveHifzPath('backward');

      expect(datasource.getHifzPath(), 'backward');
    });
  });
}
