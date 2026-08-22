import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/data/datasources/quran_local_datasource.dart';
import 'package:talia_quran/features/quran/data/models/ayah_model.dart';
import 'package:talia_quran/features/quran/data/models/surah_model.dart';
import 'package:talia_quran/features/quran/data/repositories/quran_repository_impl.dart';

void main() {
  group('QuranRepositoryImpl', () {
    test('rejects page numbers outside the Mushaf range', () async {
      final repository = QuranRepositoryImpl(_FakeQuranDatasource());

      final beforeFirst = await repository.getQuranPage(0);
      final afterLast = await repository.getQuranPage(605);

      expect(beforeFirst.isLeft(), isTrue);
      expect(afterLast.isLeft(), isTrue);
    });

    test('returns only surahs present on the requested page', () async {
      final repository = QuranRepositoryImpl(_FakeQuranDatasource());

      final result = await repository.getQuranPage(2);
      final detail = result.getOrElse(() => throw StateError('failed'));

      expect(detail.pageNumber, 2);
      expect(detail.ayahs, hasLength(1));
      expect(detail.surahs.map((s) => s.id), [2]);
    });
  });
}

class _FakeQuranDatasource implements QuranLocalDatasource {
  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<List<AyahModel>> getAyahs(int surahId) async => const [];

  @override
  Future<List<AyahModel>> getAyahsByPage(int pageNumber) async {
    return switch (pageNumber) {
      1 => const [
        AyahModel(
          number: 1,
          surahId: 1,
          text: 'آية',
          numberInSurah: 1,
          page: 1,
        ),
      ],
      2 => const [
        AyahModel(
          number: 2,
          surahId: 2,
          text: 'آية',
          numberInSurah: 1,
          page: 2,
        ),
      ],
      _ => const [],
    };
  }

  @override
  Future<Map<int, List<AyahModel>>> getAyahsGroupedByJuz() async => const {};

  @override
  Future<List<SurahModel>> getSurahs() async => const [
    SurahModel(
      id: 1,
      nameAr: 'الفاتحة',
      nameEn: 'Al-Fatihah',
      ayahCount: 1,
      juz: 1,
      type: 'meccan',
      page: 1,
    ),
    SurahModel(
      id: 2,
      nameAr: 'البقرة',
      nameEn: 'Al-Baqarah',
      ayahCount: 1,
      juz: 1,
      type: 'medinan',
      page: 2,
    ),
  ];

  @override
  Future<List<AyahModel>> searchAyahs(String query) async => const [];
}
