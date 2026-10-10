import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/get_next_practice_passage_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _Quran extends Mock implements QuranRepository {}

void main() {
  late _Quran quran;
  late GetNextPracticePassageUseCase next;
  final ayahs = [
    for (var number = 1; number <= 6; number++)
      Ayah(
        number: number,
        surahId: 114,
        text: 'fixture',
        numberInSurah: number,
      ),
  ];
  final detail = SurahDetail(
    surah: const Surah(
      id: 114,
      nameAr: '',
      nameEn: '',
      ayahCount: 6,
      juz: 30,
      type: 'meccan',
      page: 604,
    ),
    ayahs: ayahs,
  );
  setUp(() {
    quran = _Quran();
    next = GetNextPracticePassageUseCase(quran);
    when(
      () => quran.getSurahDetail(114),
    ).thenAnswer((_) async => Right(detail));
  });

  test(
    'split practice continues at the next ayah with the chosen size',
    () async {
      final step = await next(
        surahId: 114,
        completedThroughAyah: 2,
        passageSize: 2,
      );
      expect(step, isNotNull);
      expect(step!.remaining, 4);
      final uri = Uri.parse(step.route);
      expect(uri.queryParameters, containsPair('surahId', '114'));
      expect(uri.queryParameters, containsPair('startAyah', '3'));
      expect(uri.queryParameters, containsPair('blockSize', '2'));
      expect(uri.queryParameters, containsPair('origin', 'surahPractice'));
    },
  );

  test('last passage clips to the actual remaining ayahs', () async {
    final step = await next(
      surahId: 114,
      completedThroughAyah: 4,
      passageSize: 4,
    );
    expect(step!.remaining, 2);
    expect(Uri.parse(step.route).queryParameters['blockSize'], '2');
  });

  test('whole-surah completion never starts another surah', () async {
    expect(
      await next(surahId: 114, completedThroughAyah: 6, passageSize: 6),
      isNull,
    );
  });

  test('canonical lookup failure does not invent a next passage', () async {
    when(
      () => quran.getSurahDetail(114),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    expect(
      await next(surahId: 114, completedThroughAyah: 2, passageSize: 2),
      isNull,
    );
  });

  test('missing canonical ayah does not produce an invalid range', () async {
    when(() => quran.getSurahDetail(114)).thenAnswer(
      (_) async => Right(
        SurahDetail(
          surah: detail.surah,
          ayahs: ayahs.where((a) => a.numberInSurah != 3).toList(),
        ),
      ),
    );
    expect(
      await next(surahId: 114, completedThroughAyah: 2, passageSize: 2),
      isNull,
    );
  });
}
