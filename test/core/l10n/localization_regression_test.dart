import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations_ar.dart';
import 'package:talia_quran/core/l10n/app_localizations_en.dart';

/// Guards against re-introducing hardcoded Arabic literals in UI/cubit source
/// that were extracted into the ARB localization files during the cleanup
/// sprint. Each entry maps a source file to the literals that must not return.
const _removedLiterals = <String, List<String>>{
  'lib/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart':
      ['أدخل رمزًا من 4 أرقام', 'رمز غير صحيح'],
  'lib/features/azkar/presentation/pages/azkar_category_page.dart': [
    'اضغط مطولاً للتراجع',
  ],
  'lib/features/memorization_plus/presentation/pages/v2/v2_learning_page.dart':
      ['تعلّم الآية', 'Learn the ayah'],
  'lib/features/memorization_plus/presentation/pages/v2/v2_memorizing_page.dart':
      ['احفظ الآية', 'Memorize the ayah'],
  'lib/features/memorization_plus/presentation/pages/v2/v2_recitation_page.dart':
      ['سمّع من حفظك', 'Recite from memory'],
  'lib/features/memorization_plus/presentation/pages/v2/v2_remediation_page.dart':
      ['مراجعة قصيرة', 'Short remediation'],
  'lib/features/memorization_plus/presentation/pages/v2/v2_block_review_page.dart':
      ['مراجعة المقطع', 'Block review'],
  'lib/features/memorization_plus/presentation/pages/v2/v2_completion_page.dart':
      ['اكتملت الجلسة', 'Session complete'],
  'lib/features/memorization_plus/presentation/widgets/kids_loading_widget.dart':
      ['جاري التحضير...', 'يبدو أن شيئاً ما حدث!', 'حاول مرة أخرى'],
  'lib/features/home/presentation/pages/home_page_widgets.dart': [
    'راجع قبل الحفظ الجديد',
    'Review before new content',
    'مراجعة بعيدة مستحقة',
    'Long-term review due',
    'راجع الآية الصعبة',
    'Review a difficult ayah',
    'أكمل خطة اليوم',
    "Continue today's plan",
    'احفظ آيات جديدة',
    'Memorize new ayahs',
    'المهمة الحالية',
    'Current Mission',
    'متابعة جلسة الحفظ',
    'Continue Session',
    'مراجعة الحفظ مستحقة',
    'Hifz review due',
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
      expect(ar.v2LearningTitle, 'تعلّم الآية');
      expect(ar.v2BlockReviewSubtitle(1, 5), contains('1-5'));
      expect(ar.kidsPreparing, 'جارٍ التحضير...');
      expect(ar.parentDashboardPinInvalid, 'أدخل رمزًا من 4 أرقام');
      expect(ar.parentDashboardPinIncorrect, 'رمز غير صحيح');
      expect(ar.bookmarkSaveError, isNotEmpty);
      expect(ar.longPressToUndo, isNotEmpty);
      expect(ar.hifzReviewRangeHint(1, 5), contains('1'));
      expect(ar.hifzReviewRangeHint(1, 5), contains('5'));
      expect(ar.signOutPendingDataTitle, 'تقدم غير مزامن');
      expect(ar.signOutAnyway, 'تسجيل الخروج على أي حال');

      expect(en.hifzStartRecitation, 'Start recitation');
      expect(en.hifzLeaveSessionMessage, contains('will be saved'));
      expect(en.hifzAyahNumberLabel(4), 'Ayah 4');
      expect(en.hifzEvaluatingAyah, 'Evaluating...');
      expect(en.hifzRecordingAyahHint, 'Recording, recite from memory...');
      expect(en.hifzExcellentMemorization, 'Excellent! Perfect memorization.');
      expect(en.hifzNeedsAyahReview, 'You need to review this Ayah.');
      expect(en.hifzNoVoiceRecognized, '(No voice recognized)');
      expect(en.v2LearningTitle, 'Learn the ayah');
      expect(en.v2BlockReviewSubtitle(1, 5), contains('1-5'));
      expect(en.kidsPreparing, 'Getting things ready...');
      expect(en.parentDashboardLinking, isNotEmpty);
      expect(en.parentDashboardChildLinked, isNotEmpty);
      expect(en.guardianLinkingSlowHint, isNotEmpty);
      expect(en.signOutPendingDataTitle, 'Unsynced progress');
      expect(en.signOutAnyway, 'Sign out anyway');
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
  });
}
