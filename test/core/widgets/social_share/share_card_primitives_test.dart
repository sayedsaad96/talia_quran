import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_backdrop.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/share_medal.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/talia_share_tokens.dart';

import 'share_test_harness.dart';

void main() {
  group('TaliaShareMetrics', () {
    test('verse size shrinks with length in every format', () {
      for (final f in SocialShareFormat.values) {
        final m = TaliaShareMetrics.of(f);
        expect(m.verseSize(40), greaterThan(m.verseSize(120)));
        expect(m.verseSize(120), greaterThan(m.verseSize(200)));
        expect(m.verseSize(200), greaterThan(m.verseSize(400)));
      }
    });

    test('QR fits inside the signature bar', () {
      for (final f in SocialShareFormat.values) {
        final m = TaliaShareMetrics.of(f);
        expect(m.qrSize, lessThan(m.signatureHeight));
        expect(m.logoSize, lessThan(m.signatureHeight));
      }
    });

    test('display style is Reem Kufi with a matching weight variation', () {
      final style = TaliaShareTypography.display(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      );
      expect(style.fontFamily, 'Reem_Kufi');
      expect(style.fontVariations, [const FontVariation('wght', 700)]);
    });
  });

  group('ShareArchPainter', () {
    test('arch apex is centred and the path stays inside the card', () {
      const size = Size(360, 450);
      final path = ShareArchPainter.archPath(size, bottomInset: 80);
      final bounds = path.getBounds();
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(size.width));
      expect(bounds.top, closeTo(size.height * 0.09, 0.5));
      expect(bounds.bottom, closeTo(size.height - 80, 0.5));
      expect(bounds.center.dx, closeTo(size.width / 2, 0.5));
    });
  });

  group('ShareCardBackdrop', () {
    testWidgets('paints light, arch and the watermark when given', (
      tester,
    ) async {
      await tester.pumpWidget(
        shareHarness(
          ShareCardBackdrop(
            palette: SharePalettes.mushafLight,
            metrics: TaliaShareMetrics.of(SocialShareFormat.portrait),
            watermark: 'الإسراء',
          ),
          size: const Size(360, 450),
        ),
      );
      expect(find.byKey(const ValueKey('share-mushaf-light')), findsOneWidget);
      expect(find.byKey(const ValueKey('share-arch-hairline')), findsOneWidget);
      expect(find.text('الإسراء'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('omits the watermark when none is given', (tester) async {
      await tester.pumpWidget(
        shareHarness(
          ShareCardBackdrop(
            palette: SharePalettes.day,
            metrics: TaliaShareMetrics.of(SocialShareFormat.square),
          ),
          size: const Size(360, 360),
        ),
      );
      expect(find.byKey(const ValueKey('share-watermark')), findsNothing);
    });
  });

  testWidgets('ShareMedal wraps its child in the star', (tester) async {
    await tester.pumpWidget(
      shareHarness(
        const Center(
          child: ShareMedal(
            size: 80,
            color: Colors.amber,
            child: Icon(Icons.verified_rounded),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('share-medal')), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('share-medal'))),
      const Size(80, 80),
    );
  });
}
