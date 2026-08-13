import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/surah_path_ordering.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  Surah buildSurah(int id) => Surah(
    id: id,
    nameAr: 'سورة $id',
    nameEn: 'Surah $id',
    ayahCount: 10,
    juz: 1,
    type: 'meccan',
    page: id,
  );

  group('sortSurahsForPracticePath', () {
    test('sorts ascending for forward path', () {
      final sorted = sortSurahsForPracticePath(
        surahs: [buildSurah(5), buildSurah(2), buildSurah(3)],
        path: 'forward',
      );

      expect(sorted.map((surah) => surah.id).toList(), equals([2, 3, 5]));
    });

    test('sorts descending for backward path', () {
      final sorted = sortSurahsForPracticePath(
        surahs: [buildSurah(5), buildSurah(2), buildSurah(3)],
        path: 'backward',
      );

      expect(sorted.map((surah) => surah.id).toList(), equals([5, 3, 2]));
    });
  });
}
