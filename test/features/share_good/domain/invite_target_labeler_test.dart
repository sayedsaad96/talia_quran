import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/services/invite_target_labeler.dart';

class FakeQuranRepository extends Mock implements QuranRepository {}

void main() {
  test('labeler resolves surah pages without returning ayah text', () async {
    final repository = FakeQuranRepository();
    const surah = Surah(
      id: 18,
      nameAr: 'الكهف',
      nameEn: 'Al-Kahf',
      ayahCount: 2,
      juz: 15,
      type: 'meccan',
      page: 293,
    );
    const detail = SurahDetail(
      surah: surah,
      ayahs: [
        Ayah(
          number: 1,
          surahId: 18,
          text: 'sacred text',
          numberInSurah: 1,
          page: 293,
        ),
        Ayah(
          number: 2,
          surahId: 18,
          text: 'sacred text',
          numberInSurah: 2,
          page: 304,
        ),
      ],
    );
    when(
      () => repository.getSurahDetail(18),
    ).thenAnswer((_) async => const Right(detail));
    final result = await InviteTargetLabeler(
      repository,
    ).label(const QuranSurahInviteTarget(18), arabic: true);
    result.fold((failure) => fail('$failure'), (label) {
      expect(label.title, 'الكهف');
      expect(label.startPage, 293);
      expect(label.endPage, 304);
      expect(label.title, isNot(contains('sacred text')));
    });
  });
}
