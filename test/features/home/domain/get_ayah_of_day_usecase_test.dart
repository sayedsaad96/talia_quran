import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/home/domain/usecases/get_ayah_of_day_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  // Without the binding the usecase cannot read the bundled asset and silently
  // falls back to its 5-entry list, which would hide rotation regressions.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cycles through every daily ayah reference across 35 calendar days', () async {
    final selectedRefs = <String>{};
    final firstDay = DateTime(2026, 1, 1);

    for (var offset = 0; offset < 35; offset++) {
      final ayah = await GetAyahOfDayUsecase(
        const _AnyAyahQuranRepository(),
        now: () => firstDay.add(Duration(days: offset)),
      )();
      selectedRefs.add('${ayah!.surahId}:${ayah.ayahNumber}');
    }

    expect(selectedRefs, hasLength(35));
  });

  test('every daily ayah reference exists in the bundled Quran corpus', () {
    final dailyRefs = jsonDecode(
      File('assets/data/daily_ayahs.json').readAsStringSync(),
    ) as List<dynamic>;
    final corpus = jsonDecode(
      File('assets/data/quran.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    for (final ref in dailyRefs.cast<Map<String, dynamic>>()) {
      final surahId = ref['surahId'] as int;
      final ayahNumber = ref['ayahNumber'] as int;
      final ayahs = corpus['$surahId'] as List<dynamic>;

      expect(
        ayahs.any((ayah) => (ayah as Map<String, dynamic>)['verse'] == ayahNumber),
        isTrue,
        reason: 'Missing Quran reference $surahId:$ayahNumber',
      );
    }
  });
}

class _AnyAyahQuranRepository implements QuranRepository {
  const _AnyAyahQuranRepository();

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async => Right(
    SurahDetail(
      surah: Surah(
        id: surahId,
        nameAr: 'سورة',
        nameEn: 'Surah',
        ayahCount: 300,
        juz: 1,
        type: 'meccan',
        page: 1,
      ),
      ayahs: [
        for (var ayahNumber = 1; ayahNumber <= 300; ayahNumber++)
          Ayah(
            number: ayahNumber,
            surahId: surahId,
            text: 'آية $ayahNumber',
            numberInSurah: ayahNumber,
            page: 1,
          ),
      ],
    ),
  );

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() => throw UnimplementedError();

  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) =>
      throw UnimplementedError();
}
