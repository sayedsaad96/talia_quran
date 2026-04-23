import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application name
  ///
  /// In ar, this message translates to:
  /// **'تالية'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @quran.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get quran;

  /// No description provided for @hifz.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get hifz;

  /// No description provided for @azkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get azkar;

  /// No description provided for @progress.
  ///
  /// In ar, this message translates to:
  /// **'تقدمي'**
  String get progress;

  /// No description provided for @greetingMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح النور'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء النور'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In ar, this message translates to:
  /// **'ليلة مباركة'**
  String get greetingNight;

  /// No description provided for @dailyWird.
  ///
  /// In ar, this message translates to:
  /// **'الورد اليومي'**
  String get dailyWird;

  /// No description provided for @continueReading.
  ///
  /// In ar, this message translates to:
  /// **'أكمل القراءة'**
  String get continueReading;

  /// No description provided for @startMemorizing.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الحفظ'**
  String get startMemorizing;

  /// No description provided for @surahList.
  ///
  /// In ar, this message translates to:
  /// **'قائمة السور'**
  String get surahList;

  /// No description provided for @surahDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل السورة'**
  String get surahDetails;

  /// No description provided for @juz.
  ///
  /// In ar, this message translates to:
  /// **'الجزء'**
  String get juz;

  /// No description provided for @ayah.
  ///
  /// In ar, this message translates to:
  /// **'الآية'**
  String get ayah;

  /// No description provided for @ayahs.
  ///
  /// In ar, this message translates to:
  /// **'الآيات'**
  String get ayahs;

  /// No description provided for @surah.
  ///
  /// In ar, this message translates to:
  /// **'السورة'**
  String get surah;

  /// No description provided for @surahs.
  ///
  /// In ar, this message translates to:
  /// **'السور'**
  String get surahs;

  /// No description provided for @meccan.
  ///
  /// In ar, this message translates to:
  /// **'مكية'**
  String get meccan;

  /// No description provided for @medinan.
  ///
  /// In ar, this message translates to:
  /// **'مدنية'**
  String get medinan;

  /// No description provided for @searchSurah.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن سورة أو آية'**
  String get searchSurah;

  /// No description provided for @memorization.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get memorization;

  /// No description provided for @selectSurah.
  ///
  /// In ar, this message translates to:
  /// **'اختر سورة للحفظ'**
  String get selectSurah;

  /// No description provided for @selectAyah.
  ///
  /// In ar, this message translates to:
  /// **'اختر الآية'**
  String get selectAyah;

  /// No description provided for @startFrom.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ من'**
  String get startFrom;

  /// No description provided for @markMemorized.
  ///
  /// In ar, this message translates to:
  /// **'حفظت هذه الآية'**
  String get markMemorized;

  /// No description provided for @nextAyah.
  ///
  /// In ar, this message translates to:
  /// **'الآية التالية'**
  String get nextAyah;

  /// No description provided for @prevAyah.
  ///
  /// In ar, this message translates to:
  /// **'الآية السابقة'**
  String get prevAyah;

  /// No description provided for @memorized.
  ///
  /// In ar, this message translates to:
  /// **'محفوظة'**
  String get memorized;

  /// No description provided for @review.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة'**
  String get review;

  /// No description provided for @newAyah.
  ///
  /// In ar, this message translates to:
  /// **'آية جديدة'**
  String get newAyah;

  /// No description provided for @hifzProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدم الحفظ'**
  String get hifzProgress;

  /// No description provided for @morningAzkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get morningAzkar;

  /// No description provided for @eveningAzkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المساء'**
  String get eveningAzkar;

  /// No description provided for @generalAzkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار عامة'**
  String get generalAzkar;

  /// No description provided for @count.
  ///
  /// In ar, this message translates to:
  /// **'العدد'**
  String get count;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// No description provided for @reset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة'**
  String get reset;

  /// No description provided for @overallProgress.
  ///
  /// In ar, this message translates to:
  /// **'التقدم الكلي'**
  String get overallProgress;

  /// No description provided for @streak.
  ///
  /// In ar, this message translates to:
  /// **'السلسلة'**
  String get streak;

  /// No description provided for @days.
  ///
  /// In ar, this message translates to:
  /// **'أيام'**
  String get days;

  /// No description provided for @day.
  ///
  /// In ar, this message translates to:
  /// **'يوم'**
  String get day;

  /// No description provided for @achievements.
  ///
  /// In ar, this message translates to:
  /// **'الإنجازات'**
  String get achievements;

  /// No description provided for @yourStreak.
  ///
  /// In ar, this message translates to:
  /// **'سلسلة حضورك'**
  String get yourStreak;

  /// No description provided for @quranProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدمك في القرآن'**
  String get quranProgress;

  /// No description provided for @memorizedSurahs.
  ///
  /// In ar, this message translates to:
  /// **'السور المحفوظة'**
  String get memorizedSurahs;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الفاتح'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get darkMode;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get english;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// No description provided for @errorOccurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get errorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول مجدداً'**
  String get tryAgain;

  /// No description provided for @noData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get noData;

  /// No description provided for @emptyState.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد محتوى بعد'**
  String get emptyState;

  /// No description provided for @play.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get stop;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get previous;

  /// No description provided for @ofLabel.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get ofLabel;

  /// No description provided for @completed.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get completed;

  /// No description provided for @inProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التقدم'**
  String get inProgress;

  /// No description provided for @notStarted.
  ///
  /// In ar, this message translates to:
  /// **'لم يبدأ'**
  String get notStarted;

  /// No description provided for @bismillah.
  ///
  /// In ar, this message translates to:
  /// **'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'**
  String get bismillah;

  /// No description provided for @basmala.
  ///
  /// In ar, this message translates to:
  /// **'بسملة'**
  String get basmala;

  /// No description provided for @streakMessage1.
  ///
  /// In ar, this message translates to:
  /// **'استمر، أنت في المسار الصحيح!'**
  String get streakMessage1;

  /// No description provided for @streakMessage2.
  ///
  /// In ar, this message translates to:
  /// **'رائع! يوم آخر مع القرآن الكريم'**
  String get streakMessage2;

  /// No description provided for @streakMessage3.
  ///
  /// In ar, this message translates to:
  /// **'ماشاء الله! استمرارية مذهلة'**
  String get streakMessage3;

  /// No description provided for @achievementFirstSurah.
  ///
  /// In ar, this message translates to:
  /// **'حفظت أول سورة'**
  String get achievementFirstSurah;

  /// No description provided for @achievementWeekStreak.
  ///
  /// In ar, this message translates to:
  /// **'سلسلة أسبوع كامل'**
  String get achievementWeekStreak;

  /// No description provided for @achievementQuran10.
  ///
  /// In ar, this message translates to:
  /// **'٪10 من القرآن'**
  String get achievementQuran10;

  /// No description provided for @fontSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط'**
  String get fontSize;

  /// No description provided for @small.
  ///
  /// In ar, this message translates to:
  /// **'صغير'**
  String get small;

  /// No description provided for @medium.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get medium;

  /// No description provided for @large.
  ///
  /// In ar, this message translates to:
  /// **'كبير'**
  String get large;

  /// No description provided for @extraLarge.
  ///
  /// In ar, this message translates to:
  /// **'كبير جداً'**
  String get extraLarge;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @tafsir.
  ///
  /// In ar, this message translates to:
  /// **'التفسير'**
  String get tafsir;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// No description provided for @bookmark.
  ///
  /// In ar, this message translates to:
  /// **'إشارة مرجعية'**
  String get bookmark;

  /// No description provided for @copied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get copied;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get editProfile;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// No description provided for @age.
  ///
  /// In ar, this message translates to:
  /// **'العمر'**
  String get age;

  /// No description provided for @enterName.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك'**
  String get enterName;

  /// No description provided for @enterAge.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عمرك'**
  String get enterAge;

  /// No description provided for @profileUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الملف الشخصي'**
  String get profileUpdated;

  /// No description provided for @shareAchievement.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الإنجاز'**
  String get shareAchievement;

  /// No description provided for @shareAchievementText.
  ///
  /// In ar, this message translates to:
  /// **'🏆 بفضل الله، حققت إنجاز \"{title}\" 🌟\n📖 {description}\n\n📱 تم الإنجاز عبر تطبيق \"تالية\" المتميز!\n✨ لا تدع الأجر يفوتك، حمّل التطبيق الآن وانضم إلي في رحلة النور وحفظ كتاب الله 💚'**
  String shareAchievementText(Object description, Object title);

  /// No description provided for @shareAchievementWithName.
  ///
  /// In ar, this message translates to:
  /// **'🏆 بفضل الله، حقق {name} إنجاز \"{title}\" 🌟\n📖 {description}\n\n📱 تم الإنجاز عبر تطبيق \"تالية\" المتميز!\n✨ لا تدع الأجر يفوتك، حمّل التطبيق الآن وانضم إلينا في رحلة النور وحفظ كتاب الله 💚'**
  String shareAchievementWithName(
    Object description,
    Object name,
    Object title,
  );

  /// No description provided for @shareProgress.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة التقدم'**
  String get shareProgress;

  /// No description provided for @shareProgressText.
  ///
  /// In ar, this message translates to:
  /// **'📊 بفضل الله وتوفيقه، هذا تقدمي في رحلتي مع القرآن عبر تطبيق \"تالية\" 🌟:\n📖 {pages} صفحة مقروءة\n🧠 {ayahs} آية محفوظة\n🔥 {streak} أيام متتالية من الالتزام\n\n✨ حمّل تطبيق \"تالية\" الآن وابدأ رحلتك المباركة 💚'**
  String shareProgressText(Object ayahs, Object pages, Object streak);

  /// No description provided for @shareProgressWithName.
  ///
  /// In ar, this message translates to:
  /// **'📊 بفضل الله وتوفيقه، هذا تقدم {name} في رحلته مع القرآن عبر تطبيق \"تالية\" 🌟:\n📖 {pages} صفحة مقروءة\n🧠 {ayahs} آية محفوظة\n🔥 {streak} أيام متتالية من الالتزام\n\n✨ حمّل تطبيق \"تالية\" الآن وابدأ رحلتك المباركة 💚'**
  String shareProgressWithName(
    Object ayahs,
    Object name,
    Object pages,
    Object streak,
  );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
