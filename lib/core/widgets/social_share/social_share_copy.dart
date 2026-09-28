import 'package:flutter/widgets.dart';

import 'share_card_palette.dart';
import 'social_share_model.dart';

/// Share-card copy is intentionally isolated from domain data.  The selected
/// app locale controls labels; Quran and Azkar text remain untouched.
///
/// This catalog also covers the share sheet chrome so English users never see
/// Arabic-only UI strings inside the share flow.
class SocialShareCopy {
  const SocialShareCopy._(this.isArabic);

  factory SocialShareCopy.of(BuildContext context) =>
      SocialShareCopy._(Localizations.localeOf(context).languageCode == 'ar');

  /// Entry point outside a widget tree (tests, background export).
  factory SocialShareCopy.forLanguage(String languageCode) =>
      SocialShareCopy._(languageCode == 'ar');

  final bool isArabic;
  TextDirection get direction =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  /// Plain share text footer — stronger marketing copy with app download invite.
  String get plainShareFooter => isArabic
      ? '✨ شاركني في رحلة حفظ القرآن مع تالية\n'
            '🌙 خطّط • احفظ • راجع • أتقن\n'
            '📲 حمّل التطبيق: ${SocialShareData.landingPageUrl}'
      : '✨ Join me on my Quran memorization journey with Talia\n'
            '🌙 Plan • Memorize • Review • Retain\n'
            '📲 Download: ${SocialShareData.landingPageUrl}';

  String journeyFor(String name) =>
      isArabic ? 'رحلة $name مع القرآن' : "$name's Quran journey";

  // ─── Category badges ─────────────────────────────────────────────────────
  String get quranBadge => isArabic ? 'آية قرآنية' : 'Quran verse';
  String get duaBadge => isArabic ? 'دعاء' : 'Dua';
  String get dhikrBadge => isArabic ? 'ذِكر' : 'Dhikr';
  String get achievementBadge => isArabic ? 'إنجاز جديد' : 'New achievement';
  String get khatmahBadge => isArabic ? 'ختمة القرآن' : 'Quran Khatmah';

  // ─── Quran verse template ────────────────────────────────────────────────
  String surah(String name) => isArabic ? 'سورة $name' : 'Surah $name';
  String ayah(int number) => isArabic ? 'الآية $number' : 'Ayah $number';
  String get holyQuran => isArabic ? 'القرآن الكريم' : 'The Holy Quran';

  // ─── Achievement template ────────────────────────────────────────────────
  String get completed => isArabic ? 'مكتمل' : 'Completed';
  String progress(int value, int target) =>
      isArabic ? '$value من $target' : '$value of $target';
  String get achievementComplete =>
      isArabic ? 'تم الإنجاز' : 'Achievement unlocked';

  // ─── Streak template ─────────────────────────────────────────────────────
  String longestStreak(int value) =>
      isArabic ? 'أطول سلسلة: $value يوم' : 'Longest streak: $value days';
  String get newRecord =>
      isArabic ? 'رقم قياسي جديد! 🎉' : 'New personal record! 🎉';

  // ─── Progress template ───────────────────────────────────────────────────
  String get progressTitle =>
      isArabic ? 'حصاد الإنجاز والتقدم' : 'My Quran progress';
  String get pagesReadLabel => isArabic ? 'صفحات مقروءة' : 'pages read';
  String get ayahsMemorizedLabel =>
      isArabic ? 'آيات محفوظة' : 'ayahs memorized';
  String get streakDaysLabel => isArabic ? 'أيام متتالية' : 'streak days';
  String pages(int value) =>
      isArabic ? '$value صفحة مقروءة' : '$value pages read';

  // ─── Certificate template ────────────────────────────────────────────────
  String verificationCode(String code) =>
      isArabic ? 'رقم التوثيق: $code' : 'Verification code: $code';

  // ─── Dawn card copy ──────────────────────────────────────────────────────
  // App-authored invitation copy: no Quran, hadith or dua text lives here.
  String get wordmark => isArabic ? 'تالية القرآن' : 'Talia Quran';

  String eyebrow(SocialShareData data) {
    if (data.audience == SocialShareAudience.kids) {
      return isArabic ? 'أبطال تالية الصغار' : 'Little Talia champions';
    }
    final title = data.title?.trim() ?? '';
    switch (data.category) {
      case SocialShareCategory.quranAyah:
        return quranBadge;
      case SocialShareCategory.dua:
        return title.isEmpty ? duaBadge : '$duaBadge · $title';
      case SocialShareCategory.azkar:
        if (data.isAzkarWirdProgress) {
          return title.isEmpty ? dhikrBadge : title;
        }
        return title.isEmpty ? dhikrBadge : '$dhikrBadge · $title';
      case SocialShareCategory.achievement:
        return achievementBadge;
      case SocialShareCategory.memorization:
        return isArabic ? 'حفظ القرآن' : 'Memorization';
      case SocialShareCategory.streak:
        return isArabic ? 'استمرارية' : 'Streak';
      case SocialShareCategory.progress:
        return isArabic ? 'حصاد التقدم' : 'My progress';
      case SocialShareCategory.certificate:
        return isArabic ? 'شهادة إتمام' : 'Certificate';
      case SocialShareCategory.khatmah:
        return khatmahBadge;
    }
  }

