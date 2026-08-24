import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// V1-M4 / V1-S5 — narrow regression guard over the known religious-output
/// surfaces corrected for V1.
///
/// This is intentionally NOT a semantic religious-literal linter. It only
/// asserts that the specific surfaces remediated by the V1 release plan stay
/// free of the removed hand-typed content and of sacred-text truncation.
void main() {
  String readLib(String relativePath) =>
      File('lib/$relativePath').readAsStringSync();

  group('ungoverned religious output stays removed', () {
    test('azkar page no longer ships the hand-typed daily tips carousel', () {
      final source = readLib(
        'features/azkar/presentation/pages/azkar_page.dart',
      );
      expect(source.contains('_DailyTip'), isFalse);
      expect(source.contains('كلمتان خفيفتان'), isFalse);
    });

    test('notification service has no hand-typed fallback duas', () {
      final source = readLib('core/services/notification_service.dart');
      expect(source.contains('_fallbackDailyDuas'), isFalse);
      expect(source.contains('رَبَّنَا آتِنَا فِي الدُّنْيَا'), isFalse);
    });

    test('notification service never truncates religious text with an ellipsis',
        () {
      final source = readLib('core/services/notification_service.dart');
      expect(source.contains("_compactNotificationText"), isFalse);
      // No string-literal ellipsis used to clip bodies.
      expect(source.contains("'...'"), isFalse);
      expect(RegExp(r"substring\(0").allMatches(source), isEmpty);
    });

    test('certificate no longer embeds hand-typed verse or blessing', () {
      final source =
          readLib('features/certificate/presentation/widgets/certificate_widget.dart');
      expect(source.contains('إِنَّ هَٰذَا الْقُرْآنَ'), isFalse);
      expect(source.contains('نسأل الله تعالى'), isFalse);
    });

    test('settings test-notification previews carry no religious text', () {
      final source =
          readLib('features/settings/presentation/widgets/settings_notification_tiles.dart');
      expect(source.contains('رَبَّنَا آتِنَا فِي الدُّنْيَا'), isFalse);
    });
  });
}
