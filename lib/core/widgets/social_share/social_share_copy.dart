import 'package:flutter/widgets.dart';

/// Share-card copy is intentionally isolated from domain data.  The selected
/// app locale controls labels; Quran and Azkar text remain untouched.
class SocialShareCopy {
  const SocialShareCopy._(this.isArabic);

  factory SocialShareCopy.of(BuildContext context) => SocialShareCopy._(
        Localizations.localeOf(context).languageCode == 'ar',
      );

  final bool isArabic;
  TextDirection get direction => isArabic ? TextDirection.rtl : TextDirection.ltr;

  String get appName => isArabic ? 'تالية' : 'Talia';
  String get tagline => isArabic ? 'رفيقك في رحلة القرآن' : 'Your Quran companion';
  String get sharedFrom => isArabic
      ? 'تمت المشاركة عبر تطبيق تالية للقرآن الكريم'
      : 'Shared from Talia Quran';
  String journeyFor(String name) => isArabic ? 'رحلة $name مع القرآن' : "$name's Quran journey";
  String get quranBadge => isArabic ? 'آية قرآنية' : 'Quran verse';
  String get duaBadge => isArabic ? 'دعاء' : 'Dua';
  String get dhikrBadge => isArabic ? 'ذِكر' : 'Dhikr';
  String get achievementBadge => isArabic ? 'إنجاز جديد' : 'New achievement';
  String get memorizationBadge => isArabic ? 'إنجاز الحفظ' : 'Memorization milestone';
  String get streakBadge => isArabic ? 'استمرارية متواصلة' : 'Consistency streak';
  String get progressBadge => isArabic ? 'حصاد التقدم' : 'Progress snapshot';
  String surah(String name) => isArabic ? 'سورة $name' : 'Surah $name';
  String ayah(int number) => isArabic ? 'الآية $number' : 'Ayah $number';
  String get completed => isArabic ? 'مكتمل' : 'Completed';
  String progress(int value, int target) => isArabic ? '$value من $target' : '$value of $target';
  String get achievementComplete => isArabic ? 'تم الإنجاز' : 'Achievement unlocked';
  String get memorizationTitle => isArabic ? 'إنجاز في مسيرة الحفظ' : 'Memorization milestone';
  String ayahs(int value) => isArabic ? '$value آية محفوظة' : '$value ayahs memorized';
  String surahs(int value) => isArabic ? '$value سور مكتملة' : '$value surahs completed';
  String get streakTitle => isArabic ? 'استمرارية مباركة' : 'A blessed streak';
  String get consecutiveDays => isArabic ? 'أيام متواصلة' : 'consecutive days';
  String get quranCommitment => isArabic ? 'عهد مع القرآن الكريم' : 'A steady Quran habit';
  String longestStreak(int value) => isArabic ? 'أطول سلسلة: $value يوم' : 'Longest streak: $value days';
  String get progressTitle => isArabic ? 'حصاد الإنجاز والتقدم' : 'My Quran progress';
  String pages(int value) => isArabic ? '$value صفحة مقروءة' : '$value pages read';
  String get kidsLabel => isArabic ? 'رحلة الأبطال الصغار' : 'Little champions journey';
}
