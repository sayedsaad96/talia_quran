import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/heroes/award_hero.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/talia_share_tokens.dart';

import 'share_test_harness.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    SocialShareData data, {
    Size size = const Size(320, 260),
  }) => tester.pumpWidget(
    shareHarness(
      AwardHero(
        data: data,
        palette: SharePalettes.sunrise,
        metrics: TaliaShareMetrics.portrait,
      ),
      size: size,
    ),
  );

  testWidgets('unlocked achievement shows medal, title and completion', (
    tester,
  ) async {
    await pump(
      tester,
      const SocialShareData(
        content: 'قرأت جزءاً كاملاً من القرآن الكريم',
        title: 'قارئ جزء كامل',
        category: SocialShareCategory.achievement,
        achievementIcon: '📖',
        currentValue: 20,
        targetValue: 20,
        achievementUnlocked: true,
      ),
    );
    expect(find.byKey(const ValueKey('share-medal')), findsOneWidget);
    expect(find.text('قارئ جزء كامل'), findsOneWidget);
    expect(find.text('مكتمل، 20 من 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('locked achievement shows progress only', (tester) async {
    await pump(
      tester,
      const SocialShareData(
        content: 'x',
        title: 't',
        category: SocialShareCategory.achievement,
        currentValue: 5,
        targetValue: 20,
        achievementUnlocked: false,
      ),
    );
    expect(find.text('5 من 20'), findsOneWidget);
  });

  testWidgets('very long achievement title and description stay inside', (
    tester,
  ) async {
    await pump(
      tester,
      SocialShareData(
        content: 'وصف طويل جداً ' * 20,
        title: 'عنوان إنجاز طويل جداً ' * 6,
        category: SocialShareCategory.achievement,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('certificate shows the award title and verification code', (
    tester,
  ) async {
    await pump(
      tester,
      const SocialShareData(
        content: 'شهادة إتمام جزء عمّ',
        category: SocialShareCategory.certificate,
        verificationCode: 'TQ-2026-001',
      ),
    );
    expect(find.text('شهادة إتمام جزء عمّ'), findsOneWidget);
    expect(find.text('رقم التوثيق: TQ-2026-001'), findsOneWidget);
  });

  testWidgets('khatmah shows title, days, pages and dedication', (
    tester,
  ) async {
    await pump(
      tester,
      const SocialShareData(
        content: 'summary',
        title: 'ختمة رمضان',
        subtitle: 'مُهداة إلى والدتي',
        category: SocialShareCategory.khatmah,
        targetValue: 30,
        readPagesCount: 604,
      ),
    );
    expect(find.text('ختمة رمضان'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('يومًا'), findsOneWidget);
    expect(find.text('604 صفحة مقروءة'), findsOneWidget);
    expect(find.text('مُهداة إلى والدتي'), findsOneWidget);
    expect(find.text('summary'), findsNothing);
  });
}
