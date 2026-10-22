import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/prayer_review/application/prayer_review_quran_reader.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _Quran implements QuranRepository {
  _Quran(this.ayahs);
  final List<Ayah> ayahs;
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int id) async => Right(
    SurahDetail(
      surah: Surah(
        id: id,
        nameAr: '',
        nameEn: '',
        ayahCount: 7,
        juz: 1,
        type: 'meccan',
        page: 1,
      ),
      ayahs: ayahs,
    ),
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final ayahs = [
    for (var n = 1; n <= 7; n++)
      Ayah(
        number: n,
        surahId: 1,
        numberInSurah: n,
        page: 1,
        text: 'body $n  exact',
      ),
  ];
  final selection = PrayerReviewSelection(
    ownerId: 'owner',
    localDayKey: '2026-10-20',
    prayerKey: PrayerKey.fajr,
    scheduledAt: DateTime.utc(2026, 10, 20, 4),
    selectedAt: DateTime.utc(2026, 10, 20, 3),
    surahId: 1,
    startAyah: 2,
    endAyah: 4,
  );

  test(
    'selected range retains original Ayah objects in canonical order',
    () async {
      final reader = PrayerReviewQuranReader(_Quran(ayahs));
      final result = await reader.readPassage(selection);
      expect(result, ayahs.sublist(1, 4));
      expect(identical(result.first, ayahs[1]), isTrue);
      expect(result.map((a) => a.text), [
        'body 2  exact',
        'body 3  exact',
        'body 4  exact',
      ]);
    },
  );

  test(
    'missing and duplicate references reject instead of partial passage',
    () async {
      for (final malformed in [
        ayahs.where((a) => a.numberInSurah != 3).toList(),
        [...ayahs, ayahs[2]],
      ]) {
        await expectLater(
          PrayerReviewQuranReader(_Quran(malformed)).readPassage(selection),
          throwsFormatException,
        );
      }
    },
  );
}
