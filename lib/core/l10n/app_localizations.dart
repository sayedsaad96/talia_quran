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

  /// No description provided for @duas.
  ///
  /// In ar, this message translates to:
  /// **'الأدعية'**
  String get duas;

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
  /// **'🏆 إنجاز جديد يُضاف في رحلتي مع القرآن: \"{title}\"\n📖 {description}\n\nمع تالية، كل خطوة تتحول إلى أثر يُرى وإنجاز يستحق المشاركة.'**
  String shareAchievementText(Object description, Object title);

  /// No description provided for @shareAchievementWithName.
  ///
  /// In ar, this message translates to:
  /// **'🏆 إنجاز جديد يُضاف في رحلة {name} مع القرآن: \"{title}\"\n📖 {description}\n\nمع تالية، كل خطوة تتحول إلى أثر يُرى وإنجاز يستحق المشاركة.'**
  String shareAchievementWithName(
    Object description,
    Object name,
    Object title,
  );

  /// No description provided for @shareMemorizationAchievementText.
  ///
  /// In ar, this message translates to:
  /// **'🌟 إنجاز مبارك في مسيرة الحفظ: \"{title}\"\n🧠 {description}\n\nتالية يرافق رحلة الحفظ بخطوات واضحة، وتحفيز مستمر، وإنجازات تُلهم الاستمرار.'**
  String shareMemorizationAchievementText(Object description, Object title);

  /// No description provided for @shareMemorizationAchievementWithName.
  ///
  /// In ar, this message translates to:
  /// **'🌟 إنجاز مبارك في مسيرة حفظ {name}: \"{title}\"\n🧠 {description}\n\nتالية يرافق رحلة الحفظ بخطوات واضحة، وتحفيز مستمر، وإنجازات تُلهم الاستمرار.'**
  String shareMemorizationAchievementWithName(
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
  /// **'📊 هذا ملخص تقدمي في رحلتي مع القرآن عبر تالية:\n📖 {pages} صفحة مقروءة\n🧠 {ayahs} آية محفوظة\n🔥 {streak} أيام من الاستمرارية\n\nتالية يساعدني على بناء عادة قرآنية ثابتة بخطوات واضحة وتحفيز يومي.'**
  String shareProgressText(Object ayahs, Object pages, Object streak);

  /// No description provided for @shareProgressWithName.
  ///
  /// In ar, this message translates to:
  /// **'📊 هذا ملخص تقدم {name} في رحلته مع القرآن عبر تالية:\n📖 {pages} صفحة مقروءة\n🧠 {ayahs} آية محفوظة\n🔥 {streak} أيام من الاستمرارية\n\nتالية يساعد على بناء عادة قرآنية ثابتة بخطوات واضحة وتحفيز يومي.'**
  String shareProgressWithName(
    Object ayahs,
    Object name,
    Object pages,
    Object streak,
  );

  /// No description provided for @viewAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get viewAll;

  /// No description provided for @reading.
  ///
  /// In ar, this message translates to:
  /// **'القراءة'**
  String get reading;

  /// No description provided for @page.
  ///
  /// In ar, this message translates to:
  /// **'صفحة'**
  String get page;

  /// No description provided for @pages.
  ///
  /// In ar, this message translates to:
  /// **'صفحات'**
  String get pages;

  /// No description provided for @pagesRead.
  ///
  /// In ar, this message translates to:
  /// **'صفحة مقروءة'**
  String get pagesRead;

  /// No description provided for @readingProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدم القراءة'**
  String get readingProgress;

  /// No description provided for @memorizationProgressTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقدم الحفظ'**
  String get memorizationProgressTitle;

  /// No description provided for @smartMemorization.
  ///
  /// In ar, this message translates to:
  /// **'نظام الحفظ الذكي'**
  String get smartMemorization;

  /// No description provided for @smartMemorizationSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'جدول تكيّفي • مراجعة ذكية • تقييم ذاتي'**
  String get smartMemorizationSubtitle;

  /// No description provided for @recitationAccuracy.
  ///
  /// In ar, this message translates to:
  /// **'دقة التسميع'**
  String get recitationAccuracy;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @about.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get about;

  /// No description provided for @systemDefault.
  ///
  /// In ar, this message translates to:
  /// **'حسب النظام'**
  String get systemDefault;

  /// No description provided for @changeMemorizationPath.
  ///
  /// In ar, this message translates to:
  /// **'تغيير مسار الحفظ'**
  String get changeMemorizationPath;

  /// No description provided for @adultPath.
  ///
  /// In ar, this message translates to:
  /// **'مسار الكبار'**
  String get adultPath;

  /// No description provided for @adultPathDesc.
  ///
  /// In ar, this message translates to:
  /// **'البدء من الفاتحة والبقرة تصاعدياً'**
  String get adultPathDesc;

  /// No description provided for @beginnerPath.
  ///
  /// In ar, this message translates to:
  /// **'مسار المبتدئين والأطفال'**
  String get beginnerPath;

  /// No description provided for @beginnerPathDesc.
  ///
  /// In ar, this message translates to:
  /// **'البدء من جزء عم (سورة الناس) تنازلياً'**
  String get beginnerPathDesc;

  /// No description provided for @chooseMemorizationPath.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسار الحفظ المناسب لك'**
  String get chooseMemorizationPath;

  /// No description provided for @audioPlayError.
  ///
  /// In ar, this message translates to:
  /// **'فشل تشغيل الصوت. تحقق من الاتصال بالإنترنت.'**
  String get audioPlayError;

  /// No description provided for @micPermissionError.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج التطبيق إذن الميكروفون للتسميع الصوتي. يرجى السماح من إعدادات الجهاز.'**
  String get micPermissionError;

  /// No description provided for @account.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get account;

  /// No description provided for @accuracyLevel.
  ///
  /// In ar, this message translates to:
  /// **'مستوى الدقة'**
  String get accuracyLevel;

  /// No description provided for @streakProtection.
  ///
  /// In ar, this message translates to:
  /// **'حماية السلسلة'**
  String get streakProtection;

  /// No description provided for @morningAzkarReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير أذكار الصباح'**
  String get morningAzkarReminder;

  /// No description provided for @eveningAzkarReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير أذكار المساء'**
  String get eveningAzkarReminder;

  /// No description provided for @dailyDuaReminder.
  ///
  /// In ar, this message translates to:
  /// **'دعاء اليوم'**
  String get dailyDuaReminder;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In ar, this message translates to:
  /// **'حساب جديد'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @createAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get createAccount;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني غير صحيح'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'6 أحرف على الأقل'**
  String get passwordTooShort;

  /// No description provided for @enterEmail.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور'**
  String get enterPassword;

  /// No description provided for @loginSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول بنجاح ✓'**
  String get loginSuccess;

  /// No description provided for @signupSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الحساب بنجاح ✓'**
  String get signupSuccess;

  /// No description provided for @profileSavedToCloud.
  ///
  /// In ar, this message translates to:
  /// **'تقدمك محفوظ على السحابة'**
  String get profileSavedToCloud;

  /// No description provided for @guestModeWarning.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لحفظ تقدمك على جميع أجهزتك وعدم فقدانه عند مسح التطبيق.'**
  String get guestModeWarning;

  /// No description provided for @signOutWarning.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تسجيل الخروج؟ تقدمك المحفوظ على السحابة لن يُحذف.'**
  String get signOutWarning;

  /// No description provided for @dailyReviewReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير المراجعة اليومية'**
  String get dailyReviewReminder;

  /// No description provided for @dailyReviewTime.
  ///
  /// In ar, this message translates to:
  /// **'كل يوم الساعة ٨:٠٠ مساءً'**
  String get dailyReviewTime;

  /// No description provided for @streakProtectionDesc.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه الساعة ١٠:٠٠ مساءً إذا لم تراجع'**
  String get streakProtectionDesc;

  /// No description provided for @morningAzkarTime.
  ///
  /// In ar, this message translates to:
  /// **'كل يوم الساعة ٦:٠٠ صباحًا'**
  String get morningAzkarTime;

  /// No description provided for @eveningAzkarTime.
  ///
  /// In ar, this message translates to:
  /// **'كل يوم الساعة ٦:٠٠ مساءً'**
  String get eveningAzkarTime;

  /// No description provided for @taliaDescription.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق متميز لحفظ ومراجعة القرآن الكريم'**
  String get taliaDescription;

  /// No description provided for @arabicNameHint.
  ///
  /// In ar, this message translates to:
  /// **'💡 يفضل إدخال الاسم باللغة العربية ليظهر بشكل أجمل في الشهادات'**
  String get arabicNameHint;

  /// No description provided for @invalidAge.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عمرًا صحيحًا بين 1 و120'**
  String get invalidAge;

  /// No description provided for @profileSaveError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ الملف الشخصي'**
  String get profileSaveError;

  /// No description provided for @accuracySaveError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ مستوى الدقة'**
  String get accuracySaveError;

  /// No description provided for @reviewReminderSaveError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث تذكير المراجعة'**
  String get reviewReminderSaveError;

  /// No description provided for @streakReminderSaveError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث تنبيه السلسلة'**
  String get streakReminderSaveError;

  /// No description provided for @morningAzkarSaveError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث تذكير أذكار الصباح'**
  String get morningAzkarSaveError;

  /// No description provided for @eveningAzkarSaveError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث تذكير أذكار المساء'**
  String get eveningAzkarSaveError;

  /// No description provided for @difficultyEasy.
  ///
  /// In ar, this message translates to:
  /// **'سهل (٧٠٪)'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In ar, this message translates to:
  /// **'متوسط (٨٥٪)'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In ar, this message translates to:
  /// **'صعب (٩٢٪)'**
  String get difficultyHard;

  /// No description provided for @bookmarkSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ العلامة المرجعية'**
  String get bookmarkSaved;

  /// No description provided for @bookmarkAdded.
  ///
  /// In ar, this message translates to:
  /// **'تم إضافة علامة مرجعية ✓'**
  String get bookmarkAdded;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In ar, this message translates to:
  /// **'تم إزالة العلامة المرجعية'**
  String get bookmarkRemoved;

  /// No description provided for @levelBeginner.
  ///
  /// In ar, this message translates to:
  /// **'مبتدئ'**
  String get levelBeginner;

  /// No description provided for @levelStudent.
  ///
  /// In ar, this message translates to:
  /// **'طالب'**
  String get levelStudent;

  /// No description provided for @levelHafez.
  ///
  /// In ar, this message translates to:
  /// **'حافظ'**
  String get levelHafez;

  /// No description provided for @levelSheikh.
  ///
  /// In ar, this message translates to:
  /// **'شيخ'**
  String get levelSheikh;

  /// No description provided for @levelImam.
  ///
  /// In ar, this message translates to:
  /// **'إمام'**
  String get levelImam;

  /// No description provided for @juzCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأجزاء'**
  String get juzCountLabel;

  /// No description provided for @ayahsRead.
  ///
  /// In ar, this message translates to:
  /// **'الآيات المقروءة'**
  String get ayahsRead;

  /// No description provided for @learning.
  ///
  /// In ar, this message translates to:
  /// **'قيد التعلم'**
  String get learning;

  /// No description provided for @reviewing.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get reviewing;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @streakTerm.
  ///
  /// In ar, this message translates to:
  /// **'المواظبة'**
  String get streakTerm;

  /// No description provided for @achieved.
  ///
  /// In ar, this message translates to:
  /// **'تم الإنجاز!'**
  String get achieved;

  /// No description provided for @adultsTrack.
  ///
  /// In ar, this message translates to:
  /// **'مسار الكبار'**
  String get adultsTrack;

  /// No description provided for @memorizedTerm.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get memorizedTerm;

  /// No description provided for @reviewingPrefix.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة: '**
  String get reviewingPrefix;

  /// No description provided for @kidsTrack.
  ///
  /// In ar, this message translates to:
  /// **'مسار الأطفال'**
  String get kidsTrack;

  /// No description provided for @points.
  ///
  /// In ar, this message translates to:
  /// **'النقاط'**
  String get points;

  /// No description provided for @stars.
  ///
  /// In ar, this message translates to:
  /// **'النجوم'**
  String get stars;

  /// No description provided for @myCertificates.
  ///
  /// In ar, this message translates to:
  /// **'شهاداتي'**
  String get myCertificates;

  /// No description provided for @juzSaved.
  ///
  /// In ar, this message translates to:
  /// **'الأجزاء المحفوظة'**
  String get juzSaved;

  /// No description provided for @removeBookmarkTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف العلامة؟'**
  String get removeBookmarkTitle;

  /// No description provided for @goBack.
  ///
  /// In ar, this message translates to:
  /// **'العودة'**
  String get goBack;

  /// No description provided for @taliaUser.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم تالية'**
  String get taliaUser;

  /// No description provided for @startFatihah.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ قراءة سورة الفاتحة'**
  String get startFatihah;

  /// No description provided for @surahAyahFormat.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surahName}، آية {ayahNumber}'**
  String surahAyahFormat(Object surahName, Object ayahNumber);

  /// No description provided for @saveProgress.
  ///
  /// In ar, this message translates to:
  /// **'احفظ تقدمك'**
  String get saveProgress;

  /// No description provided for @syncProgressDesc.
  ///
  /// In ar, this message translates to:
  /// **'قم بتسجيل الدخول لحفظ تقدمك ومزامنته على جميع أجهزتك'**
  String get syncProgressDesc;

  /// No description provided for @later.
  ///
  /// In ar, this message translates to:
  /// **'لاحقاً'**
  String get later;

  /// No description provided for @congratulations.
  ///
  /// In ar, this message translates to:
  /// **'مبارك!'**
  String get congratulations;

  /// No description provided for @completedJuzAmma.
  ///
  /// In ar, this message translates to:
  /// **'لقد أتممت حفظ جزء عم بنجاح.'**
  String get completedJuzAmma;

  /// No description provided for @completedQuran.
  ///
  /// In ar, this message translates to:
  /// **'لقد أتممت حفظ القرآن الكريم كاملاً بنجاح.'**
  String get completedQuran;

  /// No description provided for @continueMemorizing.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الحفظ'**
  String get continueMemorizing;

  /// No description provided for @view.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get view;

  /// No description provided for @endSessionTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الجلسة؟'**
  String get endSessionTitle;

  /// No description provided for @endSessionDesc.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في إنهاء جلسة الحفظ؟ لن يتم حفظ تقدمك الحالي.'**
  String get endSessionDesc;

  /// No description provided for @continueAction.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueAction;

  /// No description provided for @exitAction.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get exitAction;

  /// No description provided for @listen.
  ///
  /// In ar, this message translates to:
  /// **'استماع'**
  String get listen;

  /// No description provided for @finish.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء'**
  String get finish;

  /// No description provided for @skip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get skip;

  /// No description provided for @tryAgainAction.
  ///
  /// In ar, this message translates to:
  /// **'حاول مجدداً'**
  String get tryAgainAction;

  /// No description provided for @youRecited.
  ///
  /// In ar, this message translates to:
  /// **'ما قرأته:'**
  String get youRecited;

  /// No description provided for @listeningInProgress.
  ///
  /// In ar, this message translates to:
  /// **'جاري الاستماع...'**
  String get listeningInProgress;

  /// No description provided for @tapToRecord.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتسميع'**
  String get tapToRecord;

  /// No description provided for @adultPathTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسار الكبار (تصاعدي)'**
  String get adultPathTitle;

  /// No description provided for @adultPathSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'من الفاتحة إلى الناس'**
  String get adultPathSubtitle;

  /// No description provided for @beginnerPathTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسار المبتدئين (تنازلي)'**
  String get beginnerPathTitle;

  /// No description provided for @beginnerPathSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'من الناس إلى الفاتحة'**
  String get beginnerPathSubtitle;

  /// No description provided for @lockedSurahText.
  ///
  /// In ar, this message translates to:
  /// **'أكمل السورة السابقة لفتح هذه السورة'**
  String get lockedSurahText;

  /// No description provided for @bookmarksCountItem.
  ///
  /// In ar, this message translates to:
  /// **'{count} {count, plural, =1{علامة} other{علامات}}'**
  String bookmarksCountItem(int count);
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
