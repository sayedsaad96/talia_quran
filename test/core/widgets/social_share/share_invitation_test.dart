import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/widgets/social_share/share_card_links.dart';
import 'package:talia_quran/core/widgets/social_share/share_signature_bar.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_sheet.dart';
import 'share_test_harness.dart';

void main() {
  final url = Uri.parse(
    'https://example.com/i/abcdefghijklmnopqrstuvwxyzABCDEFGH123456789',
  );
  final data = SocialShareData.invitation(
    title: 'Morning adhkar',
    message: 'Join me',
    linkUrl: url,
  );
  test('caption keeps the immutable invitation link after editing', () {
    expect(
      data.toPlainShareText(message: 'A new message'),
      'A new message\n\n$url',
    );
    expect(data.copyWith().linkUrl, url);
  });
  testWidgets(
    'invitation QR uses invitation URL and card only shows activity title',
    (tester) async {
      useCanvasView(tester);
      await tester.pumpWidget(
        shareHarness(
          buildSocialShareCardCanvas(
            data: data,
            format: SocialShareFormat.square,
          ),
          size: SocialShareFormat.square.exportLogicalSize,
        ),
      );
      await tester.pump();
      expect(
        tester.widget<ShareQrCode>(find.byType(ShareQrCode)).data,
        url.toString(),
      );
      expect(find.text('Morning adhkar'), findsWidgets);
      expect(find.text('Join me'), findsNothing);
    },
  );
  testWidgets('existing cards keep their Play QR', (tester) async {
    useCanvasView(tester);
    const normal = SocialShareData(
      content: 'test',
      category: SocialShareCategory.dua,
    );
    await tester.pumpWidget(
      shareHarness(
        buildSocialShareCardCanvas(
          data: normal,
          format: SocialShareFormat.square,
        ),
        size: SocialShareFormat.square.exportLogicalSize,
      ),
    );
    await tester.pump();
    expect(
      tester.widget<ShareQrCode>(find.byType(ShareQrCode)).data,
      ShareCardLinks.forCategory(SocialShareCategory.dua),
    );
  });
  testWidgets('editing the message leaves the invitation QR unchanged', (
    tester,
  ) async {
    useCanvasView(tester);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: SocialShareSheet(data: data)),
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('invitation-message')),
      'Changed message',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('invitation-message')))
          .controller!
          .text,
      'Changed message',
    );
    expect(
      tester.widget<ShareQrCode>(find.byType(ShareQrCode)).data,
      url.toString(),
    );
  });
}
