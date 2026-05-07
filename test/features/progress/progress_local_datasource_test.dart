import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/constants/app_constants.dart';
import 'package:talia_quran/features/progress/data/datasources/progress_local_datasource.dart';

void main() {
  late SharedPreferences prefs;
  late ProgressLocalDatasourceImpl datasource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    datasource = ProgressLocalDatasourceImpl(prefs);
  });

  group('ProgressLocalDatasourceImpl', () {
    test('saves read pages once and preserves existing pages', () async {
      await datasource.saveReadPage(10);
      await datasource.saveReadPage(10);
      await datasource.saveReadPage(11);

      expect(datasource.getReadPages(), [10, 11]);
    });

    test('rejects page numbers outside the Quran page range', () async {
      expect(() => datasource.saveReadPage(0), throwsA(isA<ArgumentError>()));
      expect(() => datasource.saveReadPage(605), throwsA(isA<ArgumentError>()));
    });

    test('returns empty read pages when stored value is corrupted', () async {
      await prefs.setString(AppConstants.kReadPages, '{bad json');

      expect(datasource.getReadPages(), isEmpty);
    });

    test(
      'filters invalid and duplicate read pages from older stored data',
      () async {
        await prefs.setString(
          AppConstants.kReadPages,
          '[1, 1, 0, 604, 605, "x"]',
        );

        expect(datasource.getReadPages(), [1, 604]);
      },
    );

    test('saves streak days and last active date together', () async {
      final date = DateTime(2026, 5, 5);

      await datasource.saveStreak(7, date);

      expect(datasource.getStreakDays(), 7);
      expect(datasource.getLastActiveDate(), date);
    });
  });
}
