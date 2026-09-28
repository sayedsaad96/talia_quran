import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/heroes/text_hero.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/talia_share_tokens.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

import 'share_test_harness.dart';

void main() {
  const isra9 =
      'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ وَيُبَشِّرُ الْمُؤْمِنِينَ';
  const ayatAlKursi =
      'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
      'لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۚ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ '
      'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ '
      'وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضِ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ';

  Widget hero(SocialShareData data, SocialShareFormat format) => TextHero(
    data: data,
    palette: SharePalettes.mushafLight,
    metrics: TaliaShareMetrics.of(format),
  );

  SocialShareData verse(String text, {String? translation}) =>
      SocialShareData.quranAyah(
        ayah: Ayah(number: 9, surahId: 17, text: text, numberInSurah: 9),
        surahName: 'الإسراء',
        translation: translation,
      );

  testWidgets('renders the verse verbatim in Amiri with its reference', (
    tester,
  ) async {
    await tester.pumpWidget(
      shareHarness(hero(verse(isra9), SocialShareFormat.portrait)),
    );
    expect(find.text('﴿ $isra9 ﴾'), findsOneWidget);
    expect(find.text('سورة الإسراء · الآية 9'), findsOneWidget);
    final style = tester
        .widget<Text>(find.byKey(const ValueKey('share-hero-text')))
        .style!;
    expect(style.fontFamily, 'Amiri');
    expect(tester.takeException(), isNull);
  });

  testWidgets('English cards add the translation, Arabic cards do not', (
    tester,
  ) async {
    final data = verse(isra9, translation: 'Indeed, this Quran guides');
    await tester.pumpWidget(
      shareHarness(
        hero(data, SocialShareFormat.portrait),
        locale: const Locale('en'),
      ),
    );
    expect(find.textContaining('Indeed, this Quran guides'), findsOneWidget);
    expect(find.text('Surah الإسراء · Ayah 9'), findsOneWidget);

    await tester.pumpWidget(
      shareHarness(hero(data, SocialShareFormat.portrait)),
    );
    expect(find.textContaining('Indeed, this Quran guides'), findsNothing);
  });

  testWidgets('dua keeps its text and approved reference verbatim', (
    tester,
  ) async {
    const text =
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.';
    const data = SocialShareData(
      content: text,
      subtitle: 'سورة البقرة - 201',
      category: SocialShareCategory.dua,
    );
    await tester.pumpWidget(
      shareHarness(hero(data, SocialShareFormat.portrait)),
    );
    expect(find.text('« $text »'), findsOneWidget);
    expect(find.text('سورة البقرة - 201'), findsOneWidget);
  });

  for (final format in SocialShareFormat.values) {
    testWidgets('Ayat al-Kursi fits the $format hero without overflow', (
      tester,
    ) async {
      final canvas = format.exportLogicalSize;
      // The hero area is roughly the canvas minus eyebrow and signature.
      final heroSize = Size(canvas.width - 72, canvas.height * 0.52);
      await tester.pumpWidget(
        shareHarness(hero(verse(ayatAlKursi), format), size: heroSize),
      );
      expect(
        find.textContaining('وَهُوَ الْعَلِيُّ الْعَظِيمُ'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
