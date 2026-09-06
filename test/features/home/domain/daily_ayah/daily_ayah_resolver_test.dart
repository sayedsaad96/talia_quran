import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/home/domain/daily_ayah/daily_ayah_reference.dart';
import 'package:talia_quran/features/home/domain/daily_ayah/daily_ayah_resolver.dart';
import 'package:talia_quran/features/home/domain/daily_ayah/daily_ayah_result.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

void main() {
  group('DailyAyahResolver', () {
    late _QuranRepositoryFake repository;
    late DailyAyahResolver resolver;

    setUp(() {
      repository = _QuranRepositoryFake();
      resolver = DailyAyahResolver(repository);
    });

    test('selects the same reference throughout one local day', () {
      final morning = resolver.referenceFor(DateTime(2026, 9, 6, 1));
      final evening = resolver.referenceFor(DateTime(2026, 9, 6, 23, 59));

      expect(morning.surahId, evening.surahId);
      expect(morning.ayahNumber, evening.ayahNumber);
    });

    test('uses civil dates across a daylight-saving transition', () {
      final beforeTransition = resolver.referenceFor(DateTime(2026, 3, 28));
      final transitionDay = resolver.referenceFor(DateTime(2026, 3, 29));

      final beforeIndex = DailyAyahResolver.references.indexWhere(
        (reference) =>
            reference.surahId == beforeTransition.surahId &&
            reference.ayahNumber == beforeTransition.ayahNumber,
      );
      expect(
        transitionDay,
        DailyAyahResolver.references[(beforeIndex + 1) % 30],
      );
    });

    test('rotates to a different reference on the following local day', () {
      final firstDay = resolver.referenceFor(DateTime(2026, 9, 6));
      final nextDay = resolver.referenceFor(DateTime(2026, 9, 7));

      expect((
        nextDay.surahId,
        nextDay.ayahNumber,
      ), isNot((firstDay.surahId, firstDay.ayahNumber)));
    });

    test('uses Quran text returned by the repository', () async {
      final date = DateTime(2026, 9, 6);
      final reference = resolver.referenceFor(date);
      const trustedText = 'نص من مستودع القرآن';
      repository.detail = _detailFor(reference, text: trustedText);

      final result = await resolver.resolveFor(date);

      expect(result, isA<DailyAyahResolved>());
      expect((result as DailyAyahResolved).ayah.text, trustedText);
      expect(result.ayah.surahId, reference.surahId);
      expect(result.ayah.numberInSurah, reference.ayahNumber);
    });

    test('maps a repository failure to a local unavailable result', () async {
      const failure = CacheFailure();
      repository.failure = failure;

      final result = await resolver.resolveFor(DateTime(2026, 9, 6));

      expect(result, isA<DailyAyahUnavailable>());
      expect((result as DailyAyahUnavailable).failure, failure);
    });

    test(
      'returns a local failure when the reference is absent from the surah',
      () async {
        final date = DateTime(2026, 9, 6);
        final reference = resolver.referenceFor(date);
        repository.detail = SurahDetail(
          surah: _surahFor(reference),
          ayahs: const [],
        );

        final result = await resolver.resolveFor(date);

        expect(result, isA<DailyAyahUnavailable>());
        expect(
          (result as DailyAyahUnavailable).failure,
          isA<NotFoundFailure>(),
        );
      },
    );

    test('exposes the exact reader route for a resolved reference', () async {
      final date = DateTime(2026, 9, 6);
      final reference = resolver.referenceFor(date);
      repository.detail = _detailFor(reference, text: 'نص موثوق', page: 42);

      final result = await resolver.resolveFor(date) as DailyAyahResolved;
      final location = Uri.parse(result.readerLocation!);

      expect(location.path, '/quran/page/42');
      expect(location.queryParameters['surahId'], '${reference.surahId}');
      expect(location.queryParameters['ayahNumber'], '${reference.ayahNumber}');
    });
  });
}

SurahDetail _detailFor(
  DailyAyahReference reference, {
  required String text,
  int? page,
}) => SurahDetail(
  surah: _surahFor(reference),
  ayahs: [
    Ayah(
      number: reference.ayahNumber,
      surahId: reference.surahId,
      text: text,
      numberInSurah: reference.ayahNumber,
      page: page,
    ),
  ],
);

Surah _surahFor(DailyAyahReference reference) => Surah(
  id: reference.surahId,
  nameAr: 'سورة اختبار',
  nameEn: 'Test Surah',
  ayahCount: reference.ayahNumber,
  juz: 1,
  type: 'meccan',
  page: 1,
);

class _QuranRepositoryFake implements QuranRepository {
  SurahDetail? detail;
  Failure? failure;

  @override
  Future<Either<Failure, QuranPageDetail>> getQuranPage(int pageNumber) async =>
      const Left(NotFoundFailure());

  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    final currentFailure = failure;
    if (currentFailure != null) return Left(currentFailure);
    final currentDetail = detail;
    if (currentDetail == null) {
      return const Left(NotFoundFailure());
    }
    return Right(currentDetail);
  }

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() async => const Right([]);

  @override
  Future<Either<Failure, List<Ayah>>> searchAyahs(String query) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<Surah>>> searchSurahs(String query) async =>
      const Right([]);
}
