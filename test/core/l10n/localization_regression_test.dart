import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations_ar.dart';
import 'package:talia_quran/core/l10n/app_localizations_en.dart';

void main() {
  group('Hifz localization regression', () {
    test('new Hifz session keys resolve in both locales', () {
      final ar = AppLocalizationsAr();
      final en = AppLocalizationsEn();

      expect(ar.hifzLeaveSessionMessage, isNotEmpty);
      expect(ar.hifzAyahNumberLabel(3), contains('3'));
      expect(ar.hifzEvaluatingAyah, isNotEmpty);
      expect(ar.hifzRecordingAyahHint, isNotEmpty);
      expect(ar.hifzExcellentMemorization, isNotEmpty);
      expect(ar.hifzNeedsAyahReview, isNotEmpty);
      expect(ar.hifzNoVoiceRecognized, isNotEmpty);
      expect(ar.hifzReviewRangeHint(1, 5), contains('1'));
      expect(ar.hifzReviewRangeHint(1, 5), contains('5'));

      expect(en.hifzLeaveSessionMessage, contains('will be saved'));
      expect(en.hifzAyahNumberLabel(4), 'Ayah 4');
      expect(en.hifzEvaluatingAyah, 'Evaluating...');
      expect(en.hifzRecordingAyahHint, 'Recording, recite from memory...');
      expect(en.hifzExcellentMemorization, 'Excellent! Perfect memorization.');
      expect(en.hifzNeedsAyahReview, 'You need to review this Ayah.');
      expect(en.hifzNoVoiceRecognized, '(No voice recognized)');
      expect(en.hifzReviewRangeHint(2, 4), contains('2'));
      expect(en.hifzReviewRangeHint(2, 4), contains('4'));
    });

    test('Hifz session does not use inline localized ternary strings', () {
      const path =
          'lib/features/hifz/presentation/pages/hifz_session_page.dart';
      final contents = File(path).readAsStringSync();
      final localizedStringTernary = RegExp(
        r'''context\.isArabic\s*\?\s*(?:\([^)]*)?['"]''',
        multiLine: true,
      );

      expect(
        localizedStringTernary.hasMatch(contents),
        isFalse,
        reason:
            'Use l10n keys for UI copy instead of context.isArabic string ternaries.',
      );
    });
  });
}
