import 'package:flutter/widgets.dart';

import 'social_share_model.dart';
import 'social_share_theme.dart';

/// Share-card copy is intentionally isolated from domain data.  The selected
/// app locale controls labels; Quran and Azkar text remain untouched.
///
/// This catalog also covers the share sheet chrome so English users never see
/// Arabic-only UI strings inside the share flow.
class SocialShareCopy {
  const SocialShareCopy._(this.isArabic);

  factory SocialShareCopy.of(BuildContext context) => SocialShareCopy._(
        Localizations.localeOf(context).languageCode == 'ar',
      );

  final bool isArabic;
  TextDirection get direction => isArabic ? TextDirection.rtl : TextDirection.ltr;

  // ─── Brand identity ──────────────────────────────────────────────────────
  String get appName => isArabic ? 'تالية' : 'Talia';
  String get tagline => isArabic ? 'رفيقك في رحلة القرآن' : 'Your Quran companion';
  String get brandPromise => isArabic
      ? 'خطّط  •  احفظ  •  راجع  •  أتقن'
      : 'Plan  •  Memorize  •  Review  •  Retain';
  String get compactBrandPromise => isArabic
      ? 'احفظ  •  راجع  •  أتقن'
      : 'Memorize  •  Review  •  Retain';
  String get appDomain => Uri.parse(SocialShareData.landingPageUrl).host;

  // ─── Marketing & CTA copy ─────────────────────────────────────────────────
  /// Strong CTA label shown inside the footer download pill.
  String get downloadCTA => isArabic ? 'حمّل تالية مجاناً' : 'Get Talia Free';

  /// Short CTA variant for compact square format.
  String get downloadCTAShort => isArabic ? 'حمّل تالية' : 'Get Talia';

  /// Motivational sub-label under the CTA in the footer.
  String get startJourney => isArabic ? 'ابدأ رحلتك مع القرآن' : 'Start your Quran journey';

  /// Plain share text footer — stronger marketing copy with app download invite.
  String get plainShareFooter => isArabic
      ? '✨ شاركني في رحلة حفظ القرآن مع تالية\n'
        '🌙 خطّط • احفظ • راجع • أتقن\n'
        '📲 حمّل التطبيق: ${SocialShareData.landingPageUrl}'
      : '✨ Join me on my Quran memorization journey with Talia\n'
        '🌙 Plan • Memorize • Review • Retain\n'
        '📲 Download: ${SocialShareData.landingPageUrl}';

  String journeyFor(String name) => isArabic ? 'رحلة $name مع القرآن' : "$name's Quran journey";
  String get kidsLabel => isArabic ? 'رحلة الأبطال الصغار' : 'Little champions journey';
  String get kidsEncouragement => isArabic
      ? 'أحسنت! استمر يا بطل 🌟'
      : 'Great job! Keep going, champion 🌟';

  // ─── Category badges ─────────────────────────────────────────────────────
  String get quranBadge => isArabic ? 'آية قرآنية' : 'Quran verse';
  String get duaBadge => isArabic ? 'دعاء' : 'Dua';
  String get dhikrBadge => isArabic ? 'ذِكر' : 'Dhikr';
  String get achievementBadge => isArabic ? 'إنجاز جديد' : 'New achievement';
  String get memorizationBadge => isArabic ? 'إنجاز الحفظ' : 'Memorization milestone';
  String get streakBadge => isArabic ? 'استمرارية متواصلة' : 'Consistency streak';
  String get progressBadge => isArabic ? 'حصاد التقدم' : 'Progress snapshot';
  String get certificateBadge => isArabic ? 'شهادة إتمام ومواظبة' : 'Completion certificate';

  String localizedBadge(SocialShareCategory category) {
    switch (category) {
      case SocialShareCategory.quranAyah:
        return quranBadge;
      case SocialShareCategory.azkar:
        return dhikrBadge;
      case SocialShareCategory.dua:
        return duaBadge;
      case SocialShareCategory.achievement:
        return achievementBadge;
      case SocialShareCategory.memorization:
        return memorizationBadge;
      case SocialShareCategory.streak:
        return streakBadge;
      case SocialShareCategory.progress:
        return progressBadge;
      case SocialShareCategory.certificate:
        return certificateBadge;
    }
  }

  // ─── Quran verse template ────────────────────────────────────────────────
  String surah(String name) => isArabic ? 'سورة $name' : 'Surah $name';
  String ayah(int number) => isArabic ? 'الآية $number' : 'Ayah $number';
  String get holyQuran => isArabic ? 'القرآن الكريم' : 'The Holy Quran';

