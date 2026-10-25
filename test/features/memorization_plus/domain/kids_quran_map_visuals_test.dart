import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_quran_map_visuals.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_surah_house_summary_builder.dart';

KidsSurahHouse _house(
  int surahId, {
  KidsSurahHouseStatus status = KidsSurahHouseStatus.inProgress,
  int ayahCount = 7,
  int completedCount = 0,
}) => KidsSurahHouse(
  surahId: surahId,
  ayahCount: ayahCount,
  juz: 1,
  status: status,
  completedCount: completedCount,
);

void main() {
  group('kidsSurahStars', () {
    test('no progress earns no stars', () {
      expect(kidsSurahStars(_house(1)), 0);
    });

    test('a third of the ayahs earns one star', () {
      expect(kidsSurahStars(_house(2, ayahCount: 3, completedCount: 1)), 1);
    });

    test('two thirds of the ayahs earn two stars', () {
      expect(kidsSurahStars(_house(3, ayahCount: 3, completedCount: 2)), 2);
    });

    test('a third of the way down rounds down', () {
      expect(kidsSurahStars(_house(4, ayahCount: 7, completedCount: 3)), 1);
    });

    test('a completed surah always shows three stars', () {
      expect(
        kidsSurahStars(
          _house(
            5,
            status: KidsSurahHouseStatus.completed,
            ayahCount: 7,
            completedCount: 7,
          ),
        ),
        3,
      );
    });

    test('a surah awaiting review keeps what progress earned (full)', () {
      expect(
        kidsSurahStars(
          _house(
            6,
            status: KidsSurahHouseStatus.needsReview,
            ayahCount: 5,
            completedCount: 5,
          ),
        ),
        3,
      );
    });

    test('a surah awaiting review keeps what progress earned (partial)', () {
      expect(
        kidsSurahStars(
          _house(
            7,
            status: KidsSurahHouseStatus.needsReview,
            ayahCount: 6,
            completedCount: 2,
          ),
        ),
        1,
      );
    });

    test('a surah with no ayahs earns no stars', () {
      expect(kidsSurahStars(_house(8, ayahCount: 0)), 0);
    });
  });

  group('kidsIslandForRow', () {
    test('adjacent rows never share an island', () {
      for (var i = 0; i <= 113; i++) {
        expect(
          kidsIslandForRow(i + 1),
          isNot(kidsIslandForRow(i)),
          reason: 'rows $i and ${i + 1} share an island',
        );
      }
    });

    test('every island asset path lives under the islands folder', () {
      for (final island in KidsIsland.values) {
        expect(
          island.asset,
          startsWith('assets/images/kids/islands/'),
          reason: '${island.name} asset',
        );
        expect(island.asset, endsWith('.png'), reason: '${island.name} asset');
        expect(
          island.asset,
          'assets/images/kids/islands/island_${island.name}.png',
        );
      }
    });
  });
}
