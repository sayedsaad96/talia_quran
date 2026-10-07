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

  /// No description provided for @playPageRecitation.
  ///
  /// In ar, this message translates to:
  /// **'تلاوة الصفحة'**
  String get playPageRecitation;

  /// No description provided for @pauseRecitation.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التلاوة مؤقتاً'**
  String get pauseRecitation;

  /// No description provided for @stopRecitation.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التلاوة'**
  String get stopRecitation;

  /// No description provided for @changeReciter.
  ///
  /// In ar, this message translates to:
  /// **'تغيير القارئ'**
  String get changeReciter;

  /// No description provided for @closePlayer.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق المشغل'**
  String get closePlayer;

  /// No description provided for @moreOptions.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get moreOptions;

  /// No description provided for @reciterActiveChip.
  ///
  /// In ar, this message translates to:
  /// **'المحدد'**
  String get reciterActiveChip;

  /// No description provided for @emptyBookmarksTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد علامات مرجعية بعد'**
  String get emptyBookmarksTitle;

  /// No description provided for @emptyBookmarksHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطوّلاً على أي آية أثناء القراءة لحفظها كعلامة مرجعية وتصل إليها بسهولة هنا'**
  String get emptyBookmarksHint;

  /// No description provided for @exitDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'التلاوة قيد التشغيل'**
  String get exitDialogTitle;

  /// No description provided for @exitDialogBody.
  ///
  /// In ar, this message translates to:
  /// **'تستمع الآن إلى {surah}.\nهل تود استمرار الاستماع في الخلفية مع التحكم من شريط الإشعارات، أم إيقاف التلاوة والخروج؟'**
  String exitDialogBody(String surah);

  /// No description provided for @currentSurah.
  ///
  /// In ar, this message translates to:
  /// **'السورة الحالية'**
  String get currentSurah;

  /// No description provided for @exitDialogContinueBackground.
  ///
  /// In ar, this message translates to:
  /// **'متابعة في الخلفية'**
  String get exitDialogContinueBackground;

  /// No description provided for @exitDialogStopAndExit.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التلاوة والخروج'**
  String get exitDialogStopAndExit;

  /// No description provided for @exitDialogStayInApp.
  ///
  /// In ar, this message translates to:
  /// **'البقاء في التطبيق'**
  String get exitDialogStayInApp;

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
  String celebrationAyah(String xp);

  /// No description provided for @celebrationPage.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت الصفحة! +{xp} XP 🎯'**
  String celebrationPage(String xp);

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
  /// **'٪١٠ من القرآن'**
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

  /// No description provided for @readerGoToPage.
  ///
  /// In ar, this message translates to:
  /// **'انتقل إلى صفحة أو سورة أو جزء'**
  String get readerGoToPage;

  /// No description provided for @readerTajweedColors.
  ///
  /// In ar, this message translates to:
  /// **'ألوان التجويد'**
  String get readerTajweedColors;

  /// No description provided for @readerTajweedColorsHint.
  ///
  /// In ar, this message translates to:
  /// **'تلوين أحكام التجويد في صفحة المصحف'**
  String get readerTajweedColorsHint;

  /// No description provided for @surahInProgressBadge.
  ///
  /// In ar, this message translates to:
  /// **'قيد الحفظ'**
  String get surahInProgressBadge;

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
  String azkarCountOfTotal(String total);

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
  /// **'اكتشف تطبيق تالية للقرآن الكريم 📖✨\nرفيقك الذكي في رحلة الحفظ والتلاوة\nحمّله الآن: https://play.google.com/store/apps/details?id=com.talia.quran'**
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

  /// No description provided for @pureBlackTheme.
  ///
  /// In ar, this message translates to:
  /// **'أسود كامل (OLED)'**
  String get pureBlackTheme;

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

  /// No description provided for @dailyAyahReminder.
  ///
  /// In ar, this message translates to:
  /// **'آية اليوم'**
  String get dailyAyahReminder;

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
  /// **'٦ أحرف على الأقل'**
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
  /// **'هل تريد تسجيل الخروج؟ يعود تقدم حسابك عند تسجيل الدخول مجددًا، أما خطة الختمة وسجل الختمات فمحفوظان على هذا الجهاز فقط وسيُحذفان عند تسجيل الخروج.'**
  String get signOutWarning;

  /// No description provided for @memorizationHubNothingToReview.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد آيات للمراجعة بعد. ابدأ الحفظ أولًا، وستظهر آياتك هنا عندما يحين موعد مراجعتها.'**
  String get memorizationHubNothingToReview;

  /// No description provided for @homeQuranMemorizedCaption.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ من القرآن'**
  String get homeQuranMemorizedCaption;

  /// No description provided for @kidsSetupDiscardTitle.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل إعداد الطفل؟'**
  String get kidsSetupDiscardTitle;

  /// No description provided for @kidsSetupDiscardBody.
  ///
  /// In ar, this message translates to:
  /// **'لم يُحفظ إعداد مسار الأطفال بعد. هل تريد الخروج دون حفظ؟'**
  String get kidsSetupDiscardBody;

  /// No description provided for @kidsSetupKeepEditing.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الإعداد'**
  String get kidsSetupKeepEditing;

  /// No description provided for @kidsSetupDiscard.
  ///
  /// In ar, this message translates to:
  /// **'خروج دون حفظ'**
  String get kidsSetupDiscard;

  /// No description provided for @listeningReviewStartMemorizing.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الحفظ'**
  String get listeningReviewStartMemorizing;

  /// No description provided for @customPlanChildSwitchTitle.
  ///
  /// In ar, this message translates to:
  /// **'الانتقال إلى مسار الأطفال؟'**
  String get customPlanChildSwitchTitle;

  /// No description provided for @customPlanChildSwitchBody.
  ///
  /// In ar, this message translates to:
  /// **'خطط الأطفال تُدار من مسار الأطفال. سيُنهى مسار الكبار وخطتك الحالية، وتبقى إنجازاتك وسجلك وشهاداتك، ثم يُفتح إعداد مسار الأطفال.'**
  String get customPlanChildSwitchBody;

  /// No description provided for @customPlanChildSwitchConfirm.
  ///
  /// In ar, this message translates to:
  /// **'انتقل إلى مسار الأطفال'**
  String get customPlanChildSwitchConfirm;

  /// No description provided for @guestImportTitle.
  ///
  /// In ar, this message translates to:
  /// **'نقل بيانات الحفظ المحلية؟'**
  String get guestImportTitle;

  /// No description provided for @guestImportBody.
  ///
  /// In ar, this message translates to:
  /// **'لديك بيانات حفظ أنشأتها قبل تسجيل الدخول. انقلها إلى هذا الحساب حتى تظهر في تقدمك ومراجعاتك.'**
  String get guestImportBody;

  /// No description provided for @guestImportConfirm.
  ///
  /// In ar, this message translates to:
  /// **'نقل'**
  String get guestImportConfirm;

  /// No description provided for @guestImportLater.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get guestImportLater;

  /// No description provided for @guestImportDone.
  ///
  /// In ar, this message translates to:
  /// **'تم نقل {countText} من سجلات الحفظ.'**
  String guestImportDone(String countText);

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

  /// No description provided for @tutorialGuideHeroSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مركز المعرفة وشرح مزايا تالية'**
  String get tutorialGuideHeroSubtitle;

  /// No description provided for @tutorialGuideTopicsCount.
  ///
  /// In ar, this message translates to:
  /// **'المواضيع: {count}'**
  String tutorialGuideTopicsCount(String count);

  /// No description provided for @tutorialGuideTipsCount.
  ///
  /// In ar, this message translates to:
  /// **'النصائح والشروح: {count}'**
  String tutorialGuideTipsCount(String count);

  /// No description provided for @tutorialGuideSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن ميزة أو خطوة استخدام...'**
  String get tutorialGuideSearchHint;

  /// No description provided for @tutorialGuideNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get tutorialGuideNoResults;

  /// No description provided for @tutorialGuideNoResultsHint.
  ///
  /// In ar, this message translates to:
  /// **'جرّب كلمة أقصر مثل: القرآن، الحفظ، الأذكار، الإشعارات.'**
  String get tutorialGuideNoResultsHint;

  /// No description provided for @arabicNameHint.
  ///
  /// In ar, this message translates to:
  /// **'💡 يفضل إدخال الاسم باللغة العربية ليظهر بشكل أجمل في الشهادات'**
  String get arabicNameHint;

  /// No description provided for @invalidAge.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عمرًا صحيحًا بين ١ و١٢٠'**
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

  /// No description provided for @dailyAyahSaveError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث تذكير آية اليوم'**
  String get dailyAyahSaveError;

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
  /// **'جزء ٣٠'**
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

  /// No description provided for @azkarSectionsAndServices.
  ///
  /// In ar, this message translates to:
  /// **'استكشف المزيد'**
  String get azkarSectionsAndServices;

  /// No description provided for @azkarWirdCompletedToday.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل ورد اليوم بنجاح ✨'**
  String get azkarWirdCompletedToday;

  /// No description provided for @azkarMorningHeroSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ يومك بذكر الله وطمأنينة القلب'**
  String get azkarMorningHeroSubtitle;

  /// No description provided for @azkarEveningHeroSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختم يومك بالسكينة والاستغفار'**
  String get azkarEveningHeroSubtitle;

  /// No description provided for @azkarReviewWird.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الورد'**
  String get azkarReviewWird;

  /// No description provided for @azkarStartWirdNow.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الورد الآن'**
  String get azkarStartWirdNow;

  /// No description provided for @azkarFreeTasbeeh.
  ///
  /// In ar, this message translates to:
  /// **'مسبحة حرة'**
  String get azkarFreeTasbeeh;

  /// No description provided for @azkarFreeTasbeehSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تسبيح واستغفار حر'**
  String get azkarFreeTasbeehSubtitle;

  /// No description provided for @azkarSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الأدعية والأذكار...'**
  String get azkarSearchHint;

  /// No description provided for @azkarFavorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get azkarFavorites;

  /// No description provided for @azkarFavoritesEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أدعية في المفضلة'**
  String get azkarFavoritesEmptyTitle;

  /// No description provided for @azkarFavoritesEmptyDesc.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على علامة الإشارة المرجعية بجانب أي دعاء لحفظه هنا'**
  String get azkarFavoritesEmptyDesc;

  /// No description provided for @azkarFavoriteAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إلى المفضلة'**
  String get azkarFavoriteAdd;

  /// No description provided for @azkarFavoriteRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من المفضلة'**
  String get azkarFavoriteRemove;

  /// No description provided for @azkarSearchNoResultsTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get azkarSearchNoResultsTitle;

  /// No description provided for @azkarSearchNoResultsDesc.
  ///
  /// In ar, this message translates to:
  /// **'لم نجد أي أدعية تطابق بحثك'**
  String get azkarSearchNoResultsDesc;

  /// No description provided for @azkarSearchClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get azkarSearchClear;

  /// No description provided for @azkarVirtueOrSource.
  ///
  /// In ar, this message translates to:
  /// **'فضل الذكر / المصدر'**
  String get azkarVirtueOrSource;

  /// No description provided for @azkarVirtueAndSource.
  ///
  /// In ar, this message translates to:
  /// **'فضل الذكر والمصدر'**
  String get azkarVirtueAndSource;

  /// No description provided for @azkarVirtue.
  ///
  /// In ar, this message translates to:
  /// **'فضل الذكر'**
  String get azkarVirtue;

  /// No description provided for @azkarSource.
  ///
  /// In ar, this message translates to:
  /// **'المصدر'**
  String get azkarSource;

  /// No description provided for @azkarAutoAdvanceOn.
  ///
  /// In ar, this message translates to:
  /// **'الانتقال التلقائي مفعّل'**
  String get azkarAutoAdvanceOn;

  /// No description provided for @azkarAutoAdvanceOff.
  ///
  /// In ar, this message translates to:
  /// **'الانتقال التلقائي معطّل'**
  String get azkarAutoAdvanceOff;

  /// No description provided for @azkarSmartWird.
  ///
  /// In ar, this message translates to:
  /// **'ورد ذكي'**
  String get azkarSmartWird;

  /// No description provided for @azkarSmartWirdSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ورد مبني على وقتك الآن'**
  String get azkarSmartWirdSubtitle;

  /// No description provided for @azkarSmartWirdDone.
  ///
  /// In ar, this message translates to:
  /// **'أكملت {count} من الورد الذكي اليوم'**
  String azkarSmartWirdDone(String count);

  /// No description provided for @azkarSmartWirdResume.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get azkarSmartWirdResume;

  /// No description provided for @azkarSmartWirdCompleted.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل الورد الذكي'**
  String get azkarSmartWirdCompleted;

  /// No description provided for @azkarQuietNight.
  ///
  /// In ar, this message translates to:
  /// **'الليلة الهادئة'**
  String get azkarQuietNight;

  /// No description provided for @azkarQuietNightSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'قراءة متدفقة بلا عدّاد'**
  String get azkarQuietNightSubtitle;

  /// No description provided for @azkarQuietNightExit.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء القراءة الهادئة'**
  String get azkarQuietNightExit;

  /// No description provided for @azkarPlayRecitation.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل التلاوة'**
  String get azkarPlayRecitation;

  /// No description provided for @azkarPauseRecitation.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التلاوة مؤقتًا'**
  String get azkarPauseRecitation;

  /// No description provided for @azkarShareWird.
  ///
  /// In ar, this message translates to:
  /// **'شارك تقدم الورد'**
  String get azkarShareWird;

  /// No description provided for @azkarTasbeehResetTitle.
  ///
  /// In ar, this message translates to:
  /// **'تصفير المسبحة'**
  String get azkarTasbeehResetTitle;

  /// No description provided for @azkarTasbeehResetDesc.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد إعادة تعيين العداد إلى الصفر؟'**
  String get azkarTasbeehResetDesc;

  /// No description provided for @azkarTasbeehResetConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تصفير'**
  String get azkarTasbeehResetConfirm;

  /// No description provided for @azkarTasbeehResetTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تصفير العداد'**
  String get azkarTasbeehResetTooltip;

  /// No description provided for @azkarTasbeehOpenTarget.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get azkarTasbeehOpenTarget;

  /// No description provided for @azkarTasbeehTargetLabel.
  ///
  /// In ar, this message translates to:
  /// **'الهدف: {target}'**
  String azkarTasbeehTargetLabel(String target);

  /// No description provided for @azkarTasbeehRound.
  ///
  /// In ar, this message translates to:
  /// **'دورة {round}'**
  String azkarTasbeehRound(String round);

  /// No description provided for @azkarTasbeehTapHint.
  ///
  /// In ar, this message translates to:
  /// **'انقر في أي مكان في الدائرة للتسبيح'**
  String get azkarTasbeehTapHint;

  /// No description provided for @azkarTasbeehTapSemantics.
  ///
  /// In ar, this message translates to:
  /// **'انقر للتسبيح، العداد الحالي {count}'**
  String azkarTasbeehTapSemantics(String count);

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
  /// **'احفظ جزء عمّ كاملاً'**
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
  /// **'{countText} {count, plural, =1{علامة} other{علامات}}'**
  String bookmarksCountItem(int count, String countText);

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

  /// No description provided for @settingsBackgroundPlaybackTitle.
  ///
  /// In ar, this message translates to:
  /// **'التشغيل في الخلفية'**
  String get settingsBackgroundPlaybackTitle;

  /// No description provided for @settingsBackgroundPlaybackSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تستمر التلاوة بعد مغادرة التطبيق، ويمكن التحكم بها من شريط الإشعارات.'**
  String get settingsBackgroundPlaybackSubtitle;

  /// No description provided for @settingsHubPractice.
  ///
  /// In ar, this message translates to:
  /// **'الممارسة'**
  String get settingsHubPractice;

  /// No description provided for @settingsHubReminders.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات والتذكيرات'**
  String get settingsHubReminders;

  /// No description provided for @settingsHubSupport.
  ///
  /// In ar, this message translates to:
  /// **'الدعم'**
  String get settingsHubSupport;

  /// No description provided for @settingsRemindersGeneral.
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get settingsRemindersGeneral;

  /// No description provided for @settingsRemindersMemorization.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات الحفظ'**
  String get settingsRemindersMemorization;

  /// No description provided for @settingsRemindersWorship.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار والعبادة'**
  String get settingsRemindersWorship;

  /// No description provided for @settingsRemindersPrayer.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة والأذان'**
  String get settingsRemindersPrayer;

  /// No description provided for @settingsRemindersProgress.
  ///
  /// In ar, this message translates to:
  /// **'التقدم'**
  String get settingsRemindersProgress;

  /// No description provided for @notificationPermissionBlockedTitle.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات التطبيق معطلة في إعدادات الهاتف'**
  String get notificationPermissionBlockedTitle;

  /// No description provided for @notificationPermissionBlockedBody.
  ///
  /// In ar, this message translates to:
  /// **'لن تصلك تذكيرات المراجعة أو الأذكار حتى يتم السماح بالإشعارات من إعدادات النظام.'**
  String get notificationPermissionBlockedBody;

  /// No description provided for @notificationOpenSystemSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح إعدادات الهاتف'**
  String get notificationOpenSystemSettings;

  /// No description provided for @notificationStatusBlocked.
  ///
  /// In ar, this message translates to:
  /// **'أذونات الإشعارات معطلة في إعدادات النظام'**
  String get notificationStatusBlocked;

  /// No description provided for @notificationStatusSummary.
  ///
  /// In ar, this message translates to:
  /// **'{enabled} من {total} تذكيرات مفعّلة'**
  String notificationStatusSummary(String enabled, String total);

  /// No description provided for @notificationTestInteractiveTitle.
  ///
  /// In ar, this message translates to:
  /// **'تجربة الإشعارات'**
  String get notificationTestInteractiveTitle;

  /// No description provided for @notificationTestInteractiveSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أرسل إشعارًا تجريبيًا للتأكد أن التنبيهات تعمل'**
  String get notificationTestInteractiveSubtitle;

  /// No description provided for @notificationPrayerPermissionBlockedBody.
  ///
  /// In ar, this message translates to:
  /// **'لن تصلك تنبيهات الصلاة حتى تسمح بالإشعارات من إعدادات الهاتف.'**
  String get notificationPrayerPermissionBlockedBody;

  /// No description provided for @notificationConfigurePrayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'إعداد مواقيت الصلاة'**
  String get notificationConfigurePrayerTimes;

  /// No description provided for @notificationTestPickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر إشعارًا لتجربته'**
  String get notificationTestPickerTitle;

  /// No description provided for @notificationTestPickerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سيصلك إشعار تجريبي مع أزرار تفاعل.'**
  String get notificationTestPickerSubtitle;

  /// No description provided for @notificationTestReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة اليوم 📖'**
  String get notificationTestReviewTitle;

  /// No description provided for @notificationTestReviewBody.
  ///
  /// In ar, this message translates to:
  /// **'لديك ٥ آيات مستحقة للمراجعة اليوم ⚡'**
  String get notificationTestReviewBody;

  /// No description provided for @notificationTestStreakTitle.
  ///
  /// In ar, this message translates to:
  /// **'حماية المواظبة 🔥'**
  String get notificationTestStreakTitle;

  /// No description provided for @notificationTestStreakBody.
  ///
  /// In ar, this message translates to:
  /// **'لم تراجع اليوم بعد — حافظ على مواظبتك الآن 🔥'**
  String get notificationTestStreakBody;

  /// No description provided for @notificationTestSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الإشعار التجريبي بنجاح ✨'**
  String get notificationTestSuccess;

  /// No description provided for @notificationSettingsSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ التغيير. حاول مرة أخرى.'**
  String get notificationSettingsSaveFailed;

  /// No description provided for @notificationSettingsSchedulingFailed.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ التغيير، لكن تعذر تحديث التنبيهات. حاول مرة أخرى.'**
  String get notificationSettingsSchedulingFailed;

  /// No description provided for @prayerChooseCityForAccurateTimes.
  ///
  /// In ar, this message translates to:
  /// **'اختر مدينتك لإظهار مواقيت صلاة دقيقة.'**
  String get prayerChooseCityForAccurateTimes;

  /// No description provided for @prayerChooseCityAction.
  ///
  /// In ar, this message translates to:
  /// **'اختيار المدينة'**
  String get prayerChooseCityAction;

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
  /// **'اختر مسار الكبار أو الأطفال عند فتح تبويب الحفظ.'**
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
  /// **'حذف الحساب والتقدم المرتبط به نهائيًا'**
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @settingsDeleteAccountWarning.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف حساب {email} وملفه وتقدمه وخططه وعلاماته المرجعية وشهاداته وروابط ولي الأمر والمكافآت المرتبطة من السحابة.\n\nسيُمسح أيضًا تقدم الحساب وملفاته المحلية، بما فيها ملفات الأطفال التابعة له والعمليات المعلقة، من هذا الجهاز. لا يمكن التراجع عن الحذف.\n\nتبقى الحسابات المستقلة المرتبطة، والملفات التي حفظتها أو شاركتها خارج التطبيق. يجب تنظيف بيانات التطبيق على أجهزتك الأخرى أيضًا.\n\nهل تريد حذف الحساب نهائيًا؟'**
  String settingsDeleteAccountWarning(Object email);

  /// No description provided for @settingsAccountDeletedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الحساب وتنظيف بياناته من هذا الجهاز.'**
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
  /// **'لوحة العائلة'**
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
  /// **'قم بإنشاء رمز جديد صالح لمدة ١٥ دقيقة.'**
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
  String guardianPairingExpiresIn(String minutes);

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
  /// **'اذهب إلى الإعدادات ← الأطفال وولي الأمر ← لوحة العائلة ← «ربط طفل جديد»'**
  String get guardianPairingStepOpenDashboard;

  /// No description provided for @guardianPairingStepScanOrEnterCode.
  ///
  /// In ar, this message translates to:
  /// **'امسح رمز QR أو أدخل الرمز يدوياً'**
  String get guardianPairingStepScanOrEnterCode;

  /// No description provided for @guardianLinkLater.
  ///
  /// In ar, this message translates to:
  /// **'سأربط لاحقاً'**
  String get guardianLinkLater;

  /// No description provided for @guardianLinkLaterHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك الربط في أي وقت من ⚙ في رحلة الحفظ.'**
  String get guardianLinkLaterHint;

  /// No description provided for @guardianCheckNow.
  ///
  /// In ar, this message translates to:
  /// **'تمّ المسح؟ تحقّق الآن'**
  String get guardianCheckNow;

  /// No description provided for @guardianLinkedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الربط بولي الأمر ✓'**
  String get guardianLinkedSuccess;

  /// No description provided for @parentDashboardNotLinkCode.
  ///
  /// In ar, this message translates to:
  /// **'هذا ليس رمز ربط من تالية'**
  String get parentDashboardNotLinkCode;

  /// No description provided for @familyDashboardLinking.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ ربط الطفل…'**
  String get familyDashboardLinking;

  /// No description provided for @familyPinOptionalHelp.
  ///
  /// In ar, this message translates to:
  /// **'اختياري على جهازك: يمنع غيرك من فتح لوحة العائلة.'**
  String get familyPinOptionalHelp;

  /// No description provided for @familyPinSkip.
  ///
  /// In ar, this message translates to:
  /// **'متابعة بدون قفل'**
  String get familyPinSkip;

  /// No description provided for @familyPinLockOn.
  ///
  /// In ar, this message translates to:
  /// **'قفل اللوحة برقم سري'**
  String get familyPinLockOn;

  /// No description provided for @familyPinLockRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة قفل اللوحة'**
  String get familyPinLockRemove;

  /// No description provided for @familyPinLockRemoveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'ستُفتح لوحة العائلة على هذا الجهاز دون رقم سري. يمكنك قفلها مرة أخرى في أي وقت.'**
  String get familyPinLockRemoveConfirm;

  /// No description provided for @kidsGuardianLinkedBadge.
  ///
  /// In ar, this message translates to:
  /// **'ولي أمرك يتابع رحلتك 💚'**
  String get kidsGuardianLinkedBadge;

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

  /// No description provided for @splashTagline.
  ///
  /// In ar, this message translates to:
  /// **'رفيقك في رحاب القرآن'**
  String get splashTagline;

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

  /// No description provided for @onboardingStartJourney.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ رحلتك'**
  String get onboardingStartJourney;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In ar, this message translates to:
  /// **'مصحفك اليومي بتلاوة وتدبر'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Subtitle.
  ///
  /// In ar, this message translates to:
  /// **'قراءة مصحفية أصيلة، خطوط عثمانية مريحة للعين، واستماع لكبار القراء، وخطط ختمة بالوتيرة التي تناسبك.'**
  String get onboardingSlide1Subtitle;

  /// No description provided for @onboardingBentoMushafSurah.
  ///
  /// In ar, this message translates to:
  /// **'سورة الإسراء'**
  String get onboardingBentoMushafSurah;

  /// No description provided for @onboardingBentoListeningTitle.
  ///
  /// In ar, this message translates to:
  /// **'تلاوات متقنة'**
  String get onboardingBentoListeningTitle;

  /// No description provided for @onboardingBentoListeningDesc.
  ///
  /// In ar, this message translates to:
  /// **'استماع وتكرار صوتي'**
  String get onboardingBentoListeningDesc;

  /// No description provided for @onboardingBentoKhatmahTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطط الختمة'**
  String get onboardingBentoKhatmahTitle;

  /// No description provided for @onboardingBentoKhatmahDesc.
  ///
  /// In ar, this message translates to:
  /// **'وتيرة يومية تناسبك'**
  String get onboardingBentoKhatmahDesc;

  /// No description provided for @onboardingBentoKhatmahBadge.
  ///
  /// In ar, this message translates to:
  /// **'ورد يومي'**
  String get onboardingBentoKhatmahBadge;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In ar, this message translates to:
  /// **'احفظ القرآن ورسّخه بذكاء'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Subtitle.
  ///
  /// In ar, this message translates to:
  /// **'تقنيات تكرار ذكية ومتباعدة تقيس قوة حفظك وتمنع النسيان قبل وقوعه.'**
  String get onboardingSlide2Subtitle;

  /// No description provided for @onboardingBentoMasteryTitle.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الإتقان والتثبيت'**
  String get onboardingBentoMasteryTitle;

  /// No description provided for @onboardingBentoMasteryValue.
  ///
  /// In ar, this message translates to:
  /// **'٩٨٪ متقن'**
  String get onboardingBentoMasteryValue;

  /// No description provided for @onboardingBentoActiveRecallTitle.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع نشط'**
  String get onboardingBentoActiveRecallTitle;

  /// No description provided for @onboardingBentoActiveRecallDesc.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء الكلمات للاختبار الذاتي'**
  String get onboardingBentoActiveRecallDesc;

  /// No description provided for @onboardingBentoReviewScheduleTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة ذكية'**
  String get onboardingBentoReviewScheduleTitle;

  /// No description provided for @onboardingBentoReviewScheduleDesc.
  ///
  /// In ar, this message translates to:
  /// **'تذكير تلقائي لمنع النسيان'**
  String get onboardingBentoReviewScheduleDesc;

  /// No description provided for @onboardingBentoStatusMastered.
  ///
  /// In ar, this message translates to:
  /// **'متقن راسخ'**
  String get onboardingBentoStatusMastered;

  /// No description provided for @onboardingBentoStatusDueSoon.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة قريبة'**
  String get onboardingBentoStatusDueSoon;

  /// No description provided for @onboardingBentoStatusNew.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get onboardingBentoStatusNew;

  /// No description provided for @onboardingBentoSmartAlert.
  ///
  /// In ar, this message translates to:
  /// **'تذكير ذكي'**
  String get onboardingBentoSmartAlert;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In ar, this message translates to:
  /// **'ورد مستمر وتجربة لكل العائلة'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Subtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابنِ عادة قرآنية يومية لا تنقطع، مع مسار تفاعلي ممتع مخصص للأطفال، وبدون إنترنت.'**
  String get onboardingSlide3Subtitle;

  /// No description provided for @onboardingBentoStreakTitle.
  ///
  /// In ar, this message translates to:
  /// **'سلسلة الورد اليومي'**
  String get onboardingBentoStreakTitle;

  /// No description provided for @onboardingBentoStreakDays.
  ///
  /// In ar, this message translates to:
  /// **'٧ أيام متواصلة 🔥'**
  String get onboardingBentoStreakDays;

  /// No description provided for @onboardingBentoOfflineBadge.
  ///
  /// In ar, this message translates to:
  /// **'يعمل دون إنترنت'**
  String get onboardingBentoOfflineBadge;

  /// No description provided for @onboardingBentoKidsTeaserTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسار براعم تالية'**
  String get onboardingBentoKidsTeaserTitle;

  /// No description provided for @onboardingBentoKidsTeaserDesc.
  ///
  /// In ar, this message translates to:
  /// **'نجوم، أصوات ومكافآت محفزة'**
  String get onboardingBentoKidsTeaserDesc;

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
  /// **'يعمل دون إنترنت، بياناتك محفوظة على جهازك'**
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

  /// No description provided for @kidsJourneyMotivation.
  ///
  /// In ar, this message translates to:
  /// **'مع كل آية تقترب أكثر من كتاب الله'**
  String get kidsJourneyMotivation;

  /// No description provided for @kidsJourneySignpost1.
  ///
  /// In ar, this message translates to:
  /// **'رحلتنا إلى القرآن أجمل'**
  String get kidsJourneySignpost1;

  /// No description provided for @kidsJourneySignpost2.
  ///
  /// In ar, this message translates to:
  /// **'كل خطوة نور'**
  String get kidsJourneySignpost2;

  /// No description provided for @kidsJourneySignpost3.
  ///
  /// In ar, this message translates to:
  /// **'نكمل حفظ كتاب الله'**
  String get kidsJourneySignpost3;

  /// No description provided for @kidsPointsValue.
  ///
  /// In ar, this message translates to:
  /// **'{points} نقطة'**
  String kidsPointsValue(String points);

  /// No description provided for @kidsLevelValue.
  ///
  /// In ar, this message translates to:
  /// **'مستوى {level}'**
  String kidsLevelValue(String level);

  /// No description provided for @kidsStartFirstStageToday.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ أول مرحلة اليوم'**
  String get kidsStartFirstStageToday;

  /// No description provided for @kidsStageAyahRange.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة {stage}: الآيات {startAyah}-{endAyah}'**
  String kidsStageAyahRange(String stage, String startAyah, String endAyah);

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
  String kidsStageTitle(String stage);

  /// No description provided for @kidsStageProgress.
  ///
  /// In ar, this message translates to:
  /// **'الآيات {startAyah}-{endAyah} • {completed}/{total}'**
  String kidsStageProgress(
    String startAyah,
    String endAyah,
    String completed,
    String total,
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
  String accuracyRequiredPercent(String percent);

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
  String kidsCompleteStageToday(String stage);

  /// No description provided for @kidsFirstMissionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بالاستماع والتكرار، وكل خطوة تقربك من نجمة جديدة.'**
  String get kidsFirstMissionSubtitle;

  /// No description provided for @kidsRemainingAyahs.
  ///
  /// In ar, this message translates to:
  /// **'تبقى {count} آيات في هذه المرحلة.'**
  String kidsRemainingAyahs(String count);

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

  /// No description provided for @kidsGamifiedWelcomeNamed.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً يا {name}، بطل الحفظ!'**
  String kidsGamifiedWelcomeNamed(String name);

  /// No description provided for @kidsGamifiedLevelProgress.
  ///
  /// In ar, this message translates to:
  /// **'المستوى {level} — {progress}/١٠٠'**
  String kidsGamifiedLevelProgress(String level, String progress);

  /// No description provided for @kidsGamifiedStarsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{{countText} نجمة} =1{نجمة واحدة} =2{نجمتان} few{{countText} نجمات} many{{countText} نجمة} other{{countText} نجمة}}'**
  String kidsGamifiedStarsCount(int count, String countText);

  /// No description provided for @kidsGamifiedLastMission.
  ///
  /// In ar, this message translates to:
  /// **'مهمتك الآن'**
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
  String kidsGamifiedHouseTitle(String number);

  /// No description provided for @kidsGamifiedReviewHouseTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيت المراجعة {number}'**
  String kidsGamifiedReviewHouseTitle(String number);

  /// No description provided for @kidsGamifiedAyahRange.
  ///
  /// In ar, this message translates to:
  /// **'الآيات {startAyah}-{endAyah}'**
  String kidsGamifiedAyahRange(String startAyah, String endAyah);

  /// No description provided for @kidsGamifiedProgressCount.
  ///
  /// In ar, this message translates to:
  /// **'{completed}/{total}'**
  String kidsGamifiedProgressCount(String completed, String total);

  /// No description provided for @kidsGamifiedLockedStage.
  ///
  /// In ar, this message translates to:
  /// **'هذا البيت مغلق الآن'**
  String get kidsGamifiedLockedStage;

  /// No description provided for @kidsGamifiedDailyLimitReached.
  ///
  /// In ar, this message translates to:
  /// **'أنجزت مهام اليوم، ما شاء الله! عُد غداً لبيت جديد.'**
  String kidsGamifiedDailyLimitReached(int count);

  /// No description provided for @kidsDailyMissionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مهماتي اليوم'**
  String get kidsDailyMissionsTitle;

  /// No description provided for @kidsReadingMissionTitle.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ صفحة من مصحفك'**
  String get kidsReadingMissionTitle;

  /// No description provided for @kidsMissionDone.
  ///
  /// In ar, this message translates to:
  /// **'تمّت ✓'**
  String get kidsMissionDone;

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

  /// No description provided for @kidsGamifiedTryFromMemory.
  ///
  /// In ar, this message translates to:
  /// **'جرّب من ذاكرتك'**
  String get kidsGamifiedTryFromMemory;

  /// No description provided for @kidsGamifiedTryToRemember.
  ///
  /// In ar, this message translates to:
  /// **'حاول تتذكّر الآية'**
  String get kidsGamifiedTryToRemember;

  /// No description provided for @kidsGamifiedGiveMeTheStart.
  ///
  /// In ar, this message translates to:
  /// **'أعطني البداية'**
  String get kidsGamifiedGiveMeTheStart;

  /// No description provided for @kidsGamifiedFirstWordShown.
  ///
  /// In ar, this message translates to:
  /// **'هذه أول كلمة، أكمل أنت'**
  String get kidsGamifiedFirstWordShown;

  /// No description provided for @kidsGamifiedReviewChallenge.
  ///
  /// In ar, this message translates to:
  /// **'⭐ تحدّي المراجعة'**
  String get kidsGamifiedReviewChallenge;

  /// No description provided for @kidsGamifiedReviewChallengeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'هل تتذكّرها؟ سمّعها من ذاكرتك'**
  String get kidsGamifiedReviewChallengeSubtitle;

  /// No description provided for @kidsGamifiedRemindMe.
  ///
  /// In ar, this message translates to:
  /// **'ذكّرني'**
  String get kidsGamifiedRemindMe;

  /// No description provided for @kidsTaliaListenBubble.
  ///
  /// In ar, this message translates to:
  /// **'اسمع الآية معي، ثم ردّدها!'**
  String get kidsTaliaListenBubble;

  /// No description provided for @kidsTaliaRecallBubble.
  ///
  /// In ar, this message translates to:
  /// **'أنت تقدر! تذكّرها على مهلك'**
  String get kidsTaliaRecallBubble;

  /// No description provided for @kidsTaliaRecordingBubble.
  ///
  /// In ar, this message translates to:
  /// **'أنا أسمعك…'**
  String get kidsTaliaRecordingBubble;

  /// No description provided for @kidsTaliaReviewBubble.
  ///
  /// In ar, this message translates to:
  /// **'هيا نرى ماذا تتذكّر!'**
  String get kidsTaliaReviewBubble;

  /// No description provided for @kidsTaliaEncourageBubble.
  ///
  /// In ar, this message translates to:
  /// **'محاولة رائعة! مرة أخرى'**
  String get kidsTaliaEncourageBubble;

  /// No description provided for @kidsTaliaCelebrateBubble.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت! بارك الله فيك'**
  String get kidsTaliaCelebrateBubble;

  /// No description provided for @kidsTaliaGuideBubble.
  ///
  /// In ar, this message translates to:
  /// **'مهمتك جاهزة، هيا نبدأ!'**
  String get kidsTaliaGuideBubble;

  /// No description provided for @kidsTaliaWelcomeBackBubble.
  ///
  /// In ar, this message translates to:
  /// **'اشتقت إليك!'**
  String get kidsTaliaWelcomeBackBubble;

  /// No description provided for @kidsTreasuresTitle.
  ///
  /// In ar, this message translates to:
  /// **'كنوزي'**
  String get kidsTreasuresTitle;

  /// No description provided for @kidsTreasuresEmpty.
  ///
  /// In ar, this message translates to:
  /// **'احفظ أول سورة لتجد أول كنز!'**
  String get kidsTreasuresEmpty;

  /// No description provided for @kidsRegionBeginning.
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get kidsRegionBeginning;

  /// No description provided for @kidsRegionPalmOasis.
  ///
  /// In ar, this message translates to:
  /// **'واحة النخيل'**
  String get kidsRegionPalmOasis;

  /// No description provided for @kidsRegionFlowerValley.
  ///
  /// In ar, this message translates to:
  /// **'وادي الأزهار'**
  String get kidsRegionFlowerValley;

  /// No description provided for @kidsRegionStarMountain.
  ///
  /// In ar, this message translates to:
  /// **'جبل النجوم'**
  String get kidsRegionStarMountain;

  /// No description provided for @kidsRegionPearlSea.
  ///
  /// In ar, this message translates to:
  /// **'بحر اللؤلؤ'**
  String get kidsRegionPearlSea;

  /// No description provided for @kidsRegionProgress.
  ///
  /// In ar, this message translates to:
  /// **'{memorizedText} من {totalText} سور'**
  String kidsRegionProgress(
    int memorized,
    int total,
    String memorizedText,
    String totalText,
  );

  /// No description provided for @kidsTaliaFarewellBubble.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت اليوم! نلتقي غدًا'**
  String get kidsTaliaFarewellBubble;

  /// No description provided for @kidsTaliaJourneyDoneBubble.
  ///
  /// In ar, this message translates to:
  /// **'أتممت رحلتك كلها!'**
  String get kidsTaliaJourneyDoneBubble;

  /// No description provided for @kidsTaliaMapBubble.
  ///
  /// In ar, this message translates to:
  /// **'هيا نكمل المغامرة!'**
  String get kidsTaliaMapBubble;

  /// No description provided for @kidsTaliaStageReadyBubble.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت مستعد؟'**
  String get kidsTaliaStageReadyBubble;

  /// No description provided for @kidsWelcomeBackTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بعودتك!'**
  String get kidsWelcomeBackTitle;

  /// No description provided for @kidsWelcomeBackSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نبدأ بخطوة سهلة'**
  String get kidsWelcomeBackSubtitle;

  /// No description provided for @kidsGamifiedEnoughForToday.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت! هذا وقت كافٍ لليوم، يمكنك التوقف.'**
  String get kidsGamifiedEnoughForToday;

  /// No description provided for @parentSupportTip.
  ///
  /// In ar, this message translates to:
  /// **'جرّبا معاً: استمعا للآية مرتين، ثم دع طفلك يبدأ بأول كلمة'**
  String get parentSupportTip;

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
  /// **'استمع للآية {count, plural, =1{مرة واحدة} =2{مرتين} few{{countText} مرات} other{{countText} مرة}} قبل تسجيل تلاوتك.'**
  String kidsGamifiedListenFirst(int count, String countText);

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
  /// **'+{count, plural, =0{{countText} نجمة} =1{نجمة واحدة} =2{نجمتان} few{{countText} نجمات} many{{countText} نجمة} other{{countText} نجمة}}'**
  String kidsGamifiedEarnedStars(int count, String countText);

  /// No description provided for @kidsGamifiedEarnedGems.
  ///
  /// In ar, this message translates to:
  /// **'+{count} جوهرة'**
  String kidsGamifiedEarnedGems(String count);

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
  String dailyPlanCompletedSubtitle(String count);

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
  String dailyPlanRatingExcellent(String ayahNumber);

  /// No description provided for @dailyPlanRatingAverage.
  ///
  /// In ar, this message translates to:
  /// **'⏰ متوسط، سيتم المراجعة خلال فترة معتدلة'**
  String get dailyPlanRatingAverage;

  /// No description provided for @dailyPlanRatingWeak.
  ///
  /// In ar, this message translates to:
  /// **'🔁 ضعيف، ستتم مراجعة الآية {ayahNumber} غداً'**
  String dailyPlanRatingWeak(String ayahNumber);

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
  /// **'المراجعة'**
  String get memorizationHubReviewSectionTitle;

  /// No description provided for @memorizationHubReviewSectionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سمّع ما حفظته من ذاكرتك، ويقيّم التطبيق تسميعك.'**
  String get memorizationHubReviewSectionSubtitle;

  /// No description provided for @memorizationHubReviewCardDescription.
  ///
  /// In ar, this message translates to:
  /// **'سمّع الآيات المستحقة للمراجعة من حفظك.'**
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

  /// No description provided for @listeningReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختبار الاستماع'**
  String get listeningReviewTitle;

  /// No description provided for @listeningReviewHubDescription.
  ///
  /// In ar, this message translates to:
  /// **'اسمع آية من محفوظك: حدّد سورتها أو أكمل ما بعدها.'**
  String get listeningReviewHubDescription;

  /// No description provided for @listeningReviewStartPrompt.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع الجولة'**
  String get listeningReviewStartPrompt;

  /// No description provided for @listeningReviewModeWhichSurah.
  ///
  /// In ar, this message translates to:
  /// **'من أي سورة؟'**
  String get listeningReviewModeWhichSurah;

  /// No description provided for @listeningReviewModeNextAyah.
  ///
  /// In ar, this message translates to:
  /// **'أكمل التالية'**
  String get listeningReviewModeNextAyah;

  /// No description provided for @listeningReviewModeMixed.
  ///
  /// In ar, this message translates to:
  /// **'مختلط'**
  String get listeningReviewModeMixed;

  /// No description provided for @listeningReviewLastScore.
  ///
  /// In ar, this message translates to:
  /// **'آخر جولة: {correct} من {total}'**
  String listeningReviewLastScore(String correct, String total);

  /// No description provided for @listeningReviewNotEnoughTitle.
  ///
  /// In ar, this message translates to:
  /// **'احفظ بضع آيات أولًا'**
  String get listeningReviewNotEnoughTitle;

  /// No description provided for @listeningReviewNotEnoughBody.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج اختبار الاستماع إلى ٥ آيات محفوظة على الأقل يمكن تشغيلها.'**
  String get listeningReviewNotEnoughBody;

  /// No description provided for @listeningReviewErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحضير الجولة. حاول مرة أخرى.'**
  String get listeningReviewErrorBody;

  /// No description provided for @listeningReviewRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get listeningReviewRetry;

  /// No description provided for @listeningReviewQuestionProgress.
  ///
  /// In ar, this message translates to:
  /// **'السؤال {current} من {total}'**
  String listeningReviewQuestionProgress(String current, String total);

  /// No description provided for @listeningReviewReplay.
  ///
  /// In ar, this message translates to:
  /// **'أعد الاستماع ({remaining})'**
  String listeningReviewReplay(String remaining);

  /// No description provided for @listeningReviewWhichSurahPrompt.
  ///
  /// In ar, this message translates to:
  /// **'من أي سورة هذه الآية؟'**
  String get listeningReviewWhichSurahPrompt;

  /// No description provided for @listeningReviewNextAyahPrompt.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surah}: اتلُ الآية التالية'**
  String listeningReviewNextAyahPrompt(String surah);

  /// No description provided for @listeningReviewRecord.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التسميع'**
  String get listeningReviewRecord;

  /// No description provided for @listeningReviewStopRecord.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء التسميع'**
  String get listeningReviewStopRecord;

  /// No description provided for @listeningReviewCantRecord.
  ///
  /// In ar, this message translates to:
  /// **'لا أستطيع التسجيل'**
  String get listeningReviewCantRecord;

  /// No description provided for @listeningReviewReveal.
  ///
  /// In ar, this message translates to:
  /// **'أظهر الآية'**
  String get listeningReviewReveal;

  /// No description provided for @listeningReviewGradeMastered.
  ///
  /// In ar, this message translates to:
  /// **'أتقنت'**
  String get listeningReviewGradeMastered;

  /// No description provided for @listeningReviewGradeHesitant.
  ///
  /// In ar, this message translates to:
  /// **'ترددت'**
  String get listeningReviewGradeHesitant;

  /// No description provided for @listeningReviewGradeForgot.
  ///
  /// In ar, this message translates to:
  /// **'نسيت'**
  String get listeningReviewGradeForgot;

  /// No description provided for @listeningReviewCorrect.
  ///
  /// In ar, this message translates to:
  /// **'إجابة صحيحة'**
  String get listeningReviewCorrect;

  /// No description provided for @listeningReviewWrong.
  ///
  /// In ar, this message translates to:
  /// **'ليست هذه'**
  String get listeningReviewWrong;

  /// No description provided for @listeningReviewNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get listeningReviewNext;

  /// No description provided for @listeningReviewResultTitle.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجولة'**
  String get listeningReviewResultTitle;

  /// No description provided for @listeningReviewResultScore.
  ///
  /// In ar, this message translates to:
  /// **'{correct} من {total}'**
  String listeningReviewResultScore(String correct, String total);

  /// No description provided for @listeningReviewWeakLinksTitle.
  ///
  /// In ar, this message translates to:
  /// **'روابط تحتاج مراجعة'**
  String get listeningReviewWeakLinksTitle;

  /// No description provided for @listeningReviewNoWeakLinks.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد روابط ضعيفة في هذه الجولة'**
  String get listeningReviewNoWeakLinks;

  /// No description provided for @listeningReviewAyahRef.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surah}، الآية {ayah}'**
  String listeningReviewAyahRef(String surah, String ayah);

  /// No description provided for @listeningReviewNewRound.
  ///
  /// In ar, this message translates to:
  /// **'جولة جديدة'**
  String get listeningReviewNewRound;

  /// No description provided for @listeningReviewAudioPlaying.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تشغيل الآية…'**
  String get listeningReviewAudioPlaying;

  /// No description provided for @listeningReviewBreakdownWhichSurah.
  ///
  /// In ar, this message translates to:
  /// **'من أي سورة؟: {correct} من {total}'**
  String listeningReviewBreakdownWhichSurah(String correct, String total);

  /// No description provided for @listeningReviewBreakdownNextAyah.
  ///
  /// In ar, this message translates to:
  /// **'أكمل التالية: {correct} من {total}'**
  String listeningReviewBreakdownNextAyah(String correct, String total);

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
    String surahId,
    String ayahNumber,
    String repeats,
    String points,
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

  /// No description provided for @parentDashboardForgotPin.
  ///
  /// In ar, this message translates to:
  /// **'نسيت الرمز؟'**
  String get parentDashboardForgotPin;

  /// No description provided for @parentDashboardForgotPinTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة رمز ولي الأمر'**
  String get parentDashboardForgotPinTitle;

  /// No description provided for @parentDashboardForgotPinBody.
  ///
  /// In ar, this message translates to:
  /// **'للتأكد أنك ولي الأمر، أدخل كلمة مرور حسابك {email}. بعدها تنشئ رمزاً جديداً، وتبقى المكافآت والإعدادات كما هي.'**
  String parentDashboardForgotPinBody(String email);

  /// No description provided for @parentDashboardForgotPinConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق'**
  String get parentDashboardForgotPinConfirm;

  /// No description provided for @parentDashboardAccountPasswordIncorrect.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور الحساب غير صحيحة'**
  String get parentDashboardAccountPasswordIncorrect;

  /// No description provided for @parentDashboardAccountCheckUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحقق من الحساب الآن. تأكد من الاتصال بالإنترنت وحاول مرة أخرى.'**
  String get parentDashboardAccountCheckUnavailable;

  /// No description provided for @parentDashboardChangePin.
  ///
  /// In ar, this message translates to:
  /// **'تغيير رمز ولي الأمر'**
  String get parentDashboardChangePin;

  /// No description provided for @parentDashboardChangePinConfirm.
  ///
  /// In ar, this message translates to:
  /// **'ستنشئ رمزاً جديداً الآن. تبقى المكافآت والإعدادات كما هي.'**
  String get parentDashboardChangePinConfirm;

  /// No description provided for @guardianErrorSignInRequired.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول بحسابك أولاً ثم أعد المحاولة.'**
  String get guardianErrorSignInRequired;

  /// No description provided for @guardianErrorCloudUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'ربط الأطفال غير متاح في هذا الإصدار لأن المزامنة السحابية غير مفعّلة.'**
  String get guardianErrorCloudUnavailable;

  /// No description provided for @guardianErrorOnlyForChildren.
  ///
  /// In ar, this message translates to:
  /// **'ربط ولي الأمر متاح لحسابات الأطفال فقط.'**
  String get guardianErrorOnlyForChildren;

  /// No description provided for @guardianErrorAlreadyLinked.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب مرتبط بولي أمر بالفعل.'**
  String get guardianErrorAlreadyLinked;

  /// No description provided for @guardianErrorParentModeAdultsOnly.
  ///
  /// In ar, this message translates to:
  /// **'وضع ولي الأمر متاح لمسار الكبار فقط.'**
  String get guardianErrorParentModeAdultsOnly;

  /// No description provided for @guardianErrorLinkCodeInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رمز الربط غير صحيح أو انتهت صلاحيته. اطلب من الطفل إنشاء رمز جديد ثم أعد المحاولة.'**
  String get guardianErrorLinkCodeInvalid;

  /// No description provided for @guardianErrorChildHasGuardian.
  ///
  /// In ar, this message translates to:
  /// **'هذا الطفل مرتبط بولي أمر آخر. يجب فك الربط الحالي أولاً.'**
  String get guardianErrorChildHasGuardian;

  /// No description provided for @guardianErrorSameAccount.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن ربط الطفل بنفس الحساب. يجب أن يستخدم الطفل حساباً مختلفاً عن حساب ولي الأمر.'**
  String get guardianErrorSameAccount;

  /// No description provided for @parentRewardErrorTitleRequired.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم المكافأة أولاً.'**
  String get parentRewardErrorTitleRequired;

  /// No description provided for @parentRewardErrorLimitReached.
  ///
  /// In ar, this message translates to:
  /// **'يمكن إضافة ٣ مكافآت فقط.'**
  String get parentRewardErrorLimitReached;

  /// No description provided for @parentRewardErrorUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'هذه الهدية غير متاحة لهذه الخطوة الآن. حدّث الصفحة وحاول مرة أخرى.'**
  String get parentRewardErrorUnavailable;

  /// No description provided for @parentRewardUnlockedFeedback.
  ///
  /// In ar, this message translates to:
  /// **'تم فتح الهدية'**
  String get parentRewardUnlockedFeedback;

  /// No description provided for @parentRewardApprovedFeedback.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد تسليم الهدية'**
  String get parentRewardApprovedFeedback;

  /// No description provided for @parentRewardStatusWaitingForChild.
  ///
  /// In ar, this message translates to:
  /// **'مفتوحة، بانتظار طلب الطفل'**
  String get parentRewardStatusWaitingForChild;

  /// No description provided for @parentRewardStatusRequested.
  ///
  /// In ar, this message translates to:
  /// **'الطفل يطلب استلامها'**
  String get parentRewardStatusRequested;

  /// No description provided for @parentRewardUnlockAction.
  ///
  /// In ar, this message translates to:
  /// **'افتح الهدية'**
  String get parentRewardUnlockAction;

  /// No description provided for @parentRewardApproveAction.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التسليم'**
  String get parentRewardApproveAction;

  /// No description provided for @familyDashboardOfflineCached.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال. تُعرض آخر بيانات وصلت في {time}.'**
  String familyDashboardOfflineCached(String time);

  /// No description provided for @familyDashboardRemoteUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الأطفال المرتبطين. تحقّق من الاتصال وحاول مرة أخرى.'**
  String get familyDashboardRemoteUnavailable;

  /// No description provided for @kidsHomeMissionsUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل مهام البيت الآن.'**
  String get kidsHomeMissionsUnavailable;

  /// No description provided for @guardianSessionTileTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة العائلة'**
  String get guardianSessionTileTitle;

  /// No description provided for @guardianSessionTileSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لولي الأمر فقط، وتحتاج الرقم السري'**
  String get guardianSessionTileSubtitle;

  /// No description provided for @guardianSessionBackToChild.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى الطفل'**
  String get guardianSessionBackToChild;

  /// No description provided for @kidsGiftsTitle.
  ///
  /// In ar, this message translates to:
  /// **'هداياي'**
  String get kidsGiftsTitle;

  /// No description provided for @kidsGiftLocked.
  ///
  /// In ar, this message translates to:
  /// **'أكمل هدفك لتُفتح هذه الهدية'**
  String get kidsGiftLocked;

  /// No description provided for @kidsGiftUnlocked.
  ///
  /// In ar, this message translates to:
  /// **'هديتك جاهزة!'**
  String get kidsGiftUnlocked;

  /// No description provided for @kidsGiftRequested.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا طلبك، بانتظار ولي أمرك'**
  String get kidsGiftRequested;

  /// No description provided for @kidsGiftClaimed.
  ///
  /// In ar, this message translates to:
  /// **'استلمتها، مبارك!'**
  String get kidsGiftClaimed;

  /// No description provided for @kidsGiftRequestAction.
  ///
  /// In ar, this message translates to:
  /// **'أريدها!'**
  String get kidsGiftRequestAction;

  /// No description provided for @childErrorNicknameInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسماً من حرف واحد إلى {max} حرفاً.'**
  String childErrorNicknameInvalid(String max);

  /// No description provided for @childErrorAgeInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اختر عمراً بين {min} و{max} سنة.'**
  String childErrorAgeInvalid(String min, String max);

  /// No description provided for @guardianErrorChildNotLinked.
  ///
  /// In ar, this message translates to:
  /// **'هذا الطفل لم يعد مرتبطاً بحسابك.'**
  String get guardianErrorChildNotLinked;

  /// No description provided for @guardianUnlinkTileTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء ربط ولي الأمر'**
  String get guardianUnlinkTileTitle;

  /// No description provided for @guardianUnlinkTileSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج الرقم السري والاتصال بالإنترنت'**
  String get guardianUnlinkTileSubtitle;

  /// No description provided for @guardianUnlinkConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء ربط ولي الأمر؟'**
  String get guardianUnlinkConfirmTitle;

  /// No description provided for @guardianUnlinkConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'لن يتابع ولي الأمر تقدّمك بعد الآن، ولن تصل منه مهام أو هدايا جديدة. الهدايا التي استلمتها تبقى، أما الهدايا والمهام التي لم تكتمل فتختفي من هذا الجهاز. يمكن الربط من جديد لاحقاً.'**
  String get guardianUnlinkConfirmBody;

  /// No description provided for @guardianUnlinkAction.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الربط'**
  String get guardianUnlinkAction;

  /// No description provided for @guardianUnlinkDone.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء ربط ولي الأمر'**
  String get guardianUnlinkDone;

  /// No description provided for @guardianErrorUnlinkFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إلغاء الربط، ولم يتغير شيء. تأكد من الاتصال بالإنترنت وتسجيل الدخول ثم حاول مرة أخرى.'**
  String get guardianErrorUnlinkFailed;

  /// No description provided for @pinRecoveryUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'استعادة الرقم السري تحتاج اتصالاً بالإنترنت وحساباً مرتبطاً بولي أمر، أو أن الطلب انتهت صلاحيته.'**
  String get pinRecoveryUnavailable;

  /// No description provided for @pinRecoveryTitle.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الرقم السري المنسي'**
  String get pinRecoveryTitle;

  /// No description provided for @pinRecoveryInstructions.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من ولي الأمر فتح صفحتك في لوحة العائلة على جهازه والموافقة على الطلب، ثم اكتب الرمز الذي يظهر له والرقم السري الجديد.'**
  String get pinRecoveryInstructions;

  /// No description provided for @pinRecoveryCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز ولي الأمر'**
  String get pinRecoveryCodeLabel;

  /// No description provided for @pinRecoveryNewPinLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرقم السري الجديد (4 أرقام)'**
  String get pinRecoveryNewPinLabel;

  /// No description provided for @pinRecoveryWrongCode.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح، أو لم يوافق عليه ولي الأمر بعد، أو انتهت صلاحيته.'**
  String get pinRecoveryWrongCode;

  /// No description provided for @pinRecoveryDone.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير الرقم السري'**
  String get pinRecoveryDone;

  /// No description provided for @pinRecoveryRequestTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب تغيير الرقم السري'**
  String get pinRecoveryRequestTitle;

  /// No description provided for @pinRecoveryRequestBody.
  ///
  /// In ar, this message translates to:
  /// **'طلب جهاز طفلك تغيير الرقم السري. وافق فقط إن كنت بجانبه أو طلبت ذلك بنفسك.'**
  String get pinRecoveryRequestBody;

  /// No description provided for @pinRecoveryApproveAction.
  ///
  /// In ar, this message translates to:
  /// **'موافقة وإظهار الرمز'**
  String get pinRecoveryApproveAction;

  /// No description provided for @pinRecoveryCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'رمز لمرة واحدة'**
  String get pinRecoveryCodeTitle;

  /// No description provided for @pinRecoveryCodeBody.
  ///
  /// In ar, this message translates to:
  /// **'اكتب هذا الرمز على جهاز طفلك مع رقم سري جديد. صالح حتى {time}.'**
  String pinRecoveryCodeBody(String time);

  /// No description provided for @guardianErrorUnlinkBeforePathChange.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إلغاء ربط ولي الأمر، فلم يتغير المسار. تأكد من الاتصال بالإنترنت وتسجيل الدخول ثم حاول مرة أخرى.'**
  String get guardianErrorUnlinkBeforePathChange;

  /// No description provided for @resetPathUnlinksGuardianWarning.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب مرتبط بولي أمر. تغيير المسار يلغي الربط، فلن يتابع ولي الأمر التقدم بعدها. يحتاج ذلك اتصالاً بالإنترنت.'**
  String get resetPathUnlinksGuardianWarning;

  /// No description provided for @childErrorIdentityUpdateUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات الطفل غير متاح حالياً. حاول لاحقاً.'**
  String get childErrorIdentityUpdateUnavailable;

  /// No description provided for @childAgeYears.
  ///
  /// In ar, this message translates to:
  /// **'{age, plural, =1{سنة واحدة} =2{سنتان} few{{ageText} سنوات} other{{ageText} سنة}}'**
  String childAgeYears(int age, String ageText);

  /// No description provided for @childEditIdentity.
  ///
  /// In ar, this message translates to:
  /// **'تعديل اسم الطفل وعمره'**
  String get childEditIdentity;

  /// No description provided for @childIdentitySaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ بيانات الطفل، وتظهر على جهازه بعد المزامنة التالية.'**
  String get childIdentitySaved;

  /// No description provided for @kidsLinkGuardianTileTitle.
  ///
  /// In ar, this message translates to:
  /// **'ربط ولي الأمر'**
  String get kidsLinkGuardianTileTitle;

  /// No description provided for @kidsLinkGuardianTileSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج رمز ولي الأمر. بعد الربط يتابع ولي الأمر تقدّمك من جهازه.'**
  String get kidsLinkGuardianTileSubtitle;

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
  String parentDashboardTodayCompleted(String count);

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
  /// **'تذكير يومي للطفل'**
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
  String parentDashboardRemoteChildSummary(String ayahs, String points);

  /// No description provided for @parentDashboardMemorizedSummary.
  ///
  /// In ar, this message translates to:
  /// **'{memorized}/{total} آية محفوظة • {percent}%'**
  String parentDashboardMemorizedSummary(
    String memorized,
    String total,
    String percent,
  );

  /// No description provided for @parentDashboardReviewsSummary.
  ///
  /// In ar, this message translates to:
  /// **'{completed} مراجعة مكتملة • {overdue} متأخرة'**
  String parentDashboardReviewsSummary(String completed, String overdue);

  /// No description provided for @parentDashboardStreakSummary.
  ///
  /// In ar, this message translates to:
  /// **'التتابع: {days} يوم'**
  String parentDashboardStreakSummary(String days);

  /// No description provided for @parentDashboardCertificatesSummary.
  ///
  /// In ar, this message translates to:
  /// **'{count} شهادة تم الحصول عليها'**
  String parentDashboardCertificatesSummary(String count);

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
  String parentDashboardLogTitle(String surahId, String ayahNumber);

  /// No description provided for @parentDashboardLogSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{repeats} تكرارات • {points} نقطة'**
  String parentDashboardLogSubtitle(String repeats, String points);

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
  /// **'{total, plural, =0{{totalText} عنصر} =1{عنصر واحد} =2{عنصران} few{{totalText} عناصر} many{{totalText} عنصرًا} other{{totalText} عنصر}} • {completedText} مكتمل'**
  String dailyPlanHeaderSummary(
    int total,
    String totalText,
    String completedText,
  );

  /// No description provided for @dailyPlanProgressCount.
  ///
  /// In ar, this message translates to:
  /// **'{completed} من {total}'**
  String dailyPlanProgressCount(String completed, String total);

  /// No description provided for @dailyPlanAllDoneShort.
  ///
  /// In ar, this message translates to:
  /// **'✅ أحسنت! أكملت خطتك اليوم'**
  String get dailyPlanAllDoneShort;

  /// No description provided for @dailyPlanRemainingItems.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{تبقّى عنصر واحد} =2{تبقّى عنصران} few{تبقّى {countText} عناصر} many{تبقّى {countText} عنصرًا} other{تبقّى {countText} عنصر}}'**
  String dailyPlanRemainingItems(int count, String countText);

  /// No description provided for @dailyPlanAyahTitle.
  ///
  /// In ar, this message translates to:
  /// **'آية {ayahNumber}'**
  String dailyPlanAyahTitle(String ayahNumber);

  /// No description provided for @dailyPlanSurahAyahTitle.
  ///
  /// In ar, this message translates to:
  /// **'{surah}، آية {ayahNumber}'**
  String dailyPlanSurahAyahTitle(String surah, String ayahNumber);

  /// No description provided for @dailyPlanRecordStats.
  ///
  /// In ar, this message translates to:
  /// **'قوة: {strength} • مراجعات: {reviews}'**
  String dailyPlanRecordStats(String strength, String reviews);

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

  /// No description provided for @dailyPlanNoPlanTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم تنشئ خطة حفظ بعد'**
  String get dailyPlanNoPlanTitle;

  /// No description provided for @dailyPlanNoPlanSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ خطتك لتظهر لك هنا آيات الحفظ والمراجعة كل يوم.'**
  String get dailyPlanNoPlanSubtitle;

  /// No description provided for @dailyPlanCreatePlanAction.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ خطتك'**
  String get dailyPlanCreatePlanAction;

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
  /// **'هذه السورة فيها {count, plural, =0{{countText} آية} =1{آية واحدة} =2{آيتان} few{{countText} آيات} many{{countText} آية} other{{countText} آية}}'**
  String customPlanSurahAyahLimit(int count, String countText);

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
  /// **'مراجعة آيات آخر ٥ أيام'**
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
  /// **'{count, plural, =0{{countText} أسبوع} =1{أسبوع واحد} =2{أسبوعان} few{{countText} أسابيع} many{{countText} أسبوعًا} other{{countText} أسبوع}} تقريبًا'**
  String customPlanApproxWeeks(int count, String countText);

  /// No description provided for @customPlanApproxMonths.
  ///
  /// In ar, this message translates to:
  /// **'{count} شهر تقريباً'**
  String customPlanApproxMonths(String count);

  /// No description provided for @customPlanApproxYears.
  ///
  /// In ar, this message translates to:
  /// **'{count} سنة تقريباً'**
  String customPlanApproxYears(String count);

  /// No description provided for @customPlanEstimatedScope.
  ///
  /// In ar, this message translates to:
  /// **'{surahs, plural, =0{{surahsText} سورة} =1{سورة واحدة} =2{سورتان} few{{surahsText} سور} many{{surahsText} سورة} other{{surahsText} سورة}} • ~{ayahs, plural, =0{{ayahsText} آية} =1{آية واحدة} =2{آيتان} few{{ayahsText} آيات} many{{ayahsText} آية} other{{ayahsText} آية}}'**
  String customPlanEstimatedScope(
    int surahs,
    String surahsText,
    int ayahs,
    String ayahsText,
  );

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
  /// **'٣ آيات/يوم • ٥ أيام • ٢٠ دقيقة'**
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
  /// **'٥ آيات/يوم • ٦ أيام • ٣٠ دقيقة'**
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
  /// **'١٠ آيات/يوم • كل الأسبوع • ٥٠ دقيقة'**
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
  /// **'من الناس إلى النبأ • ٣ آيات/يوم • ٢٠ دقيقة'**
  String get customPlanPresetJuzAmmaDesc;

  /// No description provided for @customPlanMinutesLimitHint.
  ///
  /// In ar, this message translates to:
  /// **'في {minutes} دقيقة يتسع وقت الجلسة لنحو {count} آيات جديدة فقط. زد مدة الجلسة لتحقيق هدفك اليومي.'**
  String customPlanMinutesLimitHint(String minutes, String count);

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
  /// **'{ayahsPerDay, plural, =0{{ayahsText} آية} =1{آية واحدة} =2{آيتان} few{{ayahsText} آيات} many{{ayahsText} آية} other{{ayahsText} آية}} يوميًا • {daysPerWeek, plural, =0{{daysText} يوم} =1{يوم واحد} =2{يومان} few{{daysText} أيام} many{{daysText} يومًا} other{{daysText} يوم}} أسبوعيًا'**
  String customPlanSummaryLoad(
    int ayahsPerDay,
    String ayahsText,
    int daysPerWeek,
    String daysText,
  );

  /// No description provided for @customPlanSummarySession.
  ///
  /// In ar, this message translates to:
  /// **'{minutes, plural, =0{{minutesText} دقيقة} =1{دقيقة واحدة} =2{دقيقتان} few{{minutesText} دقائق} many{{minutesText} دقيقة} other{{minutesText} دقيقة}} للجلسة • مستوى {difficulty}'**
  String customPlanSummarySession(
    int minutes,
    String minutesText,
    String difficulty,
  );

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
  String kidsQuranPageLabel(String pageNumber);

  /// No description provided for @kidsQuranLongPressHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً على أي آية لتسمعها'**
  String get kidsQuranLongPressHint;

  /// No description provided for @kidsQuranListenPage.
  ///
  /// In ar, this message translates to:
  /// **'استمع للصفحة'**
  String get kidsQuranListenPage;

  /// No description provided for @kidsQuranPausePage.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get kidsQuranPausePage;

  /// No description provided for @kidsReaderConfirmPage.
  ///
  /// In ar, this message translates to:
  /// **'قرأت هذه الصفحة'**
  String get kidsReaderConfirmPage;

  /// No description provided for @kidsReaderPageConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت! سُجّلت قراءتك'**
  String get kidsReaderPageConfirmed;

  /// No description provided for @parentDashboardPinInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمزًا من ٤ أرقام'**
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

  /// No description provided for @parentDashboardChildLinked.
  ///
  /// In ar, this message translates to:
  /// **'تم ربط الطفل بنجاح'**
  String get parentDashboardChildLinked;

  /// No description provided for @parentDashboardReminderSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث التذكير'**
  String get parentDashboardReminderSaved;

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
  String hifzReviewRangeHint(String startAyah, String endAyah);

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

  /// No description provided for @memorizationExitSessionMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد إكمال هذه الجلسة لاحقًا من حيث توقفت، أم التخلّي عنها؟ ستُضاف الآيات التي أخفقت فيها ولم تجتزها إلى المراجعة عند التخلّي.'**
  String get memorizationExitSessionMessage;

  /// No description provided for @memorizationExitSessionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من الجلسة؟'**
  String get memorizationExitSessionTitle;

  /// No description provided for @memorizationSaveAndLeave.
  ///
  /// In ar, this message translates to:
  /// **'أكمل لاحقًا'**
  String get memorizationSaveAndLeave;

  /// No description provided for @memorizationDiscardSession.
  ///
  /// In ar, this message translates to:
  /// **'التخلّي عن الجلسة'**
  String get memorizationDiscardSession;

  /// No description provided for @hifzAyahNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'آية {ayahNumber}'**
  String hifzAyahNumberLabel(String ayahNumber);

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

  /// No description provided for @notificationStreakMercyTitle.
  ///
  /// In ar, this message translates to:
  /// **'الله رحيم — سلسلتك مستنياك 🌿'**
  String get notificationStreakMercyTitle;

  /// No description provided for @notificationStreakMercyBody.
  ///
  /// In ar, this message translates to:
  /// **'فاتك يوم، وسلسلتك رجعت من جديد… كمّل وردك النهاردة 🤍'**
  String get notificationStreakMercyBody;

  /// No description provided for @notificationStreakAlertTitle.
  ///
  /// In ar, this message translates to:
  /// **'⚠️ متضيعش إنجاز {count} يوم!'**
  String notificationStreakAlertTitle(Object count);

  /// No description provided for @notificationStreakGentleTitle.
  ///
  /// In ar, this message translates to:
  /// **'سلسلتك من {count} يوم مستنياك'**
  String notificationStreakGentleTitle(Object count);

  /// No description provided for @notificationStreakGentleBody.
  ///
  /// In ar, this message translates to:
  /// **'دقايق مراجعة النهاردة تحافظ على سلسلتك.. وقت ما تحب 🌿'**
  String get notificationStreakGentleBody;

  /// No description provided for @notificationSmartReminderTitle.
  ///
  /// In ar, this message translates to:
  /// **'وقت قراءتك المعتاد'**
  String get notificationSmartReminderTitle;

  /// No description provided for @notificationSmartReminderBody.
  ///
  /// In ar, this message translates to:
  /// **'الوقت ده عادةً بتقرا فيه.. في آيات مستنياك.'**
  String get notificationSmartReminderBody;

  /// No description provided for @notificationChannelStreakGentleName.
  ///
  /// In ar, this message translates to:
  /// **'تذكير لطيف بالسلسلة'**
  String get notificationChannelStreakGentleName;

  /// No description provided for @notificationChannelStreakGentleDescription.
  ///
  /// In ar, this message translates to:
  /// **'تذكير هادئ قبل تنبيه حماية السلسلة'**
  String get notificationChannelStreakGentleDescription;

  /// No description provided for @notificationChannelSmartName.
  ///
  /// In ar, this message translates to:
  /// **'تذكير ذكي'**
  String get notificationChannelSmartName;

  /// No description provided for @notificationChannelSmartDescription.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات في وقت قراءتك المعتاد'**
  String get notificationChannelSmartDescription;

  /// No description provided for @notificationStreakAlertBody.
  ///
  /// In ar, this message translates to:
  /// **'فاضل تكة صغيرة وتكمل وردك النهاردة.. متكسلش، تقدر تعملها! 🔥'**
  String get notificationStreakAlertBody;

  /// No description provided for @notificationActionReviewStart.
  ///
  /// In ar, this message translates to:
  /// **'⚡ ابدأ المراجعة'**
  String get notificationActionReviewStart;

  /// No description provided for @notificationActionDailyWird.
  ///
  /// In ar, this message translates to:
  /// **'📖 الورد اليومي'**
  String get notificationActionDailyWird;

  /// No description provided for @notificationActionStreakProtect.
  ///
  /// In ar, this message translates to:
  /// **'🔥 احمي السلسلة الآن'**
  String get notificationActionStreakProtect;

  /// No description provided for @notificationActionReadWird.
  ///
  /// In ar, this message translates to:
  /// **'📖 قراءة الورد'**
  String get notificationActionReadWird;

  /// No description provided for @notificationActionReadDailyAyah.
  ///
  /// In ar, this message translates to:
  /// **'✨ قراءة آية اليوم'**
  String get notificationActionReadDailyAyah;

  /// No description provided for @notificationActionShareAyah.
  ///
  /// In ar, this message translates to:
  /// **'↗️ مشاركة الآية'**
  String get notificationActionShareAyah;

  /// No description provided for @notificationActionMorningAzkar.
  ///
  /// In ar, this message translates to:
  /// **'☀️ قراءة أذكار الصباح'**
  String get notificationActionMorningAzkar;

  /// No description provided for @notificationActionEveningAzkar.
  ///
  /// In ar, this message translates to:
  /// **'🌙 قراءة أذكار المساء'**
  String get notificationActionEveningAzkar;

  /// No description provided for @notificationActionDailyDua.
  ///
  /// In ar, this message translates to:
  /// **'🤲 قراءة أدعية اليوم'**
  String get notificationActionDailyDua;

  /// No description provided for @notificationActionAzkar.
  ///
  /// In ar, this message translates to:
  /// **'✨ الأذكار'**
  String get notificationActionAzkar;

  /// No description provided for @notificationActionKidsReview.
  ///
  /// In ar, this message translates to:
  /// **'🌟 ابدأ التسميع يا بطل'**
  String get notificationActionKidsReview;

  /// No description provided for @notificationActionReadKahf.
  ///
  /// In ar, this message translates to:
  /// **'📖 قراءة سورة الكهف'**
  String get notificationActionReadKahf;

  /// No description provided for @notificationActionOpenMushaf.
  ///
  /// In ar, this message translates to:
  /// **'✨ المصحف'**
  String get notificationActionOpenMushaf;

  /// No description provided for @notificationActionTahajjudDua.
  ///
  /// In ar, this message translates to:
  /// **'🤲 أدعية قيام الليل'**
  String get notificationActionTahajjudDua;

  /// No description provided for @notificationActionFollowKhatmah.
  ///
  /// In ar, this message translates to:
  /// **'📖 متابعة الختمة'**
  String get notificationActionFollowKhatmah;

  /// No description provided for @notificationActionReadQuran.
  ///
  /// In ar, this message translates to:
  /// **'📖 قراءة القرآن'**
  String get notificationActionReadQuran;

  /// No description provided for @notificationActionPostPrayerAzkar.
  ///
  /// In ar, this message translates to:
  /// **'📿 أذكار بعد الصلاة'**
  String get notificationActionPostPrayerAzkar;

  /// No description provided for @notificationChannelRemindersName.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات تالية'**
  String get notificationChannelRemindersName;

  /// No description provided for @notificationChannelRemindersDescription.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات يومية للمراجعة والحفظ'**
  String get notificationChannelRemindersDescription;

  /// No description provided for @notificationChannelStreakName.
  ///
  /// In ar, this message translates to:
  /// **'حماية السلسلة'**
  String get notificationChannelStreakName;

  /// No description provided for @notificationChannelStreakDescription.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات للحفاظ على سلسلة أيام الحفظ'**
  String get notificationChannelStreakDescription;

  /// No description provided for @notificationChannelDailyAyahName.
  ///
  /// In ar, this message translates to:
  /// **'آية اليوم'**
  String get notificationChannelDailyAyahName;

  /// No description provided for @notificationChannelDailyAyahDescription.
  ///
  /// In ar, this message translates to:
  /// **'آية يومية من القرآن الكريم مع التدبر'**
  String get notificationChannelDailyAyahDescription;

  /// No description provided for @notificationChannelMorningAzkarName.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get notificationChannelMorningAzkarName;

  /// No description provided for @notificationChannelMorningAzkarDescription.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات أذكار الصباح'**
  String get notificationChannelMorningAzkarDescription;

  /// No description provided for @notificationChannelEveningAzkarName.
  ///
  /// In ar, this message translates to:
  /// **'أذكار المساء'**
  String get notificationChannelEveningAzkarName;

  /// No description provided for @notificationChannelEveningAzkarDescription.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات أذكار المساء'**
  String get notificationChannelEveningAzkarDescription;

  /// No description provided for @notificationChannelDailyDuaName.
  ///
  /// In ar, this message translates to:
  /// **'دعاء اليوم'**
  String get notificationChannelDailyDuaName;

  /// No description provided for @notificationChannelDailyDuaDescription.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات دعاء اليوم والابتهالات'**
  String get notificationChannelDailyDuaDescription;

  /// No description provided for @notificationChannelKidsName.
  ///
  /// In ar, this message translates to:
  /// **'تسميع الأطفال'**
  String get notificationChannelKidsName;

  /// No description provided for @notificationChannelKidsDescription.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات مراجعة وتسميع الأطفال'**
  String get notificationChannelKidsDescription;

  /// No description provided for @notificationChannelKahfName.
  ///
  /// In ar, this message translates to:
  /// **'سورة الكهف'**
  String get notificationChannelKahfName;

  /// No description provided for @notificationChannelKahfDescription.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات قراءة سورة الكهف يوم الجمعة'**
  String get notificationChannelKahfDescription;

  /// No description provided for @notificationChannelTahajjudName.
  ///
  /// In ar, this message translates to:
  /// **'قيام الليل والوتر'**
  String get notificationChannelTahajjudName;

  /// No description provided for @notificationChannelTahajjudDescription.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات قيام الليل في الثلث الأخير'**
  String get notificationChannelTahajjudDescription;

  /// No description provided for @notificationChannelKhatmahName.
  ///
  /// In ar, this message translates to:
  /// **'ورد الختمة'**
  String get notificationChannelKhatmahName;

  /// No description provided for @notificationChannelKhatmahDescription.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات متابعة ورد الختمة'**
  String get notificationChannelKhatmahDescription;

  /// No description provided for @notificationChannelMilestonesName.
  ///
  /// In ar, this message translates to:
  /// **'احتفالات الإنجاز'**
  String get notificationChannelMilestonesName;

  /// No description provided for @notificationChannelMilestonesDesc.
  ///
  /// In ar, this message translates to:
  /// **'احتفال عند إتمام حفظ جزء أو سورة أو ختمة كاملة'**
  String get notificationChannelMilestonesDesc;

  /// No description provided for @notificationMilestoneJuzTitle.
  ///
  /// In ar, this message translates to:
  /// **'🎉 أتممت حفظ الجزء {juz}!'**
  String notificationMilestoneJuzTitle(String juz);

  /// No description provided for @notificationMilestoneJuzBody.
  ///
  /// In ar, this message translates to:
  /// **'ما شاء الله، تبارك الله! أكملت حفظ الجزء {juz} كاملاً. بارك الله فيك وثبّته في قلبك.'**
  String notificationMilestoneJuzBody(String juz);

  /// No description provided for @notificationMilestoneSurahTitle.
  ///
  /// In ar, this message translates to:
  /// **'🎉 أتممت حفظ سورة {surah}!'**
  String notificationMilestoneSurahTitle(String surah);

  /// No description provided for @notificationMilestoneSurahBody.
  ///
  /// In ar, this message translates to:
  /// **'ما شاء الله! أكملت حفظ سورة {surah} كاملة. تقبّل الله منك وجعلها نوراً لك.'**
  String notificationMilestoneSurahBody(String surah);

  /// No description provided for @notificationMilestoneKhatmahTitle.
  ///
  /// In ar, this message translates to:
  /// **'🎉 أتممت ختمة القرآن الكريم!'**
  String get notificationMilestoneKhatmahTitle;

  /// No description provided for @notificationMilestoneKhatmahBody.
  ///
  /// In ar, this message translates to:
  /// **'الحمد لله! أتممت ختمة كاملة من القرآن الكريم. تقبّل الله منك وجازاك بأفضل الجزاء.'**
  String get notificationMilestoneKhatmahBody;

  /// No description provided for @notificationMilestoneStreakTitle.
  ///
  /// In ar, this message translates to:
  /// **'🔥 ٣٠ يوماً متتالياً!'**
  String get notificationMilestoneStreakTitle;

  /// No description provided for @notificationMilestoneStreakBody.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثون يوماً من المواظبة على المراجعة، ما شاء الله! أكمل سلسلة نورك.'**
  String get notificationMilestoneStreakBody;

  /// No description provided for @notificationChannelPrayerName.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة والأذان'**
  String get notificationChannelPrayerName;

  /// No description provided for @notificationChannelPrayerDescription.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات عند دخول وقت الصلاة'**
  String get notificationChannelPrayerDescription;

  /// No description provided for @notificationChannelPrayerAthanName.
  ///
  /// In ar, this message translates to:
  /// **'صوت أذان الصلاة'**
  String get notificationChannelPrayerAthanName;

  /// No description provided for @notificationChannelPrayerAthanDescription.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الصلوات بمقطع الأذان المرفق'**
  String get notificationChannelPrayerAthanDescription;

  /// No description provided for @notificationChannelPrayerCompanionName.
  ///
  /// In ar, this message translates to:
  /// **'مرافق الصلاة'**
  String get notificationChannelPrayerCompanionName;

  /// No description provided for @notificationChannelPrayerCompanionDescription.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات مرافق الصلاة اللطيفة للتأكيد الذاتي'**
  String get notificationChannelPrayerCompanionDescription;

  /// No description provided for @notificationActionCompanionConfirm.
  ///
  /// In ar, this message translates to:
  /// **'نعم، صليتها'**
  String get notificationActionCompanionConfirm;

  /// No description provided for @notificationActionCompanionPrayNow.
  ///
  /// In ar, this message translates to:
  /// **'سأصلي الآن'**
  String get notificationActionCompanionPrayNow;

  /// No description provided for @notificationActionCompanionRemindLater.
  ///
  /// In ar, this message translates to:
  /// **'ذكرني لاحقاً'**
  String get notificationActionCompanionRemindLater;

  /// No description provided for @notificationCompanionPreparationTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعداد للصلاة'**
  String get notificationCompanionPreparationTitle;

  /// No description provided for @notificationCompanionPreparationBody.
  ///
  /// In ar, this message translates to:
  /// **'اقترب وقت صلاة {prayer}'**
  String notificationCompanionPreparationBody(Object prayer);

  /// No description provided for @notificationCompanionCheckInTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرافق الصلاة'**
  String get notificationCompanionCheckInTitle;

  /// No description provided for @notificationCompanionCheckInBody.
  ///
  /// In ar, this message translates to:
  /// **'هل صليت {prayer}؟'**
  String notificationCompanionCheckInBody(Object prayer);

  /// No description provided for @notificationCompanionFollowUpTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرافق الصلاة'**
  String get notificationCompanionFollowUpTitle;

  /// No description provided for @notificationCompanionFollowUpBody.
  ///
  /// In ar, this message translates to:
  /// **'تذكير لطيف: هل صليت {prayer}؟'**
  String notificationCompanionFollowUpBody(Object prayer);

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

  /// No description provided for @notificationFridayKahfTitle.
  ///
  /// In ar, this message translates to:
  /// **'نور ما بين الجمعتين 🌿'**
  String get notificationFridayKahfTitle;

  /// No description provided for @notificationWeeklyImpactTitle.
  ///
  /// In ar, this message translates to:
  /// **'أثرك هذا الأسبوع 🌿'**
  String get notificationWeeklyImpactTitle;

  /// No description provided for @notificationWeeklyImpactBody.
  ///
  /// In ar, this message translates to:
  /// **'{count} أيام من أسبوعك كانت مع القرآن — وكل صفحة فيها أثر باقٍ'**
  String notificationWeeklyImpactBody(String count);

  /// No description provided for @notificationWeeklyImpactQuietBody.
  ///
  /// In ar, this message translates to:
  /// **'أسبوع جديد يبدأ — وصفحة واحدة بتفرق 🌱'**
  String get notificationWeeklyImpactQuietBody;

  /// No description provided for @notificationSettingsWeeklyImpact.
  ///
  /// In ar, this message translates to:
  /// **'أثر الأسبوع (الجمعة)'**
  String get notificationSettingsWeeklyImpact;

  /// No description provided for @notificationFridayKahfBody.
  ///
  /// In ar, this message translates to:
  /// **'جمعة مباركة! لا تنسَ قراءة سورة الكهف اليوم لتضيء لك ما بين الجمعتين ✨'**
  String get notificationFridayKahfBody;

  /// No description provided for @notificationTahajjudTitle.
  ///
  /// In ar, this message translates to:
  /// **'قيام الليل والدعاء المستجاب 🌙'**
  String get notificationTahajjudTitle;

  /// No description provided for @notificationTahajjudBody.
  ///
  /// In ar, this message translates to:
  /// **'ركعتان في جوف الليل وسؤال لله تعالى في ساعة الاستجابة.. تقبل الله طاعتك 🤲'**
  String get notificationTahajjudBody;

  /// No description provided for @notificationKhatmahTitle.
  ///
  /// In ar, this message translates to:
  /// **'ورد الختمة اليومي 📖'**
  String get notificationKhatmahTitle;

  /// No description provided for @notificationKhatmahBody.
  ///
  /// In ar, this message translates to:
  /// **'واصل مسيرتك المباركة مع الختمة.. وردك اليوم بانتظارك 🌿'**
  String get notificationKhatmahBody;

  /// No description provided for @notificationKhatmahBodyWithTarget.
  ///
  /// In ar, this message translates to:
  /// **'وردك اليوم: من صفحة {start} إلى {end}.. اقتربت من إتمام الختمة! ✨'**
  String notificationKhatmahBodyWithTarget(Object start, Object end);

  /// No description provided for @notificationPrayerTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان الآن موعد صلاة {prayer} 🕌'**
  String notificationPrayerTitle(Object prayer);

  /// No description provided for @notificationPrayerBody.
  ///
  /// In ar, this message translates to:
  /// **'حي على الصلاة، حي على الفلاح.. بارك الله في صلاتك'**
  String get notificationPrayerBody;

  /// No description provided for @notificationSettingsFridayKahf.
  ///
  /// In ar, this message translates to:
  /// **'سورة الكهف (الجمعة)'**
  String get notificationSettingsFridayKahf;

  /// No description provided for @notificationSettingsFridayKahfSub.
  ///
  /// In ar, this message translates to:
  /// **'تذكير أسبوعي بقراءة سورة الكهف يوم الجمعة'**
  String get notificationSettingsFridayKahfSub;

  /// No description provided for @notificationSettingsTahajjud.
  ///
  /// In ar, this message translates to:
  /// **'قيام الليل والوتر'**
  String get notificationSettingsTahajjud;

  /// No description provided for @notificationSettingsTahajjudSub.
  ///
  /// In ar, this message translates to:
  /// **'تذكير يومي في الثلث الأخير من الليل'**
  String get notificationSettingsTahajjudSub;

  /// No description provided for @notificationSettingsKhatmah.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الختمة'**
  String get notificationSettingsKhatmah;

  /// No description provided for @notificationSettingsKhatmahSub.
  ///
  /// In ar, this message translates to:
  /// **'تذكير يومي بالورد المحدد لختمتك الحالية'**
  String get notificationSettingsKhatmahSub;

  /// No description provided for @notificationSettingsPrayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get notificationSettingsPrayerTimes;

  /// No description provided for @notificationSettingsPrayerTimesSub.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات عند حلول أوقات الصلوات الخمس'**
  String get notificationSettingsPrayerTimesSub;

  /// No description provided for @notificationSettingsPrayerAthan.
  ///
  /// In ar, this message translates to:
  /// **'الأذان الكامل'**
  String get notificationSettingsPrayerAthan;

  /// No description provided for @notificationSettingsPrayerAthanSub.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الأذان الكامل عند دخول وقت الصلاة مع إمكانية إيقافه'**
  String get notificationSettingsPrayerAthanSub;

  /// No description provided for @muezzinPickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختيار المؤذن'**
  String get muezzinPickerTitle;

  /// No description provided for @muezzinPickerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر صوت الأذان المفضل لديك، واستمع لمعاينة قبل الحفظ'**
  String get muezzinPickerSubtitle;

  /// No description provided for @muezzinDefault.
  ///
  /// In ar, this message translates to:
  /// **'الأذان الافتراضي'**
  String get muezzinDefault;

  /// No description provided for @muezzinPickerSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get muezzinPickerSave;

  /// No description provided for @muezzinPreviewPlay.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get muezzinPreviewPlay;

  /// No description provided for @muezzinPreviewStop.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف المعاينة'**
  String get muezzinPreviewStop;

  /// No description provided for @muezzinFajrSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'أذان الفجر'**
  String get muezzinFajrSectionTitle;

  /// No description provided for @muezzinFajrSameAsGeneral.
  ///
  /// In ar, this message translates to:
  /// **'مثل باقي الصلوات'**
  String get muezzinFajrSameAsGeneral;

  /// No description provided for @muezzinFajrBadge.
  ///
  /// In ar, this message translates to:
  /// **'فجر'**
  String get muezzinFajrBadge;

  /// No description provided for @muezzinFajrSummary.
  ///
  /// In ar, this message translates to:
  /// **'{general} للصلوات، و{fajr} للفجر'**
  String muezzinFajrSummary(String general, String fajr);

  /// No description provided for @notificationSettingsPrayerNeedsTimes.
  ///
  /// In ar, this message translates to:
  /// **'أكمل إعداد مواقيت الصلاة واختر مدينتك أولًا'**
  String get notificationSettingsPrayerNeedsTimes;

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
  /// **'تبدأ تالية بتعريف قصير تختار فيه مسار الكبار أو الأطفال، ثم تنقلك إلى الرئيسية. يمكنك استخدامها كضيف وتسجيل الدخول لاحقًا.'**
  String get tutorialS1Does;

  /// No description provided for @tutorialS1Open.
  ///
  /// In ar, this message translates to:
  /// **'يظهر عند أول فتح للتطبيق. بعد ذلك استخدم الشريط السفلي للتنقل بين الرئيسية والقرآن والحفظ والأذكار والتقدم.'**
  String get tutorialS1Open;

  /// No description provided for @tutorialS1Useful.
  ///
  /// In ar, this message translates to:
  /// **'مفيد للمستخدم الجديد الذي يريد فهم خريطة التطبيق قبل القراءة أو الحفظ.'**
  String get tutorialS1Useful;

  /// No description provided for @tutorialS1Step1.
  ///
  /// In ar, this message translates to:
  /// **'أنهِ صفحات التعريف، أو اضغط «تخطي».'**
  String get tutorialS1Step1;

  /// No description provided for @tutorialS1Step2.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسار الكبار أو الأطفال، ثم تابع كضيف أو سجّل الدخول.'**
  String get tutorialS1Step2;

  /// No description provided for @tutorialS1Step3.
  ///
  /// In ar, this message translates to:
  /// **'استخدم الشريط السفلي للانتقال بين الأقسام الأساسية.'**
  String get tutorialS1Step3;

  /// No description provided for @tutorialS1Tip1.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ من الرئيسية فهي تجمع قراءة اليوم وتقدمك والاختصارات.'**
  String get tutorialS1Tip1;

  /// No description provided for @tutorialS1Tip2.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تغيير مسار الحفظ لاحقًا من الإعدادات ثم «القرآن والحفظ».'**
  String get tutorialS1Tip2;

  /// No description provided for @tutorialS1Note1.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول اختياري. بدونه يبقى تقدمك على هذا الجهاز.'**
  String get tutorialS1Note1;

  /// No description provided for @tutorialS1Note2.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات خلف أيقونة الترس أعلى الرئيسية.'**
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
  /// **'تعرض الرئيسية الصلاة القادمة، وبطاقة رئيسية لما تفعله بعد ذلك، والورد اليومي، وسلسلتك ونقاطك، وآية اليوم، ونشاطك الأخير.'**
  String get tutorialS2Does;

  /// No description provided for @tutorialS2Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط تبويب الرئيسية في الشريط السفلي.'**
  String get tutorialS2Open;

  /// No description provided for @tutorialS2Useful.
  ///
  /// In ar, this message translates to:
  /// **'أفضل نقطة انطلاق يومية: القراءة والحفظ والمتابعة في شاشة واحدة.'**
  String get tutorialS2Useful;

  /// No description provided for @tutorialS2Step1.
  ///
  /// In ar, this message translates to:
  /// **'اضغط البطاقة الرئيسية لاستكمال القراءة أو استئناف جلسة أو فتح خطة اليوم.'**
  String get tutorialS2Step1;

  /// No description provided for @tutorialS2Step2.
  ///
  /// In ar, this message translates to:
  /// **'اضغط «شيء آخر» لعرض خيارات أخرى.'**
  String get tutorialS2Step2;

  /// No description provided for @tutorialS2Step3.
  ///
  /// In ar, this message translates to:
  /// **'افتح الإعدادات من أيقونة الترس أعلى الصفحة.'**
  String get tutorialS2Step3;

  /// No description provided for @tutorialS2Step4.
  ///
  /// In ar, this message translates to:
  /// **'اضغط «اختيار المدينة» لتحديد مدينتك لمواقيت الصلاة.'**
  String get tutorialS2Step4;

  /// No description provided for @tutorialS2Tip1.
  ///
  /// In ar, this message translates to:
  /// **'الحلقة تُظهر نسبة ما حفظته من القرآن كله فتنمو ببطء. النقاط السبع هي آخر سبعة أيام وتنتهي باليوم.'**
  String get tutorialS2Tip1;

  /// No description provided for @tutorialS2Tip2.
  ///
  /// In ar, this message translates to:
  /// **'اضغط الأيقونات تحت آية اليوم لمشاركتها أو فتحها في المصحف أو الاستماع إليها.'**
  String get tutorialS2Tip2;

  /// No description provided for @tutorialS2Note1.
  ///
  /// In ar, this message translates to:
  /// **'بعض البطاقات تظهر فقط عند وجود بيانات، مثل ختمة بدأتها أو موضع قراءة محفوظ.'**
  String get tutorialS2Note1;

  /// No description provided for @tutorialS2Note2.
  ///
  /// In ar, this message translates to:
  /// **'يمكن إخفاء بطاقة الحساب بعلامة ✕.'**
  String get tutorialS2Note2;

  /// No description provided for @tutorialS3Title.
  ///
  /// In ar, this message translates to:
  /// **'قراءة القرآن'**
  String get tutorialS3Title;

  /// No description provided for @tutorialS3Cat.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get tutorialS3Cat;

  /// No description provided for @tutorialS3Does.
  ///
  /// In ar, this message translates to:
  /// **'يعرض تبويب القرآن السور والأجزاء وعلاماتك المرجعية. ويعرض القارئ صفحة المصحف بألوان التجويد مع الصوت والعلامات ووضع التركيز.'**
  String get tutorialS3Does;

  /// No description provided for @tutorialS3Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط تبويب القرآن ثم اختر سورة أو جزءًا. ويمكنك فتح ورد اليوم من الرئيسية.'**
  String get tutorialS3Open;

  /// No description provided for @tutorialS3Useful.
  ///
  /// In ar, this message translates to:
  /// **'للورد اليومي، وللبحث عن آية، وللقراءة قبل جلسة الحفظ.'**
  String get tutorialS3Useful;

  /// No description provided for @tutorialS3Step1.
  ///
  /// In ar, this message translates to:
  /// **'اختر سورة من القائمة، أو استخدم مربع البحث في الأعلى.'**
  String get tutorialS3Step1;

  /// No description provided for @tutorialS3Step2.
  ///
  /// In ar, this message translates to:
  /// **'اسحب لتقليب الصفحة.'**
  String get tutorialS3Step2;

  /// No description provided for @tutorialS3Step3.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على الآية مطولًا للاستماع إليها أو نسخها أو وضع علامة أو مشاركتها أو بدء حفظها.'**
  String get tutorialS3Step3;

  /// No description provided for @tutorialS3Step4.
  ///
  /// In ar, this message translates to:
  /// **'افتح القائمة (النقاط الثلاث) للانتقال إلى صفحة أو سورة أو جزء، أو اختيار القارئ، أو تشغيل ألوان التجويد وإيقافها، أو الدخول إلى وضع التركيز.'**
  String get tutorialS3Step4;

  /// No description provided for @tutorialS3Step5.
  ///
  /// In ar, this message translates to:
  /// **'ابقَ في الصفحة بضع ثوانٍ أثناء القراءة: تُحتسب مقروءة تلقائيًا.'**
  String get tutorialS3Step5;

  /// No description provided for @tutorialS3Tip1.
  ///
  /// In ar, this message translates to:
  /// **'استمع إلى الآية قبل حفظها لتضبط النطق.'**
  String get tutorialS3Tip1;

  /// No description provided for @tutorialS3Tip2.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة «أكمل القراءة» في تبويب القرآن تعيدك إلى آخر صفحة.'**
  String get tutorialS3Tip2;

  /// No description provided for @tutorialS3Note1.
  ///
  /// In ar, this message translates to:
  /// **'نص القرآن مضمّن في التطبيق فيُعرض دون اتصال.'**
  String get tutorialS3Note1;

  /// No description provided for @tutorialS3Note2.
  ///
  /// In ar, this message translates to:
  /// **'الصوت يحتاج اتصالًا ما لم يكن مخزّنًا مسبقًا.'**
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
  /// **'ابحث عن سورة باسمها أو عن آية بكلماتها، واحفظ الآيات المهمة كعلامات مرجعية.'**
  String get tutorialS4Does;

  /// No description provided for @tutorialS4Open.
  ///
  /// In ar, this message translates to:
  /// **'استخدم مربع البحث أعلى تبويب القرآن أو أيقونة البحث في الرئيسية. وللعلامات تبويب خاص في شاشة القرآن.'**
  String get tutorialS4Open;

  /// No description provided for @tutorialS4Useful.
  ///
  /// In ar, this message translates to:
  /// **'لجمع آيات المراجعة أو الآيات المتشابهة أو مواضع تريد الرجوع إليها.'**
  String get tutorialS4Useful;

  /// No description provided for @tutorialS4Step1.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم سورة أو كلمات من آية.'**
  String get tutorialS4Step1;

  /// No description provided for @tutorialS4Step2.
  ///
  /// In ar, this message translates to:
  /// **'افتح السورة أو الآية من النتائج.'**
  String get tutorialS4Step2;

  /// No description provided for @tutorialS4Step3.
  ///
  /// In ar, this message translates to:
  /// **'اضغط الآية مطولًا في القارئ واختر «إشارة مرجعية».'**
  String get tutorialS4Step3;

  /// No description provided for @tutorialS4Step4.
  ///
  /// In ar, this message translates to:
  /// **'افتح تبويب الإشارة المرجعية للرجوع إلى الآيات المحفوظة أو حذفها.'**
  String get tutorialS4Step4;

  /// No description provided for @tutorialS4Tip1.
  ///
  /// In ar, this message translates to:
  /// **'ضع علامة عند بداية كل مقطع حفظ لتعود إليه بسرعة.'**
  String get tutorialS4Tip1;

  /// No description provided for @tutorialS4Tip2.
  ///
  /// In ar, this message translates to:
  /// **'البحث يتجاهل التشكيل فيمكنك الكتابة بدونه.'**
  String get tutorialS4Tip2;

  /// No description provided for @tutorialS4Note1.
  ///
  /// In ar, this message translates to:
  /// **'بحث الآيات يعرض ٥٠ نتيجة كحد أقصى: أضف كلمات لتضييقه.'**
  String get tutorialS4Note1;

  /// No description provided for @tutorialS4Note2.
  ///
  /// In ar, this message translates to:
  /// **'حذف علامة لا يؤثر في أي تقدم قراءة أو حفظ.'**
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
  /// **'يجمع تبويب الحفظ خطة اليوم والتدرب بالسورة واختبار الاستماع والمراجعة بالتسميع. وتمر كل آية بالتعلّم ثم الحفظ ثم التسميع.'**
  String get tutorialS5Does;

  /// No description provided for @tutorialS5Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط تبويب الحفظ. وعند أول استخدام تختار مسار الكبار أو الأطفال.'**
  String get tutorialS5Open;

  /// No description provided for @tutorialS5Useful.
  ///
  /// In ar, this message translates to:
  /// **'للحفظ المنهجي مع مراجعات متباعدة حتى يثبت ما تحفظه.'**
  String get tutorialS5Useful;

  /// No description provided for @tutorialS5Step1.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ خطة، أو اختر سورة من «تدرّب بالسورة».'**
  String get tutorialS5Step1;

  /// No description provided for @tutorialS5Step2.
  ///
  /// In ar, this message translates to:
  /// **'التعلّم: استمع إلى الآية واقرأها.'**
  String get tutorialS5Step2;

  /// No description provided for @tutorialS5Step3.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ: جرّب دون النظر، واستعن بالتلميحات (أول كلمة، أوائل الكلمات، إظهار الآية) عند الحاجة فقط.'**
  String get tutorialS5Step3;

  /// No description provided for @tutorialS5Step4.
  ///
  /// In ar, this message translates to:
  /// **'التسميع: سجّل تلاوتك، أو قيّم نفسك بصدق إن لم يتوفر التعرّف على الكلام. ثم تُسمَّع مجموعة الآيات معًا.'**
  String get tutorialS5Step4;

  /// No description provided for @tutorialS5Tip1.
  ///
  /// In ar, this message translates to:
  /// **'التلميحات تُسجَّل وتؤثر في موعد عودة الآية للمراجعة.'**
  String get tutorialS5Tip1;

  /// No description provided for @tutorialS5Tip2.
  ///
  /// In ar, this message translates to:
  /// **'غيّر صرامة التحقق من التسميع من الإعدادات ثم «القرآن والحفظ» ثم «مستوى الدقة».'**
  String get tutorialS5Tip2;

  /// No description provided for @tutorialS5Note1.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من الجلسة يسألك: أكمل لاحقًا أم تخلَّ عنها.'**
  String get tutorialS5Note1;

  /// No description provided for @tutorialS5Note2.
  ///
  /// In ar, this message translates to:
  /// **'إن لم يتوفر التعرّف على الكلام أو إذن الميكروفون فالتقييم الذاتي مسار معتمد.'**
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
  /// **'أذكار الصباح والمساء وأذكار عامة وأدعية، مع عداد تكرار وفهرس ومسبحة حرة وورد ذكي يتبع وقت اليوم.'**
  String get tutorialS6Does;

  /// No description provided for @tutorialS6Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط تبويب الأذكار ثم اختر الصباح أو المساء أو الأذكار العامة أو الأدعية أو الورد الذكي أو المسبحة الحرة.'**
  String get tutorialS6Open;

  /// No description provided for @tutorialS6Useful.
  ///
  /// In ar, this message translates to:
  /// **'للورد الصباحي والمسائي وجلسات التسبيح ومشاركة دعاء بسرعة.'**
  String get tutorialS6Useful;

  /// No description provided for @tutorialS6Step1.
  ///
  /// In ar, this message translates to:
  /// **'اختر فئة؛ وتظهر فئة الوقت الحالي مميّزة في الأعلى.'**
  String get tutorialS6Step1;

  /// No description provided for @tutorialS6Step2.
  ///
  /// In ar, this message translates to:
  /// **'اضغط العداد مرة لكل تكرار؛ وينتقل إلى الذكر التالي عند الإتمام.'**
  String get tutorialS6Step2;

  /// No description provided for @tutorialS6Step3.
  ///
  /// In ar, this message translates to:
  /// **'افتح الفهرس للانتقال إلى ذكر محدد.'**
  String get tutorialS6Step3;

  /// No description provided for @tutorialS6Step4.
  ///
  /// In ar, this message translates to:
  /// **'غيّر حجم الخط، وانسخ الذكر أو شاركه عند الحاجة.'**
  String get tutorialS6Step4;

  /// No description provided for @tutorialS6Step5.
  ///
  /// In ar, this message translates to:
  /// **'عند الانتهاء أعد ضبط الجلسة أو ارجع.'**
  String get tutorialS6Step5;

  /// No description provided for @tutorialS6Tip1.
  ///
  /// In ar, this message translates to:
  /// **'فعّل تذكيرات الصباح والمساء من الإعدادات ثم «الإشعارات».'**
  String get tutorialS6Tip1;

  /// No description provided for @tutorialS6Tip2.
  ///
  /// In ar, this message translates to:
  /// **'اضغط العداد مطولًا للتراجع عن آخر عدّة.'**
  String get tutorialS6Tip2;

  /// No description provided for @tutorialS6Note1.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار مضمّنة في التطبيق وتعمل دون اتصال.'**
  String get tutorialS6Note1;

  /// No description provided for @tutorialS6Note2.
  ///
  /// In ar, this message translates to:
  /// **'العدّادات لجلسة اليوم الحالي، وليست شهادة حفظ.'**
  String get tutorialS6Note2;

  /// No description provided for @tutorialS7Title.
  ///
  /// In ar, this message translates to:
  /// **'الخطة اليومية والمراجعة'**
  String get tutorialS7Title;

  /// No description provided for @tutorialS7Cat.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get tutorialS7Cat;

  /// No description provided for @tutorialS7Does.
  ///
  /// In ar, this message translates to:
  /// **'تقدّم خطتك كل يوم آيات جديدة ومراجعات. وتعود المراجعات بجدول يعتمد على جودة تسميعك فيثبت ما تحفظه.'**
  String get tutorialS7Does;

  /// No description provided for @tutorialS7Open.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ ثم «أكمل خطة اليوم»، أو البطاقة الرئيسية في الرئيسية.'**
  String get tutorialS7Open;

  /// No description provided for @tutorialS7Useful.
  ///
  /// In ar, this message translates to:
  /// **'لحفظ متدرج مع مراجعة ذكية بدل الاعتماد على الذاكرة وحدها.'**
  String get tutorialS7Useful;

  /// No description provided for @tutorialS7Step1.
  ///
  /// In ar, this message translates to:
  /// **'افتح «أكمل خطة اليوم» من تبويب الحفظ.'**
  String get tutorialS7Step1;

  /// No description provided for @tutorialS7Step2.
  ///
  /// In ar, this message translates to:
  /// **'أتمم آيات اليوم الجديدة.'**
  String get tutorialS7Step2;

  /// No description provided for @tutorialS7Step3.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ «مراجعة بالتسميع» عندما تستحق آيات المراجعة: تعرض الشارة عددها.'**
  String get tutorialS7Step3;

  /// No description provided for @tutorialS7Step4.
  ///
  /// In ar, this message translates to:
  /// **'افتح «تفاصيل خطة اليوم» لترى ما أُنجز وما بقي.'**
  String get tutorialS7Step4;

  /// No description provided for @tutorialS7Step5.
  ///
  /// In ar, this message translates to:
  /// **'جرّب «اختبار الاستماع» بعد حفظ بضع آيات: يشغّل آية ويطلب منك ذكر سورتها أو إكمالها.'**
  String get tutorialS7Step5;

  /// No description provided for @tutorialS7Tip1.
  ///
  /// In ar, this message translates to:
  /// **'قيّم نفسك بصدق: فهو يحدد قوة الآية وموعد عودتها.'**
  String get tutorialS7Tip1;

  /// No description provided for @tutorialS7Tip2.
  ///
  /// In ar, this message translates to:
  /// **'إن بدت الخطة ثقيلة فخفّض عدد الآيات اليومية من «إعدادات الخطة».'**
  String get tutorialS7Tip2;

  /// No description provided for @tutorialS7Note1.
  ///
  /// In ar, this message translates to:
  /// **'في أيام الراحة (حسب أيام الأسبوع المحددة) تحصل على المراجعات فقط.'**
  String get tutorialS7Note1;

  /// No description provided for @tutorialS7Note2.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج اختبار الاستماع إلى خمس آيات محفوظة على الأقل.'**
  String get tutorialS7Note2;

  /// No description provided for @tutorialS8Title.
  ///
  /// In ar, this message translates to:
  /// **'إعداد خطتك'**
  String get tutorialS8Title;

  /// No description provided for @tutorialS8Cat.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get tutorialS8Cat;

  /// No description provided for @tutorialS8Does.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ خطتك من قالب سريع أو من الصفر: الاسم ونطاق السور والآيات اليومية وأيام الأسبوع ومدة الجلسة والصعوبة والمراجعات.'**
  String get tutorialS8Does;

  /// No description provided for @tutorialS8Open.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ ثم «أنشئ خطتك»، أو «إعدادات الخطة» لاحقًا.'**
  String get tutorialS8Open;

  /// No description provided for @tutorialS8Useful.
  ///
  /// In ar, this message translates to:
  /// **'لهدف محدد مثل حفظ جزء بعينه، أو لتنظيم حفظ طفل.'**
  String get tutorialS8Useful;

  /// No description provided for @tutorialS8Step1.
  ///
  /// In ar, this message translates to:
  /// **'اختر قالبًا سريعًا (خفيف، متوازن، مكثف، جزء عم) أو املأ الحقول بنفسك.'**
  String get tutorialS8Step1;

  /// No description provided for @tutorialS8Step2.
  ///
  /// In ar, this message translates to:
  /// **'اختر نطاق السور. إن اخترت «طفل» فستُنقل إلى مسار الأطفال، لأن خطط الأطفال تُدار منه.'**
  String get tutorialS8Step2;

  /// No description provided for @tutorialS8Step3.
  ///
  /// In ar, this message translates to:
  /// **'اضبط عدد الآيات اليومية وأيام الأسبوع ومدة الجلسة.'**
  String get tutorialS8Step3;

  /// No description provided for @tutorialS8Step4.
  ///
  /// In ar, this message translates to:
  /// **'اختر الصعوبة وشغّل المراجعة القريبة والبعيدة أو أوقفها.'**
  String get tutorialS8Step4;

  /// No description provided for @tutorialS8Step5.
  ///
  /// In ar, this message translates to:
  /// **'احفظ الخطة وابدأها.'**
  String get tutorialS8Step5;

  /// No description provided for @tutorialS8Tip1.
  ///
  /// In ar, this message translates to:
  /// **'مدة الجلسة تحدد الآيات الجديدة بنحو أربع دقائق للآية. وتظهر ملاحظة إن قصرت الدقائق عن هدفك.'**
  String get tutorialS8Tip1;

  /// No description provided for @tutorialS8Tip2.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بقدر صغير لتبني العادة ثم زِد.'**
  String get tutorialS8Tip2;

  /// No description provided for @tutorialS8Note1.
  ///
  /// In ar, this message translates to:
  /// **'يمكن حذف الخطة من شاشة الإعداد نفسها.'**
  String get tutorialS8Note1;

  /// No description provided for @tutorialS8Note2.
  ///
  /// In ar, this message translates to:
  /// **'مدة الإنهاء الظاهرة في الشاشة تقدير تقريبي.'**
  String get tutorialS8Note2;

  /// No description provided for @tutorialS9Title.
  ///
  /// In ar, this message translates to:
  /// **'وضع الأطفال وأدوات ولي الأمر'**
  String get tutorialS9Title;

  /// No description provided for @tutorialS9Cat.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get tutorialS9Cat;

  /// No description provided for @tutorialS9Does.
  ///
  /// In ar, this message translates to:
  /// **'رحلة بيوت حفظ للأطفال بنجوم ومستويات واستماع متكرر، مع أدوات لولي الأمر للمتابعة.'**
  String get tutorialS9Does;

  /// No description provided for @tutorialS9Open.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسار الأطفال. ويُضبط رمز ولي الأمر أثناء إعداد الطفل. وتظهر أدوات ولي الأمر في الرئيسية بعد تسجيل الدخول.'**
  String get tutorialS9Open;

  /// No description provided for @tutorialS9Useful.
  ///
  /// In ar, this message translates to:
  /// **'للأطفال والمبتدئين، أو لولي أمر يريد متابعة النجوم والجلسات والمكافآت.'**
  String get tutorialS9Useful;

  /// No description provided for @tutorialS9Step1.
  ///
  /// In ar, this message translates to:
  /// **'اختر مسار الأطفال، ثم أدخل اسم الطفل وعمره وسورة البداية ورمز ولي أمر من أربعة أرقام.'**
  String get tutorialS9Step1;

  /// No description provided for @tutorialS9Step2.
  ///
  /// In ar, this message translates to:
  /// **'في رئيسية الأطفال اضغط «استكمل الآن»، واستمع إلى الآية ثلاث مرات، ثم جرّب من حفظك.'**
  String get tutorialS9Step2;

  /// No description provided for @tutorialS9Step3.
  ///
  /// In ar, this message translates to:
  /// **'إن لم يعمل التسجيل فاضغط «أتممت الحفظ بنفسي»: يدخل ولي الأمر الرمز للتأكيد.'**
  String get tutorialS9Step3;

  /// No description provided for @tutorialS9Step4.
  ///
  /// In ar, this message translates to:
  /// **'تابع خريطة الرحلة: تُفتح البيوت واحدًا بعد آخر كلما أتممت المهام.'**
  String get tutorialS9Step4;

  /// No description provided for @tutorialS9Tip1.
  ///
  /// In ar, this message translates to:
  /// **'حافظ على سرية الرمز: فهو يحمي أيضًا الخروج من مسار الأطفال.'**
  String get tutorialS9Tip1;

  /// No description provided for @tutorialS9Tip2.
  ///
  /// In ar, this message translates to:
  /// **'استخدم تبويب المصحف في رئيسية الأطفال ليقرأ الطفل في القرآن.'**
  String get tutorialS9Tip2;

  /// No description provided for @tutorialS9Note1.
  ///
  /// In ar, this message translates to:
  /// **'ربط طفل من جهاز آخر يحتاج إلى حساب.'**
  String get tutorialS9Note1;

  /// No description provided for @tutorialS9Note2.
  ///
  /// In ar, this message translates to:
  /// **'طفل واحد لكل جهاز: يستخدم بقية الأطفال أجهزتهم الخاصة مرتبطة بولي الأمر.'**
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
  /// **'يعرض إحصاءات القراءة والحفظ وسلسلتك اليومية والإنجازات وشهاداتك، ويتيح مشاركة تقدمك.'**
  String get tutorialS10Does;

  /// No description provided for @tutorialS10Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط تبويب التقدم في الشريط السفلي.'**
  String get tutorialS10Open;

  /// No description provided for @tutorialS10Useful.
  ///
  /// In ar, this message translates to:
  /// **'للمراجعة الأسبوعية والاحتفال بالإنجازات ومتابعة الاستمرار.'**
  String get tutorialS10Useful;

  /// No description provided for @tutorialS10Step1.
  ///
  /// In ar, this message translates to:
  /// **'راجع البطاقات العليا لأيام السلسلة والصفحات المقروءة والنقاط والمراجعات.'**
  String get tutorialS10Step1;

  /// No description provided for @tutorialS10Step2.
  ///
  /// In ar, this message translates to:
  /// **'افتح قسمي القراءة والحفظ لمعرفة الصفحات والآيات والسور والأجزاء.'**
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
  /// **'تظهر شهاداتك عند إتمام سورة أو جزء أو القرآن كله.'**
  String get tutorialS10Step5;

  /// No description provided for @tutorialS10Tip1.
  ///
  /// In ar, this message translates to:
  /// **'قراءة الختمة تُحتسب في سلسلتك لكن لا تدخل في إحصاءات القراءة الحرة.'**
  String get tutorialS10Tip1;

  /// No description provided for @tutorialS10Tip2.
  ///
  /// In ar, this message translates to:
  /// **'الشهادات تعتمد على حفظ حقيقي للآيات المطلوبة.'**
  String get tutorialS10Tip2;

  /// No description provided for @tutorialS10Note1.
  ///
  /// In ar, this message translates to:
  /// **'بعض الإحصاءات تظهر فقط بعد أن تبدأ الحفظ.'**
  String get tutorialS10Note1;

  /// No description provided for @tutorialS10Note2.
  ///
  /// In ar, this message translates to:
  /// **'لا تتم المشاركة إلا عندما تختارها.'**
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
  /// **'تجمع حسابك وملفك الشخصي واللغة والمظهر وإعدادات القرآن والحفظ ومواقيت الصلاة والإشعارات ومعلومات التطبيق.'**
  String get tutorialS11Does;

  /// No description provided for @tutorialS11Open.
  ///
  /// In ar, this message translates to:
  /// **'اضغط أيقونة الترس في الرئيسية.'**
  String get tutorialS11Open;

  /// No description provided for @tutorialS11Useful.
  ///
  /// In ar, this message translates to:
  /// **'لتخصيص التطبيق وحماية تقدمك وضبط تذكيرات تناسب يومك.'**
  String get tutorialS11Useful;

  /// No description provided for @tutorialS11Step1.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول أو أنشئ حسابًا بالبريد وكلمة المرور لإدارة حسابك.'**
  String get tutorialS11Step1;

  /// No description provided for @tutorialS11Step2.
  ///
  /// In ar, this message translates to:
  /// **'عدّل اسمك من الملف الشخصي.'**
  String get tutorialS11Step2;

  /// No description provided for @tutorialS11Step3.
  ///
  /// In ar, this message translates to:
  /// **'اختر العربية أو English، والمظهر الفاتح أو الداكن أو الأسود الكامل أو حسب النظام.'**
  String get tutorialS11Step3;

  /// No description provided for @tutorialS11Step4.
  ///
  /// In ar, this message translates to:
  /// **'من «القرآن والحفظ» اضبط التشغيل في الخلفية ومستوى الدقة، أو أعد ضبط المسار.'**
  String get tutorialS11Step4;

  /// No description provided for @tutorialS11Step5.
  ///
  /// In ar, this message translates to:
  /// **'من «مواقيت الصلاة» اختر مدينتك وطريقة الحساب.'**
  String get tutorialS11Step5;

  /// No description provided for @tutorialS11Step6.
  ///
  /// In ar, this message translates to:
  /// **'من «الإشعارات» فعّل أو أوقف تذكيرات المراجعة والسلسلة والأذكار والصلاة.'**
  String get tutorialS11Step6;

  /// No description provided for @tutorialS11Tip1.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسمك بالعربية ليظهر على الشهادات بشكل جميل.'**
  String get tutorialS11Tip1;

  /// No description provided for @tutorialS11Tip2.
  ///
  /// In ar, this message translates to:
  /// **'أعد ضبط المسار من «القرآن والحفظ» للتبديل بين الكبار والأطفال.'**
  String get tutorialS11Tip2;

  /// No description provided for @tutorialS11Note1.
  ///
  /// In ar, this message translates to:
  /// **'تحتاج الإشعارات إلى إذن النظام لتعمل.'**
  String get tutorialS11Note1;

  /// No description provided for @tutorialS11Note2.
  ///
  /// In ar, this message translates to:
  /// **'اللغة والمظهر محفوظان على هذا الجهاز.'**
  String get tutorialS11Note2;

  /// No description provided for @tutorialS12Title.
  ///
  /// In ar, this message translates to:
  /// **'العمل دون اتصال وبياناتك'**
  String get tutorialS12Title;

  /// No description provided for @tutorialS12Cat.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get tutorialS12Cat;

  /// No description provided for @tutorialS12Does.
  ///
  /// In ar, this message translates to:
  /// **'نصوص القرآن والأذكار مضمّنة في التطبيق. وتُحفظ تقدّمك وخططك وإعداداتك على الجهاز، ومع الحساب يُزامَن بعضها عبر الإنترنت.'**
  String get tutorialS12Does;

  /// No description provided for @tutorialS12Open.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد شاشة منفصلة: يعمل تلقائيًا أثناء استخدامك التطبيق.'**
  String get tutorialS12Open;

  /// No description provided for @tutorialS12Useful.
  ///
  /// In ar, this message translates to:
  /// **'لفهم ما يعمل دون اتصال وتجنب فقدان تقدم مهم.'**
  String get tutorialS12Useful;

  /// No description provided for @tutorialS12Step1.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ القرآن واستخدم الأذكار حتى دون إنترنت.'**
  String get tutorialS12Step1;

  /// No description provided for @tutorialS12Step2.
  ///
  /// In ar, this message translates to:
  /// **'واصل القراءة والحفظ: يُحفظ التقدم على الجهاز.'**
  String get tutorialS12Step2;

  /// No description provided for @tutorialS12Step3.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول عندما تريد ميزات الحساب أو استعادة تقدم حفظك.'**
  String get tutorialS12Step3;

  /// No description provided for @tutorialS12Tip1.
  ///
  /// In ar, this message translates to:
  /// **'على جهاز جديد سجّل الدخول لاستعادة ما يدعمه حسابك.'**
  String get tutorialS12Tip1;

  /// No description provided for @tutorialS12Tip2.
  ///
  /// In ar, this message translates to:
  /// **'اتصل بالإنترنت لتشغيل تلاوات غير مخزّنة.'**
  String get tutorialS12Tip2;

  /// No description provided for @tutorialS12Note1.
  ///
  /// In ar, this message translates to:
  /// **'مسح بيانات التطبيق من إعدادات النظام يزيل كل ما لم يُحفظ في حسابك.'**
  String get tutorialS12Note1;

  /// No description provided for @tutorialS12Note2.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج يزيل خطة الختمة وسجلها من هذا الجهاز: فهما محفوظان هنا فقط.'**
  String get tutorialS12Note2;

  /// No description provided for @tutorialS14Note2.
  ///
  /// In ar, this message translates to:
  /// **'قد تحتاج التنبيهات الدقيقة إلى إذن المنبّهات الدقيقة في إعدادات الهاتف.'**
  String get tutorialS14Note2;

  /// No description provided for @tutorialS14Note1.
  ///
  /// In ar, this message translates to:
  /// **'تُحسب المواقيت على الجهاز فتعمل دون اتصال.'**
  String get tutorialS14Note1;

  /// No description provided for @tutorialS14Tip2.
  ///
  /// In ar, this message translates to:
  /// **'إن لم تعرف الطريقة الأنسب فاختر ما تعتمده الجهة الرسمية في بلدك.'**
  String get tutorialS14Tip2;

  /// No description provided for @tutorialS14Tip1.
  ///
  /// In ar, this message translates to:
  /// **'إن لم تكن مدينتك في القائمة فاستخدم موقعًا مخصصًا: انسخ إحداثياتها من تطبيق الخرائط.'**
  String get tutorialS14Tip1;

  /// No description provided for @tutorialS14Step4.
  ///
  /// In ar, this message translates to:
  /// **'فعّل وضع سكينة الصلاة إن أردت أن تتوقف التلاوة عند دخول وقت الصلاة.'**
  String get tutorialS14Step4;

  /// No description provided for @tutorialS14Step3.
  ///
  /// In ar, this message translates to:
  /// **'فعّل تنبيهات الصلاة: تُفعَّل تلقائيًا أول مرة تحدد فيها موقعًا.'**
  String get tutorialS14Step3;

  /// No description provided for @tutorialS14Step2.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة الحساب (تلقائي حسب البلد افتراضيًا) وحساب وقت العصر.'**
  String get tutorialS14Step2;

  /// No description provided for @tutorialS14Step1.
  ///
  /// In ar, this message translates to:
  /// **'اختر البلد والمدينة، أو «موقع مخصص» لإدخال الإحداثيات.'**
  String get tutorialS14Step1;

  /// No description provided for @tutorialS14Useful.
  ///
  /// In ar, this message translates to:
  /// **'لمعرفة مواقيت الصلاة أينما كنت مع تنبيه عند حلول الوقت.'**
  String get tutorialS14Useful;

  /// No description provided for @tutorialS14Open.
  ///
  /// In ar, this message translates to:
  /// **'في الرئيسية اضغط «اختيار المدينة»، أو افتح الإعدادات ثم «مواقيت الصلاة».'**
  String get tutorialS14Open;

  /// No description provided for @tutorialS14Does.
  ///
  /// In ar, this message translates to:
  /// **'تعرض الرئيسية مواقيت الصلاة والصلاة القادمة، ويمكنها تنبيهك عند كل صلاة.'**
  String get tutorialS14Does;

  /// No description provided for @tutorialS14Cat.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get tutorialS14Cat;

  /// No description provided for @tutorialS14Title.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة والتنبيهات'**
  String get tutorialS14Title;

  /// No description provided for @tutorialS13Note2.
  ///
  /// In ar, this message translates to:
  /// **'تُحفظ على هذا الجهاز فقط، وتُحذف عند تسجيل الخروج.'**
  String get tutorialS13Note2;

  /// No description provided for @tutorialS13Note1.
  ///
  /// In ar, this message translates to:
  /// **'الختمة منفصلة عن القراءة الحرة: لا يحرّك أحدهما موضع الآخر.'**
  String get tutorialS13Note1;

  /// No description provided for @tutorialS13Tip2.
  ///
  /// In ar, this message translates to:
  /// **'إن تأخرت فاستخدم خيارات اللوحة للتعويض.'**
  String get tutorialS13Tip2;

  /// No description provided for @tutorialS13Tip1.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك إهداء الختمة لشخص عزيز عند إنشائها.'**
  String get tutorialS13Tip1;

  /// No description provided for @tutorialS13Step4.
  ///
  /// In ar, this message translates to:
  /// **'إن قرأت من مصحف ورقي فاستخدم «تسجيل» لإدخال الصفحات.'**
  String get tutorialS13Step4;

  /// No description provided for @tutorialS13Step3.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ ورد اليوم: تُسجَّل كل صفحة تقرؤها.'**
  String get tutorialS13Step3;

  /// No description provided for @tutorialS13Step2.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الختمة واضغط «متابعة القراءة» في اللوحة.'**
  String get tutorialS13Step2;

  /// No description provided for @tutorialS13Step1.
  ///
  /// In ar, this message translates to:
  /// **'اختر عدد الصفحات يوميًا أو المدة، ويمكنك تحديد صفحة البداية.'**
  String get tutorialS13Step1;

  /// No description provided for @tutorialS13Useful.
  ///
  /// In ar, this message translates to:
  /// **'لقراءة القرآن بانتظام بهدف واضح، كما في رمضان.'**
  String get tutorialS13Useful;

  /// No description provided for @tutorialS13Open.
  ///
  /// In ar, this message translates to:
  /// **'في الرئيسية اضغط «ابدأ ختمتك»، أو افتح بطاقة الختمة بعد أن تبدأها.'**
  String get tutorialS13Open;

  /// No description provided for @tutorialS13Does.
  ///
  /// In ar, this message translates to:
  /// **'خطط لقراءة القرآن كاملًا بالوتيرة التي تختارها: صفحات يوميًا أو عدد أيام. وتتابع تالية تقدمك صفحة بصفحة وتحفظ سجل الختمات المكتملة.'**
  String get tutorialS13Does;

  /// No description provided for @tutorialS13Cat.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get tutorialS13Cat;

  /// No description provided for @tutorialS13Title.
  ///
  /// In ar, this message translates to:
  /// **'الختمة: قراءة القرآن كاملًا'**
  String get tutorialS13Title;

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
  String certificateCelebrationMultiple(String count);

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
  /// **'{count, plural, =1{لديك آية واحدة متأخرة} =2{لديك آيتان متأخرتان} few{لديك {countText} آيات متأخرة} other{لديك {countText} آية متأخرة}}'**
  String reviewBacklogSubtitle(int count, String countText);

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

  /// No description provided for @khatmahContinueTitle.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الختمة'**
  String get khatmahContinueTitle;

  /// No description provided for @khatmahContinueSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أكمل قراءة ختمتك'**
  String get khatmahContinueSubtitle;

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
  /// **'مثال: A1B2-C3D4-E5F6'**
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
  /// **'على جهاز طفلك: افتح مسار الأطفال ← اضغط ⚙ ← «ربط ولي الأمر»، ثم امسح الرمز الظاهر أو اكتبه هنا.'**
  String get familyDashboardNoChildrenHint;

  /// Banner title
  ///
  /// In ar, this message translates to:
  /// **'اليوم في عائلتنا'**
  String get familyDashboardTodaySummaryTitle;

  /// Banner body showing active children and total points
  ///
  /// In ar, this message translates to:
  /// **'{count} نشط اليوم، {points} نقطة'**
  String familyDashboardTodaySummary(String count, String points);

  /// Badge for local (same-device) child
  ///
  /// In ar, this message translates to:
  /// **'على هذا الجهاز'**
  String get familyDashboardLocalBadge;

  /// Points earned today label on child card
  ///
  /// In ar, this message translates to:
  /// **'{points} نقطة اليوم'**
  String familyDashboardChildActiveToday(String points);

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
  /// **'{sessions} جلسة، {points} نقطة اليوم'**
  String childDetailTodayActivity(String sessions, String points);

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

  /// Section title for the child's published activity snapshot
  ///
  /// In ar, this message translates to:
  /// **'نشاط الطفل'**
  String get childDetailActivityTitle;

  /// Shown when the child device has not published an activity snapshot
  ///
  /// In ar, this message translates to:
  /// **'لم تصل بيانات النشاط من جهاز الطفل بعد'**
  String get childDetailActivityNotReceived;

  /// When the child's activity snapshot was last received
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث: {date}'**
  String childDetailActivityUpdatedAt(String date);

  /// Current and longest activity streak in days
  ///
  /// In ar, this message translates to:
  /// **'السلسلة الحالية: {days} · الأطول: {longest}'**
  String childDetailActivityStreak(String days, String longest);

  /// Active days in the trailing 30 days
  ///
  /// In ar, this message translates to:
  /// **'أيام النشاط في آخر ٣٠ يومًا: {days}'**
  String childDetailActivityActiveDays(String days);

  /// Total and today's read Mushaf pages
  ///
  /// In ar, this message translates to:
  /// **'الصفحات المقروءة: {total} · اليوم: {today}'**
  String childDetailActivityPages(String total, String today);

  /// Section title for recent sessions
  ///
  /// In ar, this message translates to:
  /// **'آخر الجلسات'**
  String get childDetailRecentSessions;

  /// Section title for rewards with count
  ///
  /// In ar, this message translates to:
  /// **'المكافآت ({count})'**
  String childDetailRewards(String count);

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

  /// No description provided for @v2SelfGradeAction.
  ///
  /// In ar, this message translates to:
  /// **'قيّم تسميعك بنفسك'**
  String get v2SelfGradeAction;

  /// No description provided for @v2SelfGradeTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف كان تسميعك من حفظك؟'**
  String get v2SelfGradeTitle;

  /// No description provided for @v2SelfGradeMastered.
  ///
  /// In ar, this message translates to:
  /// **'أتقنتها'**
  String get v2SelfGradeMastered;

  /// No description provided for @v2SelfGradeMasteredHint.
  ///
  /// In ar, this message translates to:
  /// **'سمّعتها كاملة دون تردّد'**
  String get v2SelfGradeMasteredHint;

  /// No description provided for @v2SelfGradeHesitated.
  ///
  /// In ar, this message translates to:
  /// **'تردّدت قليلاً'**
  String get v2SelfGradeHesitated;

  /// No description provided for @v2SelfGradeHesitatedHint.
  ///
  /// In ar, this message translates to:
  /// **'سمّعتها مع توقف أو خطأ بسيط؛ ستُراجَع قريباً'**
  String get v2SelfGradeHesitatedHint;

  /// No description provided for @v2SelfGradeForgot.
  ///
  /// In ar, this message translates to:
  /// **'لم أتذكّرها'**
  String get v2SelfGradeForgot;

  /// No description provided for @v2SelfGradeForgotHint.
  ///
  /// In ar, this message translates to:
  /// **'سنعيدها معك الآن'**
  String get v2SelfGradeForgotHint;

  /// No description provided for @v2SelfGradeRevealHint.
  ///
  /// In ar, this message translates to:
  /// **'سمّع من حفظك أولاً، ثم اكشف النص وقارن قبل أن تقيّم.'**
  String get v2SelfGradeRevealHint;

  /// No description provided for @v2SelfGradeRevealAction.
  ///
  /// In ar, this message translates to:
  /// **'اعرض الآية وقارن'**
  String get v2SelfGradeRevealAction;

  /// No description provided for @v2BlockRevealAction.
  ///
  /// In ar, this message translates to:
  /// **'اعرض المقطع وقارن'**
  String get v2BlockRevealAction;

  /// No description provided for @v2BlockGradeMastered.
  ///
  /// In ar, this message translates to:
  /// **'سمّعت المقطع كاملاً دون تعثّر'**
  String get v2BlockGradeMastered;

  /// No description provided for @v2BlockGradeHesitated.
  ///
  /// In ar, this message translates to:
  /// **'تردّدت في آية'**
  String get v2BlockGradeHesitated;

  /// No description provided for @v2BlockGradeForgot.
  ///
  /// In ar, this message translates to:
  /// **'نسيت آية'**
  String get v2BlockGradeForgot;

  /// No description provided for @v2StumbledAyahTitle.
  ///
  /// In ar, this message translates to:
  /// **'في أي آية تعثّرت؟'**
  String get v2StumbledAyahTitle;

  /// No description provided for @v2StumbledAyahOption.
  ///
  /// In ar, this message translates to:
  /// **'الآية {ayahNumber}'**
  String v2StumbledAyahOption(String ayahNumber);

  /// No description provided for @v2ManualRecallHint.
  ///
  /// In ar, this message translates to:
  /// **'لا يتوفر الميكروفون؟ أكّد أنك تسمّعت من حفظك وسيُسجَّل التقدم.'**
  String get v2ManualRecallHint;

  /// No description provided for @v2ManualBlockReviewAction.
  ///
  /// In ar, this message translates to:
  /// **'قيّم تسميع المقطع بنفسك'**
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
  /// **'النص مخفي الآن. سجّل الآيات من {startAyah} إلى {endAyah} كاملة بدون تلميحات.'**
  String v2BlockReviewSubtitle(String startAyah, String endAyah);

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

  /// No description provided for @closingMomentLabel.
  ///
  /// In ar, this message translates to:
  /// **'لحظة ختام'**
  String get closingMomentLabel;

  /// No description provided for @closingSummaryMemorization.
  ///
  /// In ar, this message translates to:
  /// **'تعلّمتَ {count, plural, =0{{countText} آية} =1{آية واحدة} =2{آيتين} few{{countText} آيات} many{{countText} آية} other{{countText} آية}} في هذه الجلسة، وبالمراجعة تثبت في حفظك بإذن الله.'**
  String closingSummaryMemorization(int count, String countText);

  /// No description provided for @closingSummaryReview.
  ///
  /// In ar, this message translates to:
  /// **'أتممتَ مراجعتك بثبات — ثبتها الله في قلبك.'**
  String get closingSummaryReview;

  /// No description provided for @v2ReviewSessionTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الحفظ'**
  String get v2ReviewSessionTitle;

  /// No description provided for @v2HintSchedulingNotice.
  ///
  /// In ar, this message translates to:
  /// **'التلميحات تُسجَّل وتؤثر على جدولة مراجعتك القادمة.'**
  String get v2HintSchedulingNotice;

  /// No description provided for @dailyPlanBacklogNotice.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{لديك آية واحدة مستحقة للمراجعة.} =2{لديك آيتان مستحقتان للمراجعة.} few{لديك {countText} آيات مستحقة للمراجعة.} other{لديك {countText} آية مستحقة للمراجعة.}} أكمل مراجعات اليوم لتُفتح الآيات الجديدة.'**
  String dailyPlanBacklogNotice(int count, String countText);

  /// No description provided for @dailyPlanStartReview.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ مراجعة اليوم'**
  String get dailyPlanStartReview;

  /// No description provided for @dailyPlanReviewDayNotice.
  ///
  /// In ar, this message translates to:
  /// **'اليوم يوم مراجعة في خطتك: لا آيات جديدة، ثبّت ما حفظت.'**
  String get dailyPlanReviewDayNotice;

  /// No description provided for @closingSummaryKhatmahWird.
  ///
  /// In ar, this message translates to:
  /// **'أتممتَ ورد اليوم — من صفحة {start} إلى {end} — أثرٌ باقٍ بإذن الله.'**
  String closingSummaryKhatmahWird(String start, String end);

  /// No description provided for @closingDuaButton.
  ///
  /// In ar, this message translates to:
  /// **'دعاء الختام'**
  String get closingDuaButton;

  /// No description provided for @closingDua.
  ///
  /// In ar, this message translates to:
  /// **'اللَّهُمَّ اجْعَلْ مَا حَفِظْتُ نُورًا لِي فِي قَلْبِي، وَذِكْرًا لِي عِنْدَكَ، وَاجْعَلْهُ نَاصِرًا لِي، وَانْفَعْنِي بِمَا عَلَّمْتَنِي وَعَلِّمْنِي مَا يَنْفَعُنِي.'**
  String get closingDua;

  /// No description provided for @closingDuaAmen.
  ///
  /// In ar, this message translates to:
  /// **'آمين'**
  String get closingDuaAmen;

  /// No description provided for @closingDone.
  ///
  /// In ar, this message translates to:
  /// **'تم بحمد الله'**
  String get closingDone;

  /// No description provided for @closingRestNote.
  ///
  /// In ar, this message translates to:
  /// **'خذ نفسًا… حفظك ينتظرك غدًا بإذن الله.'**
  String get closingRestNote;

  /// No description provided for @v2MemorizationHub.
  ///
  /// In ar, this message translates to:
  /// **'مركز الحفظ'**
  String get v2MemorizationHub;

  /// No description provided for @v2NextPlanItem.
  ///
  /// In ar, this message translates to:
  /// **'التالي في خطة اليوم ({count} متبقية)'**
  String v2NextPlanItem(String count);

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
  /// **'التعرّف على الكلام غير متوفر على هذا الجهاز. قيّم تسميعك بنفسك.'**
  String get v2MicrophoneUnavailable;

  /// No description provided for @v2TryRecordingAgain.
  ///
  /// In ar, this message translates to:
  /// **'حاول التسجيل مجددًا'**
  String get v2TryRecordingAgain;

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
  String v2RemediationAttempts(String count);

  /// No description provided for @v2AyahRange.
  ///
  /// In ar, this message translates to:
  /// **'الآيات من {startAyah} إلى {endAyah}'**
  String v2AyahRange(String startAyah, String endAyah);

  /// No description provided for @v2BlockProgress.
  ///
  /// In ar, this message translates to:
  /// **'اجتزتَ {passed} من {total}.'**
  String v2BlockProgress(String passed, String total);

  /// No description provided for @v2AyahOfBlock.
  ///
  /// In ar, this message translates to:
  /// **'الآية {current} من {total}'**
  String v2AyahOfBlock(String current, String total);

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

  /// No description provided for @v2ResultExcellent.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت! تسميع متقن'**
  String get v2ResultExcellent;

  /// No description provided for @v2ResultPassed.
  ///
  /// In ar, this message translates to:
  /// **'تم اجتياز الآية'**
  String get v2ResultPassed;

  /// No description provided for @v2ResultRetrying.
  ///
  /// In ar, this message translates to:
  /// **'اقتربت! حاول مرة أخرى'**
  String get v2ResultRetrying;

  /// No description provided for @v2ResultNeedsWork.
  ///
  /// In ar, this message translates to:
  /// **'يلزم مراجعة الآية'**
  String get v2ResultNeedsWork;

  /// No description provided for @v2ResultSimilarity.
  ///
  /// In ar, this message translates to:
  /// **'نسبة التطابق: {score}%'**
  String v2ResultSimilarity(String score);

  /// No description provided for @v2ResultManualGrade.
  ///
  /// In ar, this message translates to:
  /// **'تم تقييم التسميع ذاتيًا'**
  String get v2ResultManualGrade;

  /// No description provided for @v2ResultContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get v2ResultContinue;

  /// No description provided for @v2ResultRetryNow.
  ///
  /// In ar, this message translates to:
  /// **'أعد التسميع الآن'**
  String get v2ResultRetryNow;

  /// No description provided for @v2ResultReviewAyah.
  ///
  /// In ar, this message translates to:
  /// **'راجع الآية'**
  String get v2ResultReviewAyah;

  /// No description provided for @v2ResultWordsCorrect.
  ///
  /// In ar, this message translates to:
  /// **'صحيحة'**
  String get v2ResultWordsCorrect;

  /// No description provided for @v2ResultWordsMissing.
  ///
  /// In ar, this message translates to:
  /// **'ناقصة'**
  String get v2ResultWordsMissing;

  /// No description provided for @v2ResultWordsWrong.
  ///
  /// In ar, this message translates to:
  /// **'خاطئة'**
  String get v2ResultWordsWrong;

  /// No description provided for @v2ResultWordsExtra.
  ///
  /// In ar, this message translates to:
  /// **'زيادة'**
  String get v2ResultWordsExtra;

  /// No description provided for @v2LoopOff.
  ///
  /// In ar, this message translates to:
  /// **'تكرار: بدون'**
  String get v2LoopOff;

  /// No description provided for @v2LoopThree.
  ///
  /// In ar, this message translates to:
  /// **'تكرار: ٣ مرات'**
  String get v2LoopThree;

  /// No description provided for @v2LoopInfinite.
  ///
  /// In ar, this message translates to:
  /// **'تكرار: مستمر'**
  String get v2LoopInfinite;

  /// No description provided for @v2MaskedWordsHint.
  ///
  /// In ar, this message translates to:
  /// **'إظهار الكلمات المخفية'**
  String get v2MaskedWordsHint;

  /// No description provided for @v2MaskedWordsRevealed.
  ///
  /// In ar, this message translates to:
  /// **'الكلمات مخفية — حاول التذكر'**
  String get v2MaskedWordsRevealed;

  /// No description provided for @v2MaskedWordsFull.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء الكلمات'**
  String get v2MaskedWordsFull;

  /// No description provided for @v2FirstLettersHint.
  ///
  /// In ar, this message translates to:
  /// **'أوائل الكلمات'**
  String get v2FirstLettersHint;

  /// No description provided for @v2FirstLettersRevealed.
  ///
  /// In ar, this message translates to:
  /// **'ظهرت أوائل الكلمات — حاول التذكر'**
  String get v2FirstLettersRevealed;

  /// No description provided for @countAyahs.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{{countText} آية} =1{آية واحدة} =2{آيتان} few{{countText} آيات} many{{countText} آية} other{{countText} آية}}'**
  String countAyahs(int count, String countText);

  /// No description provided for @streakDaysUnit.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, few{أيام} many{يومًا} other{يوم}}'**
  String streakDaysUnit(int count);

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

  /// Child-friendly progress feedback after a near-miss recitation
  ///
  /// In ar, this message translates to:
  /// **'أنت قريب جدًا! أصبت {matched} من {total} كلمات. استمع مرة أخرى وحاول من جديد.'**
  String kidsRecitationCloseMatch(String matched, String total);

  /// No description provided for @kidsJourneyCompleteHint.
  ///
  /// In ar, this message translates to:
  /// **'أتممت الفاتحة وجزء عمّ كاملاً! أخبر وليّ أمرك بهذا الإنجاز العظيم.'**
  String get kidsJourneyCompleteHint;

  /// No description provided for @kidsHomeMissionInvalidTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مهمة من حرف إلى ١٢٠ حرفًا'**
  String get kidsHomeMissionInvalidTitle;

  /// No description provided for @kidsPolicyReduceMotion.
  ///
  /// In ar, this message translates to:
  /// **'تقليل الحركة'**
  String get kidsPolicyReduceMotion;

  /// No description provided for @kidsPolicyMaxSuggestions.
  ///
  /// In ar, this message translates to:
  /// **'عدد مهمات اليوم'**
  String get kidsPolicyMaxSuggestions;

  /// No description provided for @kidsPolicyHomeMissions.
  ///
  /// In ar, this message translates to:
  /// **'المهمات المنزلية'**
  String get kidsPolicyHomeMissions;

  /// No description provided for @kidsPolicyConflict.
  ///
  /// In ar, this message translates to:
  /// **'تغيّرت الإعدادات من جهاز آخر'**
  String get kidsPolicyConflict;

  /// No description provided for @kidsHomeMissionUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'المهمة ليست متاحة لهذا الإجراء'**
  String get kidsHomeMissionUnavailable;

  /// No description provided for @kidsPolicyUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل إعدادات الطفل الآن.'**
  String get kidsPolicyUnavailable;

  /// No description provided for @childDetailHomeMissions.
  ///
  /// In ar, this message translates to:
  /// **'المهمات المنزلية'**
  String get childDetailHomeMissions;

  /// No description provided for @childDetailAddHomeMission.
  ///
  /// In ar, this message translates to:
  /// **'أضف مهمة'**
  String get childDetailAddHomeMission;

  /// No description provided for @kidsHomeMissionAssigned.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الطفل'**
  String get kidsHomeMissionAssigned;

  /// No description provided for @kidsHomeMissionReportAction.
  ///
  /// In ar, this message translates to:
  /// **'أنجزتها!'**
  String get kidsHomeMissionReportAction;

  /// No description provided for @familyChildUnnamed.
  ///
  /// In ar, this message translates to:
  /// **'طفلي'**
  String get familyChildUnnamed;

  /// No description provided for @familyChildDetailsLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get familyChildDetailsLoading;

  /// No description provided for @kidsHomeMissionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مهام من ولي الأمر'**
  String get kidsHomeMissionsTitle;

  /// No description provided for @kidsHomeMissionNew.
  ///
  /// In ar, this message translates to:
  /// **'مهمة جديدة'**
  String get kidsHomeMissionNew;

  /// No description provided for @kidsHomeMissionWaitingGuardian.
  ///
  /// In ar, this message translates to:
  /// **'أخبرت ولي الأمر، وننتظر أن يراها'**
  String get kidsHomeMissionWaitingGuardian;

  /// No description provided for @kidsHomeMissionsPaused.
  ///
  /// In ar, this message translates to:
  /// **'أوقف ولي الأمر مهام البيت مؤقتًا، وستظهر هنا من جديد عند إعادة تشغيلها.'**
  String get kidsHomeMissionsPaused;

  /// No description provided for @kidsHomeMissionReported.
  ///
  /// In ar, this message translates to:
  /// **'أخبرنا الطفل أنه أنجزها'**
  String get kidsHomeMissionReported;

  /// No description provided for @kidsHomeMissionAcknowledged.
  ///
  /// In ar, this message translates to:
  /// **'اطّلع ولي الأمر'**
  String get kidsHomeMissionAcknowledged;

  /// No description provided for @kidsHomeMissionAcknowledgeAction.
  ///
  /// In ar, this message translates to:
  /// **'اطّلعت'**
  String get kidsHomeMissionAcknowledgeAction;

  /// No description provided for @kidsHomeMissionSuggestTidy.
  ///
  /// In ar, this message translates to:
  /// **'رتّب غرفتك'**
  String get kidsHomeMissionSuggestTidy;

  /// No description provided for @kidsHomeMissionSuggestHelp.
  ///
  /// In ar, this message translates to:
  /// **'ساعد في تجهيز المائدة'**
  String get kidsHomeMissionSuggestHelp;

  /// No description provided for @kidsHomeMissionSuggestKind.
  ///
  /// In ar, this message translates to:
  /// **'قل كلمة طيبة لأحد أفراد أسرتك'**
  String get kidsHomeMissionSuggestKind;

  /// No description provided for @kidsHomeMissionSuggestShare.
  ///
  /// In ar, this message translates to:
  /// **'شارك لعبتك مع غيرك'**
  String get kidsHomeMissionSuggestShare;

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
  String kidsSessionGoalValue(String minutes);

  /// No description provided for @kidsSessionGoalAgeDefault.
  ///
  /// In ar, this message translates to:
  /// **'حسب العمر'**
  String get kidsSessionGoalAgeDefault;

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
  String kidsSetupWeeklyGoalValue(String sessions);

  /// No description provided for @kidsSetupStartingSurah.
  ///
  /// In ar, this message translates to:
  /// **'سورة البداية'**
  String get kidsSetupStartingSurah;

  /// No description provided for @parentCommitmentDays.
  ///
  /// In ar, this message translates to:
  /// **'{count} أيام التزام'**
  String parentCommitmentDays(String count);

  /// No description provided for @parentDueReviews.
  ///
  /// In ar, this message translates to:
  /// **'{count} مراجعات مستحقة'**
  String parentDueReviews(String count);

  /// No description provided for @parentNeedsSupport.
  ///
  /// In ar, this message translates to:
  /// **'{count} آيات تحتاج دعمًا'**
  String parentNeedsSupport(String count);

  /// No description provided for @parentAverageDuration.
  ///
  /// In ar, this message translates to:
  /// **'متوسط {minutes} د'**
  String parentAverageDuration(String minutes);

  /// No description provided for @parentHintUses.
  ///
  /// In ar, this message translates to:
  /// **'{count} تلميحات'**
  String parentHintUses(String count);

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
  /// **'{count, plural, =0{{countText} صفحة} =1{صفحة واحدة} =2{صفحتان} few{{countText} صفحات} many{{countText} صفحة} other{{countText} صفحة}}'**
  String khatmahPages(int count, String countText);

  /// No description provided for @khatmahOrCustomPagesPerDay.
  ///
  /// In ar, this message translates to:
  /// **'أو عدد مخصص يومياً'**
  String get khatmahOrCustomPagesPerDay;

  /// No description provided for @khatmahOrChooseDuration.
  ///
  /// In ar, this message translates to:
  /// **'أو اختر مدة الختمة'**
  String get khatmahOrChooseDuration;

  /// No description provided for @khatmahStartFromPage.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ من الصفحة (اختياري)'**
  String get khatmahStartFromPage;

  /// No description provided for @khatmahStartFromPageHint.
  ///
  /// In ar, this message translates to:
  /// **'بعد الصفحة ٦٠٤ تكمل من الصفحة ١ حتى تتم الختمة'**
  String get khatmahStartFromPageHint;

  /// No description provided for @khatmahDurationDays.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{{countText} يوم} =1{يوم واحد} =2{يومان} few{{countText} أيام} many{{countText} يومًا} other{{countText} يوم}}'**
  String khatmahDurationDays(int count, String countText);

  /// No description provided for @khatmahDurationRamadan.
  ///
  /// In ar, this message translates to:
  /// **'رمضان (جزء يومياً)'**
  String get khatmahDurationRamadan;

  /// No description provided for @khatmahEG5.
  ///
  /// In ar, this message translates to:
  /// **'مثال: ٥'**
  String get khatmahEG5;

  /// No description provided for @khatmahEstimatedDuration.
  ///
  /// In ar, this message translates to:
  /// **'المدة التقديرية'**
  String get khatmahEstimatedDuration;

  /// No description provided for @khatmahDays.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{{countText} يوم} =1{يوم واحد} =2{يومان} few{{countText} أيام} many{{countText} يومًا} other{{countText} يوم}}'**
  String khatmahDays(int count, String countText);

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

  /// No description provided for @khatmahAdjustPreviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل جدول الختمة'**
  String get khatmahAdjustPreviewTitle;

  /// No description provided for @khatmahAdjustPreviewBody.
  ///
  /// In ar, this message translates to:
  /// **'الورد اليومي: {pages, plural, =0{{pagesText} صفحة} =1{صفحة واحدة} =2{صفحتان} few{{pagesText} صفحات} many{{pagesText} صفحة} other{{pagesText} صفحة}}\nالختام المتوقع: {date}'**
  String khatmahAdjustPreviewBody(int pages, String pagesText, String date);

  /// No description provided for @khatmahApplyAdjustment.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get khatmahApplyAdjustment;

  /// No description provided for @khatmahLoadFailureHint.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت قراءة بيانات الختمة على هذا الجهاز. أعد المحاولة.'**
  String get khatmahLoadFailureHint;

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
  /// **'أدخل رقم آخر صفحة قرأتها من المصحف الورقي (١ - ٦٠٤):'**
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
  /// **'{count, plural, =1{صفحة واحدة متبقية} =2{صفحتان متبقيتان} few{{countText} صفحات متبقية} other{{countText} صفحة متبقية}}'**
  String khatmahPagesLeft(int count, String countText);

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
  /// **'إنهاء القراءة'**
  String get khatmahSaveExit;

  /// No description provided for @khatmahPaceOnTrack.
  ///
  /// In ar, this message translates to:
  /// **'في الموعد — أحسنت'**
  String get khatmahPaceOnTrack;

  /// No description provided for @khatmahPaceAhead.
  ///
  /// In ar, this message translates to:
  /// **'متقدم — ستختم قبل موعدك ب{count, plural, =1{يوم واحد} =2{يومين} few{{countText} أيام} other{{countText} يوماً}}'**
  String khatmahPaceAhead(int count, String countText);

  /// No description provided for @khatmahRedistributeAction.
  ///
  /// In ar, this message translates to:
  /// **'أعد التوزيع للحفاظ على الموعد'**
  String get khatmahRedistributeAction;

  /// No description provided for @khatmahRedistributed.
  ///
  /// In ar, this message translates to:
  /// **'أُعيد توزيع الصفحات للحفاظ على موعد الختام'**
  String get khatmahRedistributed;

  /// No description provided for @khatmahPaceBehind.
  ///
  /// In ar, this message translates to:
  /// **'متأخر {count, plural, =1{صفحة واحدة} =2{صفحتين} few{{countText} صفحات} other{{countText} صفحة}} عن موعد الختام'**
  String khatmahPaceBehind(int count, String countText);

  /// No description provided for @khatmahStartNewKhatmah.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ ختمة جديدة'**
  String get khatmahStartNewKhatmah;

  /// No description provided for @khatmahThroughWirdEnd.
  ///
  /// In ar, this message translates to:
  /// **'حتى نهاية ورد اليوم (ص {page})'**
  String khatmahThroughWirdEnd(String page);

  /// No description provided for @khatmahCongratulations.
  ///
  /// In ar, this message translates to:
  /// **'مبارك ختم القرآن الكريم'**
  String get khatmahCongratulations;

  /// No description provided for @khatmahShareSummary.
  ///
  /// In ar, this message translates to:
  /// **'أتممت ختمة القرآن الكريم ({title}) في {days, plural, =1{يوم واحد} =2{يومين} few{{daysText} أيام} many{{daysText} يومًا} other{{daysText} يوم}}.\nعبر تطبيق تالية القرآني'**
  String khatmahShareSummary(String title, int days, String daysText);

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
  /// **'إهداء الختمة متاح للحي والمتوفى، والمتوفى أولى، والله أعلى وأعلم.'**
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

  /// No description provided for @khatmahRecipientGender.
  ///
  /// In ar, this message translates to:
  /// **'المُهدى إليه'**
  String get khatmahRecipientGender;

  /// No description provided for @khatmahRecipientMale.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get khatmahRecipientMale;

  /// No description provided for @khatmahRecipientFemale.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get khatmahRecipientFemale;

  /// No description provided for @khatmahEditDedication.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الإهداء'**
  String get khatmahEditDedication;

  /// No description provided for @khatmahDedicationSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ الإهداء'**
  String get khatmahDedicationSaved;

  /// No description provided for @khatmahWirdJuz.
  ///
  /// In ar, this message translates to:
  /// **'ورد اليوم: الجزء {juz}'**
  String khatmahWirdJuz(String juz);

  /// No description provided for @khatmahRepeatSameSettings.
  ///
  /// In ar, this message translates to:
  /// **'ختمة جديدة بنفس الإعدادات'**
  String get khatmahRepeatSameSettings;

  /// No description provided for @khatmahHistoryStats.
  ///
  /// In ar, this message translates to:
  /// **'{count} ختمات • المتوسط {avg} يوماً • الأسرع {fastest} يوماً'**
  String khatmahHistoryStats(String count, String avg, String fastest);

  /// No description provided for @khatmahJuzMapTitle.
  ///
  /// In ar, this message translates to:
  /// **'خريطة الختمة'**
  String get khatmahJuzMapTitle;

  /// No description provided for @khatmahJuzMapCell.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {juz}: {read} من {total} صفحة'**
  String khatmahJuzMapCell(String juz, String read, String total);

  /// No description provided for @khatmahCatchUpTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف تحب أن تعوّض؟'**
  String get khatmahCatchUpTitle;

  /// No description provided for @khatmahCatchUpOption.
  ///
  /// In ar, this message translates to:
  /// **'{pages} صفحة يومياً — الختم {date}'**
  String khatmahCatchUpOption(String pages, String date);

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

  /// No description provided for @brandName.
  ///
  /// In ar, this message translates to:
  /// **'تاليــة'**
  String get brandName;

  /// No description provided for @xpLabel.
  ///
  /// In ar, this message translates to:
  /// **'XP'**
  String get xpLabel;

  /// No description provided for @countOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'{count} من {total}'**
  String countOfTotal(String count, String total);

  /// No description provided for @homeTodayTitle.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get homeTodayTitle;

  /// No description provided for @homeTodayReading.
  ///
  /// In ar, this message translates to:
  /// **'ورد القراءة'**
  String get homeTodayReading;

  /// No description provided for @homeTodayMemorize.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get homeTodayMemorize;

  /// No description provided for @homeTodayReview.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة'**
  String get homeTodayReview;

  /// No description provided for @homeTodayAzkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get homeTodayAzkar;

  /// No description provided for @homeTodayDone.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get homeTodayDone;

  /// No description provided for @homeTodayTodo.
  ///
  /// In ar, this message translates to:
  /// **'متبقٍ'**
  String get homeTodayTodo;

  /// No description provided for @homeStreakAtRisk.
  ///
  /// In ar, this message translates to:
  /// **'سلسلتك في خطر'**
  String get homeStreakAtRisk;

  /// No description provided for @homeFreezesAvailable.
  ///
  /// In ar, this message translates to:
  /// **'{count} تجميد متاح'**
  String homeFreezesAvailable(String count);

  /// No description provided for @homeAyahOfDay.
  ///
  /// In ar, this message translates to:
  /// **'آية اليوم'**
  String get homeAyahOfDay;

  /// No description provided for @surahRevelationMeccan.
  ///
  /// In ar, this message translates to:
  /// **'مكية'**
  String get surahRevelationMeccan;

  /// No description provided for @surahRevelationMedinan.
  ///
  /// In ar, this message translates to:
  /// **'مدنية'**
  String get surahRevelationMedinan;

  /// No description provided for @ayahOfDaySurahMeta.
  ///
  /// In ar, this message translates to:
  /// **'{revelation}، {count, plural, =0{{countText} آية} =1{آية واحدة} =2{آيتان} few{{countText} آيات} many{{countText} آية} other{{countText} آية}}'**
  String ayahOfDaySurahMeta(String revelation, int count, String countText);

  /// No description provided for @ayahOfDayReadSurah.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ السورة كاملة'**
  String get ayahOfDayReadSurah;

  /// No description provided for @homeAyahContextFriday.
  ///
  /// In ar, this message translates to:
  /// **'آية ليوم الجمعة'**
  String get homeAyahContextFriday;

  /// No description provided for @homeAyahContextRamadanStart.
  ///
  /// In ar, this message translates to:
  /// **'آية لبداية رمضان'**
  String get homeAyahContextRamadanStart;

  /// No description provided for @homeAyahContextRamadan.
  ///
  /// In ar, this message translates to:
  /// **'آية لرمضان'**
  String get homeAyahContextRamadan;

  /// No description provided for @homeAyahContextLastTenNights.
  ///
  /// In ar, this message translates to:
  /// **'آية للعشر الأواخر'**
  String get homeAyahContextLastTenNights;

  /// No description provided for @homeAyahContextDhulHijjah.
  ///
  /// In ar, this message translates to:
  /// **'آية لأيام الحج'**
  String get homeAyahContextDhulHijjah;

  /// No description provided for @homeAyahContextArafah.
  ///
  /// In ar, this message translates to:
  /// **'آية ليوم عرفة'**
  String get homeAyahContextArafah;

  /// No description provided for @homeAyahContextEidAlAdha.
  ///
  /// In ar, this message translates to:
  /// **'آية لعيد الأضحى'**
  String get homeAyahContextEidAlAdha;

  /// No description provided for @homeAyahContextReading.
  ///
  /// In ar, this message translates to:
  /// **'آية لرحلة القراءة'**
  String get homeAyahContextReading;

  /// No description provided for @homeAyahContextMemorization.
  ///
  /// In ar, this message translates to:
  /// **'آية لرحلة الحفظ'**
  String get homeAyahContextMemorization;

  /// No description provided for @homeAyahContextSmartReview.
  ///
  /// In ar, this message translates to:
  /// **'آية للمراجعة'**
  String get homeAyahContextSmartReview;

  /// No description provided for @homeAyahContextAzkar.
  ///
  /// In ar, this message translates to:
  /// **'آية للأذكار'**
  String get homeAyahContextAzkar;

  /// No description provided for @homeAyahContextChildJourney.
  ///
  /// In ar, this message translates to:
  /// **'آية لرحلة الطفل'**
  String get homeAyahContextChildJourney;

  /// No description provided for @homeResumeListening.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الاستماع، {surah}'**
  String homeResumeListening(String surah);

  /// No description provided for @homeSomethingElse.
  ///
  /// In ar, this message translates to:
  /// **'شيء آخر'**
  String get homeSomethingElse;

  /// No description provided for @homeMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{count} د'**
  String homeMinutes(String count);

  /// No description provided for @homeOccasionFriday.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة، سورة الكهف'**
  String get homeOccasionFriday;

  /// No description provided for @homeOccasionRamadan.
  ///
  /// In ar, this message translates to:
  /// **'رمضان'**
  String get homeOccasionRamadan;

  /// No description provided for @homeOccasionLastTenNights.
  ///
  /// In ar, this message translates to:
  /// **'العشر الأواخر'**
  String get homeOccasionLastTenNights;

  /// No description provided for @homeSlotFridayTitle.
  ///
  /// In ar, this message translates to:
  /// **'سورة الكهف'**
  String get homeSlotFridayTitle;

  /// No description provided for @homeSlotFridayBody.
  ///
  /// In ar, this message translates to:
  /// **'يستحب قراءة سورة الكهف يوم الجمعة.'**
  String get homeSlotFridayBody;

  /// No description provided for @homeSlotRamadanTitle.
  ///
  /// In ar, this message translates to:
  /// **'قراءة رمضان'**
  String get homeSlotRamadanTitle;

  /// No description provided for @homeSlotRamadanBody.
  ///
  /// In ar, this message translates to:
  /// **'شهر مبارك — واصل وردك اليومي.'**
  String get homeSlotRamadanBody;

  /// No description provided for @homeSlotLastTenTitle.
  ///
  /// In ar, this message translates to:
  /// **'العشر الأواخر'**
  String get homeSlotLastTenTitle;

  /// No description provided for @homeSlotLastTenBody.
  ///
  /// In ar, this message translates to:
  /// **'التمس ليلة القدر بمزيد من القراءة والقيام.'**
  String get homeSlotLastTenBody;

  /// No description provided for @homeSlotStreakBody.
  ///
  /// In ar, this message translates to:
  /// **'سجّل نشاط اليوم قبل منتصف الليل لتحافظ على سلسلتك.'**
  String get homeSlotStreakBody;

  /// No description provided for @homeSlotKhatmahTitle.
  ///
  /// In ar, this message translates to:
  /// **'الختمة قاربت الاكتمال'**
  String get homeSlotKhatmahTitle;

  /// No description provided for @homeSlotKhatmahBody.
  ///
  /// In ar, this message translates to:
  /// **'أنت قريب من إتمام هذه الختمة.'**
  String get homeSlotKhatmahBody;

  /// No description provided for @homeSlotOpen.
  ///
  /// In ar, this message translates to:
  /// **'افتح'**
  String get homeSlotOpen;

  /// No description provided for @homeWeeklyReflectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get homeWeeklyReflectionTitle;

  /// No description provided for @homeWeeklyReflectionBody.
  ///
  /// In ar, this message translates to:
  /// **'{days} أيام نشاط، {count} أعمال'**
  String homeWeeklyReflectionBody(String days, String count);

  /// No description provided for @homeFirstRunTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ خطوتك الأولى'**
  String get homeFirstRunTitle;

  /// No description provided for @homeFirstRunBody.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ صفحة، أو ابدأ الحفظ، أو ابدأ ختمة.'**
  String get homeFirstRunBody;

  /// No description provided for @homeFirstRunRead.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ القرآن'**
  String get homeFirstRunRead;

  /// No description provided for @homeFirstRunMemorize.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الحفظ'**
  String get homeFirstRunMemorize;

  /// No description provided for @homeChildStreak.
  ///
  /// In ar, this message translates to:
  /// **'سلسلة {count} يوم'**
  String homeChildStreak(String count);

  /// No description provided for @homeSearchTitle.
  ///
  /// In ar, this message translates to:
  /// **'البحث في القرآن'**
  String get homeSearchTitle;

  /// No description provided for @homeSearchNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سور أو آيات مطابقة'**
  String get homeSearchNoResults;

  /// No description provided for @homePrayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get homePrayerTimes;

  /// No description provided for @homePrayerTimesEnabled.
  ///
  /// In ar, this message translates to:
  /// **'إظهار الصلاة التالية في الرئيسية'**
  String get homePrayerTimesEnabled;

  /// No description provided for @homePrayerCountry.
  ///
  /// In ar, this message translates to:
  /// **'البلد'**
  String get homePrayerCountry;

  /// No description provided for @homePrayerCity.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get homePrayerCity;

  /// No description provided for @homePrayerMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب'**
  String get homePrayerMethod;

  /// No description provided for @prayerMethodAuto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي حسب البلد'**
  String get prayerMethodAuto;

  /// No description provided for @homePrayerChip.
  ///
  /// In ar, this message translates to:
  /// **'{name} بعد {minutes} د'**
  String homePrayerChip(String name, String minutes);

  /// No description provided for @prayerTimelineNext.
  ///
  /// In ar, this message translates to:
  /// **'أذان {name} خلال {timeRemaining}'**
  String prayerTimelineNext(String name, String timeRemaining);

  /// No description provided for @prayerTimelineSunriseNext.
  ///
  /// In ar, this message translates to:
  /// **'الشروق خلال {timeRemaining}'**
  String prayerTimelineSunriseNext(String timeRemaining);

  /// No description provided for @prayerFajr.
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get prayerIsha;

  /// No description provided for @prayerMethodMwl.
  ///
  /// In ar, this message translates to:
  /// **'رابطة العالم الإسلامي'**
  String get prayerMethodMwl;

  /// No description provided for @prayerMethodEgyptian.
  ///
  /// In ar, this message translates to:
  /// **'الهيئة المصرية'**
  String get prayerMethodEgyptian;

  /// No description provided for @prayerMethodUmmAlQura.
  ///
  /// In ar, this message translates to:
  /// **'أم القرى'**
  String get prayerMethodUmmAlQura;

  /// No description provided for @prayerMethodKarachi.
  ///
  /// In ar, this message translates to:
  /// **'كراتشي'**
  String get prayerMethodKarachi;

  /// No description provided for @prayerMethodNorthAmerica.
  ///
  /// In ar, this message translates to:
  /// **'إسنا'**
  String get prayerMethodNorthAmerica;

  /// No description provided for @prayerMethodDubai.
  ///
  /// In ar, this message translates to:
  /// **'دبي'**
  String get prayerMethodDubai;

  /// No description provided for @prayerMethodKuwait.
  ///
  /// In ar, this message translates to:
  /// **'الكويت'**
  String get prayerMethodKuwait;

  /// No description provided for @prayerMethodQatar.
  ///
  /// In ar, this message translates to:
  /// **'قطر'**
  String get prayerMethodQatar;

  /// No description provided for @prayerMethodSingapore.
  ///
  /// In ar, this message translates to:
  /// **'سنغافورة وماليزيا وإندونيسيا'**
  String get prayerMethodSingapore;

  /// No description provided for @prayerMethodTurkey.
  ///
  /// In ar, this message translates to:
  /// **'تركيا (رئاسة الشؤون الدينية)'**
  String get prayerMethodTurkey;

  /// No description provided for @prayerMethodMoonSighting.
  ///
  /// In ar, this message translates to:
  /// **'لجنة رؤية الهلال'**
  String get prayerMethodMoonSighting;

  /// No description provided for @prayerMadhabTitle.
  ///
  /// In ar, this message translates to:
  /// **'حساب وقت العصر'**
  String get prayerMadhabTitle;

  /// No description provided for @prayerCustomLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقع مخصص (إحداثيات)'**
  String get prayerCustomLocation;

  /// No description provided for @prayerCustomLatitude.
  ///
  /// In ar, this message translates to:
  /// **'خط العرض'**
  String get prayerCustomLatitude;

  /// No description provided for @prayerCustomLongitude.
  ///
  /// In ar, this message translates to:
  /// **'خط الطول'**
  String get prayerCustomLongitude;

  /// No description provided for @prayerCustomHint.
  ///
  /// In ar, this message translates to:
  /// **'مدينتك غير موجودة؟ انسخ إحداثياتها من تطبيق الخرائط.'**
  String get prayerCustomHint;

  /// No description provided for @prayerCustomTimeZone.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية: {zone}'**
  String prayerCustomTimeZone(String zone);

  /// No description provided for @prayerCustomSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الموقع'**
  String get prayerCustomSave;

  /// No description provided for @prayerCustomSaved.
  ///
  /// In ar, this message translates to:
  /// **'حُفظ الموقع. تُحسب مواقيت الصلاة الآن لإحداثياتك.'**
  String get prayerCustomSaved;

  /// No description provided for @prayerCustomInvalid.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الإحداثيات: خط العرض بين ‎-٩٠‎ و‎٩٠‎، وخط الطول بين ‎-١٨٠‎ و‎١٨٠‎.'**
  String get prayerCustomInvalid;

  /// No description provided for @prayerCustomTimeZoneUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد المنطقة الزمنية لجهازك.'**
  String get prayerCustomTimeZoneUnavailable;

  /// No description provided for @prayerMadhabAuto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي حسب المدينة'**
  String get prayerMadhabAuto;

  /// No description provided for @prayerMadhabShafi.
  ///
  /// In ar, this message translates to:
  /// **'الجمهور (الشافعي والمالكي والحنبلي)'**
  String get prayerMadhabShafi;

  /// No description provided for @prayerMadhabHanafi.
  ///
  /// In ar, this message translates to:
  /// **'الحنفي'**
  String get prayerMadhabHanafi;

  /// No description provided for @homeBrandSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تالية القرآن'**
  String get homeBrandSubtitle;

  /// No description provided for @homeWelcomeUser.
  ///
  /// In ar, this message translates to:
  /// **'مرحبا بك {name}'**
  String homeWelcomeUser(String name);

  /// No description provided for @homeContinueRecitation.
  ///
  /// In ar, this message translates to:
  /// **'أكمل تلاوتك'**
  String get homeContinueRecitation;

  /// No description provided for @homeContinueAction.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get homeContinueAction;

  /// No description provided for @homeAyahRange.
  ///
  /// In ar, this message translates to:
  /// **'الآيات {start} إلى {end}'**
  String homeAyahRange(String start, String end);

  /// No description provided for @homeAyahProgressCount.
  ///
  /// In ar, this message translates to:
  /// **'{currentText} من {total, plural, =1{آية واحدة} =2{آيتين} few{{totalText} آيات} other{{totalText} آية}}'**
  String homeAyahProgressCount(String currentText, int total, String totalText);

  /// No description provided for @homePageProgressCount.
  ///
  /// In ar, this message translates to:
  /// **'{currentText} من {total, plural, =1{صفحة واحدة} =2{صفحتين} few{{totalText} صفحات} other{{totalText} صفحة}}'**
  String homePageProgressCount(String currentText, int total, String totalText);

  /// No description provided for @homeTileListen.
  ///
  /// In ar, this message translates to:
  /// **'تسميع'**
  String get homeTileListen;

  /// No description provided for @homeTileListenHint.
  ///
  /// In ar, this message translates to:
  /// **'استمع وسمّع'**
  String get homeTileListenHint;

  /// No description provided for @homeTileReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة'**
  String get homeTileReview;

  /// No description provided for @homeTileReviewHint.
  ///
  /// In ar, this message translates to:
  /// **'ثبّت ما حفظت'**
  String get homeTileReviewHint;

  /// No description provided for @homeTileMemorize.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get homeTileMemorize;

  /// No description provided for @homeTileMemorizeHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف آيات جديدة'**
  String get homeTileMemorizeHint;

  /// No description provided for @homeTileRead.
  ///
  /// In ar, this message translates to:
  /// **'قراءة'**
  String get homeTileRead;

  /// No description provided for @homeTileReadHint.
  ///
  /// In ar, this message translates to:
  /// **'افتح المصحف'**
  String get homeTileReadHint;

  /// No description provided for @homeDailyChallenge.
  ///
  /// In ar, this message translates to:
  /// **'التحدي اليومي'**
  String get homeDailyChallenge;

  /// No description provided for @homeDailyChallengePages.
  ///
  /// In ar, this message translates to:
  /// **'أكمل {count} صفحات اليوم'**
  String homeDailyChallengePages(String count);

  /// No description provided for @homeDailyChallengeTasks.
  ///
  /// In ar, this message translates to:
  /// **'أكمل مهام اليوم'**
  String get homeDailyChallengeTasks;

  /// No description provided for @homeChallengeProgress.
  ///
  /// In ar, this message translates to:
  /// **'{current} من {total}'**
  String homeChallengeProgress(String current, String total);

  /// No description provided for @homeStreakDays.
  ///
  /// In ar, this message translates to:
  /// **'{count} يوم مواظبة'**
  String homeStreakDays(String count);

  /// No description provided for @homeQuranJourney.
  ///
  /// In ar, this message translates to:
  /// **'رحلتك مع القرآن'**
  String get homeQuranJourney;

  /// No description provided for @homeJourneyMemorization.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ'**
  String get homeJourneyMemorization;

  /// No description provided for @homeJourneyKhatmah.
  ///
  /// In ar, this message translates to:
  /// **'الختمة'**
  String get homeJourneyKhatmah;

  /// No description provided for @homeJourneyMemorizedAyahs.
  ///
  /// In ar, this message translates to:
  /// **'{count} آية محفوظة'**
  String homeJourneyMemorizedAyahs(String count);

  /// No description provided for @homeJourneyKhatmahPages.
  ///
  /// In ar, this message translates to:
  /// **'{current} من {total} صفحة'**
  String homeJourneyKhatmahPages(String current, String total);

  /// No description provided for @homeJourneyNotStartedTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم تبدأ رحلتك بعد'**
  String get homeJourneyNotStartedTitle;

  /// No description provided for @homeJourneyNotStartedBody.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الحفظ أو افتح ختمة، وسيتابع التطبيق تقدّمك الفعلي هنا'**
  String get homeJourneyNotStartedBody;

  /// No description provided for @homeJourneyStartMemorization.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الحفظ'**
  String get homeJourneyStartMemorization;

  /// No description provided for @homeSurahsCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get homeSurahsCompleted;

  /// No description provided for @homeSurahsInProgress.
  ///
  /// In ar, this message translates to:
  /// **'جاري'**
  String get homeSurahsInProgress;

  /// No description provided for @homeSurahsRemaining.
  ///
  /// In ar, this message translates to:
  /// **'متبقٍ'**
  String get homeSurahsRemaining;

  /// No description provided for @homeRecentActivity.
  ///
  /// In ar, this message translates to:
  /// **'نشاطك الأخير'**
  String get homeRecentActivity;

  /// No description provided for @homeActivityViewAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get homeActivityViewAll;

  /// No description provided for @homeActivityEmpty.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ القراءة أو الحفظ ليظهر نشاطك هنا'**
  String get homeActivityEmpty;

  /// No description provided for @homeActivityReading.
  ///
  /// In ar, this message translates to:
  /// **'قراءة'**
  String get homeActivityReading;

  /// No description provided for @homeActivityMemorize.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get homeActivityMemorize;

  /// No description provided for @homeActivityReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة'**
  String get homeActivityReview;

  /// No description provided for @homeActivityKhatmah.
  ///
  /// In ar, this message translates to:
  /// **'ختمة'**
  String get homeActivityKhatmah;

  /// No description provided for @homeActivityJustNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get homeActivityJustNow;

  /// No description provided for @homeActivityMinutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'قبل {count} د'**
  String homeActivityMinutesAgo(String count);

  /// No description provided for @homeActivityHoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'قبل {count} س'**
  String homeActivityHoursAgo(String count);

  /// No description provided for @homeActivityYesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get homeActivityYesterday;

  /// No description provided for @homeActivityDaysAgo.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{قبل يوم} =2{قبل يومين} few{قبل {countText} أيام} many{قبل {countText} يومًا} other{قبل {countText} يوم}}'**
  String homeActivityDaysAgo(int count, String countText);

  /// No description provided for @homeActivityCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get homeActivityCompleted;

  /// No description provided for @homeFooterTagline.
  ///
  /// In ar, this message translates to:
  /// **'بالقرآن .. نحيا أجمل'**
  String get homeFooterTagline;

  /// No description provided for @quickNavTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنقل سريع'**
  String get quickNavTitle;

  /// No description provided for @quickNavGo.
  ///
  /// In ar, this message translates to:
  /// **'انتقال'**
  String get quickNavGo;

  /// No description provided for @quickNavPageHint.
  ///
  /// In ar, this message translates to:
  /// **'رقم الصفحة (١-٦٠٤)'**
  String get quickNavPageHint;

  /// No description provided for @homeStartKhatmahTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ ختمتك القرآنية الآن'**
  String get homeStartKhatmahTitle;

  /// No description provided for @homeStartKhatmahSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'رتّب وِردك اليومي وحدد مدة الختمة لتنال أجر التلاوة المستمرة'**
  String get homeStartKhatmahSubtitle;

  /// No description provided for @homeStartKhatmahCta.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء ختمة جديدة'**
  String get homeStartKhatmahCta;

  /// No description provided for @homeAchievementSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنجازاتك ومستواك'**
  String get homeAchievementSheetTitle;

  /// No description provided for @homeAchievementSheetSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'واصل التلاوة والحفظ لترقية مستواك القرآني'**
  String get homeAchievementSheetSubtitle;

  /// No description provided for @homePrayerTimesSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get homePrayerTimesSheetTitle;

  /// No description provided for @prayerCompanionStatusConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'تم التأكيد'**
  String get prayerCompanionStatusConfirmed;

  /// No description provided for @prayerCompanionStatusUnconfirmedPast.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم التأكيد بعد'**
  String get prayerCompanionStatusUnconfirmedPast;

  /// No description provided for @prayerCompanionStatusUpcoming.
  ///
  /// In ar, this message translates to:
  /// **'قادمة'**
  String get prayerCompanionStatusUpcoming;

  /// No description provided for @prayerCompanionStatusPrayNow.
  ///
  /// In ar, this message translates to:
  /// **'سأصلي الآن'**
  String get prayerCompanionStatusPrayNow;

  /// No description provided for @prayerCompanionStatusRemindLater.
  ///
  /// In ar, this message translates to:
  /// **'تم ضبط تذكير'**
  String get prayerCompanionStatusRemindLater;

  /// No description provided for @prayerCompanionStatusNotYet.
  ///
  /// In ar, this message translates to:
  /// **'ليس بعد'**
  String get prayerCompanionStatusNotYet;

  /// No description provided for @prayerCompanionActionConfirm.
  ///
  /// In ar, this message translates to:
  /// **'صليت'**
  String get prayerCompanionActionConfirm;

  /// No description provided for @prayerCompanionActionPrayNow.
  ///
  /// In ar, this message translates to:
  /// **'سأصلي الآن'**
  String get prayerCompanionActionPrayNow;

  /// No description provided for @prayerCompanionActionRemindLater.
  ///
  /// In ar, this message translates to:
  /// **'ذكرني لاحقاً'**
  String get prayerCompanionActionRemindLater;

  /// No description provided for @prayerCompanionActionNotYet.
  ///
  /// In ar, this message translates to:
  /// **'ليس بعد'**
  String get prayerCompanionActionNotYet;

  /// No description provided for @prayerCompanionConfirmedCount.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد {confirmed} من {total}'**
  String prayerCompanionConfirmedCount(String confirmed, String total);

  /// No description provided for @prayerCompanionRowSemantics.
  ///
  /// In ar, this message translates to:
  /// **'{prayer}: {status}'**
  String prayerCompanionRowSemantics(String prayer, String status);

  /// No description provided for @prayerCompanionSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرافق الصلاة'**
  String get prayerCompanionSettingsTitle;

  /// No description provided for @microReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'لمحة مراجعة'**
  String get microReviewTitle;

  /// No description provided for @microReviewQuestion.
  ///
  /// In ar, this message translates to:
  /// **'من حفظك القديم… لسه فاكرها؟'**
  String get microReviewQuestion;

  /// No description provided for @microReviewReference.
  ///
  /// In ar, this message translates to:
  /// **'سورة {surah}، آية {ayah}'**
  String microReviewReference(String surah, String ayah);

  /// No description provided for @microReviewRevealHint.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تفتكرها… ثم اضغط لعرضها'**
  String get microReviewRevealHint;

  /// No description provided for @microReviewRecite.
  ///
  /// In ar, this message translates to:
  /// **'سمّع نفسك'**
  String get microReviewRecite;

  /// No description provided for @prayerSerenityTitle.
  ///
  /// In ar, this message translates to:
  /// **'وضع سكينة الصلاة'**
  String get prayerSerenityTitle;

  /// No description provided for @prayerSerenitySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نوقف التلاوة بهدوء عند دخول وقت الصلاة'**
  String get prayerSerenitySubtitle;

  /// No description provided for @prayerSerenityNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت اللقاء 🕌'**
  String get prayerSerenityNotificationTitle;

  /// No description provided for @prayerSerenityNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'أوقفنا التلاوة بهدوء… حان وقت الصلاة، تقبّل الله'**
  String get prayerSerenityNotificationBody;

  /// No description provided for @prayerCompanionEnable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل مرافق الصلاة'**
  String get prayerCompanionEnable;

  /// No description provided for @prayerCompanionPreparation.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الاستعداد'**
  String get prayerCompanionPreparation;

  /// No description provided for @prayerCompanionPreparationDisabled.
  ///
  /// In ar, this message translates to:
  /// **'معطّل'**
  String get prayerCompanionPreparationDisabled;

  /// No description provided for @prayerCompanionMinutesValue.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقائق'**
  String prayerCompanionMinutesValue(String minutes);

  /// No description provided for @prayerCompanionCheckIn.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بعد الصلاة'**
  String get prayerCompanionCheckIn;

  /// No description provided for @prayerCompanionCheckInSub.
  ///
  /// In ar, this message translates to:
  /// **'يصل تذكير لطيف بعد ٢٠ دقيقة من وقت الصلاة.'**
  String get prayerCompanionCheckInSub;

  /// No description provided for @prayerCompanionFollowUp.
  ///
  /// In ar, this message translates to:
  /// **'السماح بتذكير لاحق واحد'**
  String get prayerCompanionFollowUp;

  /// No description provided for @prayerCompanionFollowUpSub.
  ///
  /// In ar, this message translates to:
  /// **'يُرسل مرة واحدة عند اختيار «سأصلي الآن» أو «ذكرني لاحقاً».'**
  String get prayerCompanionFollowUpSub;

  /// No description provided for @prayerCompanionLocalOnly.
  ///
  /// In ar, this message translates to:
  /// **'تُحفظ تأكيداتك على هذا الجهاز فقط ولا تُرفع إلى أي خدمة سحابية.'**
  String get prayerCompanionLocalOnly;

  /// No description provided for @prayerCompanionClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح تأكيدات الصلاة'**
  String get prayerCompanionClear;

  /// No description provided for @prayerCompanionClearSub.
  ///
  /// In ar, this message translates to:
  /// **'يحذف التأكيدات المحفوظة على هذا الجهاز.'**
  String get prayerCompanionClearSub;

  /// No description provided for @prayerCompanionClearConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسح التأكيدات؟'**
  String get prayerCompanionClearConfirmTitle;

  /// No description provided for @prayerCompanionClearConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد مسح التأكيدات المحفوظة على هذا الجهاز؟'**
  String get prayerCompanionClearConfirmBody;

  /// No description provided for @prayerCompanionClearConfirmButton.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get prayerCompanionClearConfirmButton;

  /// No description provided for @prayerCompanionClearCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get prayerCompanionClearCancel;

  /// No description provided for @prayerCompanionClearFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر مسح التأكيدات. حاول مرة أخرى.'**
  String get prayerCompanionClearFailed;

  /// No description provided for @prayerCompanionCleared.
  ///
  /// In ar, this message translates to:
  /// **'تم مسح التأكيدات.'**
  String get prayerCompanionCleared;

  /// No description provided for @weekdayMonday.
  ///
  /// In ar, this message translates to:
  /// **'الاثنين'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get weekdaySunday;

  /// No description provided for @notificationExactAlarmRequest.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل التنبيهات الدقيقة'**
  String get notificationExactAlarmRequest;

  /// No description provided for @notificationExactAlarmExplanation.
  ///
  /// In ar, this message translates to:
  /// **'تضمن وصول تنبيه الصلاة والأذان في وقتهما بالضبط'**
  String get notificationExactAlarmExplanation;

  /// No description provided for @notificationExactAlarmGranted.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل دقة تنبيهات مواقيت الصلاة.'**
  String get notificationExactAlarmGranted;

  /// No description provided for @notificationExactAlarmDenied.
  ///
  /// In ar, this message translates to:
  /// **'ستصلك التنبيهات في وقتها تقريبًا بالوضع العادي، ويمكنك تفعيل الدقة الكاملة لاحقًا من إعدادات الهاتف.'**
  String get notificationExactAlarmDenied;

  /// No description provided for @notificationTestFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إرسال الإشعار. تحقّق من إذن الإشعارات في إعدادات الهاتف.'**
  String get notificationTestFailed;

  /// No description provided for @notificationQuietHours.
  ///
  /// In ar, this message translates to:
  /// **'الساعات الهادئة'**
  String get notificationQuietHours;

  /// No description provided for @notificationQuietHoursSub.
  ///
  /// In ar, this message translates to:
  /// **'ينقل التذكيرات العادية خارج الفترة المحددة. مواقيت الصلاة لا تتغير.'**
  String get notificationQuietHoursSub;

  /// No description provided for @notificationQuietHoursStart.
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get notificationQuietHoursStart;

  /// No description provided for @notificationQuietHoursEnd.
  ///
  /// In ar, this message translates to:
  /// **'النهاية'**
  String get notificationQuietHoursEnd;

  /// No description provided for @notificationSmartReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير ذكي'**
  String get notificationSmartReminder;

  /// No description provided for @notificationSmartReminderSub.
  ///
  /// In ar, this message translates to:
  /// **'يستخدم أوقات فتحك الأخيرة على الجهاز لاختيار وقت التذكير.'**
  String get notificationSmartReminderSub;

  /// No description provided for @memorizationHubReviewDueBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{آية واحدة مستحقة للمراجعة} =2{آيتان مستحقتان للمراجعة} few{{countText} آيات مستحقة للمراجعة} other{{countText} آية مستحقة للمراجعة}}'**
  String memorizationHubReviewDueBadge(int count, String countText);

  /// No description provided for @memorizationHubReviewDueNone.
  ///
  /// In ar, this message translates to:
  /// **'لا مراجعات مستحقة الآن'**
  String get memorizationHubReviewDueNone;

  /// No description provided for @dailyPlanNextReviewInDays.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة القادمة بعد {count, plural, =0{اليوم} =1{يوم} other{{countText} أيام}}'**
  String dailyPlanNextReviewInDays(int count, String countText);

  /// No description provided for @dailyPlanStrengthWeak.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ضعيف'**
  String get dailyPlanStrengthWeak;

  /// No description provided for @dailyPlanStrengthLearning.
  ///
  /// In ar, this message translates to:
  /// **'قيد الترسيت'**
  String get dailyPlanStrengthLearning;

  /// No description provided for @dailyPlanStrengthStrong.
  ///
  /// In ar, this message translates to:
  /// **'حفظ متين'**
  String get dailyPlanStrengthStrong;

  /// No description provided for @memorizedPageAction.
  ///
  /// In ar, this message translates to:
  /// **'حفظ هذه الصفحة'**
  String get memorizedPageAction;

  /// No description provided for @memorizedPageSubtext.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ جلسة حفظ لآيات الصفحة الحالية'**
  String get memorizedPageSubtext;

  /// No description provided for @memorizedPageUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الصفحة متاح عندما تنتمي كل آياتها لسورة واحدة.'**
  String get memorizedPageUnavailable;

  /// No description provided for @customPlanDirectionForward.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه الحفظ: تصاعدي (من {from} إلى {to})'**
  String customPlanDirectionForward(String from, String to);

  /// No description provided for @customPlanDirectionBackward.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه الحفظ: تنازلي (من {from} إلى {to})'**
  String customPlanDirectionBackward(String from, String to);

  /// Validation: field must not be empty
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get fieldRequired;

  /// Validation: field exceeds max length
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن أن يتجاوز {maxLength} حرفاً'**
  String fieldTooLong(String maxLength);

  /// No description provided for @progressDueReviewsLabel.
  ///
  /// In ar, this message translates to:
  /// **'مراجعات مستحقة'**
  String get progressDueReviewsLabel;

  /// No description provided for @progressStreakDaysUnit.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{يوم} =1{يوم} =2{يومان} few{أيام} many{يوماً} other{يوم}}'**
  String progressStreakDaysUnit(int count);

  /// No description provided for @progressNextMilestoneTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنجازك القادم'**
  String get progressNextMilestoneTitle;

  /// No description provided for @progressNextMilestoneRemaining.
  ///
  /// In ar, this message translates to:
  /// **'باقي {remaining} للوصول'**
  String progressNextMilestoneRemaining(String remaining);

  /// No description provided for @progressAllAchievementsUnlocked.
  ///
  /// In ar, this message translates to:
  /// **'ما شاء الله! أتممت جميع الإنجازات، ثبّتك الله'**
  String get progressAllAchievementsUnlocked;

  /// No description provided for @progressDueReviewsNudge.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{لديك آية واحدة مستحقة للمراجعة} =2{لديك آيتان مستحقتان للمراجعة} few{لديك {countText} آيات مستحقة للمراجعة} other{لديك {countText} آية مستحقة للمراجعة}}'**
  String progressDueReviewsNudge(int count, String countText);

  /// No description provided for @progressStartReview.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ المراجعة'**
  String get progressStartReview;

  /// No description provided for @progressActiveDays.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا توجد أيام نشاط بعد} =1{يوم نشاط واحد} =2{يوما نشاط} few{{countText} أيام نشاط} many{{countText} يوماً من النشاط} other{{countText} يوم نشاط}}'**
  String progressActiveDays(int count, String countText);

  /// No description provided for @progressXpToNextLevel.
  ///
  /// In ar, this message translates to:
  /// **'نحو المستوى التالي'**
  String get progressXpToNextLevel;

  /// No description provided for @privacyEffectiveDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ النفاذ: ٢ أكتوبر ٢٠٢٦'**
  String get privacyEffectiveDate;

  /// No description provided for @privacyIntro.
  ///
  /// In ar, this message translates to:
  /// **'توضح هذه السياسة كيف يتعامل تطبيق تالية القرآن مع بياناتك على الجهاز وفي الخدمات السحابية، وكيف تتحكم في الأذونات وتطلب حذف بياناتك.'**
  String get privacyIntro;

  /// No description provided for @privacyManualOptionAction.
  ///
  /// In ar, this message translates to:
  /// **'افتح الحفظ لاستخدام التقييم الذاتي'**
  String get privacyManualOptionAction;

  /// No description provided for @privacyControllerTitle.
  ///
  /// In ar, this message translates to:
  /// **'١. مقدمة والمسؤول عن البيانات'**
  String get privacyControllerTitle;

  /// No description provided for @privacyControllerBody.
  ///
  /// In ar, this message translates to:
  /// **'تالية القرآن (Talia Quran) تطبيق للقراءة والحفظ والمراجعة والأذكار. المطوّر والمسؤول عن معالجة بيانات التطبيق هو Sayed Saad. تنطبق هذه السياسة على تطبيق تالية وميزات الحساب وربط ولي الأمر. للاستفسارات وطلبات الخصوصية: elsayed.saad2014@feps.edu.eg.'**
  String get privacyControllerBody;

  /// No description provided for @privacyDataTitle.
  ///
  /// In ar, this message translates to:
  /// **'٢. المعلومات التي نجمعها وأين تُحفظ'**
  String get privacyDataTitle;

  /// No description provided for @privacyAccountData.
  ///
  /// In ar, this message translates to:
  /// **'الحساب: عند التسجيل نعالج البريد الإلكتروني وكلمة المرور عبر Supabase للمصادقة والتحقق واستعادة الحساب، ومعرّف الحساب ورموز الجلسة. تُستخدم بيانات الملف مثل الاسم أو لقب الطفل والعمر عند تقديمها لتخصيص التجربة وعرضها لولي الأمر المرتبط وإصدار الشهادات. لا تطلب إرسال كلمة المرور إلى الدعم.'**
  String get privacyAccountData;

  /// No description provided for @privacyProgressData.
  ///
  /// In ar, this message translates to:
  /// **'التقدم والتفضيلات: يحفظ التطبيق القراءة والعلامات المرجعية وخطط الحفظ والمراجعات وتقييماتها وسجل الجلسات والنقاط والسلاسل اليومية والإنجازات والشهادات وإعدادات الطفل وولي الأمر. تُحفظ بيانات التشغيل على الجهاز، وتُزامن الميزات السحابية المتاحة بيانات الحساب المرتبطة عند تسجيل الدخول وتوفر الاتصال. قد تُرسل العمليات المعلقة تلقائيًا عند عودة الاتصال. ليست كل التفضيلات أو الميزات المحلية قابلة للمزامنة.'**
  String get privacyProgressData;

  /// No description provided for @privacyTechnicalData.
  ///
  /// In ar, this message translates to:
  /// **'البيانات التقنية والدعم: تتلقى خدمات الحساب والصوت بيانات الاتصال المعتادة مثل عنوان IP وتوقيت الطلب وبيانات تقنية لازمة لتشغيل الخدمة وأمنها. يسجّل التطبيق الأخطاء التقنية محليًا. إذا تواصلت معنا نعالج بريدك ومحتوى الرسالة وما تختار إرساله لحل الطلب. لا يتضمن الإصدار الحالي أدوات إعلانات أو تحليلات سلوكية تابعة لطرف ثالث.'**
  String get privacyTechnicalData;

  /// No description provided for @privacyPurposeTitle.
  ///
  /// In ar, this message translates to:
  /// **'٣. أغراض المعالجة'**
  String get privacyPurposeTitle;

  /// No description provided for @privacyPurposeBody.
  ///
  /// In ar, this message translates to:
  /// **'نستخدم البيانات لتشغيل الحساب ومزامنة التقدم وإتاحة المراجعة والتذكيرات والشهادات وربط ولي الأمر الذي تختاره، ولحماية الخدمة والاستجابة للدعم. لا نبيع بياناتك، ولا نستخدم تقدمك أو بيانات الأطفال للإعلانات الموجّهة. طلب الأذونات منفصل عن قبول هذه السياسة؛ يمكنك رفض الأذونات الاختيارية ومواصلة استخدام الوظائف التي لا تحتاجها.'**
  String get privacyPurposeBody;

  /// No description provided for @privacyPermissionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'٤. أذونات الجهاز والصوت'**
  String get privacyPermissionsTitle;

  /// No description provided for @privacyMicrophone.
  ///
  /// In ar, this message translates to:
  /// **'الميكروفون: يُستخدم عند بدء التسميع للتعرف على قراءتك. يعمل عبر خدمة التعرف الصوتي المدمجة في نظام الجهاز؛ وقد يعالج الصوت مزوّد نظام التشغيل وفق سياساته الخاصة، ولا نضمن بقاء المعالجة دون اتصال. لا يحتفظ تطبيق تالية بالصوت الخام ولا يرسله إلى خوادمنا. قد تُحفظ نتيجة التقييم ضمن التقدم. يتوفر خيار التقييم الذاتي اليدوي؛ يمكنك إلغاء إذن الميكروفون والتعرف على الكلام من إعدادات الجهاز.'**
  String get privacyMicrophone;

  /// No description provided for @privacyCamera.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا: تُستخدم عند اختيار مسح رمز QR لربط ولي الأمر. يحلل الماسح صورة الكاميرا لقراءة الرمز؛ لا يحفظ التطبيق صور الكاميرا أو يرفعها. يُرسل رمز الربط إلى خدمة الحساب للتحقق وإتمام الربط.'**
  String get privacyCamera;

  /// No description provided for @privacyNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات: تُجدول التذكيرات محليًا على الجهاز للحفظ والقراءة والأذكار ومواقيت الصلاة، ويمكن تعطيلها من التطبيق أو إعدادات النظام. قد تظهر معلومات التذكير على شاشة القفل حسب إعدادات جهازك.'**
  String get privacyNotifications;

  /// No description provided for @privacyPhotos.
  ///
  /// In ar, this message translates to:
  /// **'الصور والملفات والمشاركة: تُستخدم عند اختيار حفظ شهادة أو بطاقة أو تصديرها أو مشاركتها. قد تحتوي الملفات على الاسم والتقدم الذي اخترت عرضه. تصبح النسخ التي تحفظها خارج التطبيق أو ترسلها لتطبيق آخر تحت سيطرتك وسياسة الجهة المستقبلة؛ حذف الحساب لا يمحوها.'**
  String get privacyPhotos;

  /// No description provided for @privacyLocation.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة: تُحسب على الجهاز باستخدام المدينة التي تختارها أو الإحداثيات التي تدخلها يدويًا. تُحفظ هذه الإعدادات محليًا. لا يطلب هذا الإصدار تحديد موقع GPS ولا يتتبع موقعك في الخلفية.'**
  String get privacyLocation;

  /// No description provided for @privacyChildrenTitle.
  ///
  /// In ar, this message translates to:
  /// **'٥. خصوصية الأطفال وولي الأمر'**
  String get privacyChildrenTitle;

  /// No description provided for @privacyChildrenBody.
  ///
  /// In ar, this message translates to:
  /// **'يتضمن التطبيق مسارًا للأطفال، وقد تتضمن بياناته لقب الطفل والعمر وتقدم الحفظ والتقييمات والجلسات والمكافآت. ندعو ولي الأمر للإشراف على استخدام الطفل للحساب والمزامنة والتسميع والمشاركة، واستخدام لقب بدلاً من الاسم الكامل وتجنب إرسال معلومات إضافية غير لازمة. ملفات الأطفال المحلية ليست حسابات مستقلة بالضرورة.'**
  String get privacyChildrenBody;

  /// No description provided for @privacyGuardianSharing.
  ///
  /// In ar, this message translates to:
  /// **'عند إتمام ربط حساب ولي الأمر بموافقتك، يستطيع ولي الأمر المرتبط الاطلاع عبر السحابة على بيانات الطفل المتاحة للمتابعة، ومنها الاسم أو اللقب والعمر والتقدم والجلسات والإنجازات، وإدارة المكافآت. الربط ليس محليًا فقط. يمكنك إلغاء الربط من أدوات ولي الأمر، وطلب مراجعة بيانات الطفل أو حذفها عبر بريد الخصوصية. لا يمحو إلغاء الربط النسخ التي سبق للمستلم حفظها.'**
  String get privacyGuardianSharing;

  /// No description provided for @privacyChildrenSpeech.
  ///
  /// In ar, this message translates to:
  /// **'لا نعرض إعلانات موجهة للأطفال. التسميع الصوتي اختياري، وخدمة التعرف التابعة للنظام قد تعالج الصوت خارج الجهاز؛ يمكن لولي الأمر اختيار التقييم اليدوي وإلغاء الأذونات. لا يُعد ربط QR وحده إثباتًا للموافقة الأبوية القانونية.'**
  String get privacyChildrenSpeech;

  /// No description provided for @privacyProvidersTitle.
  ///
  /// In ar, this message translates to:
  /// **'٦. الجهات التي قد تتلقى البيانات'**
  String get privacyProvidersTitle;

  /// No description provided for @privacyProvidersBody.
  ///
  /// In ar, this message translates to:
  /// **'Supabase يعالج بيانات الحساب والمصادقة والتقدم السحابي نيابة عن التطبيق. مزوّد التعرف على الكلام في جهازك قد يعالج صوت التسميع. EveryAyah يوفّر تسجيلات القرّاء عبر الإنترنت ويتلقى بيانات الطلب التقنية المعتادة عند البث أو التنزيل. قد تتلقى خدمات البريد بيانات الرسائل التي نرسلها للتحقق والدعم. يحصل ولي الأمر المرتبط أو التطبيق الذي تختاره للمشاركة على البيانات الموضحة أعلاه.'**
  String get privacyProvidersBody;

  /// No description provided for @privacyProviderProtection.
  ///
  /// In ar, this message translates to:
  /// **'نقتصر على البيانات اللازمة للخدمة ونشترط على مزودي المعالجة حماية البيانات بما يتفق مع هذه السياسة ومتطلبات المتاجر والقانون الساري. خدمات نظام الجهاز والتطبيقات التي تختارها للمشاركة تخضع كذلك لسياساتها. قد نفصح بالقدر اللازم للامتثال لطلب قانوني ملزم أو لحماية الحقوق وأمن الخدمة.'**
  String get privacyProviderProtection;

  /// No description provided for @privacySecurityTitle.
  ///
  /// In ar, this message translates to:
  /// **'٧. الحماية ونقل البيانات'**
  String get privacySecurityTitle;

  /// No description provided for @privacySecurityBody.
  ///
  /// In ar, this message translates to:
  /// **'تستخدم اتصالات الحساب HTTPS، وتعتمد صلاحيات السحابة على هوية الحساب وقواعد وصول تسمح بالمشاركة المحددة مع ولي الأمر المرتبط. تُحفظ بعض البيانات الحساسة، مثل رمز حماية ولي الأمر وبيانات حساب مختارة، باستخدام تخزين آمن؛ وتحفظ مكتبة المصادقة الجلسة على الجهاز لتسجيل الدخول المستمر. لا توجد وسيلة حماية مضمونة تمامًا. قد تُعالج بيانات الخدمات لدى مزودين خارج بلدك؛ ونتعامل مع النقل وفق الضمانات والمتطلبات القانونية المنطبقة.'**
  String get privacySecurityBody;

  /// No description provided for @privacyRetentionTitle.
  ///
  /// In ar, this message translates to:
  /// **'٨. الاحتفاظ بالبيانات'**
  String get privacyRetentionTitle;

  /// No description provided for @privacyRetentionBody.
  ///
  /// In ar, this message translates to:
  /// **'يبقى تقدم الحساب وملفه في الخدمة النشطة ما دام الحساب قائمًا وحتى حذف البيانات أو الحساب. تبقى البيانات المحلية حتى حذفها أو تنظيف بيانات التطبيق. تُزال بيانات الحساب من قواعد التشغيل عند نجاح حذف الحساب؛ قد تبقى نسخ احتياطية أو سجلات أمنية لدى مزود الخدمة خلال دورة الاحتفاظ المحدودة، ولا تُستخدم لإعادة إنشاء الحساب. قد يحتفظ نظام جهازك بنسخة احتياطية وفق إعدادات النسخ الاحتياطي لديك؛ يمكنك إدارتها من إعدادات النظام. تُحفظ مراسلات الدعم بقدر ما يلزم لحل الطلب والالتزامات القانونية. للاستفسار عن المدة المنطبقة على بياناتك تواصل معنا؛ وإذا لزم الاحتفاظ ببيانات لسبب قانوني نوضح الفئات والسبب والمدة في الرد على طلبك.'**
  String get privacyRetentionBody;

  /// No description provided for @privacyDeletionTitle.
  ///
  /// In ar, this message translates to:
  /// **'٩. حذف الحساب والبيانات'**
  String get privacyDeletionTitle;

  /// No description provided for @privacyDeletionBody.
  ///
  /// In ar, this message translates to:
  /// **'لحذف الحساب: افتح الإعدادات ← الحساب ← حذف الحساب، واقرأ التحذير ثم أكّد. يلزم اتصال بالإنترنت. يحذف ذلك حساب تسجيل الدخول وملفه وبياناته السحابية المرتبطة، بما فيها التقدم والخطط والعلامات المرجعية والشهادات وروابط ولي الأمر والمكافآت المرتبطة. ينهي الجلسة وينظف بيانات الحساب المحلية على هذا الجهاز، بما فيها التقدم والملفات المحلية التابعة للحساب والعمليات المعلقة. الحذف نهائي ولا يُعد تسجيل الخروج أو إلغاء الربط بديلاً عنه. تظهر رسالة النجاح بعد إتمام التنظيف؛ إذا ظهر طلب إعادة المحاولة فاتبع تعليماته.'**
  String get privacyDeletionBody;

  /// No description provided for @privacyDeletionLimits.
  ///
  /// In ar, this message translates to:
  /// **'لا يحذف حذف حساب ولي الأمر حسابات الأطفال المستقلة أو حسابات أولياء الأمور الآخرين؛ تزال روابطها بالحساب المحذوف. لا تُحذف ملفات الشهادات أو البطاقات التي حفظتها أو شاركتها خارج التطبيق، أو النسخ المحلية على أجهزة أخرى بهذه العملية؛ نظّف بيانات التطبيق على تلك الأجهزة أيضًا. قد تبقى إعدادات الجهاز العامة والمحتوى القرآني المحمّل وبيانات الضيف التي يمكن فصلها عن الحساب.'**
  String get privacyDeletionLimits;

  /// No description provided for @privacyExternalDeletion.
  ///
  /// In ar, this message translates to:
  /// **'يمكن طلب الحذف دون تثبيت التطبيق: أرسل من بريد الحساب إلى elsayed.saad2014@feps.edu.eg بعنوان «طلب حذف حساب تالية القرآن»، واذكر أنك تريد حذف الحساب والبيانات المرتبطة به. سنتحقق من ملكية الحساب قبل التنفيذ ونبلغك بإتمام الحذف أو أي احتفاظ قانوني واجب. لا ترسل كلمة المرور أو رموز التحقق. يمكنك استخدام البريد نفسه لطلب حذف فئات من البيانات مع الإبقاء على الحساب.'**
  String get privacyExternalDeletion;

  /// No description provided for @privacyRightsTitle.
  ///
  /// In ar, this message translates to:
  /// **'١٠. خياراتك وحقوقك'**
  String get privacyRightsTitle;

  /// No description provided for @privacyRightsBody.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تعديل بيانات ملفك داخل التطبيق، وإلغاء الأذونات من إعدادات الجهاز، وتعطيل التذكيرات وإلغاء ربط ولي الأمر. بحسب القانون المنطبق، يمكنك طلب الوصول أو نسخة من بياناتك أو تصحيحها أو حذفها أو تقييد المعالجة أو الاعتراض عليها أو سحب الموافقة أو تقديم شكوى للجهة المختصة. تواصل معنا من بريد الحساب لتحديد طلبك؛ قد نطلب معلومات محدودة للتحقق من الهوية. لا يؤثر سحب الموافقة في المعالجة التي تمت قبله.'**
  String get privacyRightsBody;

  /// No description provided for @privacyChangesTitle.
  ///
  /// In ar, this message translates to:
  /// **'١١. التغييرات على السياسة'**
  String get privacyChangesTitle;

  /// No description provided for @privacyChangesBody.
  ///
  /// In ar, this message translates to:
  /// **'نحدّث تاريخ النفاذ عند تعديل السياسة، ونُظهر إشعارًا مناسبًا بالتغييرات الجوهرية. إذا احتاج استخدام جديد لبياناتك إلى موافقة، نطلبها قبل بدء هذا الاستخدام. راجع السياسة عند تحديث التطبيق.'**
  String get privacyChangesBody;

  /// No description provided for @privacyContactTitle.
  ///
  /// In ar, this message translates to:
  /// **'١٢. تواصل معنا'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In ar, this message translates to:
  /// **'المطوّر: Sayed Saad\nالتطبيق: تالية القرآن — Talia Quran\nللخصوصية وحذف الحساب وبيانات الأطفال: elsayed.saad2014@feps.edu.eg'**
  String get privacyContactBody;

  /// No description provided for @accountDeletionRemoteConfirmedCleanupFailed.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الحساب من السحابة، لكن تنظيف بيانات الجهاز لم يكتمل. أعد المحاولة لإتمام التنظيف.'**
  String get accountDeletionRemoteConfirmedCleanupFailed;

  /// No description provided for @accountDeletionSessionCleanupFailed.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الحساب، لكن إنهاء الجلسة على الجهاز لم يكتمل. أعد المحاولة.'**
  String get accountDeletionSessionCleanupFailed;

  /// No description provided for @accountDeletionProgressMarkerFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ حالة عملية الحذف بأمان. لم يبدأ حذف الحساب؛ أعد المحاولة.'**
  String get accountDeletionProgressMarkerFailed;

  /// No description provided for @accountDeletionUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'خدمة حذف الحساب غير متاحة حاليًا. أعد المحاولة أو تواصل معنا عبر بريد الخصوصية.'**
  String get accountDeletionUnavailable;

  /// No description provided for @accountDeletionFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تأكيد اكتمال حذف الحساب. تحقق من الاتصال وأعد المحاولة؛ لا تفترض اكتمال الحذف حتى تظهر رسالة النجاح.'**
  String get accountDeletionFailed;

  /// No description provided for @accountDeletionRetryTitle.
  ///
  /// In ar, this message translates to:
  /// **'إتمام حذف الحساب'**
  String get accountDeletionRetryTitle;

  /// No description provided for @accountDeletionRetryAction.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get accountDeletionRetryAction;

  /// No description provided for @sourcesLicensesTitle.
  ///
  /// In ar, this message translates to:
  /// **'المصادر والتراخيص'**
  String get sourcesLicensesTitle;

  /// No description provided for @sourcesLicensesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مصدر نص القرآن والصوتيات والبرمجيات'**
  String get sourcesLicensesSubtitle;

  /// No description provided for @sourcesQuranTextTitle.
  ///
  /// In ar, this message translates to:
  /// **'نص القرآن الكريم'**
  String get sourcesQuranTextTitle;

  /// No description provided for @sourcesQuranTextBody.
  ///
  /// In ar, this message translates to:
  /// **'الرسم العثماني برواية حفص، من مشروع تنزيل عبر خدمة alquran.cloud.'**
  String get sourcesQuranTextBody;

  /// No description provided for @sourcesMushafTitle.
  ///
  /// In ar, this message translates to:
  /// **'صفحات المصحف'**
  String get sourcesMushafTitle;

  /// No description provided for @sourcesMushafBody.
  ///
  /// In ar, this message translates to:
  /// **'تُعرض خطوط صفحات المصحف (QCF) عبر مكتبة qcf_quran_plus بترخيص MIT.'**
  String get sourcesMushafBody;

  /// No description provided for @sourcesRecitationTitle.
  ///
  /// In ar, this message translates to:
  /// **'التلاوات'**
  String get sourcesRecitationTitle;

  /// No description provided for @sourcesRecitationBody.
  ///
  /// In ar, this message translates to:
  /// **'تُبث تلاوات الآيات من موقع EveryAyah.com.'**
  String get sourcesRecitationBody;

  /// No description provided for @sourcesAdhanTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأذان'**
  String get sourcesAdhanTitle;

  /// No description provided for @sourcesAdhanBody.
  ///
  /// In ar, this message translates to:
  /// **'تسجيلات المؤذنين القابلة للاختيار مصدرها أرشيف الإنترنت (Internet Archive)، وتحمل علامة الملكية العامة 1.0.'**
  String get sourcesAdhanBody;

  /// No description provided for @sourcesKhatmDuaTitle.
  ///
  /// In ar, this message translates to:
  /// **'دعاء ختم القرآن'**
  String get sourcesKhatmDuaTitle;

  /// No description provided for @sourcesKhatmDuaBody.
  ///
  /// In ar, this message translates to:
  /// **'من ملحق مصحف مجمع الملك فهد لطباعة المصحف الشريف.'**
  String get sourcesKhatmDuaBody;

  /// No description provided for @sourcesOpenSourceTitle.
  ///
  /// In ar, this message translates to:
  /// **'تراخيص البرمجيات مفتوحة المصدر'**
  String get sourcesOpenSourceTitle;

  /// No description provided for @sourcesOpenSourceBody.
  ///
  /// In ar, this message translates to:
  /// **'التراخيص الكاملة للمكتبات المستخدمة في التطبيق.'**
  String get sourcesOpenSourceBody;

  /// No description provided for @sourcesOpenLink.
  ///
  /// In ar, this message translates to:
  /// **'فتح {site}'**
  String sourcesOpenLink(String site);

  /// No description provided for @authCloudUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات غير متاحة في هذا الإصدار. يمكنك متابعة استخدام تالية كضيف.'**
  String get authCloudUnavailable;

  /// No description provided for @surahNamed.
  ///
  /// In ar, this message translates to:
  /// **'سورة {name}'**
  String surahNamed(String name);

  /// No description provided for @azkarFontSizeTitle.
  ///
  /// In ar, this message translates to:
  /// **'حجم خط الأذكار'**
  String get azkarFontSizeTitle;

  /// No description provided for @hijriAdjustmentTitle.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ الهجري'**
  String get hijriAdjustmentTitle;

  /// No description provided for @hijriAdjustmentSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'عدّل التاريخ الهجري ليوافق إعلان بلدك لبداية الشهر.'**
  String get hijriAdjustmentSubtitle;

  /// No description provided for @hijriAdjustmentToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم: {date}'**
  String hijriAdjustmentToday(String date);
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
