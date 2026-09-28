import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_quiz_source.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _MockMemRepo extends Mock implements MemorizationPlusRepository {}

class _MockQuranRepo extends Mock implements QuranRepository {}

AyahReviewRecord _record(int s, int a, {int reviews = 2}) => AyahReviewRecord(
  surahId: s,
  ayahNumber: a,
  strengthLevel: 3,
  intervalDays: 2,
  lastReviewedAt: DateTime(2026, 9, 1),
  nextReviewDate: DateTime(2026, 9, 3),
  totalReviews: reviews,
  lastRating: PerformanceRating.average,
);

Surah _surah(int id) => Surah(
  id: id,
  nameAr: 'سورة $id',
  nameEn: 'Surah $id',
  ayahCount: 2,
  juz: 1,
  type: 'meccan',
  page: 1,
);

SurahDetail _detail(int id) => SurahDetail(
  surah: _surah(id),
  ayahs: [
    for (var a = 1; a <= 2; a++)
      Ayah(number: id * 10 + a, surahId: id, text: 't$id-$a', numberInSurah: a),
  ],
);

void main() {
  late _MockMemRepo mem;
  late _MockQuranRepo quran;

  setUpAll(() => registerFallbackValue(ReviewRecordReadScope.adult));

  setUp(() {
    mem = _MockMemRepo();
    quran = _MockQuranRepo();
    when(() => quran.getSurahs()).thenAnswer(
      (_) async => Right([for (var s = 1; s <= 114; s++) _surah(s)]),
    );
    when(() => quran.getSurahDetail(any())).thenAnswer(
      (inv) async => Right(_detail(inv.positionalArguments.first as int)),
    );
  });

  test('reads adult scope and keeps only started records as prompts', () async {
    when(() => mem.getAllReviewRecords(scope: any(named: 'scope'))).thenAnswer(
      (_) async =>
          Right([_record(1, 1), _record(2, 2, reviews: 0), _record(1, 1)]),
    );

    final result = await ListeningQuizSource(mem, quran).load();
    final material = result.getOrElse(() => throw StateError('expected Right'));

    verify(
      () => mem.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).called(1);
    expect(material.prompts, const [ListeningAyahRef(1, 1)]);
    expect(material.corpus.textOf(const ListeningAyahRef(2, 2)), 't2-2');
    expect(material.surahs[114]!.nameEn, 'Surah 114');
  });

  test('fails closed when records cannot be read', () async {
    when(
      () => mem.getAllReviewRecords(scope: any(named: 'scope')),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    expect((await ListeningQuizSource(mem, quran).load()).isLeft(), isTrue);
  });

  test('fails closed when any surah detail cannot be read', () async {
    when(
      () => mem.getAllReviewRecords(scope: any(named: 'scope')),
    ).thenAnswer((_) async => Right([_record(1, 1)]));
    when(
      () => quran.getSurahDetail(57),
    ).thenAnswer((_) async => const Left(ParseFailure()));
    expect((await ListeningQuizSource(mem, quran).load()).isLeft(), isTrue);
  });

  test('fails closed when the surah list is incomplete', () async {
    when(
      () => mem.getAllReviewRecords(scope: any(named: 'scope')),
    ).thenAnswer((_) async => Right([_record(1, 1)]));
    when(() => quran.getSurahs()).thenAnswer((_) async => Right([_surah(1)]));
    expect((await ListeningQuizSource(mem, quran).load()).isLeft(), isTrue);
  });
}
