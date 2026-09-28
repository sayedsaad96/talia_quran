import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_card.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_sheet.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

import 'share_test_harness.dart';

const _isra9 =
    'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ وَيُبَشِّرُ الْمُؤْمِنِينَ';

SocialShareData _ayah({
  String? userName,
  SocialShareAudience audience = SocialShareAudience.adult,
  String text = _isra9,
}) => SocialShareData.quranAyah(
  ayah: Ayah(number: 9, surahId: 17, text: text, numberInSurah: 9),
  surahName: 'الإسراء',
  userName: userName,
).copyWith(audience: audience);

SocialShareData _sampleFor(SocialShareCategory category) {
  switch (category) {
    case SocialShareCategory.quranAyah:
      return _ayah(userName: 'سيد');
    case SocialShareCategory.dua:
      return const SocialShareData(
        content: 'رَبِّ زِدْنِي عِلْمًا',
        subtitle: 'سورة طه - 114',
        category: SocialShareCategory.dua,
      );
    case SocialShareCategory.azkar:
      return SocialShareData.azkarWird(
        categoryTitle: 'أذكار الصباح',
        completedCount: 12,
        totalCount: 15,
      );
    case SocialShareCategory.achievement:
      return const SocialShareData(
        content: 'قرأت جزءاً كاملاً',
        title: 'قارئ جزء كامل',
        category: SocialShareCategory.achievement,
        achievementIcon: '📖',
      );
    case SocialShareCategory.memorization:
      return SocialShareData.memorization(
        ayahsCount: 250,
        surahsCount: 12,
        targetAyahs: 500,
      );
    case SocialShareCategory.streak:
      return SocialShareData.streak(
        streakDays: 45,
        longestStreak: 45,
        userName: 'سيد',
      );
    case SocialShareCategory.progress:
      return const SocialShareData(
        content: '',
        category: SocialShareCategory.progress,
        readPagesCount: 85,
        memorizedAyahsCount: 250,
        streakDays: 14,
      );
    case SocialShareCategory.certificate:
      return const SocialShareData(
        content: 'شهادة إتمام جزء عمّ',
        category: SocialShareCategory.certificate,
        verificationCode: 'TQ-1',
      );
    case SocialShareCategory.khatmah:
      return const SocialShareData(
        content: 's',
        title: 'ختمة رمضان',
        category: SocialShareCategory.khatmah,
        targetValue: 30,
        readPagesCount: 604,
      );
  }
}

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    SocialShareData data, {
    SocialShareMood mood = SocialShareMood.auto,
    SocialShareFormat format = SocialShareFormat.portrait,
    Locale locale = const Locale('ar'),
    bool hideUserName = false,
  }) async {
    useCanvasView(tester);
    await tester.pumpWidget(
      shareHarness(
        buildSocialShareCardCanvas(
          data: data,
          mood: mood,
          format: format,
          hideUserName: hideUserName,
        ),
        size: format.exportLogicalSize,
        locale: locale,
      ),
    );
  }

  testWidgets(
    'ayah card: eyebrow, reference, watermark, one logo, invitation and QR',
    (tester) async {
      await pumpCard(tester, _ayah(userName: 'سيد'));
      expect(find.text('آية قرآنية'), findsOneWidget);
      expect(find.text('سورة الإسراء · الآية 9'), findsOneWidget);
      expect(find.byKey(const ValueKey('share-watermark')), findsOneWidget);
      expect(find.byKey(const ValueKey('share-logo')), findsOneWidget);
      expect(find.text('شاركها… لعلّها تهدي قلبًا'), findsOneWidget);
      expect(find.text('رحلة سيد مع القرآن'), findsOneWidget);
      expect(
        tester.widget<ShareQrCode>(find.byType(ShareQrCode)).data,
        ShareCardLinks.forCategory(SocialShareCategory.quranAyah),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the personal line sits on the signature glass', (tester) async {
    await pumpCard(tester, _ayah(userName: 'سيد'), mood: SocialShareMood.night);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('share-personal-line')),
        matching: find.byKey(const ValueKey('share-personal-pill')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('hideUserName removes the personal line', (tester) async {
    await pumpCard(tester, _ayah(userName: 'سيد'), hideUserName: true);
    expect(find.byKey(const ValueKey('share-personal-line')), findsNothing);
  });

  testWidgets('a very long user name stays on one line', (tester) async {
    await pumpCard(
      tester,
      _ayah(userName: 'عبد الرحمن ' * 12),
      format: SocialShareFormat.square,
    );
    final line = tester.widget<Text>(
      find.byKey(const ValueKey('share-personal-line')),
    );
    expect(line.maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English cards mirror to LTR and use English chrome', (
    tester,
  ) async {
    await pumpCard(tester, _ayah(), locale: const Locale('en'));
    expect(find.text('Talia Quran'), findsOneWidget);
    expect(find.text('Share it — it may guide a heart'), findsOneWidget);
    final direction = Directionality.of(
      tester.element(find.byKey(const ValueKey('share-eyebrow'))),
    );
    expect(direction, TextDirection.ltr);
    expect(find.text('﴿ $_isra9 ﴾'), findsOneWidget);
  });

  testWidgets('adult cards never show the companion character', (tester) async {
    await pumpCard(tester, _sampleFor(SocialShareCategory.achievement));
    expect(find.byKey(const ValueKey('share-hero-character')), findsNothing);
  });

  testWidgets('kids stat cards show the companion character', (tester) async {
    await pumpCard(
      tester,
      SocialShareData.streak(
        streakDays: 7,
      ).copyWith(audience: SocialShareAudience.kids),
    );
    expect(find.byKey(const ValueKey('share-hero-character')), findsOneWidget);
    expect(find.text('أبطال تالية الصغار'), findsOneWidget);
  });

  testWidgets('kids card with long text drops the character', (tester) async {
    await pumpCard(
      tester,
      _ayah(
        audience: SocialShareAudience.kids,
        text: '$_isra9 $_isra9 $_isra9',
      ),
    );
    expect(find.byKey(const ValueKey('share-hero-character')), findsNothing);
  });

  testWidgets('verse text never uses the Kufi display font', (tester) async {
    await pumpCard(tester, _ayah());
    final style = tester
        .widget<Text>(find.byKey(const ValueKey('share-hero-text')))
        .style!;
    expect(style.fontFamily, isNot('Reem_Kufi'));
  });

  testWidgets('day mood resolves the day palette', (tester) async {
    await pumpCard(tester, _ayah(), mood: SocialShareMood.day);
    expect(
      tester
          .widget<ShareCardBackdrop>(find.byType(ShareCardBackdrop))
          .palette
          .id,
      SharePaletteId.day,
    );
  });

  for (final category in SocialShareCategory.values) {
    for (final format in SocialShareFormat.values) {
      testWidgets('$category renders in $format across moods', (tester) async {
        for (final mood in SocialShareMood.values) {
          await pumpCard(
            tester,
            _sampleFor(category),
            mood: mood,
            format: format,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$category $format $mood',
          );
          expect(find.byKey(const ValueKey('share-logo')), findsOneWidget);
        }
      });
    }
  }
}
