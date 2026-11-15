import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/share_signature_bar.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_copy.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_sheet.dart';
import 'package:talia_quran/core/widgets/social_share/talia_share_tokens.dart';

import 'share_test_harness.dart';

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family);
  final bytes = await File(path).readAsBytes();
  loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

/// Every app-authored invitation must fit the signature bar in every
/// format and language with the real bundled fonts; the default test font
/// would make every line look too wide.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      'Noto_Naskh_Arabic',
      'assets/fonts/Noto_Naskh_Arabic/NotoNaskhArabic-Regular.ttf',
    );
    await _loadFont(
      'Reem_Kufi',
      'assets/fonts/Reem_Kufi/ReemKufi-Variable.ttf',
    );
  });

  for (final language in const ['ar', 'en']) {
    for (final format in SocialShareFormat.values) {
      testWidgets('$language invitations fit the $format bar', (tester) async {
        final metrics = TaliaShareMetrics.of(format);
        final width =
            format.exportLogicalSize.width - metrics.padding.horizontal;
        final copy = SocialShareCopy.forLanguage(language);
        final data = <SocialShareData>[
          for (final c in SocialShareCategory.values)
            SocialShareData(content: 'x', category: c),
          SocialShareData.azkarWird(
            categoryTitle: 't',
            completedCount: 1,
            totalCount: 2,
          ),
          const SocialShareData(
            content: 'x',
            category: SocialShareCategory.quranAyah,
            audience: SocialShareAudience.kids,
          ),
        ];
        for (final d in data) {
          await tester.pumpWidget(
            shareHarness(
              ShareSignatureBar(
                palette: SharePalettes.mushafLight,
                metrics: metrics,
                copy: copy,
                invitation: copy.invitation(d),
                qrData: 'https://taliaapp.com/',
              ),
              size: Size(width, metrics.signatureHeight),
              locale: Locale(language),
            ),
          );
          final paragraph = tester.renderObject<RenderParagraph>(
            find.byKey(const ValueKey('share-invitation')),
          );
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '"${copy.invitation(d)}" is cut in $language/$format',
          );
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  for (final language in const ['ar', 'en']) {
    for (final format in SocialShareFormat.values) {
      for (final scale in const [0.8, 1.6]) {
        testWidgets(
          'invitation card fits $language $format at $scale text scale',
          (tester) async {
            useCanvasView(tester);
            final title = language == 'ar'
                ? 'قراءة الصفحات من ١٢٠ إلى ١٣٩'
                : 'Read pages 120 through 139';
            final data = SocialShareData.invitation(
              title: title,
              message: 'Private share message',
              linkUrl: Uri.https(
                'example.com',
                '/i/abcdefghijklmnopqrstuvwxyzABCDEFGH123456789',
              ),
            );
            await tester.pumpWidget(
              shareHarness(
                Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: buildSocialShareCardCanvas(
                      data: data,
                      format: format,
                    ),
                  ),
                ),
                size: format.exportLogicalSize,
                locale: Locale(language),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(find.text(title), findsOneWidget);
            expect(find.text('Private share message'), findsNothing);
            Rect paintedRect(Finder finder) {
              final box = tester.renderObject<RenderBox>(finder);
              return MatrixUtils.transformRect(
                box.getTransformTo(null),
                Offset.zero & box.size,
              );
            }

            final card = paintedRect(
              find.byKey(const ValueKey('social-share-card-canvas')),
            );
            final hero = paintedRect(
              find.byKey(const ValueKey('share-hero-text')),
            );
            expect(hero.left, greaterThanOrEqualTo(card.left));
            expect(hero.right, lessThanOrEqualTo(card.right));
            expect(hero.top, greaterThanOrEqualTo(card.top));
            expect(hero.bottom, lessThanOrEqualTo(card.bottom));
          },
        );
      }
    }
  }
}