  /// Faint background word for text cards: the surah name or a category
  /// word, never a fragment of Quran or azkar text.
  String? watermark(SocialShareData data) {
    switch (data.category) {
      case SocialShareCategory.quranAyah:
        return data.surahName;
      case SocialShareCategory.dua:
        return isArabic ? 'دعاء' : 'Dua';
      case SocialShareCategory.azkar:
        if (data.isAzkarWirdProgress) return null;
        return isArabic ? 'ذِكر' : 'Dhikr';
      default:
        return null;
    }
  }

  String invitation(SocialShareData data) {
    if (data.audience == SocialShareAudience.kids) {
      return isArabic
          ? 'بطلٌ صغير يحفظ القرآن'
          : 'A little champion memorizing Quran';
    }
    switch (data.category) {
      case SocialShareCategory.quranAyah:
        return isArabic
            ? 'شاركها… لعلّها تهدي قلبًا'
            : 'Share it — it may guide a heart';
      case SocialShareCategory.dua:
        return isArabic ? 'ادعُ بها لمن تحب' : 'Pray it for someone you love';
      case SocialShareCategory.azkar:
        if (data.isAzkarWirdProgress) {
          return isArabic ? 'حافظ على أذكارك معي' : 'Keep your adhkar with me';
        }
        return isArabic ? 'ذكّر بها من تحب' : 'Remind someone you love';
      case SocialShareCategory.achievement:
      case SocialShareCategory.progress:
        return isArabic ? 'رافقني في رحلتي مع القرآن' : 'Join my Quran journey';
      case SocialShareCategory.memorization:
        return isArabic
            ? 'احفظ معي… خطوة كل يوم'
            : 'Memorize with me, one step a day';
      case SocialShareCategory.streak:
        return isArabic ? 'ابدأ وِردك اليوم' : 'Start your daily wird today';
      case SocialShareCategory.certificate:
        return isArabic
            ? 'رحلة إتقان مع تالية'
            : 'A journey of mastery with Talia';
      case SocialShareCategory.khatmah:
        return isArabic ? 'ابدأ ختمتك القادمة' : 'Start your next khatmah';
    }
  }

  String moodName(SocialShareMood mood) {
    switch (mood) {
      case SocialShareMood.auto:
        return isArabic ? 'تلقائي' : 'Auto';
      case SocialShareMood.night:
        return isArabic ? 'ليل' : 'Night';
      case SocialShareMood.day:
        return isArabic ? 'نهار' : 'Day';
    }
  }

  String ayahReference(String? surahName, int? ayahNumber) {
    final surahPart = surahName == null ? holyQuran : surah(surahName);
    return ayahNumber == null ? surahPart : '$surahPart · ${ayah(ayahNumber)}';
  }

  /// Arabic noun agreement: 1, 2, 3–10, and 0 / 11+.
  static String arabicCountWord(
    int n, {
    required String one,
    required String two,
    required String few,
    required String many,
  }) {
    if (n == 1) return one;
    if (n == 2) return two;
    if (n >= 3 && n <= 10) return few;
    return many;
  }

  String streakHeroLabel(int days) => isArabic
      ? '${arabicCountWord(days, one: 'يوم', two: 'يومان', few: 'أيام', many: 'يومًا')} مع القرآن'
      : '${days == 1 ? 'day' : 'days'} with the Quran';

  String memorizedAyahsHeroLabel(int ayahs) => isArabic
      ? '${arabicCountWord(ayahs, one: 'آية', two: 'آيتان', few: 'آيات', many: 'آيةً')} في صدري'
      : '${ayahs == 1 ? 'ayah' : 'ayahs'} memorized';

  String surahsCompleted(int count) => isArabic
      ? '$count ${arabicCountWord(count, one: 'سورة مكتملة', two: 'سورتان مكتملتان', few: 'سور مكتملة', many: 'سورة مكتملة')}'
      : '$count ${count == 1 ? 'surah' : 'surahs'} completed';

  String khatmahDaysLabel(int days) => isArabic
      ? arabicCountWord(
          days,
          one: 'يوم',
          two: 'يومان',
          few: 'أيام',
          many: 'يومًا',
        )
      : (days == 1 ? 'day' : 'days');

  String get wirdCompletedLabel =>
      isArabic ? 'أذكار أتممتُها' : 'adhkar completed';

  // ─── Share sheet chrome ──────────────────────────────────────────────────
  String get sheetTitle =>
      isArabic ? 'مشاركة بطاقة سوشيال ميديا' : 'Share your card';
  String get chooseStyle => isArabic ? 'اختر مظهر البطاقة:' : 'Card style:';
  String get shareAsImage => isArabic ? 'مشاركة كصورة 📸' : 'Share as image 📸';
  String get preparing => isArabic ? 'جاري التجهيز...' : 'Preparing...';
  String get saveToGalleryTooltip =>
      isArabic ? 'حفظ المعرض' : 'Save to gallery';
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
}
