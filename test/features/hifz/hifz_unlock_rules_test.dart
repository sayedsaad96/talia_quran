import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';
import 'package:talia_quran/features/hifz/domain/hifz_unlock_rules.dart';
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

  SurahHifzProgress completeProgress(int surahId) => SurahHifzProgress(
    surahId: surahId,
    totalAyahs: 10,
    memorizedCount: 10,
    reviewCount: 0,
    learningCount: 0,
  );

  group('buildUnlockedSurahIds', () {
    test('unlocks only the first surah when no surah is complete', () {
      final orderedSurahs = [buildSurah(1), buildSurah(2), buildSurah(3)];

      final unlocked = buildUnlockedSurahIds(
        orderedSurahs: orderedSurahs,
        progressMap: const {},
      );

      expect(unlocked, equals({1}));
    });

    test('unlocks the next surah after completing the previous one', () {
      final orderedSurahs = [buildSurah(1), buildSurah(2), buildSurah(3)];

      final unlocked = buildUnlockedSurahIds(
        orderedSurahs: orderedSurahs,
        progressMap: {1: completeProgress(1)},
      );

      expect(unlocked, equals({1, 2}));
    });

    test('respects backward path ordering', () {
      final orderedSurahs = [buildSurah(114), buildSurah(113), buildSurah(112)];

      final unlocked = buildUnlockedSurahIds(
        orderedSurahs: orderedSurahs,
        progressMap: {114: completeProgress(114)},
      );

      expect(unlocked, equals({114, 113}));
    });

    test('locks later surahs when a middle surah is still incomplete', () {
      final orderedSurahs = [buildSurah(1), buildSurah(2), buildSurah(3)];

      final unlocked = buildUnlockedSurahIds(
        orderedSurahs: orderedSurahs,
        progressMap: {
          1: completeProgress(1),
          2: const SurahHifzProgress(
            surahId: 2,
            totalAyahs: 10,
            memorizedCount: 4,
            reviewCount: 3,
            learningCount: 3,
          ),
        },
      );

      expect(unlocked, equals({1, 2}));
      expect(unlocked.contains(3), isFalse);
    });
  });

  group('sortSurahsForHifzPath', () {
    test('sorts ascending for forward path', () {
      final sorted = sortSurahsForHifzPath(
        surahs: [buildSurah(5), buildSurah(2), buildSurah(3)],
        path: 'forward',
      );

      expect(sorted.map((surah) => surah.id).toList(), equals([2, 3, 5]));
    });

    test('sorts descending for backward path', () {
      final sorted = sortSurahsForHifzPath(
        surahs: [buildSurah(5), buildSurah(2), buildSurah(3)],
        path: 'backward',
      );

      expect(sorted.map((surah) => surah.id).toList(), equals([5, 3, 2]));
    });
  });
}
