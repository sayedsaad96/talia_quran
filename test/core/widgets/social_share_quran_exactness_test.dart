import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  test('quranAyah removes only its matching terminal number', () {
    const sacredText = '  وَٱلتِّينِ وَٱلزَّيْتُونِ\u00A0١\n';
    const ayah = Ayah(
      number: 6099,
      surahId: 95,
      text: sacredText,
      numberInSurah: 1,
      juz: 30,
      page: 597,
    );

    final share = SocialShareData.quranAyah(ayah: ayah, surahName: 'التين');

    expect(share.content, '  وَٱلتِّينِ وَٱلزَّيْتُونِ');
    expect(ayah.text, sacredText);
  });

  test(
    'quranVerse removes a matching terminal number from bookmarked text',
    () {
      const sacredText =
          '\uFEFF  إِنَّآ أَنزَلْنَٰهُ فِى لَيْلَةِ ٱلْقَدْرِ ﴿١﴾';

      final share = SocialShareData.quranVerse(
        ayahText: sacredText,
        surahName: 'القدر',
        ayahNumber: 1,
      );

      expect(
        share.content,
        '\uFEFF  إِنَّآ أَنزَلْنَٰهُ فِى لَيْلَةِ ٱلْقَدْرِ',
      );
      expect(
        share.toPlainShareText(footer: 'تالية'),
        contains('﴿ إِنَّآ أَنزَلْنَٰهُ فِى لَيْلَةِ ٱلْقَدْرِ ﴾'),
      );
    },
  );

  test(
    'dua share preserves approved text and citation character-for-character',
    () {
      const sacredText = '  رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً\n';
      const citation = '  القرآن 2:201  ';
      const zikr = Zikr(
        id: 'approved-dua-001',
        text: sacredText,
        transliteration: '',
        translation: '',
        totalCount: 1,
        category: AzkarCategory.duas,
        reference: citation,
        citation: citation,
        sourceType: 'quran',
        tier: DuaTier.essential,
        reviewStatus: ContentReviewStatus.approved,
        datasetVersion: 'v1-reviewed-1',
      );

      final share = SocialShareData.dua(zikr: zikr);

      expect(share.content, sacredText);
      expect(share.subtitle, citation);
    },
  );
}