  // ─── Achievement template ────────────────────────────────────────────────
  String get completed => isArabic ? 'مكتمل' : 'Completed';
  String progress(int value, int target) => isArabic ? '$value من $target' : '$value of $target';
  String get achievementComplete => isArabic ? 'تم الإنجاز' : 'Achievement unlocked';

  // ─── Memorization template ───────────────────────────────────────────────
  String get memorizationTitle => isArabic ? 'إنجاز في مسيرة الحفظ' : 'Memorization milestone';
  String get ayahsLabel => isArabic ? 'آية محفوظة' : 'ayahs memorized';
  String get surahsLabel => isArabic ? 'سورة مكتملة' : 'surahs completed';
  String ayahs(int value) => isArabic ? '$value آية محفوظة' : '$value ayahs memorized';
  String surahs(int value) => isArabic ? '$value سور مكتملة' : '$value surahs completed';

  // ─── Streak template ─────────────────────────────────────────────────────
  String get streakTitle => isArabic ? 'استمرارية مباركة' : 'A blessed streak';
  String get consecutiveDays => isArabic ? 'أيام متواصلة' : 'consecutive days';
  String get quranCommitment => isArabic ? 'عهد مع القرآن الكريم' : 'A steady Quran habit';
  String longestStreak(int value) => isArabic ? 'أطول سلسلة: $value يوم' : 'Longest streak: $value days';
  String get newRecord => isArabic ? 'رقم قياسي جديد! 🎉' : 'New personal record! 🎉';

  // ─── Progress template ───────────────────────────────────────────────────
  String get progressTitle => isArabic ? 'حصاد الإنجاز والتقدم' : 'My Quran progress';
  String get pagesReadLabel => isArabic ? 'صفحات مقروءة' : 'pages read';
  String get ayahsMemorizedLabel => isArabic ? 'آيات محفوظة' : 'ayahs memorized';
  String get streakDaysLabel => isArabic ? 'أيام متتالية' : 'streak days';
  String pages(int value) => isArabic ? '$value صفحة مقروءة' : '$value pages read';

  // ─── Certificate template ────────────────────────────────────────────────
  String get certificateTitle => isArabic ? 'شهادة إتمام ومواظبة' : 'Completion certificate';
  String verificationCode(String code) => isArabic ? 'رقم التوثيق: $code' : 'Verification code: $code';
  String certificateSentence(String awardTitle) => isArabic
      ? 'حصلت بحمد الله على $awardTitle بتقدير ممتاز من منصة تالية للقرآن الكريم ✨'
      : 'Alhamdulillah, I earned $awardTitle with distinction on Talia Quran ✨';

  // ─── Share sheet chrome ──────────────────────────────────────────────────
  String get sheetTitle => isArabic ? 'مشاركة بطاقة سوشيال ميديا' : 'Share your card';
  String get chooseStyle => isArabic ? 'اختر مظهر البطاقة:' : 'Card style:';
  String get shareAsImage => isArabic ? 'مشاركة كصورة 📸' : 'Share as image 📸';
  String get preparing => isArabic ? 'جاري التجهيز...' : 'Preparing...';
  String get saveToGalleryTooltip => isArabic ? 'حفظ المعرض' : 'Save to gallery';
  String get shareAsTextTooltip => isArabic ? 'مشاركة كنص' : 'Share as text';
  String get showNameLabel => isArabic ? 'إظهار اسمي' : 'Show my name';
  String get errorCapture => isArabic
      ? 'تعذر إنشاء صورة البطاقة، يرجى المحاولة مرة أخرى.'
      : 'Could not create the card image, please try again.';
  String get errorShare => isArabic
      ? 'حدث خطأ أثناء مشاركة الصورة'
      : 'Something went wrong while sharing the image';
  String get permissionNeeded => isArabic
      ? 'يلزم الحصول على إذن الوصول لمعرض الصور للحفظ'
      : 'Photo gallery permission is needed to save';
  String get errorCaptureForSave => isArabic
      ? 'تعذر جلب صورة البطاقة للحفظ'
      : 'Could not capture the card to save';
  String get savedToGallery => isArabic
      ? 'تم حفظ البطاقة بنجاح في معرض الصور! 📸'
      : 'Card saved to your gallery! 📸';
  String get errorSave => isArabic
      ? 'تعذر حفظ الصورة في المعرض'
      : 'Could not save the image to the gallery';

  String formatName(SocialShareFormat format) =>
      isArabic ? format.nameAr : format.nameEn;
  String themeName(SocialShareThemeType type) =>
      isArabic ? type.nameAr : type.nameEn;
}
