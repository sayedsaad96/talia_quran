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

  /// No description provided for @undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get undo;

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

  /// No description provided for @dailyDuaTime.
  ///
  /// In ar, this message translates to:
  /// **'كل يوم الساعة ٩:٠٠ صباحًا'**
  String get dailyDuaTime;

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

  /// No description provided for @confirmationEmailSent.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم إرسال رسالة التأكيد، تحقق من بريدك'**
  String get confirmationEmailSent;

  /// No description provided for @resendConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال'**
  String get resendConfirmation;

  /// No description provided for @authEmailAlreadyRegistered.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني مسجل بالفعل. حاول تسجيل الدخول.'**
  String get authEmailAlreadyRegistered;

  /// No description provided for @authConfirmEmailFirst.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تأكيد بريدك الإلكتروني أولاً. تحقق من صندوق الوارد.'**
  String get authConfirmEmailFirst;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة'**
  String get authInvalidCredentials;

  /// No description provided for @authTooManyRequests.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة. انتظر قليلاً ثم حاول مرة أخرى.'**
  String get authTooManyRequests;

  /// No description provided for @authNoInternet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get authNoInternet;

  /// No description provided for @authAccountNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حساب بهذا البريد الإلكتروني'**
  String get authAccountNotFound;

  /// No description provided for @authSignupFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إنشاء الحساب'**
  String get authSignupFailed;

  /// No description provided for @authSigninFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تسجيل الدخول'**
  String get authSigninFailed;

  /// No description provided for @authSignoutFailed.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تسجيل الخروج'**
  String get authSignoutFailed;

  /// No description provided for @authGenericError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ، حاول مرة أخرى'**
  String get authGenericError;

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

  /// No description provided for @settingsAppBrand.
  ///
  /// In ar, this message translates to:
  /// **'تالية — Talia'**
  String get settingsAppBrand;

  /// No description provided for @tutorialGuideTitle.
  ///
  /// In ar, this message translates to:
  /// **'دليل استخدام تالية'**
  String get tutorialGuideTitle;

  /// No description provided for @tutorialGuideSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تعرف على كل مزايا التطبيق وطريقة استخدامها'**
  String get tutorialGuideSubtitle;

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

  /// No description provided for @dailyDuaSaveError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث دعاء اليوم'**
  String get dailyDuaSaveError;

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

  /// No description provided for @bestStreak.
  ///
  /// In ar, this message translates to:
  /// **'أفضل: {count}'**
  String bestStreak(Object count);

  /// No description provided for @consecutiveDays.
  ///
  /// In ar, this message translates to:
  /// **'يوم متتالي'**
  String get consecutiveDays;

  /// No description provided for @miniProgressOf.
  ///
  /// In ar, this message translates to:
  /// **'{unit} من {total}'**
  String miniProgressOf(Object total, Object unit);

  /// No description provided for @dailyPlanSummary.
  ///
  /// In ar, this message translates to:
  /// **'{ayahs} آيات يومياً • {minutes} دقيقة'**
  String dailyPlanSummary(Object ayahs, Object minutes);

  /// No description provided for @debugCertificatePreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الشهادات للتجربة'**
  String get debugCertificatePreview;

  /// No description provided for @debugCertificatePreviewDesc.
  ///
  /// In ar, this message translates to:
  /// **'اختبار عرض الشهادة دون الحصول عليها فعلياً.'**
  String get debugCertificatePreviewDesc;

  /// No description provided for @debugCertJuz30.
  ///
  /// In ar, this message translates to:
  /// **'جزء 30'**
  String get debugCertJuz30;

  /// No description provided for @debugCertSurahBaqarah.
  ///
  /// In ar, this message translates to:
  /// **'سورة البقرة'**
  String get debugCertSurahBaqarah;

  /// No description provided for @debugCertHalfQuran.
  ///
  /// In ar, this message translates to:
  /// **'نصف القرآن'**
  String get debugCertHalfQuran;

  /// No description provided for @debugCertFullQuran.
  ///
  /// In ar, this message translates to:
  /// **'ختم القرآن'**
  String get debugCertFullQuran;

  /// No description provided for @backupProgressTitle.
  ///
  /// In ar, this message translates to:
  /// **'احفظ تقدمك الآن!'**
  String get backupProgressTitle;

  /// No description provided for @backupProgressDesc.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك من الإعدادات لحماية تقدمك'**
  String get backupProgressDesc;

  /// No description provided for @azkarSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اذكر الله كثيراً'**
  String get azkarSubtitle;

  /// No description provided for @zikrCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} ذكر'**
  String zikrCount(Object count);

  /// No description provided for @azkarCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} أذكار'**
  String azkarCount(Object count);

  /// No description provided for @duaCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} دعاء'**
  String duaCount(Object count);

  /// No description provided for @azkarIndex.
  ///
  /// In ar, this message translates to:
  /// **'فهرس الأذكار'**
  String get azkarIndex;

  /// No description provided for @zikrNumber.
  ///
  /// In ar, this message translates to:
  /// **'ذكر رقم {number}'**
  String zikrNumber(Object number);

  /// No description provided for @completedCount.
  ///
  /// In ar, this message translates to:
  /// **'{completed} من {total} مكتمل'**
  String completedCount(Object completed, Object total);

  /// No description provided for @zikrCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الذكر'**
  String get zikrCopied;

  /// No description provided for @sharedFromTalia.
  ///
  /// In ar, this message translates to:
  /// **'تمت المشاركة من تطبيق تالية للقرآن'**
  String get sharedFromTalia;

  /// No description provided for @zikrCompleted.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل الذكر'**
  String get zikrCompleted;

  /// No description provided for @tapToTasbeeh.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للتسبيح (من {total})'**
  String tapToTasbeeh(Object total);

  /// No description provided for @azkarCompletedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم بحمد الله'**
  String get azkarCompletedTitle;

  /// No description provided for @azkarCompletedDesc.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت جميع الأذكار في هذه الفئة'**
  String get azkarCompletedDesc;

  /// No description provided for @generalAzkarSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة من الأذكار الشاملة'**
  String get generalAzkarSubtitle;

  /// No description provided for @duasSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدعية من القرآن والسنة ودعاء ختم القرآن'**
  String get duasSubtitle;

  /// No description provided for @totalSurahsAyahs.
  ///
  /// In ar, this message translates to:
  /// **'{surahs} سورة • {ayahs} آية'**
  String totalSurahsAyahs(Object ayahs, Object surahs);

  /// No description provided for @yearActivity.
  ///
  /// In ar, this message translates to:
  /// **'نشاط السنة'**
  String get yearActivity;

  /// No description provided for @activityTooltip.
  ///
  /// In ar, this message translates to:
  /// **'{count} نشاط'**
  String activityTooltip(Object count);

  /// No description provided for @less.
  ///
  /// In ar, this message translates to:
  /// **'أقل'**
  String get less;

  /// No description provided for @more.
  ///
  /// In ar, this message translates to:
  /// **'أكثر'**
  String get more;

  /// No description provided for @memorizedAyahs.
  ///
  /// In ar, this message translates to:
  /// **'الآيات المحفوظة'**
  String get memorizedAyahs;

  /// No description provided for @memorizedSurahsLabel.
  ///
  /// In ar, this message translates to:
  /// **'السور المحفوظة'**
  String get memorizedSurahsLabel;

  /// No description provided for @memorizedJuzLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأجزاء المحفوظة'**
  String get memorizedJuzLabel;

  /// No description provided for @earnCertificatesHint.
  ///
  /// In ar, this message translates to:
  /// **'احفظ السور والأجزاء كاملة لتحصل على شهادات التميز!'**
  String get earnCertificatesHint;

  /// No description provided for @certificateTitleJuz.
  ///
  /// In ar, this message translates to:
  /// **'شهادة حفظ الجزء {juz}'**
  String certificateTitleJuz(Object juz);

  /// No description provided for @certificateTitleSurah.
  ///
  /// In ar, this message translates to:
  /// **'شهادة حفظ سورة'**
  String get certificateTitleSurah;

  /// No description provided for @certificateTitleSurahNamed.
  ///
  /// In ar, this message translates to:
  /// **'شهادة حفظ سورة {surahName}'**
  String certificateTitleSurahNamed(Object surahName);

  /// No description provided for @certificateTitleHalfQuran.
  ///
  /// In ar, this message translates to:
  /// **'شهادة حفظ نصف القرآن الكريم'**
  String get certificateTitleHalfQuran;

  /// No description provided for @certificateTitleFullQuran.
  ///
  /// In ar, this message translates to:
  /// **'شهادة ختم القرآن الكريم كاملاً'**
  String get certificateTitleFullQuran;

  /// No description provided for @saveFormatTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر صيغة الحفظ'**
  String get saveFormatTitle;

  /// No description provided for @saveAsImage.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كصورة (في الاستوديو)'**
  String get saveAsImage;

  /// No description provided for @saveAsPdf.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كملف PDF'**
  String get saveAsPdf;

  /// No description provided for @certificateShareError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء المشاركة'**
  String get certificateShareError;

  /// No description provided for @certificateGalleryPermissionError.
  ///
  /// In ar, this message translates to:
  /// **'يجب منح صلاحية الوصول للاستوديو لحفظ الشهادة'**
  String get certificateGalleryPermissionError;

  /// No description provided for @certificateGallerySaveSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الشهادة في الاستوديو بنجاح ✓'**
  String get certificateGallerySaveSuccess;

  /// No description provided for @certificateSaveError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الحفظ'**
  String get certificateSaveError;

  /// No description provided for @certificatePdfError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء إنشاء ملف PDF'**
  String get certificatePdfError;

  /// No description provided for @shareCertificateJuz.
  ///
  /// In ar, this message translates to:
  /// **'بفضل الله أتممت حفظ الجزء {juz} من القرآن الكريم 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙'**
  String shareCertificateJuz(Object juz);

  /// No description provided for @shareCertificateSurah.
  ///
  /// In ar, this message translates to:
  /// **'بفضل الله أتممت حفظ سورة {surahName} من القرآن الكريم 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙'**
  String shareCertificateSurah(Object surahName);

  /// No description provided for @shareCertificateHalfQuran.
  ///
  /// In ar, this message translates to:
  /// **'بفضل الله أتممت حفظ نصف القرآن الكريم 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙'**
  String get shareCertificateHalfQuran;

  /// No description provided for @shareCertificateFullQuran.
  ///
  /// In ar, this message translates to:
  /// **'بفضل الله أتممت حفظ القرآن الكريم كاملاً 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙'**
  String get shareCertificateFullQuran;

  /// No description provided for @achievementTitleFirstPage.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة الأولى'**
  String get achievementTitleFirstPage;

  /// No description provided for @achievementDescFirstPage.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ أول صفحة من القرآن'**
  String get achievementDescFirstPage;

  /// No description provided for @achievementTitleTenPages.
  ///
  /// In ar, this message translates to:
  /// **'١٠ صفحات'**
  String get achievementTitleTenPages;

  /// No description provided for @achievementDescTenPages.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ ١٠ صفحات من القرآن'**
  String get achievementDescTenPages;

  /// No description provided for @achievementTitleFiftyPages.
  ///
  /// In ar, this message translates to:
  /// **'٥٠ صفحة'**
  String get achievementTitleFiftyPages;

  /// No description provided for @achievementDescFiftyPages.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ ٥٠ صفحة من القرآن'**
  String get achievementDescFiftyPages;

  /// No description provided for @achievementTitleJuzRead.
  ///
  /// In ar, this message translates to:
  /// **'جزء كامل'**
  String get achievementTitleJuzRead;

  /// No description provided for @achievementDescJuzRead.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ جزءاً كاملاً (٢٠ صفحة)'**
  String get achievementDescJuzRead;

  /// No description provided for @achievementTitleFiveJuzRead.
  ///
  /// In ar, this message translates to:
  /// **'٥ أجزاء'**
  String get achievementTitleFiveJuzRead;

  /// No description provided for @achievementDescFiveJuzRead.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ ٥ أجزاء من القرآن'**
  String get achievementDescFiveJuzRead;

  /// No description provided for @achievementTitleHalfQuranRead.
  ///
  /// In ar, this message translates to:
  /// **'نصف القرآن'**
  String get achievementTitleHalfQuranRead;

  /// No description provided for @achievementDescHalfQuranRead.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ نصف القرآن الكريم'**
  String get achievementDescHalfQuranRead;

  /// No description provided for @achievementTitleFullQuranRead.
  ///
  /// In ar, this message translates to:
  /// **'ختم القرآن'**
  String get achievementTitleFullQuranRead;

  /// No description provided for @achievementDescFullQuranRead.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ القرآن الكريم كاملاً'**
  String get achievementDescFullQuranRead;

  /// No description provided for @achievementTitleFirstAyah.
  ///
  /// In ar, this message translates to:
  /// **'أول آية'**
  String get achievementTitleFirstAyah;

  /// No description provided for @achievementDescFirstAyah.
  ///
  /// In ar, this message translates to:
  /// **'احفظ أول آية من القرآن'**
  String get achievementDescFirstAyah;

  /// No description provided for @achievementTitleTenAyahs.
  ///
  /// In ar, this message translates to:
  /// **'١٠ آيات'**
  String get achievementTitleTenAyahs;

  /// No description provided for @achievementDescTenAyahs.
  ///
  /// In ar, this message translates to:
  /// **'احفظ ١٠ آيات'**
  String get achievementDescTenAyahs;

  /// No description provided for @achievementTitleFiftyAyahs.
  ///
  /// In ar, this message translates to:
  /// **'٥٠ آية'**
  String get achievementTitleFiftyAyahs;

  /// No description provided for @achievementDescFiftyAyahs.
  ///
  /// In ar, this message translates to:
  /// **'احفظ ٥٠ آية'**
  String get achievementDescFiftyAyahs;

  /// No description provided for @achievementTitleHundredAyahs.
  ///
  /// In ar, this message translates to:
  /// **'١٠٠ آية'**
  String get achievementTitleHundredAyahs;

  /// No description provided for @achievementDescHundredAyahs.
  ///
  /// In ar, this message translates to:
  /// **'احفظ ١٠٠ آية'**
  String get achievementDescHundredAyahs;

  /// No description provided for @achievementTitleFirstSurah.
  ///
  /// In ar, this message translates to:
  /// **'أول سورة'**
  String get achievementTitleFirstSurah;

  /// No description provided for @achievementDescFirstSurah.
  ///
  /// In ar, this message translates to:
  /// **'احفظ سورة كاملة'**
  String get achievementDescFirstSurah;

  /// No description provided for @achievementTitleFiveSurahs.
  ///
  /// In ar, this message translates to:
  /// **'٥ سور'**
  String get achievementTitleFiveSurahs;

  /// No description provided for @achievementDescFiveSurahs.
  ///
  /// In ar, this message translates to:
  /// **'احفظ ٥ سور كاملة'**
  String get achievementDescFiveSurahs;

  /// No description provided for @achievementTitleTenSurahs.
  ///
  /// In ar, this message translates to:
  /// **'١٠ سور'**
  String get achievementTitleTenSurahs;

  /// No description provided for @achievementDescTenSurahs.
  ///
  /// In ar, this message translates to:
  /// **'احفظ ١٠ سور كاملة'**
  String get achievementDescTenSurahs;

  /// No description provided for @achievementTitleJuzAmma.
  ///
  /// In ar, this message translates to:
  /// **'جزء عمّ'**
  String get achievementTitleJuzAmma;

  /// No description provided for @achievementDescJuzAmma.
  ///
  /// In ar, this message translates to:
  /// **'احفظ ٥٦٤ آية (جزء عمّ)'**
  String get achievementDescJuzAmma;

  /// No description provided for @achievementTitleOneJuzMemorized.
  ///
  /// In ar, this message translates to:
  /// **'جزء محفوظ'**
  String get achievementTitleOneJuzMemorized;

  /// No description provided for @achievementDescOneJuzMemorized.
  ///
  /// In ar, this message translates to:
  /// **'احفظ جزءاً كاملاً'**
  String get achievementDescOneJuzMemorized;

  /// No description provided for @achievementTitleFiveJuzMemorized.
  ///
  /// In ar, this message translates to:
  /// **'٥ أجزاء محفوظة'**
  String get achievementTitleFiveJuzMemorized;

  /// No description provided for @achievementDescFiveJuzMemorized.
  ///
  /// In ar, this message translates to:
  /// **'احفظ ٥ أجزاء من القرآن'**
  String get achievementDescFiveJuzMemorized;

  /// No description provided for @achievementTitleTenJuzMemorized.
  ///
  /// In ar, this message translates to:
  /// **'١٠ أجزاء'**
  String get achievementTitleTenJuzMemorized;

  /// No description provided for @achievementDescTenJuzMemorized.
  ///
  /// In ar, this message translates to:
  /// **'احفظ ١٠ أجزاء من القرآن'**
  String get achievementDescTenJuzMemorized;

  /// No description provided for @achievementTitleHalfQuranMemorized.
  ///
  /// In ar, this message translates to:
  /// **'نصف القرآن'**
  String get achievementTitleHalfQuranMemorized;

  /// No description provided for @achievementDescHalfQuranMemorized.
  ///
  /// In ar, this message translates to:
  /// **'احفظ نصف القرآن الكريم'**
  String get achievementDescHalfQuranMemorized;

  /// No description provided for @achievementTitleFullQuranMemorized.
  ///
  /// In ar, this message translates to:
  /// **'حافظ القرآن'**
  String get achievementTitleFullQuranMemorized;

  /// No description provided for @achievementDescFullQuranMemorized.
  ///
  /// In ar, this message translates to:
  /// **'احفظ القرآن الكريم كاملاً'**
  String get achievementDescFullQuranMemorized;

  /// No description provided for @achievementTitleThreeDayStreak.
  ///
  /// In ar, this message translates to:
  /// **'٣ أيام متتالية'**
  String get achievementTitleThreeDayStreak;

  /// No description provided for @achievementDescThreeDayStreak.
  ///
  /// In ar, this message translates to:
  /// **'حافظ على ٣ أيام متتالية'**
  String get achievementDescThreeDayStreak;

  /// No description provided for @achievementTitleWeekStreak.
  ///
  /// In ar, this message translates to:
  /// **'أسبوع كامل'**
  String get achievementTitleWeekStreak;

  /// No description provided for @achievementDescWeekStreak.
  ///
  /// In ar, this message translates to:
  /// **'حافظ على ٧ أيام متتالية'**
  String get achievementDescWeekStreak;

  /// No description provided for @achievementTitleTwoWeekStreak.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعان'**
  String get achievementTitleTwoWeekStreak;

  /// No description provided for @achievementDescTwoWeekStreak.
  ///
  /// In ar, this message translates to:
  /// **'حافظ على ١٤ يوماً متتالية'**
  String get achievementDescTwoWeekStreak;

  /// No description provided for @achievementTitleMonthStreak.
  ///
  /// In ar, this message translates to:
  /// **'شهر كامل'**
  String get achievementTitleMonthStreak;

  /// No description provided for @achievementDescMonthStreak.
  ///
  /// In ar, this message translates to:
  /// **'حافظ على ٣٠ يوماً متتالية'**
  String get achievementDescMonthStreak;

  /// No description provided for @achievementTitleNinetyDayStreak.
  ///
  /// In ar, this message translates to:
  /// **'٩٠ يوماً'**
  String get achievementTitleNinetyDayStreak;

  /// No description provided for @achievementDescNinetyDayStreak.
  ///
  /// In ar, this message translates to:
  /// **'حافظ على ٩٠ يوماً متتالية'**
  String get achievementDescNinetyDayStreak;

  /// No description provided for @achievementTitleYearStreak.
  ///
  /// In ar, this message translates to:
  /// **'سنة كاملة'**
  String get achievementTitleYearStreak;

  /// No description provided for @achievementDescYearStreak.
  ///
  /// In ar, this message translates to:
  /// **'حافظ على ٣٦٥ يوماً متتالياً'**
  String get achievementDescYearStreak;

  /// No description provided for @bookmarksCountItem.
  ///
  /// In ar, this message translates to:
  /// **'{count} {count, plural, =1{علامة} other{علامات}}'**
  String bookmarksCountItem(int count);

  /// No description provided for @memorizationPathReset.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة ضبط مسار الحفظ'**
  String get memorizationPathReset;

  /// No description provided for @resetMemorizationPath.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ضبط / تغيير المسار'**
  String get resetMemorizationPath;

  /// No description provided for @memorizationPath.
  ///
  /// In ar, this message translates to:
  /// **'مسار الحفظ'**
  String get memorizationPath;

  /// No description provided for @kidsAndGuardian.
  ///
  /// In ar, this message translates to:
  /// **'الأطفال وولي الأمر'**
  String get kidsAndGuardian;

  /// No description provided for @parentDashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة ولي الأمر'**
  String get parentDashboardTitle;

  /// No description provided for @parentDashboardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تابع حفظ الطفل والمكافآت والربط عن بعد'**
  String get parentDashboardSubtitle;

  /// No description provided for @parentModeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'فعّل لمتابعة حفظ طفلك والربط عن بعد'**
  String get parentModeSubtitle;

  /// No description provided for @resetMemorizationPathQuestion.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ضبط مسار الحفظ؟'**
  String get resetMemorizationPathQuestion;

  /// No description provided for @resetMemorizationIdentityWarning.
  ///
  /// In ar, this message translates to:
  /// **'سيؤدي هذا إلى إلغاء المسار المختار وحالة ربط ولي الأمر، ولكنه سيحتفظ بإعدادات الحفظ الذكي الخاصة بك.'**
  String get resetMemorizationIdentityWarning;

  /// No description provided for @confirmResetMemorizationPath.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد إعادة الضبط'**
  String get confirmResetMemorizationPath;

  /// No description provided for @resetMemorizationPathTileTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ضبط المسار'**
  String get resetMemorizationPathTileTitle;

  /// No description provided for @resetMemorizationPathTileSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسار الكبار أو الأطفال مرة أخرى بدون فقدان إعدادات الحفظ الذكي.'**
  String get resetMemorizationPathTileSubtitle;

  /// No description provided for @resetMemorizationPathPreserveProgressDesc.
  ///
  /// In ar, this message translates to:
  /// **'تغيير مسار الحفظ بين مسار الكبار والأطفال، مع الاحتفاظ ببيانات الحفظ.'**
  String get resetMemorizationPathPreserveProgressDesc;

  /// No description provided for @resetMemorizationPathPreserveProgressDialog.
  ///
  /// In ar, this message translates to:
  /// **'هذا سيقوم بإلغاء مسار الحفظ الحالي لتتمكن من اختيار مسار جديد. لن تفقد آياتك المحفوظة.'**
  String get resetMemorizationPathPreserveProgressDialog;

  /// No description provided for @completePreviousSurahFirst.
  ///
  /// In ar, this message translates to:
  /// **'أكمل {surahName} أولاً'**
  String completePreviousSurahFirst(Object surahName);

  /// No description provided for @linkGuardianNow.
  ///
  /// In ar, this message translates to:
  /// **'ربط ولي الأمر الآن'**
  String get linkGuardianNow;

  /// No description provided for @continueWithoutGuardian.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة بدون ولي أمر'**
  String get continueWithoutGuardian;

  /// No description provided for @guardianLinkTitle.
  ///
  /// In ar, this message translates to:
  /// **'ربط حساب ولي الأمر'**
  String get guardianLinkTitle;

  /// No description provided for @guardianLinkDesc.
  ///
  /// In ar, this message translates to:
  /// **'اختر ما إذا كنت تريد ربط ولي أمر بهذا المسار لمتابعة حفظ الطفل.'**
  String get guardianLinkDesc;

  /// No description provided for @guardianCreateCodeMessage.
  ///
  /// In ar, this message translates to:
  /// **'قم بإنشاء رمز جديد صالح لمدة 15 دقيقة.'**
  String get guardianCreateCodeMessage;

  /// No description provided for @guardianCodeUsedMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن استخدام هذا الرمز مرة أخرى.'**
  String get guardianCodeUsedMessage;

  /// No description provided for @guardianCreateNewCode.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رمز جديد'**
  String get guardianCreateNewCode;

  /// No description provided for @guardianCodeExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الرمز'**
  String get guardianCodeExpired;

  /// No description provided for @guardianCodeAlreadyUsed.
  ///
  /// In ar, this message translates to:
  /// **'تم استخدام الرمز مسبقاً'**
  String get guardianCodeAlreadyUsed;

  /// No description provided for @guardianPairingValidUntil.
  ///
  /// In ar, this message translates to:
  /// **'صالح حتى الساعة {time}'**
  String guardianPairingValidUntil(Object time);

  /// No description provided for @guardianPairingExpiresIn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي خلال {minutes} دقيقة'**
  String guardianPairingExpiresIn(int minutes);

  /// No description provided for @guardianPairingExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الرمز'**
  String get guardianPairingExpired;

  /// No description provided for @guardianPairingStepsTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطوات الربط'**
  String get guardianPairingStepsTitle;

  /// No description provided for @guardianPairingStepOpenParentDevice.
  ///
  /// In ar, this message translates to:
  /// **'افتح تالية على جهاز ولي الأمر'**
  String get guardianPairingStepOpenParentDevice;

  /// No description provided for @guardianPairingStepOpenDashboard.
  ///
  /// In ar, this message translates to:
  /// **'اذهب إلى الإعدادات > لوحة ولي الأمر'**
  String get guardianPairingStepOpenDashboard;

  /// No description provided for @guardianPairingStepScanOrEnterCode.
  ///
  /// In ar, this message translates to:
  /// **'امسح رمز QR أو أدخل الرمز يدوياً'**
  String get guardianPairingStepScanOrEnterCode;

  /// No description provided for @guardianRegenerateCode.
  ///
  /// In ar, this message translates to:
  /// **'تجديد الرمز'**
  String get guardianRegenerateCode;

  /// No description provided for @splashSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق تحفيظ القرآن الكريم'**
  String get splashSubtitle;

  /// No description provided for @onboardingSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get onboardingSkip;

  /// No description provided for @onboardingStartNow.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get onboardingStartNow;

  /// No description provided for @onboardingQuranTitle.
  ///
  /// In ar, this message translates to:
  /// **'تجربة المصحف الحقيقي'**
  String get onboardingQuranTitle;

  /// No description provided for @onboardingQuranDesc.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ القرآن الكريم بتجربة فريدة تحاكي المصحف الورقي بصفحاته وتصميمه الأصيل لتنعم بخشوع التلاوة.'**
  String get onboardingQuranDesc;

  /// No description provided for @onboardingSmartTitle.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ذكي ومراجعة مخصصة'**
  String get onboardingSmartTitle;

  /// No description provided for @onboardingSmartDesc.
  ///
  /// In ar, this message translates to:
  /// **'خطط حفظ مرنة، ومراجعات ذكية، وتقييم ذاتي يساعدك على تثبيت الآيات بدون ضغط.'**
  String get onboardingSmartDesc;

  /// No description provided for @onboardingKidsTitle.
  ///
  /// In ar, this message translates to:
  /// **'رحلة ممتعة للأطفال'**
  String get onboardingKidsTitle;

  /// No description provided for @onboardingKidsDesc.
  ///
  /// In ar, this message translates to:
  /// **'مسار مبسط للأطفال يجمع بين الاستماع والتكرار والنجوم، مع متابعة ولي الأمر.'**
  String get onboardingKidsDesc;

  /// No description provided for @memorizationPathTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسار الحفظ'**
  String get memorizationPathTitle;

  /// No description provided for @memorizationPathQuestion.
  ///
  /// In ar, this message translates to:
  /// **'من سيستخدم هذه الميزة؟'**
  String get memorizationPathQuestion;

  /// No description provided for @memorizationPathDescription.
  ///
  /// In ar, this message translates to:
  /// **'اختر المسار المناسب لك أو لطفلك لتجربة حفظ مخصصة.'**
  String get memorizationPathDescription;

  /// No description provided for @memorizationPathAdultsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسار البالغين'**
  String get memorizationPathAdultsTitle;

  /// No description provided for @memorizationPathAdultsDesc.
  ///
  /// In ar, this message translates to:
  /// **'خطة حفظ مرنة مع مراجعة ذكية وتتبع يومي للإنجاز.'**
  String get memorizationPathAdultsDesc;

  /// No description provided for @memorizationPathKidsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسار الأطفال'**
  String get memorizationPathKidsTitle;

  /// No description provided for @memorizationPathKidsDesc.
  ///
  /// In ar, this message translates to:
  /// **'رحلة حفظ تفاعلية ممتعة بإشراف ولي الأمر.'**
  String get memorizationPathKidsDesc;

  /// No description provided for @kidsJourneyTitle.
  ///
  /// In ar, this message translates to:
  /// **'رحلة الحفظ'**
  String get kidsJourneyTitle;

  /// No description provided for @kidsJourneySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'استمع، كرر، واجمع النجوم خطوة بخطوة'**
  String get kidsJourneySubtitle;

  /// No description provided for @kidsJourneyMapTitle.
  ///
  /// In ar, this message translates to:
  /// **'خريطة الحفظ'**
  String get kidsJourneyMapTitle;

  /// No description provided for @kidsPointsValue.
  ///
  /// In ar, this message translates to:
  /// **'{points} نقطة'**
  String kidsPointsValue(int points);

  /// No description provided for @kidsLevelValue.
  ///
  /// In ar, this message translates to:
  /// **'مستوى {level}'**
  String kidsLevelValue(int level);

  /// No description provided for @kidsStartFirstStageToday.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ أول مرحلة اليوم'**
  String get kidsStartFirstStageToday;

  /// No description provided for @kidsStageAyahRange.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة {stage}: الآيات {startAyah}-{endAyah}'**
  String kidsStageAyahRange(int stage, int startAyah, int endAyah);

  /// No description provided for @remoteGuardianLinkTitle.
  ///
  /// In ar, this message translates to:
  /// **'ربط ولي الأمر عن بعد'**
  String get remoteGuardianLinkTitle;

  /// No description provided for @createQr.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء QR'**
  String get createQr;

  /// No description provided for @renew.
  ///
  /// In ar, this message translates to:
  /// **'تجديد'**
  String get renew;

  /// No description provided for @remoteGuardianLinkInstruction.
  ///
  /// In ar, this message translates to:
  /// **'افتح لوحة ولي الأمر على الجهاز الآخر وامسح الرمز.'**
  String get remoteGuardianLinkInstruction;

  /// No description provided for @kidsStageTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحلة {stage}'**
  String kidsStageTitle(int stage);

  /// No description provided for @kidsStageProgress.
  ///
  /// In ar, this message translates to:
  /// **'الآيات {startAyah}-{endAyah} • {completed}/{total}'**
  String kidsStageProgress(
    int startAyah,
    int endAyah,
    int completed,
    int total,
  );

  /// No description provided for @quranLongPressHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً على الآية للاستماع أو إضافة علامة'**
  String get quranLongPressHint;

  /// No description provided for @readPageConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'تم احتساب الصفحة'**
  String get readPageConfirmed;

  /// No description provided for @dailyPlanRatingWeakDesc.
  ///
  /// In ar, this message translates to:
  /// **'احتجت للمصحف'**
  String get dailyPlanRatingWeakDesc;

  /// No description provided for @dailyPlanRatingAverageDesc.
  ///
  /// In ar, this message translates to:
  /// **'أخطاء بسيطة'**
  String get dailyPlanRatingAverageDesc;

  /// No description provided for @dailyPlanRatingExcellentDesc.
  ///
  /// In ar, this message translates to:
  /// **'بدون خطأ'**
  String get dailyPlanRatingExcellentDesc;

  /// No description provided for @dailyPlanRatingHintTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف تختار التقييم؟'**
  String get dailyPlanRatingHintTitle;

  /// No description provided for @dailyPlanRatingHintBody.
  ///
  /// In ar, this message translates to:
  /// **'التقييم يحدد موعد المراجعة القادمة: ضعيف للمراجعة القريبة، متوسط للمراجعة المعتدلة، وممتاز للمراجعة بعد فترة أطول.'**
  String get dailyPlanRatingHintBody;

  /// No description provided for @understood.
  ///
  /// In ar, this message translates to:
  /// **'فهمت'**
  String get understood;

  /// No description provided for @hifzSkipHintTitle.
  ///
  /// In ar, this message translates to:
  /// **'تخطي الآية'**
  String get hifzSkipHintTitle;

  /// No description provided for @hifzSkipHintBody.
  ///
  /// In ar, this message translates to:
  /// **'سنضيف هذه الآية للمراجعة لاحقاً، لا تقلق.'**
  String get hifzSkipHintBody;

  /// No description provided for @accuracyEasyTitle.
  ///
  /// In ar, this message translates to:
  /// **'متسامح'**
  String get accuracyEasyTitle;

  /// No description provided for @accuracyEasyDesc.
  ///
  /// In ar, this message translates to:
  /// **'مناسب للأطفال والمبتدئين'**
  String get accuracyEasyDesc;

  /// No description provided for @accuracyMediumTitle.
  ///
  /// In ar, this message translates to:
  /// **'متوازن'**
  String get accuracyMediumTitle;

  /// No description provided for @accuracyMediumDesc.
  ///
  /// In ar, this message translates to:
  /// **'للممارسة اليومية'**
  String get accuracyMediumDesc;

  /// No description provided for @accuracyHardTitle.
  ///
  /// In ar, this message translates to:
  /// **'دقيق'**
  String get accuracyHardTitle;

  /// No description provided for @accuracyHardDesc.
  ///
  /// In ar, this message translates to:
  /// **'للمتقدمين'**
  String get accuracyHardDesc;

  /// No description provided for @accuracyRequiredPercent.
  ///
  /// In ar, this message translates to:
  /// **'{percent}% مطلوبة'**
  String accuracyRequiredPercent(int percent);

  /// No description provided for @parentGuardianMode.
  ///
  /// In ar, this message translates to:
  /// **'أنا ولي أمر'**
  String get parentGuardianMode;

  /// No description provided for @qcfPocTitle.
  ///
  /// In ar, this message translates to:
  /// **'تجربة عرض QCF'**
  String get qcfPocTitle;

  /// No description provided for @qcfPocIntro.
  ///
  /// In ar, this message translates to:
  /// **'شاشة مؤقتة لاختبار العرض البصري للقرآن داخل منطقة الحفظ.'**
  String get qcfPocIntro;

  /// No description provided for @qcfPocNoProduction.
  ///
  /// In ar, this message translates to:
  /// **'هذه الشاشة لا تغيّر منطق الحفظ أو حالة الحفظ أو التقدم أو القفل أو نقاط التحقق.'**
  String get qcfPocNoProduction;

  /// No description provided for @qcfPocVisualOnly.
  ///
  /// In ar, this message translates to:
  /// **'يُستخدم qcf_quran_plus هنا لعرض آيات القرآن بصرياً فقط.'**
  String get qcfPocVisualOnly;

  /// No description provided for @qcfPocSingleVerse.
  ///
  /// In ar, this message translates to:
  /// **'آية واحدة'**
  String get qcfPocSingleVerse;

  /// No description provided for @qcfPocMultipleVerses.
  ///
  /// In ar, this message translates to:
  /// **'عدة آيات'**
  String get qcfPocMultipleVerses;

  /// No description provided for @qcfPocLastVerse.
  ///
  /// In ar, this message translates to:
  /// **'آخر آية'**
  String get qcfPocLastVerse;

  /// No description provided for @qcfPocFullPage.
  ///
  /// In ar, this message translates to:
  /// **'صفحة مصحف كاملة'**
  String get qcfPocFullPage;

  /// No description provided for @qcfPocFindings.
  ///
  /// In ar, this message translates to:
  /// **'النتائج'**
  String get qcfPocFindings;

  /// No description provided for @qcfPocSupported.
  ///
  /// In ar, this message translates to:
  /// **'مدعوم'**
  String get qcfPocSupported;

  /// No description provided for @qcfPocLimited.
  ///
  /// In ar, this message translates to:
  /// **'محدود'**
  String get qcfPocLimited;

  /// No description provided for @qcfPocUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'غير مدعوم'**
  String get qcfPocUnsupported;

  /// No description provided for @qcfPocStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get qcfPocStatus;

  /// No description provided for @qcfPocAlBaqarah255.
  ///
  /// In ar, this message translates to:
  /// **'البقرة ٢٥٥'**
  String get qcfPocAlBaqarah255;

  /// No description provided for @qcfPocAlFatihah.
  ///
  /// In ar, this message translates to:
  /// **'الفاتحة ١-٧'**
  String get qcfPocAlFatihah;

  /// No description provided for @qcfPocAlIkhlas.
  ///
  /// In ar, this message translates to:
  /// **'الإخلاص ١-٤'**
  String get qcfPocAlIkhlas;

  /// No description provided for @qcfPocAshSharh8.
  ///
  /// In ar, this message translates to:
  /// **'الشرح ٨'**
  String get qcfPocAshSharh8;

  /// No description provided for @qcfPocFullPageSample.
  ///
  /// In ar, this message translates to:
  /// **'معاينة صفحة المصحف ١'**
  String get qcfPocFullPageSample;

  /// No description provided for @qcfPocVerseSupported.
  ///
  /// In ar, this message translates to:
  /// **'تظهر الآية بصرياً باستخدام أدوات QCF.'**
  String get qcfPocVerseSupported;

  /// No description provided for @qcfPocMultiVerseSupported.
  ///
  /// In ar, this message translates to:
  /// **'تظهر الآيات المجموعة بصرياً من السورة نفسها.'**
  String get qcfPocMultiVerseSupported;

  /// No description provided for @qcfPocFullPageSupported.
  ///
  /// In ar, this message translates to:
  /// **'عرض الصفحة الكاملة متاح داخل معاينة محددة.'**
  String get qcfPocFullPageSupported;

  /// No description provided for @qcfPocNoLimitations.
  ///
  /// In ar, this message translates to:
  /// **'لم تظهر قيود في هذه التجربة المعزولة.'**
  String get qcfPocNoLimitations;

  /// No description provided for @qcfPocLimitationInstruction.
  ///
  /// In ar, this message translates to:
  /// **'يجب مراجعة أي قيد يظهر هنا قبل تغيير شاشات الحفظ الفعلية.'**
  String get qcfPocLimitationInstruction;

  /// No description provided for @parentDashboardCardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تابع حفظ الطفل والمكافآت'**
  String get parentDashboardCardSubtitle;

  /// No description provided for @viewDashboard.
  ///
  /// In ar, this message translates to:
  /// **'عرض اللوحة'**
  String get viewDashboard;

  /// No description provided for @resumeWhereYouLeft.
  ///
  /// In ar, this message translates to:
  /// **'استكمال من حيث توقفت'**
  String get resumeWhereYouLeft;

  /// No description provided for @resumeAction.
  ///
  /// In ar, this message translates to:
  /// **'استكمال'**
  String get resumeAction;

  /// No description provided for @notNow.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get notNow;

  /// No description provided for @lastSavedReading.
  ///
  /// In ar, this message translates to:
  /// **'آخر قراءة محفوظة'**
  String get lastSavedReading;

  /// No description provided for @incompleteHifzSession.
  ///
  /// In ar, this message translates to:
  /// **'جلسة حفظ غير مكتملة'**
  String get incompleteHifzSession;

  /// No description provided for @dailyMemorizationPlan.
  ///
  /// In ar, this message translates to:
  /// **'خطة حفظ يومية'**
  String get dailyMemorizationPlan;

  /// No description provided for @incompleteKidsSession.
  ///
  /// In ar, this message translates to:
  /// **'جلسة طفل غير مكتملة'**
  String get incompleteKidsSession;

  /// No description provided for @previousHifzQuiz.
  ///
  /// In ar, this message translates to:
  /// **'اختبار حفظ سابق'**
  String get previousHifzQuiz;

  /// No description provided for @savedPreviousActivity.
  ///
  /// In ar, this message translates to:
  /// **'نشاط سابق محفوظ'**
  String get savedPreviousActivity;

  /// No description provided for @completeTodaysHifz.
  ///
  /// In ar, this message translates to:
  /// **'أكمل ورد الحفظ اليوم'**
  String get completeTodaysHifz;

  /// No description provided for @planReadySmallStep.
  ///
  /// In ar, this message translates to:
  /// **'خطتك جاهزة، خطوة صغيرة تكفي.'**
  String get planReadySmallStep;

  /// No description provided for @readTodaysPortion.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ ورد اليوم'**
  String get readTodaysPortion;

  /// No description provided for @onePageMakesProgress.
  ///
  /// In ar, this message translates to:
  /// **'صفحة واحدة تجعل التقدّم واضحاً.'**
  String get onePageMakesProgress;

  /// No description provided for @timeForDhikr.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت الذكر'**
  String get timeForDhikr;

  /// No description provided for @startShortAzkarNow.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بأذكار قصيرة الآن.'**
  String get startShortAzkarNow;

  /// No description provided for @followChildJourney.
  ///
  /// In ar, this message translates to:
  /// **'تابع رحلة الطفل'**
  String get followChildJourney;

  /// No description provided for @reviewProgressOrReward.
  ///
  /// In ar, this message translates to:
  /// **'راجع التقدم أو أضف مكافأة مشجعة.'**
  String get reviewProgressOrReward;

  /// No description provided for @startQuranStepNow.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ خطوة قرآنية الآن'**
  String get startQuranStepNow;

  /// No description provided for @chooseReadingOrMemorization.
  ///
  /// In ar, this message translates to:
  /// **'اختر قراءة أو حفظاً بسيطاً لهذا اليوم.'**
  String get chooseReadingOrMemorization;

  /// No description provided for @kidsFirstMissionToday.
  ///
  /// In ar, this message translates to:
  /// **'مهمتك الأولى اليوم'**
  String get kidsFirstMissionToday;

  /// No description provided for @kidsCompleteStageToday.
  ///
  /// In ar, this message translates to:
  /// **'أكمل المرحلة {stage} اليوم'**
  String kidsCompleteStageToday(int stage);

  /// No description provided for @kidsFirstMissionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بالاستماع والتكرار، وكل خطوة تقربك من نجمة جديدة.'**
  String get kidsFirstMissionSubtitle;

  /// No description provided for @kidsRemainingAyahs.
  ///
  /// In ar, this message translates to:
  /// **'تبقى {count} آيات في هذه المرحلة.'**
  String kidsRemainingAyahs(int count);

  /// No description provided for @notificationEverydayAt.
  ///
  /// In ar, this message translates to:
  /// **'كل يوم الساعة {time}'**
  String notificationEverydayAt(String time);
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
