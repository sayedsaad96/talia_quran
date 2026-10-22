import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/learning_launch_context.dart';
import 'package:talia_quran/core/quran/ayah_target_validation.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  const target = AyahReference(surahId: 2, ayahNumber: 255);
  const detail = QuranPageDetail(
    pageNumber: 42,
    surahs: [],
    ayahs: [
      Ayah(number: 262, surahId: 2, text: '', numberInSurah: 255, page: 42),
    ],
  );

  test('returns a canonical target on its loaded page', () {
    expect(validatedInitialTargetForPage(detail: detail, target: target), (
      surah: 2,
      ayah: 255,
    ));
  });

  test('rejects a target whose loaded ayah is on another page', () {
    const wrongPage = QuranPageDetail(
      pageNumber: 42,
      surahs: [],
      ayahs: [
        Ayah(number: 262, surahId: 2, text: '', numberInSurah: 255, page: 43),
      ],
    );
    expect(
      validatedInitialTargetForPage(detail: wrongPage, target: target),
      isNull,
    );
  });

  test('rejects wrong-surah, missing, and absent targets', () {
    expect(
      validatedInitialTargetForPage(
        detail: detail,
        target: const AyahReference(surahId: 1, ayahNumber: 255),
      ),
      isNull,
    );
    expect(
      validatedInitialTargetForPage(
        detail: detail,
        target: const AyahReference(surahId: 2, ayahNumber: 256),
      ),
      isNull,
    );
    expect(validatedInitialTargetForPage(detail: detail, target: null), isNull);
  });
}
