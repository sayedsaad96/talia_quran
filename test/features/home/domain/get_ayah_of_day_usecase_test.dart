import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/home/domain/entities/ayah_of_day.dart';
import 'package:talia_quran/features/home/domain/services/daily_ayah_context_resolver.dart';
import 'package:talia_quran/features/home/domain/usecases/get_ayah_of_day_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  // Without the binding the usecase cannot read the bundled asset and silently
  // falls back to its 5-entry list, which would hide rotation regressions.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cycles through 35 distinct general ayahs on matching calendar days', () async {
    final selectedRefs = <String>{};
    var day = DateTime(2026, 1, 1);

    while (selectedRefs.length < 35) {
      if (day.weekday == DateTime.friday) {
        day = day.add(const Duration(days: 1));
        continue;
      }
      final ayah = await GetAyahOfDayUsecase(
        const _AnyAyahQuranRepository(),
        now: () => day,
        contextResolver: const DailyAyahContextResolver(
          hijriDateFor: _noHijriDate,
        ),
      )();
      selectedRefs.add('${ayah!.surahId}:${ayah.ayahNumber}');
      day = day.add(const Duration(days: 1));
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

  test('daily ayah source includes seasonal and goal-specific guidance', () {
    final dailyRefs = jsonDecode(
      File('assets/data/daily_ayahs.json').readAsStringSync(),
    ) as List<dynamic>;
    final tags = dailyRefs
        .cast<Map<String, dynamic>>()
        .expand((ref) => (ref['tags'] as List<dynamic>? ?? const <dynamic>[]))
        .whereType<String>()
        .toSet();

    expect(
      tags,
      containsAll(<String>[
        'ramadanStart',
        'ramadan',
        'lastTenNights',
        'friday',
        'dhulHijjah',
        'arafah',
        'eidAlAdha',
        'reading',
        'memorization',
        'smartReview',
        'azkar',
        'childJourney',
      ]),
    );
  });

  test('prioritizes seasonal guidance, then the user goal, then general ayahs',
      () async {
    final ramadanAyah = await GetAyahOfDayUsecase(
      const _AnyAyahQuranRepository(),
      now: () => DateTime(2026, 2, 18),
      contextResolver: DailyAyahContextResolver(
        hijriDateFor: (_) => const DailyAyahHijriDate(month: 9, day: 1),
      ),
    )(userGoal: 'memorization');

    final goalAyah = await GetAyahOfDayUsecase(
      const _AnyAyahQuranRepository(),
      now: () => DateTime(2026, 2, 18),
      contextResolver: const DailyAyahContextResolver(
        hijriDateFor: _noHijriDate,
      ),
    )(userGoal: 'memorization');

    final generalAyah = await GetAyahOfDayUsecase(
      const _AnyAyahQuranRepository(),
      now: () => DateTime(2026, 2, 18),
      contextResolver: const DailyAyahContextResolver(
        hijriDateFor: _noHijriDate,
      ),
    )();

    expect(ramadanAyah!.context, DailyAyahContext.ramadanStart);
    expect('${ramadanAyah.surahId}:${ramadanAyah.ayahNumber}', anyOf('2:183', '2:185'));
    expect(goalAyah!.context, DailyAyahContext.memorization);
    expect('${goalAyah.surahId}:${goalAyah.ayahNumber}', '54:17');
    expect(generalAyah!.context, DailyAyahContext.general);
  });
}

DailyAyahHijriDate? _noHijriDate(DateTime _) => null;

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
