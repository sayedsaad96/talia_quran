import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations_ar.dart';
import 'package:talia_quran/core/l10n/app_localizations_en.dart';

/// Guards against re-introducing hardcoded Arabic literals in UI/cubit source
/// that were extracted into the ARB localization files during the cleanup
/// sprint. Each entry maps a source file to the literals that must not return.
const _removedLiterals = <String, List<String>>{
  'lib/features/memorization_plus/presentation/cubits/parent_dashboard_cubit.dart':
      ['أدخل رمزًا من 4 أرقام', 'رمز غير صحيح'],
  'lib/features/quran/presentation/pages/surah_detail_page.dart': [
    'حدث خطأ أثناء حفظ العلامة المرجعية',
  ],
  'lib/features/azkar/presentation/pages/azkar_category_page.dart': [
    'اضغط مطولاً للتراجع',
  ],
  'lib/features/hifz/presentation/pages/hifz_session_page.dart': [
    'هل تريد الخروج من جلسة الحفظ؟ سيتم حفظ تقدمك الحالي.',
    'ابدأ التسميع',
    'إنهاء التسميع',
    'جارِ التقييم...',
    'جارِ تقييم المراجعة...',
    'يتم التسجيل، اقرأ الآية من حفظك...',
    'ممتاز! حفظ متقن.',
    'تحتاج إلى مراجعة هذه الآية.',
    'لم يتم التعرف على صوت',
    'لم يتم اجتياز المراجعة. حاول مرة أخرى.',
    'Do you want to leave the memorization session? Your current progress will be saved.',
    'Evaluating...',
    'Recording, recite from memory...',
    'Finish Session',
    'Excellent! Perfect memorization.',
    'You need to review this Ayah.',
    'No voice recognized',
  ],
};

void main() {
  group('localization regression', () {
    test('newly extracted keys resolve in both locales', () {
      final ar = AppLocalizationsAr();
      final en = AppLocalizationsEn();

      expect(ar.hifzStartRecitation, 'ابدأ التسميع');
      expect(ar.hifzLeaveSessionMessage, contains('سيتم حفظ تقدمك الحالي'));
      expect(ar.hifzAyahNumberLabel(3), 'آية 3');
      expect(ar.hifzEvaluatingAyah, 'جارِ التقييم...');
      expect(ar.hifzRecordingAyahHint, 'يتم التسجيل، اقرأ الآية من حفظك...');
      expect(ar.hifzExcellentMemorization, 'ممتاز! حفظ متقن.');
      expect(ar.hifzNeedsAyahReview, 'تحتاج إلى مراجعة هذه الآية.');
      expect(ar.hifzNoVoiceRecognized, '(لم يتم التعرف على صوت)');
      expect(ar.parentDashboardPinInvalid, 'أدخل رمزًا من 4 أرقام');
      expect(ar.parentDashboardPinIncorrect, 'رمز غير صحيح');
      expect(ar.bookmarkSaveError, isNotEmpty);
      expect(ar.longPressToUndo, isNotEmpty);
      expect(ar.hifzReviewRangeHint(1, 5), contains('1'));
      expect(ar.hifzReviewRangeHint(1, 5), contains('5'));

      expect(en.hifzStartRecitation, 'Start recitation');
      expect(en.hifzLeaveSessionMessage, contains('will be saved'));
      expect(en.hifzAyahNumberLabel(4), 'Ayah 4');
      expect(en.hifzEvaluatingAyah, 'Evaluating...');
      expect(en.hifzRecordingAyahHint, 'Recording, recite from memory...');
      expect(en.hifzExcellentMemorization, 'Excellent! Perfect memorization.');
      expect(en.hifzNeedsAyahReview, 'You need to review this Ayah.');
      expect(en.hifzNoVoiceRecognized, '(No voice recognized)');
      expect(en.parentDashboardLinking, isNotEmpty);
      expect(en.parentDashboardChildLinked, isNotEmpty);
      expect(en.guardianLinkingSlowHint, isNotEmpty);
      expect(en.hifzReviewRangeHint(2, 4), contains('2'));
      expect(en.hifzReviewRangeHint(2, 4), contains('4'));
    });

    test('source files no longer contain extracted Arabic literals', () {
      _removedLiterals.forEach((path, literals) {
        final file = File(path);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Expected source file to exist: $path',
        );
        final contents = file.readAsStringSync();
        for (final literal in literals) {
          expect(
            contents.contains(literal),
            isFalse,
            reason: '"$literal" should be localized, not hardcoded in $path',
          );
        }
      });
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
