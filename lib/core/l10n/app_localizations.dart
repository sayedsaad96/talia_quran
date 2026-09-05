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

  /// No description provided for @settingsPageSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اضبط تالية بما يناسب روتينك'**
  String get settingsPageSubtitle;

  /// No description provided for @settingsQuickPreferences.
  ///
  /// In ar, this message translates to:
  /// **'تفضيلات سريعة'**
  String get settingsQuickPreferences;

  /// No description provided for @settingsMoreSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات أخرى'**
  String get settingsMoreSettings;

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

  /// No description provided for @errorCacheMessage.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الوصول إلى البيانات المحفوظة. حاول مجدداً.'**
  String get errorCacheMessage;

  /// No description provided for @errorNetworkMessage.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق من اتصالك بالإنترنت وحاول مجدداً.'**
  String get errorNetworkMessage;

  /// No description provided for @errorNotFoundMessage.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على المحتوى المطلوب.'**
  String get errorNotFoundMessage;

  /// No description provided for @errorParseMessage.
  ///
  /// In ar, this message translates to:
  /// **'حدثت مشكلة أثناء قراءة المحتوى. حاول مجدداً.'**
  String get errorParseMessage;

  /// No description provided for @errorUnknownMessage.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. حاول مجدداً.'**
  String get errorUnknownMessage;

  /// No description provided for @celebrationAyah.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت! +{xp} XP ⭐'**
  String celebrationAyah(int xp);

  /// No description provided for @celebrationPage.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت الصفحة! +{xp} XP 🎯'**
  String celebrationPage(int xp);

  /// No description provided for @celebrationJuzDone.
  ///
  /// In ar, this message translates to:
  /// **'أتممت الجزء كاملاً بإذن الله'**
  String get celebrationJuzDone;

  /// No description provided for @tutorialQuickStartTitle.
  ///
  /// In ar, this message translates to:
  /// **'خريطة تالية السريعة'**
  String get tutorialQuickStartTitle;

  /// No description provided for @tutorialQuickStartSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أهم خمسة أقسام لاستخدام التطبيق يومياً'**
  String get tutorialQuickStartSubtitle;

  /// No description provided for @tutorialQuickStartHint.
  ///
  /// In ar, this message translates to:
  /// **'استخدم البحث أو التصفية للوصول إلى أي شرح تفصيلي.'**
  String get tutorialQuickStartHint;

  /// No description provided for @tutorialShortcutHomeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get tutorialShortcutHomeLabel;

  /// No description provided for @tutorialShortcutHomeDesc.
  ///
  /// In ar, this message translates to:
  /// **'الورد والتقدم اليومي'**
  String get tutorialShortcutHomeDesc;

  /// No description provided for @tutorialShortcutQuranLabel.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get tutorialShortcutQuranLabel;

  /// No description provided for @tutorialShortcutQuranDesc.
  ///
  /// In ar, this message translates to:
  /// **'المصحف والقراءة'**
  String get tutorialShortcutQuranDesc;

  /// No description provided for @tutorialShortcutHifzLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get tutorialShortcutHifzLabel;

  /// No description provided for @tutorialShortcutHifzDesc.
  ///
  /// In ar, this message translates to:
  /// **'الخطة والجلسات'**
  String get tutorialShortcutHifzDesc;

  /// No description provided for @tutorialShortcutAzkarLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get tutorialShortcutAzkarLabel;

  /// No description provided for @tutorialShortcutAzkarDesc.
  ///
  /// In ar, this message translates to:
  /// **'الورد والعداد'**
  String get tutorialShortcutAzkarDesc;

  /// No description provided for @tutorialShortcutProgressLabel.
  ///
  /// In ar, this message translates to:
  /// **'التقدم'**
  String get tutorialShortcutProgressLabel;

  /// No description provided for @tutorialShortcutProgressDesc.
  ///
  /// In ar, this message translates to:
  /// **'الشهادات والإنجازات'**
  String get tutorialShortcutProgressDesc;

  /// No description provided for @splashTagline.
  ///
  /// In ar, this message translates to:
  /// **'رفيقك في رحاب القرآن'**
  String get splashTagline;

  /// No description provided for @splashInitError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إكمال التحميل، يرجى المحاولة مرة أخرى'**
  String get splashInitError;

  /// No description provided for @retryLabel.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retryLabel;

  /// No description provided for @showPassword.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get hidePassword;

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

  /// No description provided for @playSurah.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل السورة'**
  String get playSurah;

  /// No description provided for @playPage.
  ///
  /// In ar, this message translates to:
  /// **'تلاوة الصفحة'**
  String get playPage;

  /// No description provided for @listenToSurah.
  ///
  /// In ar, this message translates to:
  /// **'استماع للسورة'**
  String get listenToSurah;

  /// No description provided for @nowPlaying.
  ///
  /// In ar, this message translates to:
  /// **'يتلو الآن'**
  String get nowPlaying;

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

  /// No description provided for @clearSearch.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get clearSearch;

  /// No description provided for @selectReciter.
  ///
  /// In ar, this message translates to:
  /// **'اختيار القارئ'**
  String get selectReciter;

  /// No description provided for @enterFocusMode.
  ///
  /// In ar, this message translates to:
  /// **'الدخول إلى وضع التركيز'**
  String get enterFocusMode;

  /// No description provided for @exitFocusMode.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من وضع التركيز'**
  String get exitFocusMode;

  /// No description provided for @closeReader.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق القارئ'**
  String get closeReader;

  /// No description provided for @hizbNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحزب {number}'**
  String hizbNumberLabel(Object number);

  /// No description provided for @azkarCountOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'من {total}'**
  String azkarCountOfTotal(int total);

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

  /// No description provided for @shareMemorizationMilestone.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة إنجاز الحفظ'**
  String get shareMemorizationMilestone;

  /// No description provided for @shareConsistencyStreak.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الاستمرارية'**
  String get shareConsistencyStreak;

  /// No description provided for @shareApp.
  ///
  /// In ar, this message translates to:
  /// **'شارك تطبيق تالية'**
  String get shareApp;

  /// No description provided for @shareAppText.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف تطبيق تالية للقرآن الكريم 📖✨\nرفيقك الذكي في رحلة الحفظ والتلاوة\nحمّله الآن: https://taliaapp.com'**
  String get shareAppText;

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

  /// No description provided for @speechUnavailableError.
  ///
  /// In ar, this message translates to:
  /// **'التسميع الصوتي غير متاح على هذا الجهاز حالياً.'**
  String get speechUnavailableError;

  /// No description provided for @openSettingsAction.
  ///
  /// In ar, this message translates to:
  /// **'فتح الإعدادات'**
  String get openSettingsAction;

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

  /// No description provided for @authPasswordSameAsOld.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة مطابقة للقديمة. يرجى اختيار كلمة مرور مختلفة.'**
  String get authPasswordSameAsOld;

  /// No description provided for @authSessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'رابط إعادة التعيين غير صالح أو انتهت صلاحيته. اطلب رسالة إعادة تعيين جديدة.'**
  String get authSessionExpired;

  /// No description provided for @profileSavedToCloud.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول إلى حسابك'**
  String get profileSavedToCloud;

  /// No description provided for @guestModeWarning.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لإدارة حسابك وخيارات الاستعادة وميزات العائلة.'**
  String get guestModeWarning;

  /// No description provided for @signOutWarning.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تسجيل الخروج؟ سيبقى تقدمك المحلي متاحًا على هذا الجهاز.'**
  String get signOutWarning;

  /// No description provided for @signOutPendingDataTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقدم غير مزامن'**
  String get signOutPendingDataTitle;

  /// No description provided for @signOutPendingDataWarning.
  ///
  /// In ar, this message translates to:
  /// **'بعض تقدم الحفظ لم يصل إلى السحابة بعد. تسجيل الخروج الآن سيحذفه من هذا الجهاز.'**
  String get signOutPendingDataWarning;

  /// No description provided for @signOutAnyway.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج على أي حال'**
  String get signOutAnyway;

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
  /// **'سجّل دخولك لإدارة حسابك وخيارات الاستعادة وميزات العائلة'**
  String get syncProgressDesc;

  /// No description provided for @restoringProgress.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ استعادة بياناتك…'**
  String get restoringProgress;

  /// No description provided for @retrySyncAfterError.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retrySyncAfterError;

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
  /// **'إدارة الحساب'**
  String get backupProgressTitle;

  /// No description provided for @backupProgressDesc.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك من الإعدادات لإدارة حسابك وميزات العائلة'**
  String get backupProgressDesc;

  /// No description provided for @azkarSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اذكر الله كثيراً'**
  String get azkarSubtitle;

  /// No description provided for @azkarContentUnderReview.
  ///
  /// In ar, this message translates to:
  /// **'محتوى الأذكار قيد المراجعة والاعتماد، وسيظهر هنا فور اعتماده.'**
  String get azkarContentUnderReview;

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

  /// No description provided for @startedAyahsLabel.
  ///
  /// In ar, this message translates to:
  /// **'آيات بدأ حفظها'**
  String get startedAyahsLabel;

  /// No description provided for @reviewedAyahsTotalLabel.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المراجعات'**
  String get reviewedAyahsTotalLabel;

  /// No description provided for @overdueReviewsLabel.
  ///
  /// In ar, this message translates to:
  /// **'مراجعات متأخرة'**
  String get overdueReviewsLabel;

  /// No description provided for @retentionRateLabel.
  ///
  /// In ar, this message translates to:
  /// **'معدل الاحتفاظ'**
  String get retentionRateLabel;

  /// No description provided for @lastReviewLabel.
  ///
  /// In ar, this message translates to:
  /// **'آخر مراجعة'**
  String get lastReviewLabel;

  /// No description provided for @lastMemorizedLabel.
  ///
  /// In ar, this message translates to:
  /// **'آخر آية محفوظة'**
  String get lastMemorizedLabel;

  /// No description provided for @homeEngagementTitle.
  ///
  /// In ar, this message translates to:
  /// **'نشاطك'**
  String get homeEngagementTitle;

  /// No description provided for @homeWeeklyActivityLabel.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get homeWeeklyActivityLabel;

  /// No description provided for @homeDueTodayLabel.
  ///
  /// In ar, this message translates to:
  /// **'مستحق اليوم'**
  String get homeDueTodayLabel;

  /// No description provided for @homeXpLevelLabel.
  ///
  /// In ar, this message translates to:
  /// **'المستوى'**
  String get homeXpLevelLabel;

  /// No description provided for @homeActivityHeatmapTitle.
  ///
  /// In ar, this message translates to:
  /// **'خريطة النشاط'**
  String get homeActivityHeatmapTitle;

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

  /// No description provided for @certificateNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على الشهادة'**
  String get certificateNotFound;

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
  /// **'تمت اعادة ضبط مسار الحفظ'**
  String get memorizationPathReset;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionQuranMemorization.
  ///
  /// In ar, this message translates to:
  /// **'القرآن والحفظ'**
  String get settingsSectionQuranMemorization;

  /// No description provided for @settingsSectionKidsGuardian.
  ///
  /// In ar, this message translates to:
  /// **'الأطفال وولي الأمر'**
  String get settingsSectionKidsGuardian;

  /// No description provided for @settingsSectionProgressAchievements.
  ///
  /// In ar, this message translates to:
  /// **'التقدم والإنجازات'**
  String get settingsSectionProgressAchievements;

  /// No description provided for @settingsSectionHelpTutorial.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة والدليل'**
  String get settingsSectionHelpTutorial;

  /// No description provided for @settingsSectionPrivacySecurity.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية والأمان'**
  String get settingsSectionPrivacySecurity;

  /// No description provided for @settingsSectionAboutTalia.
  ///
  /// In ar, this message translates to:
  /// **'حول تالية'**
  String get settingsSectionAboutTalia;

  /// No description provided for @settingsGuestStatusTitle.
  ///
  /// In ar, this message translates to:
  /// **'تستخدم تالية كضيف'**
  String get settingsGuestStatusTitle;

  /// No description provided for @settingsGuestStatusSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يبقى تقدمك المحلي على هذا الجهاز. أنشئ حساباً لإدارة الحساب وميزات العائلة.'**
  String get settingsGuestStatusSubtitle;

  /// No description provided for @settingsSignInCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول / إنشاء حساب'**
  String get settingsSignInCreateAccount;

  /// No description provided for @settingsSignedInStatus.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول إلى حسابك'**
  String get settingsSignedInStatus;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف نحفظ بياناتك وخصوصيتك'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsMemorizationPathNotSelected.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم اختيار مسار'**
  String get settingsMemorizationPathNotSelected;

  /// No description provided for @settingsMemorizationPathNotSelectedDesc.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسار الكبار أو الأطفال عند بدء الحفظ بلس.'**
  String get settingsMemorizationPathNotSelectedDesc;

  /// No description provided for @settingsResetPathKeeps.
  ///
  /// In ar, this message translates to:
  /// **'سيبقى: الإنجازات والسجل والشهادات'**
  String get settingsResetPathKeeps;

  /// No description provided for @settingsResetPathChanges.
  ///
  /// In ar, this message translates to:
  /// **'سيتغير: المسار المختار والخطة الحالية'**
  String get settingsResetPathChanges;

  /// No description provided for @settingsResetPathInstruction.
  ///
  /// In ar, this message translates to:
  /// **'اكتب \"اعادة ضبط\" لتأكيد العملية.'**
  String get settingsResetPathInstruction;

  /// No description provided for @settingsResetPathConfirmPhrase.
  ///
  /// In ar, this message translates to:
  /// **'اعادة ضبط'**
  String get settingsResetPathConfirmPhrase;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يحذف الحساب السحابي فقط'**
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @settingsDeleteAccountWarning.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف حساب Supabase المرتبط بـ {email} وبياناته السحابية.\n\nلن يتم حذف تقدم القرآن المحلي، أو الحفظ، أو مسار الأطفال، أو الحفظ الذكي من هذا الجهاز.\n\nهل تريد المتابعة؟'**
  String settingsDeleteAccountWarning(Object email);

  /// No description provided for @settingsAccountDeletedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الحساب السحابي. بقي تقدمك المحلي محفوظاً على هذا الجهاز.'**
  String get settingsAccountDeletedMessage;

  /// No description provided for @settingsVersion.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String settingsVersion(Object version);

  /// No description provided for @settingsBuild.
  ///
  /// In ar, this message translates to:
  /// **'رقم البناء {buildNumber}'**
  String settingsBuild(Object buildNumber);

  /// No description provided for @resetMemorizationPath.
  ///
  /// In ar, this message translates to:
  /// **'اعادة ضبط / تغيير المسار'**
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
  /// **'اعادة ضبط مسار الحفظ؟'**
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
  /// **'اعادة ضبط المسار'**
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

  /// No description provided for @guardianSignInRequired.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك للوصول إلى أدوات ولي الأمر. يبقى تقدمك المحلي على هذا الجهاز.'**
  String get guardianSignInRequired;

  /// No description provided for @guardianSignInAction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول أو إنشاء حساب'**
  String get guardianSignInAction;

  /// No description provided for @guardianGuestContinueKids.
  ///
  /// In ar, this message translates to:
  /// **'متابعة حفظ الأطفال'**
  String get guardianGuestContinueKids;

  /// No description provided for @guardianLinkingTemporarilyBlocked.
  ///
  /// In ar, this message translates to:
  /// **'الربط متوقف مؤقتاً'**
  String get guardianLinkingTemporarilyBlocked;

  /// No description provided for @guardianLinkingFailedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذر ربط ولي الأمر'**
  String get guardianLinkingFailedTitle;

  /// No description provided for @guardianLinkingTimeoutMessage.
  ///
  /// In ar, this message translates to:
  /// **'استغرق ربط ولي الأمر وقتاً طويلاً. تحقق من الاتصال وحاول مجدداً، أو تابع بدون ولي أمر الآن.'**
  String get guardianLinkingTimeoutMessage;

  /// No description provided for @splashSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ، احفظ، راجع، وانمُ مع القرآن.'**
  String get splashSubtitle;

  /// No description provided for @splashFeatureRead.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ'**
  String get splashFeatureRead;

  /// No description provided for @splashFeatureMemorize.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get splashFeatureMemorize;

  /// No description provided for @splashFeatureReview.
  ///
  /// In ar, this message translates to:
  /// **'راجع'**
  String get splashFeatureReview;

  /// No description provided for @splashFeatureGrow.
  ///
  /// In ar, this message translates to:
  /// **'انمُ'**
  String get splashFeatureGrow;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في تالية'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مساحة قرآنية هادئة ومتقنة تعينك على التلاوة والتدبر، والحفظ والمراجعة الذكية، وبناء ورد يومي مستدام.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingStartJourney.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ رحلتك'**
  String get onboardingStartJourney;

  /// No description provided for @onboardingPillarReadTitle.
  ///
  /// In ar, this message translates to:
  /// **'تلاوة ومصحف أصيل'**
  String get onboardingPillarReadTitle;

  /// No description provided for @onboardingPillarMemorizeTitle.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ومراجعة ذكية'**
  String get onboardingPillarMemorizeTitle;

  /// No description provided for @onboardingPillarHabitTitle.
  ///
  /// In ar, this message translates to:
  /// **'ورد واستمرارية'**
  String get onboardingPillarHabitTitle;

  /// No description provided for @onboardingChooseExpTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر التجربة المناسبة'**
  String get onboardingChooseExpTitle;

  /// No description provided for @onboardingChooseExpSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'خصص تجربة تالية لتلائم احتياجك. يمكنك تبديل المسار دائماً من الإعدادات.'**
  String get onboardingChooseExpSubtitle;

  /// No description provided for @onboardingAdultPathTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسار الكبار واليافعين'**
  String get onboardingAdultPathTitle;

  /// No description provided for @onboardingAdultPathSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مساحة قرآنية مركزة للقراءة والحفظ والمراجعة ومتابعة التقدم.'**
  String get onboardingAdultPathSubtitle;

  /// No description provided for @onboardingKidsPathTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسار البراعم والأطفال'**
  String get onboardingKidsPathTitle;

  /// No description provided for @onboardingKidsPathSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'رحلة تفاعلية ممتعة بالمهام المبسطة والتكرار الإيجابي والمكافآت.'**
  String get onboardingKidsPathSubtitle;

  /// No description provided for @onboardingKidsFeatureMissions.
  ///
  /// In ar, this message translates to:
  /// **'مهام قصيرة وميسرة'**
  String get onboardingKidsFeatureMissions;

  /// No description provided for @onboardingKidsFeatureAudio.
  ///
  /// In ar, this message translates to:
  /// **'استماع وتكرار تفاعلي'**
  String get onboardingKidsFeatureAudio;

  /// No description provided for @onboardingKidsFeatureStars.
  ///
  /// In ar, this message translates to:
  /// **'نجوم ومكافآت تشجيعية'**
  String get onboardingKidsFeatureStars;

  /// No description provided for @onboardingEnterAsGuest.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة كضيف'**
  String get onboardingEnterAsGuest;

  /// No description provided for @onboardingSignInAccount.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول / إنشاء حساب'**
  String get onboardingSignInAccount;

  /// No description provided for @onboardingAyahReference.
  ///
  /// In ar, this message translates to:
  /// **'سورة المزمّل ٤'**
  String get onboardingAyahReference;

  /// No description provided for @onboardingOfflineTrustLine.
  ///
  /// In ar, this message translates to:
  /// **'يعمل دون إنترنت · بياناتك محفوظة على جهازك'**
  String get onboardingOfflineTrustLine;

  /// No description provided for @onboardingErrorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إكمال الإعداد. تأكد من توفر مساحة على الجهاز ثم حاول مجدداً، أو تخطَّ الإعداد الآن.'**
  String get onboardingErrorGeneric;

  /// No description provided for @onboardingSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get onboardingSkip;

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

  /// No description provided for @kidsGamifiedWelcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بطل الحفظ!'**
  String get kidsGamifiedWelcome;

  /// No description provided for @kidsGamifiedLevelProgress.
  ///
  /// In ar, this message translates to:
  /// **'المستوى {level} — {progress}/100'**
  String kidsGamifiedLevelProgress(int level, int progress);

  /// No description provided for @kidsGamifiedStarsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} نجمة'**
  String kidsGamifiedStarsCount(int count);

  /// No description provided for @kidsGamifiedLastMission.
  ///
  /// In ar, this message translates to:
  /// **'آخر مهمة'**
  String get kidsGamifiedLastMission;

  /// No description provided for @kidsGamifiedContinueNow.
  ///
  /// In ar, this message translates to:
  /// **'استكمل الآن'**
  String get kidsGamifiedContinueNow;

  /// No description provided for @kidsGamifiedMushaf.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get kidsGamifiedMushaf;

  /// No description provided for @kidsGamifiedJourney.
  ///
  /// In ar, this message translates to:
  /// **'رحلتي'**
  String get kidsGamifiedJourney;

  /// No description provided for @kidsGamifiedMissions.
  ///
  /// In ar, this message translates to:
  /// **'المهام'**
  String get kidsGamifiedMissions;

  /// No description provided for @kidsGamifiedHouseTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيت الحفظ {number}'**
  String kidsGamifiedHouseTitle(int number);

  /// No description provided for @kidsGamifiedReviewHouseTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيت المراجعة {number}'**
  String kidsGamifiedReviewHouseTitle(int number);

  /// No description provided for @kidsGamifiedAyahRange.
  ///
  /// In ar, this message translates to:
  /// **'الآيات {startAyah}-{endAyah}'**
  String kidsGamifiedAyahRange(int startAyah, int endAyah);

  /// No description provided for @kidsGamifiedProgressCount.
  ///
  /// In ar, this message translates to:
  /// **'{completed}/{total}'**
  String kidsGamifiedProgressCount(int completed, int total);

  /// No description provided for @kidsGamifiedLockedStage.
  ///
  /// In ar, this message translates to:
  /// **'هذا البيت مغلق الآن'**
  String get kidsGamifiedLockedStage;

  /// No description provided for @kidsGamifiedCurrentStage.
  ///
  /// In ar, this message translates to:
  /// **'مهمتك الحالية'**
  String get kidsGamifiedCurrentStage;

  /// No description provided for @kidsGamifiedCompletedStage.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت، اكتمل البيت'**
  String get kidsGamifiedCompletedStage;

  /// No description provided for @kidsGamifiedNeedsReview.
  ///
  /// In ar, this message translates to:
  /// **'جاهز للمراجعة'**
  String get kidsGamifiedNeedsReview;

  /// No description provided for @kidsGamifiedListenStep.
  ///
  /// In ar, this message translates to:
  /// **'استمع'**
  String get kidsGamifiedListenStep;

  /// No description provided for @kidsGamifiedListenStepSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اسمع الآية بتأنٍ وتركيز'**
  String get kidsGamifiedListenStepSubtitle;

  /// No description provided for @kidsGamifiedRepeatStep.
  ///
  /// In ar, this message translates to:
  /// **'ردد'**
  String get kidsGamifiedRepeatStep;

  /// No description provided for @kidsGamifiedRepeatStepSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كرر خلف القارئ حتى تثبت الآية'**
  String get kidsGamifiedRepeatStepSubtitle;

  /// No description provided for @kidsGamifiedTestStep.
  ///
  /// In ar, this message translates to:
  /// **'اختبر نفسك'**
  String get kidsGamifiedTestStep;

  /// No description provided for @kidsGamifiedTestStepSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حاول التسميع بدون مساعدة'**
  String get kidsGamifiedTestStepSubtitle;

  /// No description provided for @kidsGamifiedStartMission.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ المهمة'**
  String get kidsGamifiedStartMission;

  /// No description provided for @kidsGamifiedListenAndRepeat.
  ///
  /// In ar, this message translates to:
  /// **'استمع وكرر'**
  String get kidsGamifiedListenAndRepeat;

  /// No description provided for @kidsGamifiedRecordYourVoice.
  ///
  /// In ar, this message translates to:
  /// **'سجل تلاوتك'**
  String get kidsGamifiedRecordYourVoice;

  /// No description provided for @kidsGamifiedRecordingInProgress.
  ///
  /// In ar, this message translates to:
  /// **'جاري التسجيل...'**
  String get kidsGamifiedRecordingInProgress;

  /// No description provided for @kidsGamifiedDoneRecording.
  ///
  /// In ar, this message translates to:
  /// **'انتهيت من التسجيل'**
  String get kidsGamifiedDoneRecording;

  /// No description provided for @kidsGamifiedAudioUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الصوت غير متاح الآن، حاول مرة أخرى بعد قليل.'**
  String get kidsGamifiedAudioUnavailable;

  /// No description provided for @kidsManualCompleteAction.
  ///
  /// In ar, this message translates to:
  /// **'أتممت الحفظ بنفسي'**
  String get kidsManualCompleteAction;

  /// No description provided for @kidsManualCompleteHint.
  ///
  /// In ar, this message translates to:
  /// **'لا يتوفر الصوت أو الميكروفون؟ يمكن لولي الأمر تأكيد إتمام الحفظ.'**
  String get kidsManualCompleteHint;

  /// No description provided for @kidsGamifiedListenFirst.
  ///
  /// In ar, this message translates to:
  /// **'استمع للآية {count} مرات قبل تسجيل تلاوتك.'**
  String kidsGamifiedListenFirst(int count);

  /// No description provided for @kidsGamifiedAudioLoading.
  ///
  /// In ar, this message translates to:
  /// **'جاري تجهيز التلاوة...'**
  String get kidsGamifiedAudioLoading;

  /// No description provided for @kidsGamifiedWellDone.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت!'**
  String get kidsGamifiedWellDone;

  /// No description provided for @kidsGamifiedEarnedStars.
  ///
  /// In ar, this message translates to:
  /// **'+{count} نجمة'**
  String kidsGamifiedEarnedStars(int count);

  /// No description provided for @kidsGamifiedEarnedGems.
  ///
  /// In ar, this message translates to:
  /// **'+{count} جوهرة'**
  String kidsGamifiedEarnedGems(int count);

  /// No description provided for @kidsGamifiedNextStage.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get kidsGamifiedNextStage;

  /// No description provided for @kidsGamifiedReturnToMap.
  ///
  /// In ar, this message translates to:
  /// **'العودة للخريطة'**
  String get kidsGamifiedReturnToMap;

  /// No description provided for @kidsGamifiedJourneyComplete.
  ///
  /// In ar, this message translates to:
  /// **'أتممت رحلة الحفظ الحالية، بارك الله فيك!'**
  String get kidsGamifiedJourneyComplete;

  /// No description provided for @kidsGamifiedFallbackMessage.
  ///
  /// In ar, this message translates to:
  /// **'سنعود للتجربة القديمة للحفاظ على تقدمك.'**
  String get kidsGamifiedFallbackMessage;

  /// No description provided for @privacyPolicy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacyPolicy;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'**
  String get passwordResetEmailSent;

  /// No description provided for @forgotPasswordEnterEmail.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني أولاً لإعادة تعيين كلمة المرور'**
  String get forgotPasswordEnterEmail;

  /// No description provided for @updatePasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كلمة مرور جديدة'**
  String get updatePasswordTitle;

  /// No description provided for @updatePasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة مرور قوية جديدة لحسابك.'**
  String get updatePasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور الجديدة'**
  String get confirmNewPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث كلمة المرور بنجاح. سجل الدخول مرة أخرى.'**
  String get passwordUpdated;

  /// No description provided for @updatePasswordButton.
  ///
  /// In ar, this message translates to:
  /// **'تحديث كلمة المرور'**
  String get updatePasswordButton;

  /// No description provided for @invalidPasswordRecoveryLink.
  ///
  /// In ar, this message translates to:
  /// **'رابط إعادة التعيين غير صالح أو انتهت صلاحيته. اطلب رسالة إعادة تعيين جديدة.'**
  String get invalidPasswordRecoveryLink;

  /// No description provided for @dailyPlanQuizAction.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة بالتسميع'**
  String get dailyPlanQuizAction;

  /// No description provided for @dailyPlanNewAyahs.
  ///
  /// In ar, this message translates to:
  /// **'آيات جديدة للحفظ'**
  String get dailyPlanNewAyahs;

  /// No description provided for @dailyPlanNearRevision.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة قريبة (آخر ٥ أيام)'**
  String get dailyPlanNearRevision;

  /// No description provided for @dailyPlanFarRevision.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة بعيدة'**
  String get dailyPlanFarRevision;

  /// No description provided for @dailyPlanRetentionReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة تثبيت'**
  String get dailyPlanRetentionReview;

  /// No description provided for @dailyPlanRetentionReviewHint.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة اختيارية لتثبيت الآيات التي حفظتها بالفعل.'**
  String get dailyPlanRetentionReviewHint;

  /// No description provided for @dailyPlanCompletedTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما شاء الله! أكملت خطة اليوم'**
  String get dailyPlanCompletedTitle;

  /// No description provided for @dailyPlanCompletedSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أتممت {count} عناصر بنجاح.\nثابر على هذا المستوى.'**
  String dailyPlanCompletedSubtitle(int count);

  /// No description provided for @dailyPlanNewAyahsShort.
  ///
  /// In ar, this message translates to:
  /// **'آيات جديدة'**
  String get dailyPlanNewAyahsShort;

  /// No description provided for @dailyPlanReviewShort.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة'**
  String get dailyPlanReviewShort;

  /// No description provided for @dailyPlanBlessingAction.
  ///
  /// In ar, this message translates to:
  /// **'بارك الله فيك ✨'**
  String get dailyPlanBlessingAction;

  /// No description provided for @dailyPlanRatingExcellent.
  ///
  /// In ar, this message translates to:
  /// **'✅ ممتاز! تم جدولة مراجعة الآية {ayahNumber} بعد فترة أطول'**
  String dailyPlanRatingExcellent(int ayahNumber);

  /// No description provided for @dailyPlanRatingAverage.
  ///
  /// In ar, this message translates to:
  /// **'⏰ متوسط، سيتم المراجعة خلال فترة معتدلة'**
  String get dailyPlanRatingAverage;

  /// No description provided for @dailyPlanRatingWeak.
  ///
  /// In ar, this message translates to:
  /// **'🔁 ضعيف، ستتم مراجعة الآية {ayahNumber} غداً'**
  String dailyPlanRatingWeak(int ayahNumber);

  /// No description provided for @performanceWeak.
  ///
  /// In ar, this message translates to:
  /// **'ضعيف'**
  String get performanceWeak;

  /// No description provided for @performanceAverage.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get performanceAverage;

  /// No description provided for @performanceExcellent.
  ///
  /// In ar, this message translates to:
  /// **'ممتاز'**
  String get performanceExcellent;

  /// No description provided for @dailyPlanListenBeforeRating.
  ///
  /// In ar, this message translates to:
  /// **'استمع للآية قبل التقييم'**
  String get dailyPlanListenBeforeRating;

  /// No description provided for @reviewQuizTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة بالتسميع'**
  String get reviewQuizTitle;

  /// No description provided for @memorizationSessionTitle.
  ///
  /// In ar, this message translates to:
  /// **'جلسة الحفظ'**
  String get memorizationSessionTitle;

  /// No description provided for @memorizationHubReviewSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة بالتسميع'**
  String get memorizationHubReviewSectionTitle;

  /// No description provided for @memorizationHubReviewSectionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'راجع ما حفظته عبر جلسة تسميع موجهة (تحويل الصوت إلى نص).'**
  String get memorizationHubReviewSectionSubtitle;

  /// No description provided for @memorizationHubReviewCardDescription.
  ///
  /// In ar, this message translates to:
  /// **'افتح جلسة حفظ للآيات التي حفظتها مسبقًا.'**
  String get memorizationHubReviewCardDescription;

  /// No description provided for @memorizationHubDailyPlanSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'وجهتك الأساسية للحفظ والمراجعة اليومية.'**
  String get memorizationHubDailyPlanSubtitle;

  /// No description provided for @memorizationHubContinuePlanDescription.
  ///
  /// In ar, this message translates to:
  /// **'افتح ورد الحفظ والمراجعة الحالي.'**
  String get memorizationHubContinuePlanDescription;

  /// No description provided for @memorizationHubViewPlanTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل خطة اليوم'**
  String get memorizationHubViewPlanTitle;

  /// No description provided for @memorizationHubPracticeSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'التدريب'**
  String get memorizationHubPracticeSectionTitle;

  /// No description provided for @memorizationHubPracticeSectionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر سورة أو تدرب بالتسميع الصوتي.'**
  String get memorizationHubPracticeSectionSubtitle;

  /// No description provided for @memorizationHubPracticeBySurahTitle.
  ///
  /// In ar, this message translates to:
  /// **'تدرّب بالسورة'**
  String get memorizationHubPracticeBySurahTitle;

  /// No description provided for @memorizationHubPracticeBySurahDescription.
  ///
  /// In ar, this message translates to:
  /// **'تسميع صوتي واضح: اختر سورة وابدأ جلسة الحفظ.'**
  String get memorizationHubPracticeBySurahDescription;

  /// No description provided for @memorizationHubSettingsSectionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اضبط خطة الحفظ بدون تغيير المسار.'**
  String get memorizationHubSettingsSectionSubtitle;

  /// No description provided for @memorizationHubPlanSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الخطة'**
  String get memorizationHubPlanSettingsTitle;

  /// No description provided for @memorizationHubPlanSettingsDescription.
  ///
  /// In ar, this message translates to:
  /// **'عدّل الخطة اليومية أو إعدادات مسار الحفظ.'**
  String get memorizationHubPlanSettingsDescription;

  /// No description provided for @memorizationHubKidsMissionSectionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ من المهمة النشطة للطفل.'**
  String get memorizationHubKidsMissionSectionSubtitle;

  /// No description provided for @memorizationHubKidsMissionCardDescription.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ مهمة الحفظ التالية في رحلة الأطفال.'**
  String get memorizationHubKidsMissionCardDescription;

  /// No description provided for @memorizationHubKidsJourneyTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرحلة'**
  String get memorizationHubKidsJourneyTitle;

  /// No description provided for @memorizationHubKidsJourneySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'شاهد مراحل الطفل الحالية والقادمة.'**
  String get memorizationHubKidsJourneySubtitle;

  /// No description provided for @memorizationHubKidsJourneyDescription.
  ///
  /// In ar, this message translates to:
  /// **'شاهد المراحل الحالية والقادمة.'**
  String get memorizationHubKidsJourneyDescription;

  /// No description provided for @memorizationHubKidsRewardsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المكافآت / التقدم'**
  String get memorizationHubKidsRewardsTitle;

  /// No description provided for @memorizationHubKidsRewardsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'راجع نجوم الطفل ونقاطه من شاشة التقدم.'**
  String get memorizationHubKidsRewardsSubtitle;

  /// No description provided for @memorizationHubKidsRewardsDescription.
  ///
  /// In ar, this message translates to:
  /// **'راجع النقاط والنجوم من شاشة التقدم.'**
  String get memorizationHubKidsRewardsDescription;

  /// No description provided for @memorizationHubHeaderSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مكان واحد لكل مسارات الحفظ'**
  String get memorizationHubHeaderSubtitle;

  /// No description provided for @backAction.
  ///
  /// In ar, this message translates to:
  /// **'العودة'**
  String get backAction;

  /// No description provided for @hifzKidsRedirectedFromAdult.
  ///
  /// In ar, this message translates to:
  /// **'هذا المسار مخصص للبالغين. سيتم توجيهك لمسار الأطفال.'**
  String get hifzKidsRedirectedFromAdult;

  /// No description provided for @parentDashboardLastSession.
  ///
  /// In ar, this message translates to:
  /// **'آخر جلسة'**
  String get parentDashboardLastSession;

  /// No description provided for @parentDashboardNoSessionsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد جلسات مسجلة بعد.'**
  String get parentDashboardNoSessionsYet;

  /// No description provided for @parentDashboardSessionSummary.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surahId} • آية {ayahNumber}\n{repeats} تكرارات • {points} نقطة'**
  String parentDashboardSessionSummary(
    int surahId,
    int ayahNumber,
    int repeats,
    int points,
  );

  /// No description provided for @parentDashboardDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get parentDashboardDone;

  /// No description provided for @parentDashboardPinMismatch.
  ///
  /// In ar, this message translates to:
  /// **'رمزا PIN غير متطابقين'**
  String get parentDashboardPinMismatch;

  /// No description provided for @parentDashboardPinHelp.
  ///
  /// In ar, this message translates to:
  /// **'هذا الرمز يحمي لوحة ولي الأمر على هذا الجهاز'**
  String get parentDashboardPinHelp;

  /// No description provided for @parentDashboardPinConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد PIN'**
  String get parentDashboardPinConfirm;

  /// No description provided for @parentDashboardCreatePinTitle.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ رمز ولي الأمر'**
  String get parentDashboardCreatePinTitle;

  /// No description provided for @parentDashboardSavePinButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الرمز'**
  String get parentDashboardSavePinButton;

  /// No description provided for @parentDashboardEnterPinTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز ولي الأمر'**
  String get parentDashboardEnterPinTitle;

  /// No description provided for @parentDashboardEnterButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get parentDashboardEnterButton;

  /// No description provided for @parentDashboardEnterLinkingCode.
  ///
  /// In ar, this message translates to:
  /// **'إدخال رمز الربط'**
  String get parentDashboardEnterLinkingCode;

  /// No description provided for @parentDashboardResetPin.
  ///
  /// In ar, this message translates to:
  /// **'اعادة ضبط على هذا الجهاز — سيطلب إنشاء رمز جديد'**
  String get parentDashboardResetPin;

  /// No description provided for @parentDashboardTodaySummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص اليوم'**
  String get parentDashboardTodaySummary;

  /// No description provided for @parentDashboardTodayEmpty.
  ///
  /// In ar, this message translates to:
  /// **'اليوم: لا توجد جلسات بعد. شجعه على جلسة قصيرة.'**
  String get parentDashboardTodayEmpty;

  /// No description provided for @parentDashboardTodayCompleted.
  ///
  /// In ar, this message translates to:
  /// **'اليوم: أكمل الطفل {count} جلسة. شجعه على المراجعة القادمة.'**
  String parentDashboardTodayCompleted(int count);

  /// No description provided for @parentDashboardTodaySessions.
  ///
  /// In ar, this message translates to:
  /// **'جلسات اليوم'**
  String get parentDashboardTodaySessions;

  /// No description provided for @parentDashboardTodayPoints.
  ///
  /// In ar, this message translates to:
  /// **'نقاط اليوم'**
  String get parentDashboardTodayPoints;

  /// No description provided for @parentDashboardAddReward.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مكافأة'**
  String get parentDashboardAddReward;

  /// No description provided for @parentDashboardShowLastSession.
  ///
  /// In ar, this message translates to:
  /// **'عرض آخر جلسة'**
  String get parentDashboardShowLastSession;

  /// No description provided for @parentDashboardChildSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الطفل'**
  String get parentDashboardChildSummary;

  /// No description provided for @parentDashboardPoints.
  ///
  /// In ar, this message translates to:
  /// **'نقاط'**
  String get parentDashboardPoints;

  /// No description provided for @parentDashboardStars.
  ///
  /// In ar, this message translates to:
  /// **'نجوم'**
  String get parentDashboardStars;

  /// No description provided for @parentDashboardWeekSessions.
  ///
  /// In ar, this message translates to:
  /// **'جلسات الأسبوع'**
  String get parentDashboardWeekSessions;

  /// No description provided for @parentDashboardChildReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الطفل'**
  String get parentDashboardChildReminder;

  /// No description provided for @parentDashboardDailyReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير يومي الساعة 6:30 مساءً'**
  String get parentDashboardDailyReminder;

  /// No description provided for @parentDashboardReminderSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يمكن تغيير الوقت لاحقًا من إعدادات ولي الأمر'**
  String get parentDashboardReminderSubtitle;

  /// No description provided for @parentDashboardRemoteFollowup.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة عن بعد'**
  String get parentDashboardRemoteFollowup;

  /// No description provided for @parentDashboardScanQr.
  ///
  /// In ar, this message translates to:
  /// **'مسح QR'**
  String get parentDashboardScanQr;

  /// No description provided for @parentDashboardManualEntry.
  ///
  /// In ar, this message translates to:
  /// **'إدخال يدوي'**
  String get parentDashboardManualEntry;

  /// No description provided for @parentDashboardNoRemoteChild.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد طفل مرتبط عن بعد حتى الآن.'**
  String get parentDashboardNoRemoteChild;

  /// No description provided for @parentDashboardRemoteChildSummary.
  ///
  /// In ar, this message translates to:
  /// **'{ayahs} آية • {points} نقطة'**
  String parentDashboardRemoteChildSummary(int ayahs, int points);

  /// No description provided for @parentDashboardMemorizedSummary.
  ///
  /// In ar, this message translates to:
  /// **'{memorized}/{total} آية محفوظة • {percent}%'**
  String parentDashboardMemorizedSummary(int memorized, int total, int percent);

  /// No description provided for @parentDashboardReviewsSummary.
  ///
  /// In ar, this message translates to:
  /// **'{completed} مراجعة مكتملة • {overdue} متأخرة'**
  String parentDashboardReviewsSummary(int completed, int overdue);

  /// No description provided for @parentDashboardStreakSummary.
  ///
  /// In ar, this message translates to:
  /// **'التتابع: {days} يوم'**
  String parentDashboardStreakSummary(int days);

  /// No description provided for @parentDashboardCertificatesSummary.
  ///
  /// In ar, this message translates to:
  /// **'{count} شهادة تم الحصول عليها'**
  String parentDashboardCertificatesSummary(int count);

  /// No description provided for @parentDashboardRemoveChild.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الطفل'**
  String get parentDashboardRemoveChild;

  /// No description provided for @parentDashboardRemoveChildConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الطفل؟'**
  String get parentDashboardRemoveChildConfirmTitle;

  /// No description provided for @parentDashboardRemoveChildConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'سيؤدي هذا إلى فصل {name} عن حسابك. يمكنك الربط مرة أخرى لاحقًا برمز جديد.'**
  String parentDashboardRemoveChildConfirmBody(String name);

  /// No description provided for @parentDashboardReminders.
  ///
  /// In ar, this message translates to:
  /// **'التذكيرات'**
  String get parentDashboardReminders;

  /// No description provided for @parentDashboardNotSet.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get parentDashboardNotSet;

  /// No description provided for @parentDashboardEditChild.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات الطفل'**
  String get parentDashboardEditChild;

  /// No description provided for @parentDashboardChildLinked.
  ///
  /// In ar, this message translates to:
  /// **'تم ربط الطفل بنجاح'**
  String get parentDashboardChildLinked;

  /// No description provided for @parentDashboardRewardAdded.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة المكافأة'**
  String get parentDashboardRewardAdded;

  /// No description provided for @parentDashboardRemoteRewardAdded.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال المكافأة للطفل'**
  String get parentDashboardRemoteRewardAdded;

  /// No description provided for @parentDashboardReminderSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث التذكير'**
  String get parentDashboardReminderSaved;

  /// No description provided for @parentDashboardChildRemoved.
  ///
  /// In ar, this message translates to:
  /// **'تمت إزالة الطفل'**
  String get parentDashboardChildRemoved;

  /// No description provided for @parentDashboardRewardsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مكافآت ولي الأمر'**
  String get parentDashboardRewardsTitle;

  /// No description provided for @parentDashboardRewardHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: وقت لعب إضافي'**
  String get parentDashboardRewardHint;

  /// No description provided for @parentDashboardRewardEmpty.
  ///
  /// In ar, this message translates to:
  /// **'أضف مكافآت تظهر للطفل عند تحقيق هدفه الأسبوعي.'**
  String get parentDashboardRewardEmpty;

  /// No description provided for @parentDashboardRewardLocked.
  ///
  /// In ar, this message translates to:
  /// **'مقفلة'**
  String get parentDashboardRewardLocked;

  /// No description provided for @parentDashboardRewardUnlocked.
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة'**
  String get parentDashboardRewardUnlocked;

  /// No description provided for @parentDashboardRewardClaimed.
  ///
  /// In ar, this message translates to:
  /// **'تم استلامها'**
  String get parentDashboardRewardClaimed;

  /// No description provided for @parentDashboardRecentSessions.
  ///
  /// In ar, this message translates to:
  /// **'آخر الجلسات'**
  String get parentDashboardRecentSessions;

  /// No description provided for @parentDashboardNoKidsSessions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد جلسات أطفال بعد.'**
  String get parentDashboardNoKidsSessions;

  /// No description provided for @parentDashboardLogTitle.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surahId} • آية {ayahNumber}'**
  String parentDashboardLogTitle(int surahId, int ayahNumber);

  /// No description provided for @parentDashboardLogSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{repeats} تكرارات • {points} نقطة'**
  String parentDashboardLogSubtitle(int repeats, int points);

  /// No description provided for @dailyPlanSettingsTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات مسار الحفظ الذكي'**
  String get dailyPlanSettingsTooltip;

  /// No description provided for @dailyPlanRefreshTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الخطة'**
  String get dailyPlanRefreshTooltip;

  /// No description provided for @dailyPlanHeaderTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطتك اليومية'**
  String get dailyPlanHeaderTitle;

  /// No description provided for @dailyPlanHeaderSummary.
  ///
  /// In ar, this message translates to:
  /// **'{total} عنصر • {completed} مكتمل'**
  String dailyPlanHeaderSummary(int total, int completed);

  /// No description provided for @dailyPlanProgressCount.
  ///
  /// In ar, this message translates to:
  /// **'{completed} من {total}'**
  String dailyPlanProgressCount(int completed, int total);

  /// No description provided for @dailyPlanAllDoneShort.
  ///
  /// In ar, this message translates to:
  /// **'✅ أحسنت! أكملت خطتك اليوم'**
  String get dailyPlanAllDoneShort;

  /// No description provided for @dailyPlanRemainingItems.
  ///
  /// In ar, this message translates to:
  /// **'تبقّى {count} عناصر'**
  String dailyPlanRemainingItems(int count);

  /// No description provided for @dailyPlanAyahTitle.
  ///
  /// In ar, this message translates to:
  /// **'آية {ayahNumber}'**
  String dailyPlanAyahTitle(int ayahNumber);

  /// No description provided for @dailyPlanRecordStats.
  ///
  /// In ar, this message translates to:
  /// **'قوة: {strength} • مراجعات: {reviews}'**
  String dailyPlanRecordStats(int strength, int reviews);

  /// No description provided for @dailyPlanNewLabel.
  ///
  /// In ar, this message translates to:
  /// **'جديدة'**
  String get dailyPlanNewLabel;

  /// No description provided for @dailyPlanEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت! لا توجد مراجعات مطلوبة اليوم'**
  String get dailyPlanEmptyTitle;

  /// No description provided for @dailyPlanEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تفقّد غداً لمتابعة جدولك'**
  String get dailyPlanEmptySubtitle;

  /// No description provided for @customPlanDeleteConfirmPhrase.
  ///
  /// In ar, this message translates to:
  /// **'حذف الخطة'**
  String get customPlanDeleteConfirmPhrase;

  /// No description provided for @customPlanDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد حذف الخطة'**
  String get customPlanDeleteTitle;

  /// No description provided for @customPlanDeleteKeeps.
  ///
  /// In ar, this message translates to:
  /// **'سيبقى: الإنجازات، السجل، الشهادات'**
  String get customPlanDeleteKeeps;

  /// No description provided for @customPlanDeleteRemoves.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف: الخطة الحالية فقط'**
  String get customPlanDeleteRemoves;

  /// No description provided for @customPlanDeleteInstruction.
  ///
  /// In ar, this message translates to:
  /// **'اكتب \"حذف الخطة\" لتأكيد العملية.'**
  String get customPlanDeleteInstruction;

  /// No description provided for @customPlanDeleteAction.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد حذف الخطة'**
  String get customPlanDeleteAction;

  /// No description provided for @customPlanSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الخطة بنجاح ✅'**
  String get customPlanSaved;

  /// No description provided for @customPlanTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطتك المخصصة'**
  String get customPlanTitle;

  /// No description provided for @customPlanSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'صمّم نظام حفظ يناسبك'**
  String get customPlanSubtitle;

  /// No description provided for @customPlanName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الخطة'**
  String get customPlanName;

  /// No description provided for @customPlanNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: خطتي لحفظ جزء عمّ'**
  String get customPlanNameHint;

  /// No description provided for @customPlanNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال اسم للخطة'**
  String get customPlanNameRequired;

  /// No description provided for @customPlanTargetUserTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخطة لمن؟'**
  String get customPlanTargetUserTitle;

  /// No description provided for @customPlanChildFeaturesNote.
  ///
  /// In ar, this message translates to:
  /// **'سيتم تفعيل ميزات ولي الأمر والمتابعة تلقائياً.'**
  String get customPlanChildFeaturesNote;

  /// No description provided for @customPlanSurahRange.
  ///
  /// In ar, this message translates to:
  /// **'نطاق السور'**
  String get customPlanSurahRange;

  /// No description provided for @customPlanDailyLoad.
  ///
  /// In ar, this message translates to:
  /// **'الحِمل اليومي'**
  String get customPlanDailyLoad;

  /// No description provided for @customPlanNewAyahsPerDay.
  ///
  /// In ar, this message translates to:
  /// **'آيات جديدة يومياً'**
  String get customPlanNewAyahsPerDay;

  /// No description provided for @customPlanAyahUnit.
  ///
  /// In ar, this message translates to:
  /// **'آية'**
  String get customPlanAyahUnit;

  /// No description provided for @customPlanSchedule.
  ///
  /// In ar, this message translates to:
  /// **'الجدول الزمني'**
  String get customPlanSchedule;

  /// No description provided for @customPlanDaysPerWeek.
  ///
  /// In ar, this message translates to:
  /// **'أيام الحفظ في الأسبوع'**
  String get customPlanDaysPerWeek;

  /// No description provided for @customPlanDayUnit.
  ///
  /// In ar, this message translates to:
  /// **'يوم'**
  String get customPlanDayUnit;

  /// No description provided for @customPlanSessionDuration.
  ///
  /// In ar, this message translates to:
  /// **'مدة الجلسة'**
  String get customPlanSessionDuration;

  /// No description provided for @customPlanMinuteUnit.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة'**
  String get customPlanMinuteUnit;

  /// No description provided for @customPlanDifficulty.
  ///
  /// In ar, this message translates to:
  /// **'مستوى الصعوبة'**
  String get customPlanDifficulty;

  /// No description provided for @customPlanAdvanced.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص متقدم'**
  String get customPlanAdvanced;

  /// No description provided for @customPlanAdvancedSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات المراجعة القريبة والبعيدة'**
  String get customPlanAdvancedSubtitle;

  /// No description provided for @customPlanSaveAndStart.
  ///
  /// In ar, this message translates to:
  /// **'حفظ وبدء الخطة'**
  String get customPlanSaveAndStart;

  /// No description provided for @customPlanDeleteCurrent.
  ///
  /// In ar, this message translates to:
  /// **'حذف الخطة الحالية'**
  String get customPlanDeleteCurrent;

  /// No description provided for @customPlanFromSurah.
  ///
  /// In ar, this message translates to:
  /// **'من سورة'**
  String get customPlanFromSurah;

  /// No description provided for @customPlanToSurah.
  ///
  /// In ar, this message translates to:
  /// **'إلى سورة'**
  String get customPlanToSurah;

  /// No description provided for @customPlanFromAyah.
  ///
  /// In ar, this message translates to:
  /// **'من آية رقم'**
  String get customPlanFromAyah;

  /// No description provided for @customPlanInvalidAyah.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم آية صحيح'**
  String get customPlanInvalidAyah;

  /// No description provided for @customPlanSurahAyahLimit.
  ///
  /// In ar, this message translates to:
  /// **'هذه السورة فيها {maxAyah} آيات'**
  String customPlanSurahAyahLimit(int maxAyah);

  /// No description provided for @customPlanAdult.
  ///
  /// In ar, this message translates to:
  /// **'كبير'**
  String get customPlanAdult;

  /// No description provided for @customPlanChild.
  ///
  /// In ar, this message translates to:
  /// **'طفل'**
  String get customPlanChild;

  /// No description provided for @customPlanDifficultyEasy.
  ///
  /// In ar, this message translates to:
  /// **'سهل'**
  String get customPlanDifficultyEasy;

  /// No description provided for @customPlanDifficultyModerate.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get customPlanDifficultyModerate;

  /// No description provided for @customPlanDifficultyChallenging.
  ///
  /// In ar, this message translates to:
  /// **'صعب'**
  String get customPlanDifficultyChallenging;

  /// No description provided for @customPlanNearRevision.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة القريبة'**
  String get customPlanNearRevision;

  /// No description provided for @customPlanNearRevisionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة آيات آخر 5 أيام'**
  String get customPlanNearRevisionSubtitle;

  /// No description provided for @customPlanNearRevisionCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد آيات المراجعة القريبة'**
  String get customPlanNearRevisionCount;

  /// No description provided for @customPlanFarRevision.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة البعيدة'**
  String get customPlanFarRevision;

  /// No description provided for @customPlanFarRevisionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تكرار ذكي للآيات القديمة'**
  String get customPlanFarRevisionSubtitle;

  /// No description provided for @customPlanFarRevisionCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد آيات المراجعة البعيدة'**
  String get customPlanFarRevisionCount;

  /// No description provided for @customPlanEstimatedDuration.
  ///
  /// In ar, this message translates to:
  /// **'المدة المقدّرة للإنهاء'**
  String get customPlanEstimatedDuration;

  /// No description provided for @customPlanApproxWeeks.
  ///
  /// In ar, this message translates to:
  /// **'{count} أسبوع تقريباً'**
  String customPlanApproxWeeks(int count);

  /// No description provided for @customPlanApproxMonths.
  ///
  /// In ar, this message translates to:
  /// **'{count} شهر تقريباً'**
  String customPlanApproxMonths(int count);

  /// No description provided for @customPlanApproxYears.
  ///
  /// In ar, this message translates to:
  /// **'{count} سنة تقريباً'**
  String customPlanApproxYears(String count);

  /// No description provided for @customPlanEstimatedScope.
  ///
  /// In ar, this message translates to:
  /// **'{surahs} سورة • ~{ayahs} آية'**
  String customPlanEstimatedScope(int surahs, int ayahs);

  /// No description provided for @customPlanQuickPresetTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر قالباً سريعاً'**
  String get customPlanQuickPresetTitle;

  /// No description provided for @customPlanPresetLight.
  ///
  /// In ar, this message translates to:
  /// **'خفيف'**
  String get customPlanPresetLight;

  /// No description provided for @customPlanPresetLightDesc.
  ///
  /// In ar, this message translates to:
  /// **'3 آيات/يوم • 5 أيام • 10 دقائق'**
  String get customPlanPresetLightDesc;

  /// No description provided for @customPlanPresetLightName.
  ///
  /// In ar, this message translates to:
  /// **'خطة خفيفة'**
  String get customPlanPresetLightName;

  /// No description provided for @customPlanPresetBalanced.
  ///
  /// In ar, this message translates to:
  /// **'متوازن'**
  String get customPlanPresetBalanced;

  /// No description provided for @customPlanPresetBalancedDesc.
  ///
  /// In ar, this message translates to:
  /// **'5 آيات/يوم • 6 أيام • 15 دقيقة'**
  String get customPlanPresetBalancedDesc;

  /// No description provided for @customPlanPresetBalancedName.
  ///
  /// In ar, this message translates to:
  /// **'خطة متوازنة'**
  String get customPlanPresetBalancedName;

  /// No description provided for @customPlanPresetIntensive.
  ///
  /// In ar, this message translates to:
  /// **'مكثف'**
  String get customPlanPresetIntensive;

  /// No description provided for @customPlanPresetIntensiveDesc.
  ///
  /// In ar, this message translates to:
  /// **'10 آيات/يوم • كل الأسبوع • 30 دقيقة'**
  String get customPlanPresetIntensiveDesc;

  /// No description provided for @customPlanPresetIntensiveName.
  ///
  /// In ar, this message translates to:
  /// **'خطة مكثفة'**
  String get customPlanPresetIntensiveName;

  /// No description provided for @customPlanPresetJuzAmma.
  ///
  /// In ar, this message translates to:
  /// **'جزء عم'**
  String get customPlanPresetJuzAmma;

  /// No description provided for @customPlanPresetJuzAmmaDesc.
  ///
  /// In ar, this message translates to:
  /// **'من الناس إلى الفيل • 3 آيات/يوم'**
  String get customPlanPresetJuzAmmaDesc;

  /// No description provided for @customPlanPresetJuzAmmaName.
  ///
  /// In ar, this message translates to:
  /// **'خطة جزء عم'**
  String get customPlanPresetJuzAmmaName;

  /// No description provided for @customPlanSummaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الخطة'**
  String get customPlanSummaryTitle;

  /// No description provided for @customPlanSummaryRange.
  ///
  /// In ar, this message translates to:
  /// **'النطاق: {startSurah} ← {endSurah}'**
  String customPlanSummaryRange(Object startSurah, Object endSurah);

  /// No description provided for @customPlanSummaryLoad.
  ///
  /// In ar, this message translates to:
  /// **'{ayahsPerDay} آيات يومياً • {daysPerWeek} أيام أسبوعياً'**
  String customPlanSummaryLoad(int ayahsPerDay, int daysPerWeek);

  /// No description provided for @customPlanSummarySession.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة للجلسة • مستوى {difficulty}'**
  String customPlanSummarySession(int minutes, Object difficulty);

  /// No description provided for @memorizationPathSelectionFailedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ اختيارك'**
  String get memorizationPathSelectionFailedTitle;

  /// No description provided for @memorizationPathConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'ماذا سيحدث بعد ذلك؟'**
  String get memorizationPathConfirmTitle;

  /// No description provided for @memorizationPathCanChangeLater.
  ///
  /// In ar, this message translates to:
  /// **'يمكن تغييره من الإعدادات لاحقاً بدون فقدان تقدمك.'**
  String get memorizationPathCanChangeLater;

  /// No description provided for @parentDashboardLinkAction.
  ///
  /// In ar, this message translates to:
  /// **'ربط'**
  String get parentDashboardLinkAction;

  /// No description provided for @parentDashboardRemoteRewardTitle.
  ///
  /// In ar, this message translates to:
  /// **'مكافأة للطفل'**
  String get parentDashboardRemoteRewardTitle;

  /// No description provided for @parentDashboardScanChildCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسح رمز الطفل'**
  String get parentDashboardScanChildCodeTitle;

  /// No description provided for @homeParentToolsTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدوات ولي الأمر'**
  String get homeParentToolsTitle;

  /// No description provided for @homeParentToolsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تابع تقدم طفلك ومكافآته'**
  String get homeParentToolsSubtitle;

  /// No description provided for @homeParentToolsAction.
  ///
  /// In ar, this message translates to:
  /// **'فتح لوحة ولي الأمر'**
  String get homeParentToolsAction;

  /// No description provided for @guestUpgradeTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الحساب'**
  String get guestUpgradeTitle;

  /// No description provided for @guestUpgradeMessage.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساباً لإدارة الحساب وميزات العائلة.'**
  String get guestUpgradeMessage;

  /// No description provided for @guestUpgradeLocalProgress.
  ///
  /// In ar, this message translates to:
  /// **'يبقى تقدمك المحلي على هذا الجهاز.'**
  String get guestUpgradeLocalProgress;

  /// No description provided for @parentDashboardGuestSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك لإدارة حسابك والوصول إلى أدوات ولي الأمر. يبقى تقدمك المحلي على هذا الجهاز.'**
  String get parentDashboardGuestSubtitle;

  /// No description provided for @kidsQuranTitle.
  ///
  /// In ar, this message translates to:
  /// **'قرآن الأطفال'**
  String get kidsQuranTitle;

  /// No description provided for @kidsQuranSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ بهدوء وتنقل بين الصفحات على مهلك.'**
  String get kidsQuranSubtitle;

  /// No description provided for @kidsQuranBackToHome.
  ///
  /// In ar, this message translates to:
  /// **'العودة لصفحة الأطفال'**
  String get kidsQuranBackToHome;

  /// No description provided for @kidsQuranPageLabel.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {pageNumber}'**
  String kidsQuranPageLabel(int pageNumber);

  /// No description provided for @kidsQuranSwipeHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب بهدوء للصفحة التالية'**
  String get kidsQuranSwipeHint;

  /// No description provided for @parentDashboardPinInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمزًا من 4 أرقام'**
  String get parentDashboardPinInvalid;

  /// No description provided for @parentDashboardPinIncorrect.
  ///
  /// In ar, this message translates to:
  /// **'رمز غير صحيح'**
  String get parentDashboardPinIncorrect;

  /// No description provided for @parentDashboardLinking.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من رمز الربط…'**
  String get parentDashboardLinking;

  /// No description provided for @parentDashboardUnlinking.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ إزالة ربط ولي الأمر…'**
  String get parentDashboardUnlinking;

  /// No description provided for @guardianLinkingSlowHint.
  ///
  /// In ar, this message translates to:
  /// **'تستغرق العملية وقتًا أطول من المعتاد. يمكنك المتابعة والربط لاحقًا.'**
  String get guardianLinkingSlowHint;

  /// No description provided for @bookmarkSaveError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء حفظ العلامة المرجعية'**
  String get bookmarkSaveError;

  /// No description provided for @longPressToUndo.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً للتراجع'**
  String get longPressToUndo;

  /// No description provided for @hifzReviewPassedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم اجتياز المراجعة'**
  String get hifzReviewPassedTitle;

  /// No description provided for @hifzReviewTimeTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت المراجعة'**
  String get hifzReviewTimeTitle;

  /// No description provided for @hifzReviewFullSurahHint.
  ///
  /// In ar, this message translates to:
  /// **'راجع السورة كاملة قبل إنهائها'**
  String get hifzReviewFullSurahHint;

  /// No description provided for @hifzReviewRangeHint.
  ///
  /// In ar, this message translates to:
  /// **'راجع الآيات من {startAyah} إلى {endAyah} قبل الانتقال للآية التالية'**
  String hifzReviewRangeHint(int startAyah, int endAyah);

  /// No description provided for @hifzEvaluatingReview.
  ///
  /// In ar, this message translates to:
  /// **'جارِ تقييم المراجعة...'**
  String get hifzEvaluatingReview;

  /// No description provided for @hifzLeaveSessionMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد الخروج من جلسة الحفظ؟ سيتم حفظ تقدمك الحالي.'**
  String get hifzLeaveSessionMessage;

  /// No description provided for @hifzAyahNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'آية {ayahNumber}'**
  String hifzAyahNumberLabel(int ayahNumber);

  /// No description provided for @hifzEvaluatingAyah.
  ///
  /// In ar, this message translates to:
  /// **'جارِ التقييم...'**
  String get hifzEvaluatingAyah;

  /// No description provided for @hifzRecordingAyahHint.
  ///
  /// In ar, this message translates to:
  /// **'يتم التسجيل، اقرأ الآية من حفظك...'**
  String get hifzRecordingAyahHint;

  /// No description provided for @hifzExcellentMemorization.
  ///
  /// In ar, this message translates to:
  /// **'ممتاز! حفظ متقن.'**
  String get hifzExcellentMemorization;

  /// No description provided for @hifzNeedsAyahReview.
  ///
  /// In ar, this message translates to:
  /// **'تحتاج إلى مراجعة هذه الآية.'**
  String get hifzNeedsAyahReview;

  /// No description provided for @hifzNoVoiceRecognized.
  ///
  /// In ar, this message translates to:
  /// **'(لم يتم التعرف على صوت)'**
  String get hifzNoVoiceRecognized;

  /// No description provided for @hifzRecordingReviewHint.
  ///
  /// In ar, this message translates to:
  /// **'يتم التسجيل، اقرأ المقطع من حفظك...'**
  String get hifzRecordingReviewHint;

  /// No description provided for @hifzFinishRecitation.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء التسميع'**
  String get hifzFinishRecitation;

  /// No description provided for @hifzFinishSession.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الجلسة'**
  String get hifzFinishSession;

  /// No description provided for @hifzNextAyah.
  ///
  /// In ar, this message translates to:
  /// **'الآية التالية'**
  String get hifzNextAyah;

  /// No description provided for @hifzReviewNotPassed.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم اجتياز المراجعة. حاول مرة أخرى.'**
  String get hifzReviewNotPassed;

  /// No description provided for @hifzStartRecitation.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التسميع'**
  String get hifzStartRecitation;

  /// No description provided for @hifzAudioPlaybackFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تشغيل الصوت. تحقق من الاتصال بالइंटترنت.'**
  String get hifzAudioPlaybackFailed;

  /// No description provided for @hifzReviewSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل حفظ تقدم المراجعة. حاول مرة أخرى.'**
  String get hifzReviewSaveFailed;

  /// No description provided for @hifzMemorizationSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل حفظ تقدم الحفظ. حاول مرة أخرى.'**
  String get hifzMemorizationSaveFailed;

  /// No description provided for @hifzSurahLockedMessage.
  ///
  /// In ar, this message translates to:
  /// **'هذه السورة مقفلة حالياً. أكمل حفظ سورة {surahName} أولاً لفتحها.'**
  String hifzSurahLockedMessage(String surahName);

  /// No description provided for @kidsAudioPlaybackFailed.
  ///
  /// In ar, this message translates to:
  /// **'لم يعمل الصوت الآن. جرّب مرة أخرى أو اطلب من ولي الأمر الاتصال بالإنترنت.'**
  String get kidsAudioPlaybackFailed;

  /// No description provided for @smartCoachMemorizedReviewDueTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة تثبيت مستحقة'**
  String get smartCoachMemorizedReviewDueTitle;

  /// No description provided for @smartCoachMemorizedReviewDueSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'راجع الآيات المحفوظة من سورة {surahName} لتثبيت حفظك.'**
  String smartCoachMemorizedReviewDueSubtitle(String surahName);

  /// No description provided for @homeContinueTodaysPlan.
  ///
  /// In ar, this message translates to:
  /// **'أكمل خطة اليوم'**
  String get homeContinueTodaysPlan;

  /// No description provided for @homeCurrentMission.
  ///
  /// In ar, this message translates to:
  /// **'المهمة الحالية'**
  String get homeCurrentMission;

  /// No description provided for @homeStartKidsMission.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ مهمة الطفل الحالية.'**
  String get homeStartKidsMission;

  /// No description provided for @homeChooseKidsPath.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسار الطفل أو تابع المهمة الحالية.'**
  String get homeChooseKidsPath;

  /// No description provided for @homeDailyWirdPage.
  ///
  /// In ar, this message translates to:
  /// **'قراءة الصفحة {page} من القرآن الكريم'**
  String homeDailyWirdPage(Object page);

  /// No description provided for @homeDailyWirdSurah.
  ///
  /// In ar, this message translates to:
  /// **'قراءة سورة {surah} من القرآن الكريم'**
  String homeDailyWirdSurah(Object surah);

  /// No description provided for @homeDailyWird.
  ///
  /// In ar, this message translates to:
  /// **'الورد اليومي'**
  String get homeDailyWird;

  /// No description provided for @homeDailyWirdSurahPage.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surah} — صفحة {page}'**
  String homeDailyWirdSurahPage(Object page, Object surah);

  /// No description provided for @homeTodaysPlan.
  ///
  /// In ar, this message translates to:
  /// **'خطة اليوم'**
  String get homeTodaysPlan;

  /// No description provided for @homeKidsProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدم الطفل'**
  String get homeKidsProgress;

  /// No description provided for @homeYourProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدمك'**
  String get homeYourProgress;

  /// No description provided for @homeActionQuran.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get homeActionQuran;

  /// No description provided for @homeActionReadToday.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ وردك'**
  String get homeActionReadToday;

  /// No description provided for @homeActionTodaysPlan.
  ///
  /// In ar, this message translates to:
  /// **'خطة اليوم'**
  String get homeActionTodaysPlan;

  /// No description provided for @homeActionContinuePlan.
  ///
  /// In ar, this message translates to:
  /// **'تابع حفظك'**
  String get homeActionContinuePlan;

  /// No description provided for @homeActionProgress.
  ///
  /// In ar, this message translates to:
  /// **'التقدم'**
  String get homeActionProgress;

  /// No description provided for @homeActionReviewGains.
  ///
  /// In ar, this message translates to:
  /// **'راجع إنجازك'**
  String get homeActionReviewGains;

  /// No description provided for @homeActionSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get homeActionSettings;

  /// No description provided for @homeActionTuneApp.
  ///
  /// In ar, this message translates to:
  /// **'خصص تجربتك'**
  String get homeActionTuneApp;

  /// No description provided for @homeGoToSettings.
  ///
  /// In ar, this message translates to:
  /// **'انتقل إلى الإعدادات'**
  String get homeGoToSettings;

  /// No description provided for @notificationDailyReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'جاهز نراجع سوا؟ 📖'**
  String get notificationDailyReviewTitle;

  /// No description provided for @notificationDailyReviewBodyCount.
  ///
  /// In ar, this message translates to:
  /// **'عندك {count} آية مستنية مراجعتك النهاردة.. يلا خطوة بخطوة! ✨'**
  String notificationDailyReviewBodyCount(Object count);

  /// No description provided for @notificationDailyReviewBody.
  ///
  /// In ar, this message translates to:
  /// **'يلا بينا نرجع للمصحف ونثبت حفظ اليوم 🌸'**
  String get notificationDailyReviewBody;

  /// No description provided for @notificationStreakAlertTitle.
  ///
  /// In ar, this message translates to:
  /// **'⚠️ متضيعش إنجاز {count} يوم!'**
  String notificationStreakAlertTitle(Object count);

  /// No description provided for @notificationStreakAlertBody.
  ///
  /// In ar, this message translates to:
  /// **'فاضل تكة صغيرة وتكمل وردك النهاردة.. متكسلش، تقدر تعملها! 🔥'**
  String get notificationStreakAlertBody;

  /// No description provided for @notificationDailyAyahTitle.
  ///
  /// In ar, this message translates to:
  /// **'آية تفتح لك يومك ✨'**
  String get notificationDailyAyahTitle;

  /// No description provided for @notificationDailyAyahBody.
  ///
  /// In ar, this message translates to:
  /// **'خدلك دقيقة روق بالك مع وردك النهاردة من القرآن الكريم 🌿'**
  String get notificationDailyAyahBody;

  /// No description provided for @notificationMorningAzkarTitle.
  ///
  /// In ar, this message translates to:
  /// **'صبحك الله بالخير ☀️'**
  String get notificationMorningAzkarTitle;

  /// No description provided for @notificationMorningAzkarBody.
  ///
  /// In ar, this message translates to:
  /// **'يلا ابدأ يومك بذكر الله وطمئن قلبك.. أذكار الصباح في انتظارك'**
  String get notificationMorningAzkarBody;

  /// No description provided for @notificationEveningAzkarTitle.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير والسكينة 🌙'**
  String get notificationEveningAzkarTitle;

  /// No description provided for @notificationEveningAzkarBody.
  ///
  /// In ar, this message translates to:
  /// **'يومك كان زحمة؟ خذ لحظة هدوء مع أذكار المساء واختم يومك بحفظ الله'**
  String get notificationEveningAzkarBody;

  /// No description provided for @notificationKidsReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'يلا يا بطل جاهز؟ 🌟'**
  String get notificationKidsReviewTitle;

  /// No description provided for @notificationKidsReviewBody.
  ///
  /// In ar, this message translates to:
  /// **'مرحلتك الجديدة مستنياك.. يلا نكمل ونجمع نجوم جديدة! 🚀'**
  String get notificationKidsReviewBody;

  /// No description provided for @notificationDailyDuaTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعوة من القلب 🤲'**
  String get notificationDailyDuaTitle;

  /// No description provided for @homeTourTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحتاج جولة سريعة؟'**
  String get homeTourTitle;

  /// No description provided for @homeTourDesc.
  ///
  /// In ar, this message translates to:
  /// **'افتح الدليل متى أردت من هنا أو من المساعدة.'**
  String get homeTourDesc;

  /// No description provided for @homeTourGuideAction.
  ///
  /// In ar, this message translates to:
  /// **'الدليل'**
  String get homeTourGuideAction;

  /// No description provided for @journeyReviewBeforeNewTitle.
  ///
  /// In ar, this message translates to:
  /// **'راجع قبل الحفظ الجديد'**
  String get journeyReviewBeforeNewTitle;

  /// No description provided for @journeyReviewBeforeNewDesc.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة قريبة مستحقة في {surahAyahLabel}.'**
  String journeyReviewBeforeNewDesc(Object surahAyahLabel);

  /// No description provided for @journeyLongTermReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة بعيدة مستحقة'**
  String get journeyLongTermReviewTitle;

  /// No description provided for @journeyLongTermReviewDesc.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت مراجعة {surahAyahLabel}.'**
  String journeyLongTermReviewDesc(Object surahAyahLabel);

  /// No description provided for @journeyReviewDifficultAyahTitle.
  ///
  /// In ar, this message translates to:
  /// **'راجع الآية الصعبة'**
  String get journeyReviewDifficultAyahTitle;

  /// No description provided for @journeyReviewDifficultAyahDesc.
  ///
  /// In ar, this message translates to:
  /// **'آخر مراجعة كانت صعبة في {surahAyahLabel}.'**
  String journeyReviewDifficultAyahDesc(Object surahAyahLabel);

  /// No description provided for @journeyContinueDailyPlanTitle.
  ///
  /// In ar, this message translates to:
  /// **'أكمل خطة اليوم'**
  String get journeyContinueDailyPlanTitle;

  /// No description provided for @journeyContinueDailyPlanDesc.
  ///
  /// In ar, this message translates to:
  /// **'{completed}/{total} من مهام اليوم.'**
  String journeyContinueDailyPlanDesc(Object completed, Object total);

  /// No description provided for @journeyMemorizeNewAyahsTitle.
  ///
  /// In ar, this message translates to:
  /// **'احفظ آيات جديدة'**
  String get journeyMemorizeNewAyahsTitle;

  /// No description provided for @journeyMemorizeNewAyahsDesc.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بالآيات الجديدة في {surahAyahLabel}.'**
  String journeyMemorizeNewAyahsDesc(Object surahAyahLabel);

  /// No description provided for @journeyCurrentMissionTitle.
  ///
  /// In ar, this message translates to:
  /// **'المهمة الحالية'**
  String get journeyCurrentMissionTitle;

  /// No description provided for @journeyCurrentMissionDesc.
  ///
  /// In ar, this message translates to:
  /// **'تابع مهمة الطفل الحالية.'**
  String get journeyCurrentMissionDesc;

  /// No description provided for @journeyContinueSessionTitle.
  ///
  /// In ar, this message translates to:
  /// **'متابعة جلسة الحفظ'**
  String get journeyContinueSessionTitle;

  /// No description provided for @journeyContinueSessionDesc.
  ///
  /// In ar, this message translates to:
  /// **'لديك جلسة حفظ مفتوحة لم تكتمل في {surahLabel}.'**
  String journeyContinueSessionDesc(Object surahLabel);

  /// No description provided for @journeyHifzReviewDueTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الحفظ مستحقة'**
  String get journeyHifzReviewDueTitle;

  /// No description provided for @journeyHifzReviewDueDesc.
  ///
  /// In ar, this message translates to:
  /// **'راجع مواضع الحفظ المستحقة في مسار الحفظ.'**
  String get journeyHifzReviewDueDesc;

  /// No description provided for @journeyFallbackSurah.
  ///
  /// In ar, this message translates to:
  /// **'السورة'**
  String get journeyFallbackSurah;

  /// No description provided for @journeyAyahLabel.
  ///
  /// In ar, this message translates to:
  /// **'، الآية {start}'**
  String journeyAyahLabel(Object start);

  /// No description provided for @journeyAyahsLabel.
  ///
  /// In ar, this message translates to:
  /// **'، الآيات {start}–{end}'**
  String journeyAyahsLabel(Object end, Object start);

  /// No description provided for @tutorialS1Title.
  ///
  /// In ar, this message translates to:
  /// **'البداية مع تالية'**
  String get tutorialS1Title;

  /// No description provided for @tutorialS1Cat.
  ///
  /// In ar, this message translates to:
  /// **'البدء'**
  String get tutorialS1Cat;

  /// No description provided for @tutorialS1Does.
  ///
  /// In ar, this message translates to:
  /// **'تالية تبدأ بشاشة افتتاحية ثم تعريف سريع لأول استخدام، وبعدها تعيدك إلى آخر موضع قراءة أو جلسة قابلة للاستئناف.'**
  String get tutorialS1Does;

  /// No description provided for @tutorialS1Open.
  ///
  /// In ar, this message translates to:
  /// **'تظهر تلقائيًا عند فتح التطبيق. بعد ذلك استخدم الشريط السفلي للتنقل بين الرئيسية، القرآن، الحفظ، الأذكار، والتقدم.'**
  String get tutorialS1Open;

  /// No description provided for @tutorialS1Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيد للمستخدم الجديد أو لمن يريد فهم خريطة التطبيق قبل البدء بالحفظ أو القراءة.'**
  String get tutorialS1Useful;

  /// No description provided for @tutorialS1Step1.
  ///
  /// In ar, this message translates to:
  /// **'أنهِ صفحات التعريف الأولى عند أول تشغيل.'**
  String get tutorialS1Step1;

  /// No description provided for @tutorialS1Step2.
  ///
  /// In ar, this message translates to:
  /// **'استخدم الشريط السفلي للانتقال بين أقسام التطبيق الأساسية.'**
  String get tutorialS1Step2;

  /// No description provided for @tutorialS1Step3.
  ///
  /// In ar, this message translates to:
  /// **'إذا ظهر زر استكمال القراءة في الرئيسية فاضغطه للعودة إلى آخر موضع محفوظ.'**
  String get tutorialS1Step3;

  /// No description provided for @tutorialS1Tip1.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ من الصفحة الرئيسية لأنها تجمع ورد اليوم والتقدم والاختصارات.'**
  String get tutorialS1Tip1;

  /// No description provided for @tutorialS1Tip2.
  ///
  /// In ar, this message translates to:
  /// **'آخر موضع محفوظ يعمل مع صفحات القرآن وبعض مسارات الحفظ الذكي.'**
  String get tutorialS1Tip2;

  /// No description provided for @tutorialS1Note1.
  ///
  /// In ar, this message translates to:
  /// **'شاشة البداية والتعريف لا تتغير عند إضافة هذا الدليل.'**
  String get tutorialS1Note1;

  /// No description provided for @tutorialS1Note2.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول اختياري، ويفيد في إدارة الحساب وميزات العائلة.'**
  String get tutorialS1Note2;

  /// No description provided for @tutorialS2Title.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة الرئيسية'**
  String get tutorialS2Title;

  /// No description provided for @tutorialS2Cat.
  ///
  /// In ar, this message translates to:
  /// **'البدء'**
  String get tutorialS2Cat;

  /// No description provided for @tutorialS2Does.
  ///
  /// In ar, this message translates to:
  /// **'تعرض تحية باسمك إن وجد، وردًا يوميًا، استكمال القراءة، ملخص التقدم، اختصار الأذكار، الخطة المخصصة، الحفظ الذكي، وخريطة نشاطك.'**
  String get tutorialS2Does;

  /// No description provided for @tutorialS2Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط تبويب الرئيسية من الشريط السفلي، أو ارجع إلى المسار الرئيسي للتطبيق.'**
  String get tutorialS2Open;

  /// No description provided for @tutorialS2Useful.
  ///
  /// In ar, this message translates to:
  /// **'أفضل نقطة انطلاق يومية لأنها تجمع ما تحتاجه للقراءة والحفظ والمتابعة في شاشة واحدة.'**
  String get tutorialS2Useful;

  /// No description provided for @tutorialS2Step1.
  ///
  /// In ar, this message translates to:
  /// **'اضغط بطاقة الورد اليومي لفتح صفحة القرآن المقترحة.'**
  String get tutorialS2Step1;

  /// No description provided for @tutorialS2Step2.
  ///
  /// In ar, this message translates to:
  /// **'استخدم استكمال القراءة للعودة إلى آخر صفحة أو سورة محفوظة.'**
  String get tutorialS2Step2;

  /// No description provided for @tutorialS2Step3.
  ///
  /// In ar, this message translates to:
  /// **'افتح الإعدادات من أيقونة الترس أعلى الصفحة.'**
  String get tutorialS2Step3;

  /// No description provided for @tutorialS2Step4.
  ///
  /// In ar, this message translates to:
  /// **'اضغط بطاقة الحفظ الذكي للدخول إلى Memorization Plus.'**
  String get tutorialS2Step4;

  /// No description provided for @tutorialS2Tip1.
  ///
  /// In ar, this message translates to:
  /// **'راجع صف التقدم يوميًا لمعرفة السلسلة و XP.'**
  String get tutorialS2Tip1;

  /// No description provided for @tutorialS2Tip2.
  ///
  /// In ar, this message translates to:
  /// **'الخطة المخصصة تظهر في الرئيسية عندما تحفظ خطة من الحفظ الذكي.'**
  String get tutorialS2Tip2;

  /// No description provided for @tutorialS2Note1.
  ///
  /// In ar, this message translates to:
  /// **'بعض البطاقات تظهر فقط عند وجود بيانات، مثل آخر موضع قراءة أو خطة مخصصة.'**
  String get tutorialS2Note1;

  /// No description provided for @tutorialS2Note2.
  ///
  /// In ar, this message translates to:
  /// **'معاينة الشهادات التجريبية تظهر في وضع التطوير فقط وليست جزءًا للمستخدم النهائي.'**
  String get tutorialS2Note2;

  /// No description provided for @tutorialS3Title.
  ///
  /// In ar, this message translates to:
  /// **'قراءة القرآن وعرض صفحات المصحف'**
  String get tutorialS3Title;

  /// No description provided for @tutorialS3Cat.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get tutorialS3Cat;

  /// No description provided for @tutorialS3Does.
  ///
  /// In ar, this message translates to:
  /// **'يوفر تبويب القرآن قائمة السور، عرض الأجزاء والصفحات، قارئ المصحف، تشغيل الآيات، النسخ، العلامات المرجعية، حجم الخط، ووضع التركيز.'**
  String get tutorialS3Does;

  /// No description provided for @tutorialS3Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط تبويب القرآن، ثم اختر سورة من تبويب السور أو صفحة من تبويب الأجزاء. يمكن فتح الصفحة أيضًا من الورد اليومي.'**
  String get tutorialS3Open;

  /// No description provided for @tutorialS3Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيد للورد اليومي، مراجعة آية محددة، القراءة حسب الصفحة، أو التحضير لجلسة حفظ.'**
  String get tutorialS3Useful;

  /// No description provided for @tutorialS3Step1.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن السورة من مربع البحث أو اخترها من القائمة.'**
  String get tutorialS3Step1;

  /// No description provided for @tutorialS3Step2.
  ///
  /// In ar, this message translates to:
  /// **'افتح تبويب الأجزاء للوصول إلى صفحات المصحف حسب الجزء.'**
  String get tutorialS3Step2;

  /// No description provided for @tutorialS3Step3.
  ///
  /// In ar, this message translates to:
  /// **'داخل القارئ اضغط الآية لعرض إجراءات التشغيل والنسخ والحفظ.'**
  String get tutorialS3Step3;

  /// No description provided for @tutorialS3Step4.
  ///
  /// In ar, this message translates to:
  /// **'استخدم زر حجم الخط لتكبير النص، وزر التركيز لتقليل التشتيت.'**
  String get tutorialS3Step4;

  /// No description provided for @tutorialS3Step5.
  ///
  /// In ar, this message translates to:
  /// **'في قارئ الصفحة اضغط تأكيد القراءة ليُحتسب تقدم القراءة.'**
  String get tutorialS3Step5;

  /// No description provided for @tutorialS3Tip1.
  ///
  /// In ar, this message translates to:
  /// **'البحث يدعم أسماء السور، والبحث النصي في الآيات يعتمد على تطبيع النص العربي.'**
  String get tutorialS3Tip1;

  /// No description provided for @tutorialS3Tip2.
  ///
  /// In ar, this message translates to:
  /// **'استخدم تشغيل الصوت قبل الحفظ لتثبيت النطق.'**
  String get tutorialS3Tip2;

  /// No description provided for @tutorialS3Note1.
  ///
  /// In ar, this message translates to:
  /// **'بيانات القرآن محملة من ملفات التطبيق المحلية، لذلك يمكن عرض النص بدون اتصال.'**
  String get tutorialS3Note1;

  /// No description provided for @tutorialS3Note2.
  ///
  /// In ar, this message translates to:
  /// **'الصوت قد يحتاج اتصالًا أو ملفًا مخزنًا في الكاش حسب توفره.'**
  String get tutorialS3Note2;

  /// No description provided for @tutorialS4Title.
  ///
  /// In ar, this message translates to:
  /// **'البحث والعلامات المرجعية'**
  String get tutorialS4Title;

  /// No description provided for @tutorialS4Cat.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get tutorialS4Cat;

  /// No description provided for @tutorialS4Does.
  ///
  /// In ar, this message translates to:
  /// **'يسمح لك بالعثور على السور أو الآيات، وحفظ الآيات المهمة كعلامات مرجعية مجمعة حسب السورة.'**
  String get tutorialS4Does;

  /// No description provided for @tutorialS4Open.
  ///
  /// In ar, this message translates to:
  /// **'البحث من أعلى تبويب القرآن. العلامات من تبويب العلامات داخل القرآن أو من إجراء الحفظ داخل القارئ.'**
  String get tutorialS4Open;

  /// No description provided for @tutorialS4Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيد لتجميع آيات المراجعة، الآيات المتشابهة، أو مواضع تريد الرجوع إليها لاحقًا.'**
  String get tutorialS4Useful;

  /// No description provided for @tutorialS4Step1.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم سورة أو كلمة من الآية في مربع البحث.'**
  String get tutorialS4Step1;

  /// No description provided for @tutorialS4Step2.
  ///
  /// In ar, this message translates to:
  /// **'افتح الآية أو السورة المطلوبة من النتائج.'**
  String get tutorialS4Step2;

  /// No description provided for @tutorialS4Step3.
  ///
  /// In ar, this message translates to:
  /// **'من القارئ اختر علامة مرجعية لحفظ الآية.'**
  String get tutorialS4Step3;

  /// No description provided for @tutorialS4Step4.
  ///
  /// In ar, this message translates to:
  /// **'افتح تبويب العلامات للرجوع إلى الآيات المحفوظة أو حذفها بالسحب/التأكيد.'**
  String get tutorialS4Step4;

  /// No description provided for @tutorialS4Tip1.
  ///
  /// In ar, this message translates to:
  /// **'احفظ بدايات مقاطع الحفظ كعلامات لتعود إليها بسرعة.'**
  String get tutorialS4Tip1;

  /// No description provided for @tutorialS4Tip2.
  ///
  /// In ar, this message translates to:
  /// **'استخدم النسخ عند مشاركة آية خارج التطبيق.'**
  String get tutorialS4Tip2;

  /// No description provided for @tutorialS4Note1.
  ///
  /// In ar, this message translates to:
  /// **'العلامات محفوظة محليًا في SharedPreferences.'**
  String get tutorialS4Note1;

  /// No description provided for @tutorialS4Note2.
  ///
  /// In ar, this message translates to:
  /// **'إزالة علامة لا تحذف أي تقدم قراءة أو حفظ.'**
  String get tutorialS4Note2;

  /// No description provided for @tutorialS5Title.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ خطوة بخطوة'**
  String get tutorialS5Title;

  /// No description provided for @tutorialS5Cat.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get tutorialS5Cat;

  /// No description provided for @tutorialS5Does.
  ///
  /// In ar, this message translates to:
  /// **'يوفر تبويب الحفظ مسارين: مسار البالغين من البداية، ومسار المبتدئين من قصار السور، مع فتح السور تدريجيًا ومتابعة حالة كل آية.'**
  String get tutorialS5Does;

  /// No description provided for @tutorialS5Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط تبويب الحفظ، اختر المسار عند أول استخدام، ثم اختر سورة مفتوحة أو غيّر المسار من زر المسار.'**
  String get tutorialS5Open;

  /// No description provided for @tutorialS5Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيد للحفظ المنهجي بسور كاملة ومراجعات إجبارية تمنع تراكم النسيان.'**
  String get tutorialS5Useful;

  /// No description provided for @tutorialS5Step1.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسار البالغين أو المبتدئين.'**
  String get tutorialS5Step1;

  /// No description provided for @tutorialS5Step2.
  ///
  /// In ar, this message translates to:
  /// **'افتح سورة متاحة من قائمة السور.'**
  String get tutorialS5Step2;

  /// No description provided for @tutorialS5Step3.
  ///
  /// In ar, this message translates to:
  /// **'استمع للآية، ثم ابدأ التسميع عند الحاجة.'**
  String get tutorialS5Step3;

  /// No description provided for @tutorialS5Step4.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الآيات المطلوبة، وتعامل مع نقاط المراجعة قبل فتح التالي.'**
  String get tutorialS5Step4;

  /// No description provided for @tutorialS5Tip1.
  ///
  /// In ar, this message translates to:
  /// **'استخدم إعداد دقة التسميع من الإعدادات إذا كان التقييم صارمًا أو سهلًا أكثر من اللازم.'**
  String get tutorialS5Tip1;

  /// No description provided for @tutorialS5Tip2.
  ///
  /// In ar, this message translates to:
  /// **'راجع الآيات التي تظهر في حالة مراجعة قبل الانتقال السريع.'**
  String get tutorialS5Tip2;

  /// No description provided for @tutorialS5Note1.
  ///
  /// In ar, this message translates to:
  /// **'بعض السور تكون مقفلة حتى يكتمل الشرط السابق في المسار المختار.'**
  String get tutorialS5Note1;

  /// No description provided for @tutorialS5Note2.
  ///
  /// In ar, this message translates to:
  /// **'تقدم الحفظ محفوظ محليًا في Isar، وقد يزامن سحابيًا عند تسجيل الدخول.'**
  String get tutorialS5Note2;

  /// No description provided for @tutorialS6Title.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار اليومية والعداد'**
  String get tutorialS6Title;

  /// No description provided for @tutorialS6Cat.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get tutorialS6Cat;

  /// No description provided for @tutorialS6Does.
  ///
  /// In ar, this message translates to:
  /// **'يحتوي على أذكار الصباح والمساء، أذكار عامة، وأدعية، مع عداد تكرار، فهرس، تغيير حجم الخط، نسخ ومشاركة.'**
  String get tutorialS6Does;

  /// No description provided for @tutorialS6Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط تبويب الأذكار، ثم اختر الصباح أو المساء أو الأذكار العامة أو الأدعية.'**
  String get tutorialS6Open;

  /// No description provided for @tutorialS6Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيد للورد الصباحي والمسائي، جلسات التسبيح، ومشاركة دعاء أو ذكر بسرعة.'**
  String get tutorialS6Useful;

  /// No description provided for @tutorialS6Step1.
  ///
  /// In ar, this message translates to:
  /// **'اختر فئة الأذكار المطلوبة.'**
  String get tutorialS6Step1;

  /// No description provided for @tutorialS6Step2.
  ///
  /// In ar, this message translates to:
  /// **'اضغط بطاقة الذكر أو العداد لإكمال التكرارات.'**
  String get tutorialS6Step2;

  /// No description provided for @tutorialS6Step3.
  ///
  /// In ar, this message translates to:
  /// **'استخدم الفهرس للانتقال إلى ذكر محدد.'**
  String get tutorialS6Step3;

  /// No description provided for @tutorialS6Step4.
  ///
  /// In ar, this message translates to:
  /// **'غيّر حجم الخط من زر التنسيق، وانسخ أو شارك الذكر عند الحاجة.'**
  String get tutorialS6Step4;

  /// No description provided for @tutorialS6Step5.
  ///
  /// In ar, this message translates to:
  /// **'بعد الإكمال يمكنك اعادة ضبط الجلسة أو العودة للرئيسية.'**
  String get tutorialS6Step5;

  /// No description provided for @tutorialS6Tip1.
  ///
  /// In ar, this message translates to:
  /// **'فعّل تذكيرات الصباح والمساء من الإعدادات.'**
  String get tutorialS6Tip1;

  /// No description provided for @tutorialS6Tip2.
  ///
  /// In ar, this message translates to:
  /// **'استخدم تبويب الأدعية للتذكير اليومي بالدعاء.'**
  String get tutorialS6Tip2;

  /// No description provided for @tutorialS6Note1.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار محملة من ملفات التطبيق المحلية.'**
  String get tutorialS6Note1;

  /// No description provided for @tutorialS6Note2.
  ///
  /// In ar, this message translates to:
  /// **'عداد الأذكار مخصص للجلسة الحالية، وليس شهادة حفظ.'**
  String get tutorialS6Note2;

  /// No description provided for @tutorialS7Title.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ الذكي والخطة اليومية'**
  String get tutorialS7Title;

  /// No description provided for @tutorialS7Cat.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get tutorialS7Cat;

  /// No description provided for @tutorialS7Does.
  ///
  /// In ar, this message translates to:
  /// **'Memorization Plus ينشئ خطة يومية للبالغين تجمع آيات جديدة ومراجعة قريبة وبعيدة، مع تقييم ممتاز/متوسط/ضعيف واختبار شفهي.'**
  String get tutorialS7Does;

  /// No description provided for @tutorialS7Open.
  ///
  /// In ar, this message translates to:
  /// **'من الصفحة الرئيسية أو بطاقة الحفظ الذكي في تبويب الحفظ، ثم اختر مسار البالغين.'**
  String get tutorialS7Open;

  /// No description provided for @tutorialS7Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيد لمن يريد حفظًا متدرجًا مع مراجعة ذكية بدل الاعتماد على الذاكرة وحدها.'**
  String get tutorialS7Useful;

  /// No description provided for @tutorialS7Step1.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسار البالغين من شاشة اختيار المسار.'**
  String get tutorialS7Step1;

  /// No description provided for @tutorialS7Step2.
  ///
  /// In ar, this message translates to:
  /// **'افتح الخطة اليومية للسورة الأخيرة أو المختارة.'**
  String get tutorialS7Step2;

  /// No description provided for @tutorialS7Step3.
  ///
  /// In ar, this message translates to:
  /// **'راجع كل آية ثم قيّمها: ممتاز، متوسط، أو ضعيف.'**
  String get tutorialS7Step3;

  /// No description provided for @tutorialS7Step4.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الاختبار من زر الاختبار لتسميع الآيات صوتيًا.'**
  String get tutorialS7Step4;

  /// No description provided for @tutorialS7Step5.
  ///
  /// In ar, this message translates to:
  /// **'استخدم زر التحديث لإعادة توليد الخطة عند الحاجة.'**
  String get tutorialS7Step5;

  /// No description provided for @tutorialS7Tip1.
  ///
  /// In ar, this message translates to:
  /// **'قيّم بصدق لأن التقييم يحدد قوة الآية وموعد مراجعتها التالي.'**
  String get tutorialS7Tip1;

  /// No description provided for @tutorialS7Tip2.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بعدد آيات قليل إذا كنت تبني عادة يومية جديدة.'**
  String get tutorialS7Tip2;

  /// No description provided for @tutorialS7Note1.
  ///
  /// In ar, this message translates to:
  /// **'الخطة اليومية تحفظ في SharedPreferences وتستخدم سجلات مراجعة محلية.'**
  String get tutorialS7Note1;

  /// No description provided for @tutorialS7Note2.
  ///
  /// In ar, this message translates to:
  /// **'الاختبار يحتاج صلاحية الميكروفون والتعرف على الكلام من الجهاز.'**
  String get tutorialS7Note2;

  /// No description provided for @tutorialS8Title.
  ///
  /// In ar, this message translates to:
  /// **'الخطة المخصصة'**
  String get tutorialS8Title;

  /// No description provided for @tutorialS8Cat.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get tutorialS8Cat;

  /// No description provided for @tutorialS8Does.
  ///
  /// In ar, this message translates to:
  /// **'تسمح بإنشاء خطة حفظ باسم ونطاق سور وحمل يومي وأيام أسبوعية ومدة جلسة وصعوبة ومراجعة قريبة/بعيدة.'**
  String get tutorialS8Does;

  /// No description provided for @tutorialS8Open.
  ///
  /// In ar, this message translates to:
  /// **'افتح الحفظ الذكي، ثم اضغط بطاقة الخطة المخصصة من شاشة اختيار المسار.'**
  String get tutorialS8Open;

  /// No description provided for @tutorialS8Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيدة لمن لديه هدف محدد مثل حفظ جزء معين أو تنظيم حفظ طفل بخطة قصيرة.'**
  String get tutorialS8Useful;

  /// No description provided for @tutorialS8Step1.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم الخطة وحدد هل هي لك أم لطفل.'**
  String get tutorialS8Step1;

  /// No description provided for @tutorialS8Step2.
  ///
  /// In ar, this message translates to:
  /// **'اختر بداية ونهاية نطاق السور.'**
  String get tutorialS8Step2;

  /// No description provided for @tutorialS8Step3.
  ///
  /// In ar, this message translates to:
  /// **'اضبط عدد الآيات اليومية وأيام الحفظ ومدة الجلسة.'**
  String get tutorialS8Step3;

  /// No description provided for @tutorialS8Step4.
  ///
  /// In ar, this message translates to:
  /// **'اختر مستوى الصعوبة وشغّل أو أوقف المراجعات.'**
  String get tutorialS8Step4;

  /// No description provided for @tutorialS8Step5.
  ///
  /// In ar, this message translates to:
  /// **'احفظ الخطة للانتقال إلى الخطة اليومية.'**
  String get tutorialS8Step5;

  /// No description provided for @tutorialS8Tip1.
  ///
  /// In ar, this message translates to:
  /// **'اجعل نطاق الخطة صغيرًا في البداية لتسهيل الالتزام.'**
  String get tutorialS8Tip1;

  /// No description provided for @tutorialS8Tip2.
  ///
  /// In ar, this message translates to:
  /// **'اترك المراجعة القريبة والبعيدة مفعّلتين إن كنت تحفظ يوميًا.'**
  String get tutorialS8Tip2;

  /// No description provided for @tutorialS8Note1.
  ///
  /// In ar, this message translates to:
  /// **'يمكن حذف الخطة من شاشة الإعداد نفسها.'**
  String get tutorialS8Note1;

  /// No description provided for @tutorialS8Note2.
  ///
  /// In ar, this message translates to:
  /// **'الخطة تظهر في الصفحة الرئيسية عند وجود خطة نشطة.'**
  String get tutorialS8Note2;

  /// No description provided for @tutorialS9Title.
  ///
  /// In ar, this message translates to:
  /// **'وضع الأطفال ولوحة ولي الأمر'**
  String get tutorialS9Title;

  /// No description provided for @tutorialS9Cat.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get tutorialS9Cat;

  /// No description provided for @tutorialS9Does.
  ///
  /// In ar, this message translates to:
  /// **'يوفر رحلة أطفال بمراحل ونجوم ومستويات وتكرار صوتي، مع لوحة ولي أمر للملخص والتذكير والمكافآت والربط عن بعد.'**
  String get tutorialS9Does;

  /// No description provided for @tutorialS9Open.
  ///
  /// In ar, this message translates to:
  /// **'من الحفظ الذكي اختر مسار الأطفال. لوحة ولي الأمر تظهر من رحلة الأطفال أو من الإعدادات عند اختيار مسار الأطفال أو تفعيل وضع ولي الأمر.'**
  String get tutorialS9Open;

  /// No description provided for @tutorialS9Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيد للأطفال والمبتدئين، أو للوالد الذي يريد متابعة النجوم والجلسات والمكافآت.'**
  String get tutorialS9Useful;

  /// No description provided for @tutorialS9Step1.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسار الأطفال وافتح رحلة السورة.'**
  String get tutorialS9Step1;

  /// No description provided for @tutorialS9Step2.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ المرحلة المفتوحة، واستمع للآية وكررها.'**
  String get tutorialS9Step2;

  /// No description provided for @tutorialS9Step3.
  ///
  /// In ar, this message translates to:
  /// **'اضغط أنهيت المراجعة لمنح النقاط والنجوم.'**
  String get tutorialS9Step3;

  /// No description provided for @tutorialS9Step4.
  ///
  /// In ar, this message translates to:
  /// **'افتح لوحة ولي الأمر لإنشاء رمز، ضبط التذكير، إضافة مكافآت، أو ربط طفل عبر QR/إدخال يدوي.'**
  String get tutorialS9Step4;

  /// No description provided for @tutorialS9Tip1.
  ///
  /// In ar, this message translates to:
  /// **'استخدم المكافآت الصغيرة لتحويل الحفظ إلى عادة لطيفة.'**
  String get tutorialS9Tip1;

  /// No description provided for @tutorialS9Tip2.
  ///
  /// In ar, this message translates to:
  /// **'فعّل تذكير الطفل اليومي من لوحة ولي الأمر.'**
  String get tutorialS9Tip2;

  /// No description provided for @tutorialS9Note1.
  ///
  /// In ar, this message translates to:
  /// **'المراحل المقفلة تفتح بعد إكمال السابق.'**
  String get tutorialS9Note1;

  /// No description provided for @tutorialS9Note2.
  ///
  /// In ar, this message translates to:
  /// **'الربط عن بعد يعتمد على الحساب، بينما تقدم الطفل المحلي محفوظ في الجهاز.'**
  String get tutorialS9Note2;

  /// No description provided for @tutorialS10Title.
  ///
  /// In ar, this message translates to:
  /// **'التقدم والإنجازات والشهادات'**
  String get tutorialS10Title;

  /// No description provided for @tutorialS10Cat.
  ///
  /// In ar, this message translates to:
  /// **'التقدم'**
  String get tutorialS10Cat;

  /// No description provided for @tutorialS10Does.
  ///
  /// In ar, this message translates to:
  /// **'يعرض إحصاءات القراءة والحفظ، السلسلة اليومية، إنجازات القراءة والحفظ والالتزام، إحصاءات الحفظ الذكي، شهاداتك، ومشاركة التقدم.'**
  String get tutorialS10Does;

  /// No description provided for @tutorialS10Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط تبويب التقدم من الشريط السفلي.'**
  String get tutorialS10Open;

  /// No description provided for @tutorialS10Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيد للمراجعة الأسبوعية، الاحتفال بالإنجازات، ومتابعة الاتساق عبر السلسلة والنشاط.'**
  String get tutorialS10Useful;

  /// No description provided for @tutorialS10Step1.
  ///
  /// In ar, this message translates to:
  /// **'راجع البطاقات العليا لمعرفة أيام السلسلة والصفحات المقروءة.'**
  String get tutorialS10Step1;

  /// No description provided for @tutorialS10Step2.
  ///
  /// In ar, this message translates to:
  /// **'افتح أقسام القراءة والحفظ لمعرفة الصفحات والآيات والسور والأجزاء.'**
  String get tutorialS10Step2;

  /// No description provided for @tutorialS10Step3.
  ///
  /// In ar, this message translates to:
  /// **'بدّل فلاتر الإنجازات بين الكل والقراءة والحفظ والسلسلة.'**
  String get tutorialS10Step3;

  /// No description provided for @tutorialS10Step4.
  ///
  /// In ar, this message translates to:
  /// **'اضغط إنجازًا مفتوحًا لعرض التفاصيل والمشاركة.'**
  String get tutorialS10Step4;

  /// No description provided for @tutorialS10Step5.
  ///
  /// In ar, this message translates to:
  /// **'افتح شهاداتك عند اكتمال سورة أو جزء أو نصف/كامل القرآن.'**
  String get tutorialS10Step5;

  /// No description provided for @tutorialS10Tip1.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد قراءة الصفحة من القارئ هو ما يرفع إحصاءات القراءة.'**
  String get tutorialS10Tip1;

  /// No description provided for @tutorialS10Tip2.
  ///
  /// In ar, this message translates to:
  /// **'الشهادات تعتمد على اكتمال الحفظ الحقيقي للآيات المطلوبة.'**
  String get tutorialS10Tip2;

  /// No description provided for @tutorialS10Note1.
  ///
  /// In ar, this message translates to:
  /// **'بعض الإحصاءات تظهر فقط بعد وجود تقدم في الحفظ الذكي أو وضع الأطفال.'**
  String get tutorialS10Note1;

  /// No description provided for @tutorialS10Note2.
  ///
  /// In ar, this message translates to:
  /// **'المشاركة ترسل نصًا فقط ولا تنشر تلقائيًا بدون اختيارك.'**
  String get tutorialS10Note2;

  /// No description provided for @tutorialS11Title.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات والحساب والإشعارات'**
  String get tutorialS11Title;

  /// No description provided for @tutorialS11Cat.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get tutorialS11Cat;

  /// No description provided for @tutorialS11Does.
  ///
  /// In ar, this message translates to:
  /// **'تجمع الحساب، الملف الشخصي، وضع ولي الأمر، المظهر، اللغة، دقة التسميع، تذكيرات المراجعة والأذكار والدعاء، ومعلومات التطبيق.'**
  String get tutorialS11Does;

  /// No description provided for @tutorialS11Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط الترس من الصفحة الرئيسية أو افتح مسار الإعدادات.'**
  String get tutorialS11Open;

  /// No description provided for @tutorialS11Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيد لتخصيص التجربة، حماية التقدم، وضبط التذكيرات بما يناسب يومك.'**
  String get tutorialS11Useful;

  /// No description provided for @tutorialS11Step1.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول أو أنشئ حسابًا بالبريد وكلمة المرور لإدارة حسابك وخيارات الاستعادة.'**
  String get tutorialS11Step1;

  /// No description provided for @tutorialS11Step2.
  ///
  /// In ar, this message translates to:
  /// **'عدّل الاسم والعمر من قسم الملف الشخصي.'**
  String get tutorialS11Step2;

  /// No description provided for @tutorialS11Step3.
  ///
  /// In ar, this message translates to:
  /// **'اختر الوضع الفاتح أو الداكن أو إعداد النظام.'**
  String get tutorialS11Step3;

  /// No description provided for @tutorialS11Step4.
  ///
  /// In ar, this message translates to:
  /// **'اختر العربية أو English من قسم اللغة.'**
  String get tutorialS11Step4;

  /// No description provided for @tutorialS11Step5.
  ///
  /// In ar, this message translates to:
  /// **'اضبط دقة التسميع بين سهل ومتوسط وصعب.'**
  String get tutorialS11Step5;

  /// No description provided for @tutorialS11Step6.
  ///
  /// In ar, this message translates to:
  /// **'فعّل أو أوقف تذكيرات المراجعة والسلسلة وأذكار الصباح والمساء والدعاء.'**
  String get tutorialS11Step6;

  /// No description provided for @tutorialS11Tip1.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الاسم بالعربية ليظهر أجمل في الشهادات.'**
  String get tutorialS11Tip1;

  /// No description provided for @tutorialS11Tip2.
  ///
  /// In ar, this message translates to:
  /// **'فعّل وضع ولي الأمر إذا كنت تستخدم مسار البالغين وتريد متابعة طفل.'**
  String get tutorialS11Tip2;

  /// No description provided for @tutorialS11Note1.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات تحتاج صلاحيات النظام حتى تعمل.'**
  String get tutorialS11Note1;

  /// No description provided for @tutorialS11Note2.
  ///
  /// In ar, this message translates to:
  /// **'تغيير اللغة والمظهر محفوظ محليًا ويطبق على واجهة التطبيق.'**
  String get tutorialS11Note2;

  /// No description provided for @tutorialS12Title.
  ///
  /// In ar, this message translates to:
  /// **'العمل دون اتصال وحفظ البيانات'**
  String get tutorialS12Title;

  /// No description provided for @tutorialS12Cat.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get tutorialS12Cat;

  /// No description provided for @tutorialS12Does.
  ///
  /// In ar, this message translates to:
  /// **'يعتمد التطبيق على بيانات محلية للقرآن والأذكار، ويحفظ الإعدادات والعلامات والخطط في SharedPreferences، وتقدم الحفظ والسلسلة و XP في Isar.'**
  String get tutorialS12Does;

  /// No description provided for @tutorialS12Open.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد شاشة منفصلة لهذه الميزة؛ تعمل تلقائيًا أثناء استخدام القرآن، الأذكار، الحفظ، التقدم، والإعدادات.'**
  String get tutorialS12Open;

  /// No description provided for @tutorialS12Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيد لفهم ما يعمل محليًا وما يحتاج اتصالًا، وتجنب فقدان التقدم المهم.'**
  String get tutorialS12Useful;

  /// No description provided for @tutorialS12Step1.
  ///
  /// In ar, this message translates to:
  /// **'استخدم القرآن والأذكار حتى بدون اتصال لأن النصوص ضمن أصول التطبيق.'**
  String get tutorialS12Step1;

  /// No description provided for @tutorialS12Step2.
  ///
  /// In ar, this message translates to:
  /// **'استمر في القراءة والحفظ ليُحفظ التقدم محليًا.'**
  String get tutorialS12Step2;

  /// No description provided for @tutorialS12Step3.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول عندما تحتاج إلى ميزات الحساب أو استعادة الوصول.'**
  String get tutorialS12Step3;

  /// No description provided for @tutorialS12Tip1.
  ///
  /// In ar, this message translates to:
  /// **'افتح التطبيق بعد تغيير الجهاز أو إعادة التثبيت ثم سجّل الدخول لاسترجاع ما يدعمه الحساب.'**
  String get tutorialS12Tip1;

  /// No description provided for @tutorialS12Tip2.
  ///
  /// In ar, this message translates to:
  /// **'حافظ على اتصال جيد عند تشغيل الصوت أو استخدام ميزات الحساب.'**
  String get tutorialS12Tip2;

  /// No description provided for @tutorialS12Note1.
  ///
  /// In ar, this message translates to:
  /// **'حذف بيانات التطبيق من النظام قد يزيل البيانات المحلية غير المتزامنة.'**
  String get tutorialS12Note1;

  /// No description provided for @tutorialS12Note2.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك أو المزايا المدفوعة غير موثقة هنا لأنها غير مفعلة كواجهة مستخدم حالية.'**
  String get tutorialS12Note2;

  /// No description provided for @tutorialCategoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get tutorialCategoryTitle;

  /// No description provided for @tutorialWhatItDoesTitle.
  ///
  /// In ar, this message translates to:
  /// **'ماذا تفعل؟'**
  String get tutorialWhatItDoesTitle;

  /// No description provided for @tutorialHowToOpenTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف أصل إليها؟'**
  String get tutorialHowToOpenTitle;

  /// No description provided for @tutorialStepsTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطوات الاستخدام'**
  String get tutorialStepsTitle;

  /// No description provided for @tutorialTipsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تلميحات'**
  String get tutorialTipsTitle;

  /// No description provided for @tutorialNotesTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات فنية'**
  String get tutorialNotesTitle;

  /// No description provided for @tutorialWhenUsefulTitle.
  ///
  /// In ar, this message translates to:
  /// **'متى تكون مفيدة؟'**
  String get tutorialWhenUsefulTitle;

  /// No description provided for @certificateCelebrationMultiple.
  ///
  /// In ar, this message translates to:
  /// **'لقد حصلت على {count} شهادات جديدة'**
  String certificateCelebrationMultiple(int count);

  /// No description provided for @certificateCelebrationSingle.
  ///
  /// In ar, this message translates to:
  /// **'لقد حصلت على {title}'**
  String certificateCelebrationSingle(String title);

  /// No description provided for @learningAlertReduceNewTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقليل الحفظ الجديد'**
  String get learningAlertReduceNewTitle;

  /// No description provided for @learningAlertReduceNewSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حِملك الدراسي ثقيل، ركز على المراجعة'**
  String get learningAlertReduceNewSubtitle;

  /// No description provided for @learningAlertFocusWeakTitle.
  ///
  /// In ar, this message translates to:
  /// **'ركز على الآيات الصعبة'**
  String get learningAlertFocusWeakTitle;

  /// No description provided for @learningAlertFocusWeakSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لديك آيات صعبة تحتاج مراجعة مكثفة'**
  String get learningAlertFocusWeakSubtitle;

  /// No description provided for @learningAlertGenericTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه تعليمي'**
  String get learningAlertGenericTitle;

  /// No description provided for @learningAlertGenericSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب اتخاذ إجراء'**
  String get learningAlertGenericSubtitle;

  /// No description provided for @reviewBacklogTitle.
  ///
  /// In ar, this message translates to:
  /// **'تراكم المراجعة'**
  String get reviewBacklogTitle;

  /// No description provided for @reviewBacklogSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لديك {overdue} آيات متأخرة'**
  String reviewBacklogSubtitle(String overdue);

  /// No description provided for @smartPlanCustomTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطة مخصصة'**
  String get smartPlanCustomTitle;

  /// No description provided for @smartPlanReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطة المراجعة'**
  String get smartPlanReviewTitle;

  /// No description provided for @smartPlanTodayTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطة اليوم'**
  String get smartPlanTodayTitle;

  /// No description provided for @smartPlanSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أكمل رحلة حفظك'**
  String get smartPlanSubtitle;

  /// No description provided for @dailyWirdTitle.
  ///
  /// In ar, this message translates to:
  /// **'الورد اليومي'**
  String get dailyWirdTitle;

  /// No description provided for @dailyWirdSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ وردك اليومي'**
  String get dailyWirdSubtitle;

  /// No description provided for @exploreAzkarTitle.
  ///
  /// In ar, this message translates to:
  /// **'وقت الذكر'**
  String get exploreAzkarTitle;

  /// No description provided for @exploreAzkarSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ أذكارك اليومية'**
  String get exploreAzkarSubtitle;

  /// No description provided for @exploreMissionTitle.
  ///
  /// In ar, this message translates to:
  /// **'المهمة الحالية'**
  String get exploreMissionTitle;

  /// No description provided for @exploreMissionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ مهمتك الحالية'**
  String get exploreMissionSubtitle;

  /// No description provided for @exploreQuranTitle.
  ///
  /// In ar, this message translates to:
  /// **'القرآن الكريم'**
  String get exploreQuranTitle;

  /// No description provided for @exploreQuranSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ القرآن'**
  String get exploreQuranSubtitle;

  /// No description provided for @parentDashboardLinkHint.
  ///
  /// In ar, this message translates to:
  /// **'talia-kids-link:...'**
  String get parentDashboardLinkHint;

  /// Family dashboard page title
  ///
  /// In ar, this message translates to:
  /// **'لوحة العائلة'**
  String get familyDashboardTitle;

  /// Section label for children grid
  ///
  /// In ar, this message translates to:
  /// **'أطفالي'**
  String get familyDashboardMyChildren;

  /// Add / link a new child button
  ///
  /// In ar, this message translates to:
  /// **'ربط طفل جديد'**
  String get familyDashboardAddChild;

  /// Empty state title
  ///
  /// In ar, this message translates to:
  /// **'لم يتم ربط أي طفل بعد'**
  String get familyDashboardNoChildren;

  /// Empty state hint
  ///
  /// In ar, this message translates to:
  /// **'اطلب من طفلك فتح صفحة الربط في التطبيق لمسح رمز QR'**
  String get familyDashboardNoChildrenHint;

  /// Banner title
  ///
  /// In ar, this message translates to:
  /// **'اليوم في عائلتنا'**
  String get familyDashboardTodaySummaryTitle;

  /// Banner body showing active children and total points
  ///
  /// In ar, this message translates to:
  /// **'{count} نشط اليوم · {points} نقطة'**
  String familyDashboardTodaySummary(int count, int points);

  /// Badge for local (same-device) child
  ///
  /// In ar, this message translates to:
  /// **'على هذا الجهاز'**
  String get familyDashboardLocalBadge;

  /// Points earned today label on child card
  ///
  /// In ar, this message translates to:
  /// **'{points} نقطة اليوم'**
  String familyDashboardChildActiveToday(int points);

  /// No activity today label on child card
  ///
  /// In ar, this message translates to:
  /// **'لا نشاط اليوم'**
  String get familyDashboardChildNoActivity;

  /// Snackbar when nickname is saved
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الاسم'**
  String get familyDashboardNicknameSaved;

  /// Child detail page title
  ///
  /// In ar, this message translates to:
  /// **'تقدم {name}'**
  String childDetailTitle(String name);

  /// Today summary in child detail page
  ///
  /// In ar, this message translates to:
  /// **'{sessions} جلسة · {points} نقطة اليوم'**
  String childDetailTodayActivity(int sessions, int points);

  /// No activity label in child detail
  ///
  /// In ar, this message translates to:
  /// **'لا نشاط اليوم'**
  String get childDetailNoActivity;

  /// Section title for memorization progress
  ///
  /// In ar, this message translates to:
  /// **'تقدم الحفظ'**
  String get childDetailMemorizationProgress;

  /// Section title for recent sessions
  ///
  /// In ar, this message translates to:
  /// **'آخر الجلسات'**
  String get childDetailRecentSessions;

  /// Section title for rewards with count
  ///
  /// In ar, this message translates to:
  /// **'المكافآت ({count})'**
  String childDetailRewards(int count);

  /// Add reward tooltip/button
  ///
  /// In ar, this message translates to:
  /// **'إضافة مكافأة'**
  String get childDetailAddReward;

  /// Button to open full parent dashboard for local child
  ///
  /// In ar, this message translates to:
  /// **'فتح لوحة التحكم الكاملة'**
  String get childDetailOpenFullDashboard;

  /// No description provided for @kidsPreparing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحضير...'**
  String get kidsPreparing;

  /// No description provided for @kidsUnexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'يبدو أن شيئًا ما حدث!'**
  String get kidsUnexpectedError;

  /// No description provided for @v2LearningTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعلّم الآية'**
  String get v2LearningTitle;

  /// No description provided for @v2LearningSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'استمع واقرأ الآية بهدوء قبل محاولة حفظها.'**
  String get v2LearningSubtitle;

  /// No description provided for @v2StartMemorizing.
  ///
  /// In ar, this message translates to:
  /// **'انتقل للحفظ'**
  String get v2StartMemorizing;

  /// No description provided for @v2MemorizingTitle.
  ///
  /// In ar, this message translates to:
  /// **'احفظ الآية'**
  String get v2MemorizingTitle;

  /// No description provided for @v2MemorizingSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'درّب ذاكرتك. التلميحات متاحة هنا فقط.'**
  String get v2MemorizingSubtitle;

  /// No description provided for @v2ReadyToRecite.
  ///
  /// In ar, this message translates to:
  /// **'أنا جاهز للتسميع'**
  String get v2ReadyToRecite;

  /// No description provided for @v2FirstWordHint.
  ///
  /// In ar, this message translates to:
  /// **'أول كلمة'**
  String get v2FirstWordHint;

  /// No description provided for @v2ShowAyahHint.
  ///
  /// In ar, this message translates to:
  /// **'إظهار الآية'**
  String get v2ShowAyahHint;

  /// No description provided for @v2RecitationTitle.
  ///
  /// In ar, this message translates to:
  /// **'سمّع من حفظك'**
  String get v2RecitationTitle;

  /// No description provided for @v2RecitationSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'النص مخفي الآن. سجّل تسميعك بدون تلميحات.'**
  String get v2RecitationSubtitle;

  /// No description provided for @v2StartRecording.
  ///
  /// In ar, this message translates to:
  /// **'بدء التسجيل'**
  String get v2StartRecording;

  /// No description provided for @v2StopRecording.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التسجيل'**
  String get v2StopRecording;

  /// No description provided for @v2ManualRecallAction.
  ///
  /// In ar, this message translates to:
  /// **'أتممت التسميع من حفظي (تقييم ذاتي)'**
  String get v2ManualRecallAction;

  /// No description provided for @v2ManualRecallHint.
  ///
  /// In ar, this message translates to:
  /// **'لا يتوفر الميكروفون؟ أكّد أنك تسمّعت من حفظك وسيُسجَّل التقدم.'**
  String get v2ManualRecallHint;

  /// No description provided for @v2ManualBlockReviewAction.
  ///
  /// In ar, this message translates to:
  /// **'أتممت مراجعة الكتلة من حفظي (تقييم ذاتي)'**
  String get v2ManualBlockReviewAction;

  /// No description provided for @v2RemediationTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة قصيرة'**
  String get v2RemediationTitle;

  /// No description provided for @v2RemediationSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'استمع واقرأ الآية مرة أخرى، ثم ارجع لمحاولة التسميع.'**
  String get v2RemediationSubtitle;

  /// No description provided for @v2TryAgain.
  ///
  /// In ar, this message translates to:
  /// **'أحاول مرة أخرى'**
  String get v2TryAgain;

  /// No description provided for @v2BlockReviewPendingTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة المقطع'**
  String get v2BlockReviewPendingTitle;

  /// No description provided for @v2BlockReviewPendingSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أنهيت الآيات منفردة. الخطوة التالية تسميع المقطع كاملاً من الذاكرة.'**
  String get v2BlockReviewPendingSubtitle;

  /// No description provided for @v2StartBlockReview.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ مراجعة المقطع'**
  String get v2StartBlockReview;

  /// No description provided for @v2BlockReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'سمّع المقطع كاملاً'**
  String get v2BlockReviewTitle;

  /// No description provided for @v2BlockReviewSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'النص مخفي الآن. سجّل الآيات {startAyah}-{endAyah} كاملة بدون تلميحات.'**
  String v2BlockReviewSubtitle(int startAyah, int endAyah);

  /// No description provided for @v2CompletionTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت الجلسة'**
  String get v2CompletionTitle;

  /// No description provided for @v2CompletionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ آيات هذا المقطع بنجاح.'**
  String get v2CompletionSubtitle;

  /// No description provided for @v2MemorizationHub.
  ///
  /// In ar, this message translates to:
  /// **'مركز الحفظ'**
  String get v2MemorizationHub;

  /// No description provided for @v2TryWithoutHint.
  ///
  /// In ar, this message translates to:
  /// **'حاول من غير تلميح'**
  String get v2TryWithoutHint;

  /// No description provided for @v2FirstWordRevealed.
  ///
  /// In ar, this message translates to:
  /// **'تم كشف أول كلمة'**
  String get v2FirstWordRevealed;

  /// No description provided for @v2Evaluating.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التقييم...'**
  String get v2Evaluating;

  /// No description provided for @v2RecordingNow.
  ///
  /// In ar, this message translates to:
  /// **'يتم التسجيل الآن'**
  String get v2RecordingNow;

  /// No description provided for @v2PressRecord.
  ///
  /// In ar, this message translates to:
  /// **'اضغط التسجيل عندما تكون جاهزًا'**
  String get v2PressRecord;

  /// No description provided for @v2MicrophoneUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذر استخدام الميكروفون'**
  String get v2MicrophoneUnavailable;

  /// No description provided for @v2NoSpeechDetected.
  ///
  /// In ar, this message translates to:
  /// **'لم نسمع تلاوة. سجّل مرة أخرى.'**
  String get v2NoSpeechDetected;

  /// No description provided for @v2MicrophonePermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'يلزم السماح بالميكروفون للتسجيل.'**
  String get v2MicrophonePermissionDenied;

  /// No description provided for @v2MicrophoneOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'الوصول للميكروفون محظور. افتح الإعدادات للسماح به.'**
  String get v2MicrophoneOpenSettings;

  /// No description provided for @v2AudioPlaybackFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تشغيل صوت الآية. حاول مرة أخرى.'**
  String get v2AudioPlaybackFailed;

  /// No description provided for @v2RemediationAttempts.
  ///
  /// In ar, this message translates to:
  /// **'عدد المحاولات التي تحتاج مراجعة: {count}'**
  String v2RemediationAttempts(int count);

  /// No description provided for @v2AyahRange.
  ///
  /// In ar, this message translates to:
  /// **'الآيات {startAyah}-{endAyah}'**
  String v2AyahRange(int startAyah, int endAyah);

  /// No description provided for @v2BlockProgress.
  ///
  /// In ar, this message translates to:
  /// **'تم اجتياز {passed}/{total} آيات.'**
  String v2BlockProgress(int passed, int total);

  /// No description provided for @v2EvaluatingBlock.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تقييم المقطع...'**
  String get v2EvaluatingBlock;

  /// No description provided for @v2RecordingBlock.
  ///
  /// In ar, this message translates to:
  /// **'يتم تسجيل المقطع الآن'**
  String get v2RecordingBlock;

  /// No description provided for @v2Playing.
  ///
  /// In ar, this message translates to:
  /// **'يتم التشغيل'**
  String get v2Playing;

  /// No description provided for @v2ListenToAyah.
  ///
  /// In ar, this message translates to:
  /// **'استمع للآية'**
  String get v2ListenToAyah;

  /// No description provided for @v2Passed.
  ///
  /// In ar, this message translates to:
  /// **'تم تسميعها'**
  String get v2Passed;

  /// No description provided for @v2Retries.
  ///
  /// In ar, this message translates to:
  /// **'محاولات'**
  String get v2Retries;

  /// No description provided for @v2SurahLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات السورة.'**
  String get v2SurahLoadFailed;

  /// No description provided for @v2NoAyahsInRange.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد آيات في النطاق المحدد.'**
  String get v2NoAyahsInRange;

  /// No description provided for @kidsRecordingUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'لم يعمل الميكروفون الآن. جرّب مرة أخرى أو اطلب مساعدة ولي الأمر.'**
  String get kidsRecordingUnavailable;

  /// No description provided for @kidsRecordingNotCaptured.
  ///
  /// In ar, this message translates to:
  /// **'لم نسمع تلاوتك بوضوح. اضغط وسجّل الآية مرة أخرى.'**
  String get kidsRecordingNotCaptured;

  /// No description provided for @kidsRecitationMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الآية لم تتطابق. استمع للآية مرة أخرى ثم سجّل تلاوتك.'**
  String get kidsRecitationMismatch;

  /// No description provided for @kidsAyahAlreadyCompleted.
  ///
  /// In ar, this message translates to:
  /// **'أكملت هذه الآية من قبل. ارجع للخريطة للمتابعة.'**
  String get kidsAyahAlreadyCompleted;

  /// No description provided for @accountSwitchOfflineDataDiscarded.
  ///
  /// In ar, this message translates to:
  /// **'تعذر رفع التقدم غير المتزامن للحساب السابق، لذا تمت إزالته من هذا الجهاز.'**
  String get accountSwitchOfflineDataDiscarded;

  /// No description provided for @startYourJourneyWithQuran.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ رحلتك مع القرآن'**
  String get startYourJourneyWithQuran;

  /// No description provided for @startNow.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get startNow;

  /// No description provided for @kidsJourneyBetaTitle.
  ///
  /// In ar, this message translates to:
  /// **'رحلة الحفظ الجديدة'**
  String get kidsJourneyBetaTitle;

  /// No description provided for @kidsJourneyBetaDescription.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل مهمة اليوم والمراجعة المتباعدة مع إمكانية الرجوع.'**
  String get kidsJourneyBetaDescription;

  /// No description provided for @kidsGuidanceAudioTitle.
  ///
  /// In ar, this message translates to:
  /// **'صوت المرشد'**
  String get kidsGuidanceAudioTitle;

  /// No description provided for @kidsGuidanceAudioDescription.
  ///
  /// In ar, this message translates to:
  /// **'إرشادات قصيرة لا تعمل أثناء تلاوة القرآن.'**
  String get kidsGuidanceAudioDescription;

  /// No description provided for @kidsSessionGoalTitle.
  ///
  /// In ar, this message translates to:
  /// **'مدة الجلسة المستهدفة'**
  String get kidsSessionGoalTitle;

  /// No description provided for @kidsSessionGoalValue.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقائق'**
  String kidsSessionGoalValue(int minutes);

  /// No description provided for @kidsSetupReminderTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت التذكير'**
  String get kidsSetupReminderTime;

  /// No description provided for @kidsSetupWeeklyGoal.
  ///
  /// In ar, this message translates to:
  /// **'الهدف الأسبوعي'**
  String get kidsSetupWeeklyGoal;

  /// No description provided for @kidsSetupWeeklyGoalValue.
  ///
  /// In ar, this message translates to:
  /// **'{sessions} جلسات أسبوعياً'**
  String kidsSetupWeeklyGoalValue(int sessions);

  /// No description provided for @kidsSetupStartingSurah.
  ///
  /// In ar, this message translates to:
  /// **'سورة البداية'**
  String get kidsSetupStartingSurah;

  /// No description provided for @parentCommitmentDays.
  ///
  /// In ar, this message translates to:
  /// **'{count} أيام التزام'**
  String parentCommitmentDays(int count);

  /// No description provided for @parentDueReviews.
  ///
  /// In ar, this message translates to:
  /// **'{count} مراجعات مستحقة'**
  String parentDueReviews(int count);

  /// No description provided for @parentNeedsSupport.
  ///
  /// In ar, this message translates to:
  /// **'{count} آيات تحتاج دعمًا'**
  String parentNeedsSupport(int count);

  /// No description provided for @parentAverageDuration.
  ///
  /// In ar, this message translates to:
  /// **'متوسط {minutes} د'**
  String parentAverageDuration(int minutes);

  /// No description provided for @parentHintUses.
  ///
  /// In ar, this message translates to:
  /// **'{count} تلميحات'**
  String parentHintUses(int count);

  /// No description provided for @khatmahStartAction.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ ختمة'**
  String get khatmahStartAction;

  /// No description provided for @khatmahResumeAction.
  ///
  /// In ar, this message translates to:
  /// **'استئناف'**
  String get khatmahResumeAction;

  /// No description provided for @khatmahNoPlanTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ختمة حالية'**
  String get khatmahNoPlanTitle;

  /// No description provided for @khatmahNoPlanDescription.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ ختمة جديدة بالوتيرة التي تناسبك.'**
  String get khatmahNoPlanDescription;

  /// No description provided for @khatmahPausedSummary.
  ///
  /// In ar, this message translates to:
  /// **'الختمة متوقفة مؤقتاً — استأنف للمتابعة'**
  String get khatmahPausedSummary;

  /// No description provided for @khatmahExistingActivePlan.
  ///
  /// In ar, this message translates to:
  /// **'لديك ختمة نشطة بالفعل'**
  String get khatmahExistingActivePlan;

  /// No description provided for @khatmahExistingPausedPlan.
  ///
  /// In ar, this message translates to:
  /// **'لديك ختمة متوقفة مؤقتاً بالفعل'**
  String get khatmahExistingPausedPlan;

  /// No description provided for @khatmahViewCurrentPlan.
  ///
  /// In ar, this message translates to:
  /// **'عرض الختمة الحالية'**
  String get khatmahViewCurrentPlan;

  /// No description provided for @khatmahEndCurrentPlan.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الختمة الحالية'**
  String get khatmahEndCurrentPlan;

  /// No description provided for @khatmahEndCurrentConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الختمة الحالية؟'**
  String get khatmahEndCurrentConfirmTitle;

  /// No description provided for @khatmahEndCurrentConfirmDescription.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف خطة \"{title}\". بعد ذلك يمكنك اختيار بدء خطة جديدة.'**
  String khatmahEndCurrentConfirmDescription(String title);

  /// No description provided for @khatmahEndPlanAction.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الختمة'**
  String get khatmahEndPlanAction;

  /// No description provided for @khatmahStartNewKhatmah.
  ///
  /// In ar, this message translates to:
  /// **'بدء ختمة جديدة'**
  String get khatmahStartNewKhatmah;

  /// No description provided for @khatmahChooseYourDailyReadingPaceToCompleteThe.
  ///
  /// In ar, this message translates to:
  /// **'اختر خطتك اليومية المناسبة لقراءة القرآن الكريم بهدوء وسكينة'**
  String get khatmahChooseYourDailyReadingPaceToCompleteThe;

  /// No description provided for @khatmahDailyPages.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات اليومية'**
  String get khatmahDailyPages;

  /// No description provided for @khatmahPages.
  ///
  /// In ar, this message translates to:
  /// **'{v1} صفحات'**
  String khatmahPages(String v1);

  /// No description provided for @khatmahOrCustomPagesPerDay.
  ///
  /// In ar, this message translates to:
  /// **'أو عدد مخصص يومياً'**
  String get khatmahOrCustomPagesPerDay;

  /// No description provided for @khatmahEG5.
  ///
  /// In ar, this message translates to:
  /// **'مثال: 5'**
  String get khatmahEG5;

  /// No description provided for @khatmahEstimatedDuration.
  ///
  /// In ar, this message translates to:
  /// **'المدة التقديرية'**
  String get khatmahEstimatedDuration;

  /// No description provided for @khatmahDays.
  ///
  /// In ar, this message translates to:
  /// **'{v1} يوم'**
  String khatmahDays(String v1);

  /// No description provided for @khatmahExpectedCompletion.
  ///
  /// In ar, this message translates to:
  /// **'موعد الختام المتوقع'**
  String get khatmahExpectedCompletion;

  /// No description provided for @khatmahStartKhatmah.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الختمة'**
  String get khatmahStartKhatmah;

  /// No description provided for @khatmahPhysicalMushafProgressSavedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل القراءة بنجاح'**
  String get khatmahPhysicalMushafProgressSavedSuccessfully;

  /// No description provided for @khatmahEndKhatmah.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء الختمة'**
  String get khatmahEndKhatmah;

  /// No description provided for @khatmahAreYouSureYouWantToEndThis.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في إنهاء هذه الختمة؟ يمكنك دائماً البدء من جديد بهدوء وبدون أي حرج.'**
  String get khatmahAreYouSureYouWantToEndThis;

  /// No description provided for @khatmahCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get khatmahCancel;

  /// No description provided for @khatmahUnableToSaveKhatmahProgress.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ تقدم الختمة.'**
  String get khatmahUnableToSaveKhatmahProgress;

  /// No description provided for @khatmahRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get khatmahRetry;

  /// No description provided for @khatmahLiving.
  ///
  /// In ar, this message translates to:
  /// **'حي'**
  String get khatmahLiving;

  /// No description provided for @khatmahDeceased.
  ///
  /// In ar, this message translates to:
  /// **'متوفى'**
  String get khatmahDeceased;

  /// No description provided for @khatmahDedicatedTo.
  ///
  /// In ar, this message translates to:
  /// **'إهداء إلى: {v1}'**
  String khatmahDedicatedTo(String v1);

  /// No description provided for @khatmahKhatmahDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الختمة'**
  String get khatmahKhatmahDashboard;

  /// No description provided for @khatmahUnableToLoadYourKhatmah.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الختمة'**
  String get khatmahUnableToLoadYourKhatmah;

  /// No description provided for @khatmahCheckYourConnectionAndTryAgain.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الاتصال وحاول مرة أخرى.'**
  String get khatmahCheckYourConnectionAndTryAgain;

  /// No description provided for @khatmahReload.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get khatmahReload;

  /// No description provided for @khatmahQuranKhatmah.
  ///
  /// In ar, this message translates to:
  /// **'ختمة القرآن الكريم'**
  String get khatmahQuranKhatmah;

  /// No description provided for @khatmahTodaySWirdCompleted.
  ///
  /// In ar, this message translates to:
  /// **'أتممت ورد اليوم'**
  String get khatmahTodaySWirdCompleted;

  /// No description provided for @khatmahTodaySWird.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم'**
  String get khatmahTodaySWird;

  /// No description provided for @khatmahPagesTo.
  ///
  /// In ar, this message translates to:
  /// **'من صفحة {v1} إلى صفحة {v2}'**
  String khatmahPagesTo(String v1, String v2);

  /// No description provided for @khatmahResuming.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الاستئناف'**
  String get khatmahResuming;

  /// No description provided for @khatmahContinueReading.
  ///
  /// In ar, this message translates to:
  /// **'متابعة القراءة'**
  String get khatmahContinueReading;

  /// No description provided for @khatmahReadFromPhysicalMushaf.
  ///
  /// In ar, this message translates to:
  /// **'قرأت من المصحف الورقي؟'**
  String get khatmahReadFromPhysicalMushaf;

  /// No description provided for @khatmahLog.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل'**
  String get khatmahLog;

  /// No description provided for @khatmahCalmAdaptiveControls.
  ///
  /// In ar, this message translates to:
  /// **'خيارات التكيّف الهادئ'**
  String get khatmahCalmAdaptiveControls;

  /// No description provided for @khatmahEndDateRecalibratedSmoothly.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة ضبط موعد الختام بهدوء وسكينة'**
  String get khatmahEndDateRecalibratedSmoothly;

  /// No description provided for @khatmahCalmAdjust.
  ///
  /// In ar, this message translates to:
  /// **'تعديل هادئ'**
  String get khatmahCalmAdjust;

  /// No description provided for @khatmahAdded1PageDayMildCompensation.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة صفحة يومياً للتعويض الخفيف'**
  String get khatmahAdded1PageDayMildCompensation;

  /// No description provided for @khatmahMildBoost.
  ///
  /// In ar, this message translates to:
  /// **'تعويض خفيف'**
  String get khatmahMildBoost;

  /// No description provided for @khatmahPause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get khatmahPause;

  /// No description provided for @khatmahResume.
  ///
  /// In ar, this message translates to:
  /// **'استئناف'**
  String get khatmahResume;

  /// No description provided for @khatmahLogPhysicalMushafReading.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل قراءة من المصحف'**
  String get khatmahLogPhysicalMushafReading;

  /// No description provided for @khatmahEnterTheLastPageReadFromYourPhysical.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم آخر صفحة قرأتها من المصحف الورقي (1 - 604):'**
  String get khatmahEnterTheLastPageReadFromYourPhysical;

  /// No description provided for @khatmahPageNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الصفحة'**
  String get khatmahPageNumber;

  /// No description provided for @khatmahEG.
  ///
  /// In ar, this message translates to:
  /// **'مثال: {v1}'**
  String khatmahEG(String v1);

  /// No description provided for @khatmahSaveProgress.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التقدم'**
  String get khatmahSaveProgress;

  /// No description provided for @khatmahNoSavedCompletionAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ختمة مكتملة محفوظة'**
  String get khatmahNoSavedCompletionAvailable;

  /// No description provided for @khatmahPagesLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات'**
  String get khatmahPagesLabel;

  /// No description provided for @khatmahDuration.
  ///
  /// In ar, this message translates to:
  /// **'المدة'**
  String get khatmahDuration;

  /// No description provided for @khatmahCompleted.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الختام'**
  String get khatmahCompleted;

  /// No description provided for @khatmahDedicationOfReward.
  ///
  /// In ar, this message translates to:
  /// **'إهداء ثواب الختمة'**
  String get khatmahDedicationOfReward;

  /// No description provided for @khatmahReadDuAKhatmAlQuran.
  ///
  /// In ar, this message translates to:
  /// **'قراءة دعاء ختم القرآن'**
  String get khatmahReadDuAKhatmAlQuran;

  /// No description provided for @khatmahShareAchievement.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الإنجاز'**
  String get khatmahShareAchievement;

  /// No description provided for @khatmahBackToHome.
  ///
  /// In ar, this message translates to:
  /// **'العودة للرئيسية'**
  String get khatmahBackToHome;

  /// No description provided for @khatmahDuACopiedToClipboard.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الدعاء بنجاح'**
  String get khatmahDuACopiedToClipboard;

  /// No description provided for @khatmahDuAKhatmAlQuran.
  ///
  /// In ar, this message translates to:
  /// **'دعاء ختم القرآن'**
  String get khatmahDuAKhatmAlQuran;

  /// No description provided for @khatmahDecreaseFontSize.
  ///
  /// In ar, this message translates to:
  /// **'تصغير الخط'**
  String get khatmahDecreaseFontSize;

  /// No description provided for @khatmahIncreaseFontSize.
  ///
  /// In ar, this message translates to:
  /// **'تكبير الخط'**
  String get khatmahIncreaseFontSize;

  /// No description provided for @khatmahCopyDuA.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الدعاء'**
  String get khatmahCopyDuA;

  /// No description provided for @khatmahPagesLeft.
  ///
  /// In ar, this message translates to:
  /// **'{v1} صفحة متبقية'**
  String khatmahPagesLeft(String v1);

  /// No description provided for @khatmahEstCompletion.
  ///
  /// In ar, this message translates to:
  /// **'الختام المتوقع: {v1}'**
  String khatmahEstCompletion(String v1);

  /// No description provided for @khatmahDedicateKhatmahToSomeone.
  ///
  /// In ar, this message translates to:
  /// **'إهداء الختمة لشخص عزيز'**
  String get khatmahDedicateKhatmahToSomeone;

  /// No description provided for @khatmahRecipientName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المهدى له'**
  String get khatmahRecipientName;

  /// No description provided for @khatmahEGMyBelovedMother.
  ///
  /// In ar, this message translates to:
  /// **'مثال: والدتي الغالية'**
  String get khatmahEGMyBelovedMother;

  /// No description provided for @khatmahRelationship.
  ///
  /// In ar, this message translates to:
  /// **'صلة القرابة'**
  String get khatmahRelationship;

  /// No description provided for @khatmahCondition.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get khatmahCondition;

  /// No description provided for @khatmahSickRecovery.
  ///
  /// In ar, this message translates to:
  /// **'مريض'**
  String get khatmahSickRecovery;

  /// No description provided for @khatmahSpecialNoteDuAOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة أو دعاء خاص (اختياري)'**
  String get khatmahSpecialNoteDuAOptional;

  /// No description provided for @khatmahPageOfOfTodaySWird.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {v1} ({v2} من {v3} من ورد اليوم)'**
  String khatmahPageOfOfTodaySWird(String v1, String v2, String v3);

  /// No description provided for @khatmahSaveExit.
  ///
  /// In ar, this message translates to:
  /// **'حفظ وخروج'**
  String get khatmahSaveExit;

  /// No description provided for @khatmahCongratulations.
  ///
  /// In ar, this message translates to:
  /// **'مبارك ختم القرآن الكريم'**
  String get khatmahCongratulations;

  /// No description provided for @khatmahShareSummary.
  ///
  /// In ar, this message translates to:
  /// **'أتممت ختمة القرآن الكريم ({title}) في {days} يوماً.\nعبر تطبيق تالية القرآني'**
  String khatmahShareSummary(String title, String days);

  /// No description provided for @khatmahUserNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة شخصية كتبتها: {note}'**
  String khatmahUserNote(String note);

  /// No description provided for @khatmahTodayRange.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم: الصفحات {start} - {end}{completed}'**
  String khatmahTodayRange(String start, String end, String completed);

  /// No description provided for @khatmahDailyCompletedSuffix.
  ///
  /// In ar, this message translates to:
  /// **' — مكتمل'**
  String get khatmahDailyCompletedSuffix;

  /// No description provided for @khatmahProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدم الختمة'**
  String get khatmahProgress;

  /// No description provided for @khatmahProgressValue.
  ///
  /// In ar, this message translates to:
  /// **'{completed} من {total} صفحة، {percent} بالمئة'**
  String khatmahProgressValue(String completed, String total, String percent);

  /// No description provided for @khatmahSetupSaveError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر بدء الختمة. حاول مرة أخرى.'**
  String get khatmahSetupSaveError;

  /// No description provided for @khatmahEndError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إنهاء الختمة. حاول مرة أخرى.'**
  String get khatmahEndError;

  /// No description provided for @khatmahDedicationPreference.
  ///
  /// In ar, this message translates to:
  /// **'إهداء الختمة متاح للحي والمتوفى، والمتوفى أولى؛ وفق مراجعة شرعية نقلها صاحب التطبيق.'**
  String get khatmahDedicationPreference;

  /// No description provided for @khatmahWriteYourOwnNote.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ملاحظتك الشخصية هنا'**
  String get khatmahWriteYourOwnNote;

  /// No description provided for @khatmahPhysicalRangeHint.
  ///
  /// In ar, this message translates to:
  /// **'سجّل نطاق الصفحات الذي قرأته من الصفحة التالية غير المقروءة.'**
  String get khatmahPhysicalRangeHint;

  /// No description provided for @khatmahConfirmRange.
  ///
  /// In ar, this message translates to:
  /// **'سيتم تسجيل الصفحات من {start} إلى {end} شاملة الطرفين.'**
  String khatmahConfirmRange(String start, String end);

  /// No description provided for @khatmahRangeValidation.
  ///
  /// In ar, this message translates to:
  /// **'أدخل صفحة من {start} إلى ٦٠٤ لتأكيد النطاق.'**
  String khatmahRangeValidation(String start);

  /// No description provided for @khatmahIsPaused.
  ///
  /// In ar, this message translates to:
  /// **'الختمة متوقفة مؤقتاً'**
  String get khatmahIsPaused;

  /// No description provided for @khatmahProgressNotSaved.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم حفظ التقدم'**
  String get khatmahProgressNotSaved;

  /// No description provided for @khatmahSaving.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الحفظ…'**
  String get khatmahSaving;

  /// No description provided for @khatmahDuaLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الدعاء. حاول مرة أخرى.'**
  String get khatmahDuaLoadError;

  /// No description provided for @khatmahSuggestedDua.
  ///
  /// In ar, this message translates to:
  /// **'دعاء عام مقترح بعد الختم'**
  String get khatmahSuggestedDua;

  /// No description provided for @khatmahDuaPendingReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة النص والمصدر معلّقة. هذا دعاء عام مقترح، وليس صيغة مخصوصة لازمة للختم أو منسوبة للنبي ﷺ. لم يوثّق مصدر هذا النص بعد.'**
  String get khatmahDuaPendingReview;

  /// No description provided for @khatmahGeneralGuidance.
  ///
  /// In ar, this message translates to:
  /// **'دعاء عام'**
  String get khatmahGeneralGuidance;

  /// No description provided for @khatmahRelationshipParent.
  ///
  /// In ar, this message translates to:
  /// **'والد / والدة'**
  String get khatmahRelationshipParent;

  /// No description provided for @khatmahRelationshipMother.
  ///
  /// In ar, this message translates to:
  /// **'الأم'**
  String get khatmahRelationshipMother;

  /// No description provided for @khatmahRelationshipFather.
  ///
  /// In ar, this message translates to:
  /// **'الأب'**
  String get khatmahRelationshipFather;

  /// No description provided for @khatmahRelationshipFriend.
  ///
  /// In ar, this message translates to:
  /// **'صديق'**
  String get khatmahRelationshipFriend;

  /// No description provided for @khatmahRelationshipRelative.
  ///
  /// In ar, this message translates to:
  /// **'قريب'**
  String get khatmahRelationshipRelative;

  /// No description provided for @khatmahRelationshipOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get khatmahRelationshipOther;

  /// No description provided for @khatmahRecentCompletions.
  ///
  /// In ar, this message translates to:
  /// **'الختمات المكتملة حديثاً'**
  String get khatmahRecentCompletions;

  /// No description provided for @khatmahHistoryEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد شهادات ختمة محفوظة بعد.'**
  String get khatmahHistoryEmpty;

  /// No description provided for @khatmahHistoryLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل شهادات الختمة المحفوظة. حاول مرة أخرى.'**
  String get khatmahHistoryLoadError;

  /// No description provided for @khatmahHistoryCorrupt.
  ///
  /// In ar, this message translates to:
  /// **'بعض شهادات الختمة المحفوظة غير صالحة وتم حجبها. حاول مرة أخرى بعد استعادة بياناتك.'**
  String get khatmahHistoryCorrupt;

  /// No description provided for @khatmahReopenCertificate.
  ///
  /// In ar, this message translates to:
  /// **'فتح الشهادة مجدداً'**
  String get khatmahReopenCertificate;

  /// No description provided for @khatmahCompletedOn.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت في {date}'**
  String khatmahCompletedOn(String date);
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
