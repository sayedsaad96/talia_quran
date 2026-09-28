import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/heroes/stat_hero.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/talia_share_tokens.dart';

import 'share_test_harness.dart';

void main() {
  Future<void> pump(WidgetTester tester, SocialShareData data) =>
      tester.pumpWidget(
        shareHarness(
          StatHero(
            data: data,
            palette: SharePalettes.forenoon,
            metrics: TaliaShareMetrics.portrait,
          ),
        ),
      );

  final progressLine = find.byKey(const ValueKey('share-progress-line'));

  testWidgets('streak at its record shows the new-record line', (tester) async {
    await pump(
      tester,
      SocialShareData.streak(streakDays: 45, longestStreak: 45),
    );
    expect(find.text('45'), findsOneWidget);
    expect(find.text('يومًا مع القرآن'), findsOneWidget);
    expect(find.text('رقم قياسي جديد! 🎉'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('streak below its record shows the longest streak', (
    tester,
  ) async {
    await pump(
      tester,
      SocialShareData.streak(streakDays: 30, longestStreak: 45),
    );
    expect(find.text('أطول سلسلة: 45 يوم'), findsOneWidget);
  });

  testWidgets('streak without values shows zero and no record line', (
    tester,
  ) async {
    await pump(
      tester,
      const SocialShareData(content: '', category: SocialShareCategory.streak),
    );
    expect(find.text('0'), findsOneWidget);
    expect(find.textContaining('أطول'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('memorization shows ayahs, surahs and progress to target', (
    tester,
  ) async {
    await pump(
      tester,
      SocialShareData.memorization(
        ayahsCount: 250,
        surahsCount: 12,
        targetAyahs: 500,
      ),
    );
    expect(find.text('250'), findsOneWidget);
    expect(find.text('آيةً في صدري'), findsOneWidget);
    expect(find.text('12 سورة مكتملة'), findsOneWidget);
    expect(find.text('250 من 500'), findsOneWidget);
    expect(progressLine, findsOneWidget);
  });

  testWidgets('memorization with a zero target hides the progress line', (
    tester,
  ) async {
    await pump(
      tester,
      SocialShareData.memorization(
        ayahsCount: 3,
        surahsCount: 0,
        targetAyahs: 0,
      ),
    );
    expect(progressLine, findsNothing);
    expect(find.textContaining('سورة'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress shows all three stats', (tester) async {
    await pump(
      tester,
      const SocialShareData(
        content: '',
        category: SocialShareCategory.progress,
        readPagesCount: 85,
        memorizedAyahsCount: 250,
        streakDays: 14,
      ),
    );
    for (final v in ['85', '250', '14']) {
      expect(find.text(v), findsOneWidget);
    }
    expect(find.text('صفحات مقروءة'), findsOneWidget);
    expect(find.text('آيات محفوظة'), findsOneWidget);
    expect(find.text('أيام متتالية'), findsOneWidget);
  });

  testWidgets('azkar wird progress shows counts and a line', (tester) async {
    await pump(
      tester,
      SocialShareData.azkarWird(
        categoryTitle: 'أذكار الصباح',
        completedCount: 12,
        totalCount: 15,
      ),
    );
    expect(find.text('12 / 15'), findsOneWidget);
    expect(find.text('أذكار أتممتُها'), findsOneWidget);
    expect(progressLine, findsOneWidget);
  });

  RenderParagraph numeralParagraph(WidgetTester tester) =>
      tester.renderObject<RenderParagraph>(
        find.byKey(const ValueKey('share-hero-numeral')).first,
      );

  testWidgets('a wide wird numeral scales down instead of wrapping', (
    tester,
  ) async {
    await tester.pumpWidget(
      shareHarness(
        StatHero(
          data: SocialShareData.azkarWird(
            categoryTitle: 'أذكار',
            completedCount: 100,
            totalCount: 100,
          ),
          palette: SharePalettes.forenoon,
          metrics: TaliaShareMetrics.story,
        ),
        size: const Size(174, 400),
      ),
    );
    expect(numeralParagraph(tester).didExceedMaxLines, isFalse);
    expect(find.text('100 / 100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a three-digit streak scales down in a narrow kids column', (
    tester,
  ) async {
    await tester.pumpWidget(
      shareHarness(
        StatHero(
          data: SocialShareData.streak(streakDays: 100),
          palette: SharePalettes.kidsMorning,
          metrics: TaliaShareMetrics.story,
        ),
        size: const Size(174, 400),
      ),
    );
    expect(numeralParagraph(tester).didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('azkar wird with zero total shows the count only', (
    tester,
  ) async {
    await pump(
      tester,
      SocialShareData.azkarWird(
        categoryTitle: 'أذكار',
        completedCount: 0,
        totalCount: 0,
      ),
    );
    expect(find.text('0'), findsOneWidget);
    expect(progressLine, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
