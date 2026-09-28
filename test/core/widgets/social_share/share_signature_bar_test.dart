import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_palette.dart';
import 'package:talia_quran/core/widgets/social_share/share_signature_bar.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_copy.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/talia_share_tokens.dart';

import 'share_test_harness.dart';

void main() {
  const url = 'https://taliaapp.com/?utm_source=tc&utm_campaign=quranAyah';

  Widget bar(SocialShareFormat format, String languageCode, String invitation) {
    return ShareSignatureBar(
      palette: SharePalettes.mushafLight,
      metrics: TaliaShareMetrics.of(format),
      copy: SocialShareCopy.forLanguage(languageCode),
      invitation: invitation,
      qrData: url,
    );
  }

  testWidgets('shows the logo once, wordmark, invitation and the QR', (
    tester,
  ) async {
    await tester.pumpWidget(
      shareHarness(
        bar(SocialShareFormat.portrait, 'ar', 'شاركها… لعلّها تهدي قلبًا'),
        size: const Size(320, 54),
      ),
    );
    expect(find.byKey(const ValueKey('share-logo')), findsOneWidget);
    expect(find.text('تالية القرآن'), findsOneWidget);
    expect(find.text('شاركها… لعلّها تهدي قلبًا'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.widget<ShareQrCode>(find.byType(ShareQrCode)).data, url);
    final logo = tester.widget<Image>(find.byKey(const ValueKey('share-logo')));
    expect(
      (logo.image as ResizeImage).imageProvider,
      const AssetImage(ShareSignatureBar.logoAsset),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long English invitation ellipsizes on the square card', (
    tester,
  ) async {
    await tester.pumpWidget(
      shareHarness(
        bar(
          SocialShareFormat.square,
          'en',
          'A little champion memorizing Quran every single day with family',
        ),
        size: const Size(328, 46),
        locale: const Locale('en'),
      ),
    );
    final text = tester.widget<Text>(
      find.byKey(const ValueKey('share-invitation')),
    );
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
