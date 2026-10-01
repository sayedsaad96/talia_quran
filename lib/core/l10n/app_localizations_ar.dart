// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'تالية';

  @override
  String get home => 'الرئيسية';

  @override
  String get quran => 'القرآن';

  @override
  String get hifz => 'الحفظ';

  @override
  String get azkar => 'الأذكار';

  @override
  String get progress => 'تقدمي';

  @override
  String get greetingMorning => 'صباح النور';

  @override
  String get greetingAfternoon => 'مساء الخير';

  @override
  String get greetingEvening => 'مساء النور';

  @override
  String get greetingNight => 'ليلة مباركة';

  @override
  String get dailyWird => 'الورد اليومي';

  @override
  String get continueReading => 'أكمل القراءة';

  @override
  String get startMemorizing => 'ابدأ الحفظ';

  @override
  String get surahList => 'قائمة السور';

  @override
  String get surahDetails => 'تفاصيل السورة';

  @override
  String get juz => 'الجزء';

  @override
  String get ayah => 'الآية';

  @override
  String get ayahs => 'الآيات';

  @override
  String get surah => 'السورة';

  @override
  String get surahs => 'السور';

  @override
  String get meccan => 'مكية';

  @override
  String get medinan => 'مدنية';

  @override
  String get searchSurah => 'ابحث عن سورة أو آية';

  @override
  String get memorization => 'الحفظ';

  @override
  String get selectSurah => 'اختر سورة للحفظ';

  @override
  String get selectAyah => 'اختر الآية';

  @override
  String get startFrom => 'ابدأ من';

  @override
  String get markMemorized => 'حفظت هذه الآية';

  @override
  String get nextAyah => 'الآية التالية';

  @override
  String get prevAyah => 'الآية السابقة';

  @override
  String get playPageRecitation => 'تلاوة الصفحة';

  @override
  String get pauseRecitation => 'إيقاف التلاوة مؤقتاً';

  @override
  String get stopRecitation => 'إيقاف التلاوة';

  @override
  String get changeReciter => 'تغيير القارئ';

  @override
  String get closePlayer => 'إغلاق المشغل';

  @override
  String get moreOptions => 'المزيد';

  @override
  String get reciterActiveChip => 'المحدد';

  @override
  String get emptyBookmarksTitle => 'لا توجد علامات مرجعية بعد';

  @override
  String get emptyBookmarksHint =>
      'اضغط مطوّلاً على أي آية أثناء القراءة لحفظها كعلامة مرجعية وتصل إليها بسهولة هنا';

  @override
  String get exitDialogTitle => 'التلاوة قيد التشغيل';

  @override
  String exitDialogBody(String surah) {
    return 'تستمع الآن إلى $surah.\nهل تود استمرار الاستماع في الخلفية مع التحكم من شريط الإشعارات، أم إيقاف التلاوة والخروج؟';
  }

  @override
  String get currentSurah => 'السورة الحالية';

  @override
  String get exitDialogContinueBackground => 'متابعة في الخلفية';

  @override
  String get exitDialogStopAndExit => 'إيقاف التلاوة والخروج';

  @override
  String get exitDialogStayInApp => 'البقاء في التطبيق';

  @override
  String get memorized => 'محفوظة';

  @override
  String get review => 'مراجعة';

  @override
  String get newAyah => 'آية جديدة';

  @override
  String get hifzProgress => 'تقدم الحفظ';

  @override
  String get morningAzkar => 'أذكار الصباح';

  @override
  String get eveningAzkar => 'أذكار المساء';

  @override
  String get generalAzkar => 'أذكار عامة';

  @override
  String get duas => 'الأدعية';

  @override
  String get count => 'العدد';

  @override
  String get done => 'تم';

  @override
  String get reset => 'إعادة';

  @override
  String get overallProgress => 'التقدم الكلي';

  @override
  String get streak => 'السلسلة';

  @override
  String get days => 'أيام';

  @override
  String get day => 'يوم';

  @override
  String get achievements => 'الإنجازات';

  @override
  String get yourStreak => 'سلسلة حضورك';

  @override
  String get quranProgress => 'تقدمك في القرآن';

  @override
  String get memorizedSurahs => 'السور المحفوظة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get settingsPageSubtitle => 'اضبط تالية بما يناسب روتينك';

  @override
  String get settingsQuickPreferences => 'تفضيلات سريعة';

  @override
  String get settingsMoreSettings => 'إعدادات أخرى';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get tryAgain => 'حاول مجدداً';

  @override
  String get errorCacheMessage =>
      'تعذّر الوصول إلى البيانات المحفوظة. حاول مجدداً.';

  @override
  String get errorNetworkMessage => 'تحقّق من اتصالك بالإنترنت وحاول مجدداً.';

  @override
  String get errorNotFoundMessage => 'لم يتم العثور على المحتوى المطلوب.';

  @override
  String get errorParseMessage =>
      'حدثت مشكلة أثناء قراءة المحتوى. حاول مجدداً.';

  @override
  String get errorUnknownMessage => 'حدث خطأ غير متوقع. حاول مجدداً.';

  @override
  String celebrationAyah(int xp) {
    return 'أحسنت! +$xp XP ⭐';
  }

  @override
  String celebrationPage(int xp) {
    return 'اكتملت الصفحة! +$xp XP 🎯';
  }

  @override
  String get celebrationJuzDone => 'أتممت الجزء كاملاً بإذن الله';

  @override
  String get tutorialQuickStartTitle => 'خريطة تالية السريعة';

  @override
  String get tutorialQuickStartSubtitle =>
      'أهم خمسة أقسام لاستخدام التطبيق يومياً';

  @override
  String get tutorialQuickStartHint =>
      'استخدم البحث أو التصفية للوصول إلى أي شرح تفصيلي.';

  @override
  String get tutorialShortcutHomeLabel => 'الرئيسية';

  @override
  String get tutorialShortcutHomeDesc => 'الورد والتقدم اليومي';

  @override
  String get tutorialShortcutQuranLabel => 'القرآن';

  @override
  String get tutorialShortcutQuranDesc => 'المصحف والقراءة';

  @override
  String get tutorialShortcutHifzLabel => 'الحفظ';

  @override
  String get tutorialShortcutHifzDesc => 'الخطة والجلسات';

  @override
  String get tutorialShortcutAzkarLabel => 'الأذكار';

  @override
  String get tutorialShortcutAzkarDesc => 'الورد والعداد';

  @override
  String get tutorialShortcutProgressLabel => 'التقدم';

  @override
  String get tutorialShortcutProgressDesc => 'الشهادات والإنجازات';

  @override
  String get splashTagline => 'رفيقك في رحاب القرآن';

  @override
  String get splashInitError => 'تعذّر إكمال التحميل، يرجى المحاولة مرة أخرى';

  @override
  String get retryLabel => 'إعادة المحاولة';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get emptyState => 'لا يوجد محتوى بعد';

  @override
  String get play => 'تشغيل';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get stop => 'إيقاف';

  @override
  String get next => 'التالي';

  @override
  String get previous => 'السابق';

  @override
  String get playSurah => 'تشغيل السورة';

  @override
  String get playPage => 'تلاوة الصفحة';

  @override
  String get listenToSurah => 'استماع للسورة';

  @override
  String get nowPlaying => 'يتلو الآن';

  @override
  String get ofLabel => 'من';

  @override
  String get completed => 'مكتمل';

  @override
  String get inProgress => 'قيد التقدم';

  @override
  String get notStarted => 'لم يبدأ';

  @override
  String get bismillah => 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  @override
  String get basmala => 'بسملة';

  @override
  String get streakMessage1 => 'استمر، أنت في المسار الصحيح!';

  @override
  String get streakMessage2 => 'رائع! يوم آخر مع القرآن الكريم';

  @override
  String get streakMessage3 => 'ماشاء الله! استمرارية مذهلة';

  @override
  String get achievementFirstSurah => 'حفظت أول سورة';

  @override
  String get achievementWeekStreak => 'سلسلة أسبوع كامل';

  @override
  String get achievementQuran10 => '٪10 من القرآن';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String get small => 'صغير';

  @override
  String get medium => 'متوسط';

  @override
  String get large => 'كبير';

  @override
  String get extraLarge => 'كبير جداً';

  @override
  String get close => 'إغلاق';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get selectReciter => 'اختيار القارئ';

  @override
  String get enterFocusMode => 'الدخول إلى وضع التركيز';

  @override
  String get readerGoToPage => 'انتقل إلى صفحة أو سورة أو جزء';

  @override
  String get readerTajweedColors => 'ألوان التجويد';

  @override
  String get readerTajweedColorsHint => 'تلوين أحكام التجويد في صفحة المصحف';

  @override
  String get surahInProgressBadge => 'قيد الحفظ';

  @override
  String get exitFocusMode => 'الخروج من وضع التركيز';

  @override
  String get closeReader => 'إغلاق القارئ';

  @override
  String hizbNumberLabel(Object number) {
    return 'الحزب $number';
  }

  @override
  String azkarCountOfTotal(String total) {
    return 'من $total';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get confirm => 'تأكيد';

  @override
  String get delete => 'حذف';

  @override
  String get tafsir => 'التفسير';

  @override
  String get share => 'مشاركة';

  @override
  String get copy => 'نسخ';

  @override
  String get bookmark => 'إشارة مرجعية';

  @override
  String get undo => 'تراجع';

  @override
  String get copied => 'تم النسخ';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get name => 'الاسم';

  @override
  String get age => 'العمر';

  @override
  String get enterName => 'أدخل اسمك';

  @override
  String get enterAge => 'أدخل عمرك';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي';

  @override
  String get shareAchievement => 'مشاركة الإنجاز';

  @override
  String shareAchievementText(Object description, Object title) {
    return '🏆 إنجاز جديد يُضاف في رحلتي مع القرآن: \"$title\"\n📖 $description\n\nمع تالية، كل خطوة تتحول إلى أثر يُرى وإنجاز يستحق المشاركة.';
  }

  @override
  String shareAchievementWithName(
    Object description,
    Object name,
    Object title,
  ) {
    return '🏆 إنجاز جديد يُضاف في رحلة $name مع القرآن: \"$title\"\n📖 $description\n\nمع تالية، كل خطوة تتحول إلى أثر يُرى وإنجاز يستحق المشاركة.';
  }

  @override
  String shareMemorizationAchievementText(Object description, Object title) {
    return '🌟 إنجاز مبارك في مسيرة الحفظ: \"$title\"\n🧠 $description\n\nتالية يرافق رحلة الحفظ بخطوات واضحة، وتحفيز مستمر، وإنجازات تُلهم الاستمرار.';
  }

  @override
  String shareMemorizationAchievementWithName(
    Object description,
    Object name,
    Object title,
  ) {
    return '🌟 إنجاز مبارك في مسيرة حفظ $name: \"$title\"\n🧠 $description\n\nتالية يرافق رحلة الحفظ بخطوات واضحة، وتحفيز مستمر، وإنجازات تُلهم الاستمرار.';
  }

  @override
  String get shareProgress => 'مشاركة التقدم';

  @override
  String get shareMemorizationMilestone => 'مشاركة إنجاز الحفظ';

  @override
  String get shareConsistencyStreak => 'مشاركة الاستمرارية';

  @override
  String get shareApp => 'شارك تطبيق تالية';

  @override
  String get shareAppText =>
      'اكتشف تطبيق تالية للقرآن الكريم 📖✨\nرفيقك الذكي في رحلة الحفظ والتلاوة\nحمّله الآن: https://taliaapp.com';

  @override
  String shareProgressText(Object ayahs, Object pages, Object streak) {
    return '📊 هذا ملخص تقدمي في رحلتي مع القرآن عبر تالية:\n📖 $pages صفحة مقروءة\n🧠 $ayahs آية محفوظة\n🔥 $streak أيام من الاستمرارية\n\nتالية يساعدني على بناء عادة قرآنية ثابتة بخطوات واضحة وتحفيز يومي.';
  }

  @override
  String shareProgressWithName(
    Object ayahs,
    Object name,
    Object pages,
    Object streak,
  ) {
    return '📊 هذا ملخص تقدم $name في رحلته مع القرآن عبر تالية:\n📖 $pages صفحة مقروءة\n🧠 $ayahs آية محفوظة\n🔥 $streak أيام من الاستمرارية\n\nتالية يساعد على بناء عادة قرآنية ثابتة بخطوات واضحة وتحفيز يومي.';
  }

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get reading => 'القراءة';

  @override
  String get page => 'صفحة';

  @override
  String get pages => 'صفحات';

  @override
  String get pagesRead => 'صفحة مقروءة';

  @override
  String get readingProgress => 'تقدم القراءة';

  @override
  String get memorizationProgressTitle => 'تقدم الحفظ';

  @override
  String get smartMemorization => 'نظام الحفظ الذكي';

  @override
  String get smartMemorizationSubtitle =>
      'جدول تكيّفي • مراجعة ذكية • تقييم ذاتي';

  @override
  String get recitationAccuracy => 'دقة التسميع';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get about => 'حول التطبيق';

  @override
  String get systemDefault => 'حسب النظام';

  @override
  String get pureBlackTheme => 'أسود كامل (OLED)';

  @override
  String get changeMemorizationPath => 'تغيير مسار الحفظ';

  @override
  String get adultPath => 'مسار الكبار';

  @override
  String get adultPathDesc => 'البدء من الفاتحة والبقرة تصاعدياً';

  @override
  String get beginnerPath => 'مسار المبتدئين والأطفال';

  @override
  String get beginnerPathDesc => 'البدء من جزء عم (سورة الناس) تنازلياً';

  @override
  String get chooseMemorizationPath => 'اختر مسار الحفظ المناسب لك';

  @override
  String get audioPlayError => 'فشل تشغيل الصوت. تحقق من الاتصال بالإنترنت.';

  @override
  String get micPermissionError =>
      'يحتاج التطبيق إذن الميكروفون للتسميع الصوتي. يرجى السماح من إعدادات الجهاز.';

  @override
  String get speechUnavailableError =>
      'التسميع الصوتي غير متاح على هذا الجهاز حالياً.';

  @override
  String get openSettingsAction => 'فتح الإعدادات';

  @override
  String get account => 'الحساب';

  @override
  String get accuracyLevel => 'مستوى الدقة';

  @override
  String get streakProtection => 'حماية السلسلة';

  @override
  String get morningAzkarReminder => 'تذكير أذكار الصباح';

  @override
  String get eveningAzkarReminder => 'تذكير أذكار المساء';

  @override
  String get dailyDuaReminder => 'دعاء اليوم';

  @override
  String get dailyAyahReminder => 'آية اليوم';

  @override
  String get dailyDuaTime => 'كل يوم الساعة ٩:٠٠ صباحًا';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'حساب جديد';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صحيح';

  @override
  String get passwordTooShort => '6 أحرف على الأقل';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get loginSuccess => 'تم تسجيل الدخول بنجاح ✓';

  @override
  String get signupSuccess => 'تم إنشاء الحساب بنجاح ✓';

  @override
  String get confirmationEmailSent => '✅ تم إرسال رسالة التأكيد، تحقق من بريدك';

  @override
  String get resendConfirmation => 'إعادة إرسال';

  @override
  String get authEmailAlreadyRegistered =>
      'البريد الإلكتروني مسجل بالفعل. حاول تسجيل الدخول.';

  @override
  String get authConfirmEmailFirst =>
      'يرجى تأكيد بريدك الإلكتروني أولاً. تحقق من صندوق الوارد.';

  @override
  String get authInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get authTooManyRequests =>
      'محاولات كثيرة. انتظر قليلاً ثم حاول مرة أخرى.';

  @override
  String get authNoInternet => 'لا يوجد اتصال بالإنترنت';

  @override
  String get authAccountNotFound => 'لا يوجد حساب بهذا البريد الإلكتروني';

  @override
  String get authSignupFailed => 'فشل إنشاء الحساب';

  @override
  String get authSigninFailed => 'فشل تسجيل الدخول';

  @override
  String get authSignoutFailed => 'حدث خطأ أثناء تسجيل الخروج';

  @override
  String get authGenericError => 'حدث خطأ، حاول مرة أخرى';

  @override
  String get authPasswordSameAsOld =>
      'كلمة المرور الجديدة مطابقة للقديمة. يرجى اختيار كلمة مرور مختلفة.';

  @override
  String get authSessionExpired =>
      'رابط إعادة التعيين غير صالح أو انتهت صلاحيته. اطلب رسالة إعادة تعيين جديدة.';

  @override
  String get profileSavedToCloud => 'تم تسجيل الدخول إلى حسابك';

  @override
  String get guestModeWarning =>
      'سجّل دخولك لإدارة حسابك وخيارات الاستعادة وميزات العائلة.';

  @override
  String get signOutWarning =>
      'هل تريد تسجيل الخروج؟ يعود تقدم حسابك عند تسجيل الدخول مجددًا، أما خطة الختمة وسجل الختمات فمحفوظان على هذا الجهاز فقط وسيُحذفان عند تسجيل الخروج.';

  @override
  String get memorizationHubNothingToReview =>
      'لا توجد آيات للمراجعة بعد. ابدأ الحفظ أولًا، وستظهر آياتك هنا عندما يحين موعد مراجعتها.';

  @override
  String get homeQuranMemorizedCaption => 'حُفظ من القرآن';

  @override
  String get kidsSetupDiscardTitle => 'تجاهل إعداد الطفل؟';

  @override
  String get kidsSetupDiscardBody =>
      'لم يُحفظ إعداد مسار الأطفال بعد. هل تريد الخروج دون حفظ؟';

  @override
  String get kidsSetupKeepEditing => 'متابعة الإعداد';

  @override
  String get kidsSetupDiscard => 'خروج دون حفظ';

  @override
  String get listeningReviewStartMemorizing => 'ابدأ الحفظ';

  @override
  String get customPlanChildSwitchTitle => 'الانتقال إلى مسار الأطفال؟';

  @override
  String get customPlanChildSwitchBody =>
      'خطط الأطفال تُدار من مسار الأطفال. سيُنهى مسار الكبار وخطتك الحالية، وتبقى إنجازاتك وسجلك وشهاداتك، ثم يُفتح إعداد مسار الأطفال.';

  @override
  String get customPlanChildSwitchConfirm => 'انتقل إلى مسار الأطفال';

  @override
  String get guestImportTitle => 'نقل بيانات الحفظ المحلية؟';

  @override
  String get guestImportBody =>
      'لديك بيانات حفظ أنشأتها قبل تسجيل الدخول. انقلها إلى هذا الحساب حتى تظهر في تقدمك ومراجعاتك.';

  @override
  String get guestImportConfirm => 'نقل';

  @override
  String get guestImportLater => 'ليس الآن';

  @override
  String guestImportDone(String countText) {
    return 'تم نقل $countText من سجلات الحفظ.';
  }

  @override
  String get signOutPendingDataTitle => 'تقدم غير مزامن';

  @override
  String get signOutPendingDataWarning =>
      'بعض تقدم الحفظ لم يصل إلى السحابة بعد. تسجيل الخروج الآن سيحذفه من هذا الجهاز.';

  @override
  String get signOutAnyway => 'تسجيل الخروج على أي حال';

  @override
  String get dailyReviewReminder => 'تذكير المراجعة اليومية';

  @override
  String get dailyReviewTime => 'كل يوم الساعة ٨:٠٠ مساءً';

  @override
  String get streakProtectionDesc => 'تنبيه الساعة ١٠:٠٠ مساءً إذا لم تراجع';

  @override
  String get morningAzkarTime => 'كل يوم الساعة ٦:٠٠ صباحًا';

  @override
  String get eveningAzkarTime => 'كل يوم الساعة ٦:٠٠ مساءً';

  @override
  String get taliaDescription => 'تطبيق متميز لحفظ ومراجعة القرآن الكريم';

  @override
  String get settingsAppBrand => 'تالية — Talia';

  @override
  String get tutorialGuideTitle => 'دليل استخدام تالية';

  @override
  String get tutorialGuideSubtitle =>
      'تعرف على كل مزايا التطبيق وطريقة استخدامها';

  @override
  String get tutorialGuideHeroSubtitle => 'مركز المعرفة وشرح مزايا تالية';

  @override
  String tutorialGuideTopicsCount(int count) {
    return 'المواضيع: $count';
  }

  @override
  String tutorialGuideTipsCount(int count) {
    return 'النصائح والشروح: $count';
  }

  @override
  String get tutorialGuideSearchHint => 'ابحث عن ميزة أو خطوة استخدام...';

  @override
  String get tutorialGuideNoResults => 'لا توجد نتائج مطابقة';

  @override
  String get tutorialGuideNoResultsHint =>
      'جرّب كلمة أقصر مثل: القرآن، الحفظ، الأذكار، الإشعارات.';

  @override
  String get arabicNameHint =>
      '💡 يفضل إدخال الاسم باللغة العربية ليظهر بشكل أجمل في الشهادات';

  @override
  String get invalidAge => 'أدخل عمرًا صحيحًا بين 1 و120';

  @override
  String get profileSaveError => 'تعذر حفظ الملف الشخصي';

  @override
  String get accuracySaveError => 'تعذر حفظ مستوى الدقة';

  @override
  String get reviewReminderSaveError => 'تعذر تحديث تذكير المراجعة';

  @override
  String get streakReminderSaveError => 'تعذر تحديث تنبيه السلسلة';

  @override
  String get morningAzkarSaveError => 'تعذر تحديث تذكير أذكار الصباح';

  @override
  String get eveningAzkarSaveError => 'تعذر تحديث تذكير أذكار المساء';

  @override
  String get dailyDuaSaveError => 'تعذر تحديث دعاء اليوم';

  @override
  String get dailyAyahSaveError => 'تعذر تحديث تذكير آية اليوم';

  @override
  String get difficultyEasy => 'سهل (٧٠٪)';

  @override
  String get difficultyMedium => 'متوسط (٨٥٪)';

  @override
  String get difficultyHard => 'صعب (٩٢٪)';

  @override
  String get bookmarkSaved => 'تم حفظ العلامة المرجعية';

  @override
  String get bookmarkAdded => 'تم إضافة علامة مرجعية ✓';

  @override
  String get bookmarkRemoved => 'تم إزالة العلامة المرجعية';

  @override
  String get levelBeginner => 'مبتدئ';

  @override
  String get levelStudent => 'طالب';

  @override
  String get levelHafez => 'حافظ';

  @override
  String get levelSheikh => 'شيخ';

  @override
  String get levelImam => 'إمام';

  @override
  String get juzCountLabel => 'الأجزاء';

  @override
  String get ayahsRead => 'الآيات المقروءة';

  @override
  String get learning => 'قيد التعلم';

  @override
  String get reviewing => 'قيد المراجعة';

  @override
  String get all => 'الكل';

  @override
  String get streakTerm => 'المواظبة';

  @override
  String get achieved => 'تم الإنجاز!';

  @override
  String get adultsTrack => 'مسار الكبار';

  @override
  String get memorizedTerm => 'مكتمل';

  @override
  String get reviewingPrefix => 'قيد المراجعة: ';

  @override
  String get kidsTrack => 'مسار الأطفال';

  @override
  String get points => 'النقاط';

  @override
  String get stars => 'النجوم';

  @override
  String get myCertificates => 'شهاداتي';

  @override
  String get juzSaved => 'الأجزاء المحفوظة';

  @override
  String get removeBookmarkTitle => 'حذف العلامة؟';

  @override
  String get goBack => 'العودة';

  @override
  String get taliaUser => 'مستخدم تالية';

  @override
  String get startFatihah => 'ابدأ قراءة سورة الفاتحة';

  @override
  String surahAyahFormat(Object surahName, Object ayahNumber) {
    return 'سورة $surahName، آية $ayahNumber';
  }

  @override
  String get saveProgress => 'احفظ تقدمك';

  @override
  String get syncProgressDesc =>
      'سجّل دخولك لإدارة حسابك وخيارات الاستعادة وميزات العائلة';

  @override
  String get restoringProgress => 'جارٍ استعادة بياناتك…';

  @override
  String get retrySyncAfterError => 'إعادة المحاولة';

  @override
  String get later => 'لاحقاً';

  @override
  String get congratulations => 'مبارك!';

  @override
  String get completedJuzAmma => 'لقد أتممت حفظ جزء عم بنجاح.';

  @override
  String get completedQuran => 'لقد أتممت حفظ القرآن الكريم كاملاً بنجاح.';

  @override
  String get continueMemorizing => 'متابعة الحفظ';

  @override
  String get view => 'عرض';

  @override
  String get endSessionTitle => 'إنهاء الجلسة؟';

  @override
  String get endSessionDesc =>
      'هل أنت متأكد من رغبتك في إنهاء جلسة الحفظ؟ لن يتم حفظ تقدمك الحالي.';

  @override
  String get continueAction => 'متابعة';

  @override
  String get exitAction => 'خروج';

  @override
  String get listen => 'استماع';

  @override
  String get finish => 'إنهاء';

  @override
  String get skip => 'تخطي';

  @override
  String get tryAgainAction => 'حاول مجدداً';

  @override
  String get youRecited => 'ما قرأته:';

  @override
  String get listeningInProgress => 'جاري الاستماع...';

  @override
  String get tapToRecord => 'اضغط للتسميع';

  @override
  String get adultPathTitle => 'مسار الكبار (تصاعدي)';

  @override
  String get adultPathSubtitle => 'من الفاتحة إلى الناس';

  @override
  String get beginnerPathTitle => 'مسار المبتدئين (تنازلي)';

  @override
  String get beginnerPathSubtitle => 'من الناس إلى الفاتحة';

  @override
  String get lockedSurahText => 'أكمل السورة السابقة لفتح هذه السورة';

  @override
  String bestStreak(Object count) {
    return 'أفضل: $count';
  }

  @override
  String get consecutiveDays => 'يوم متتالي';

  @override
  String miniProgressOf(Object total, Object unit) {
    return '$unit من $total';
  }

  @override
  String dailyPlanSummary(Object ayahs, Object minutes) {
    return '$ayahs آيات يومياً • $minutes دقيقة';
  }

  @override
  String get debugCertificatePreview => 'معاينة الشهادات للتجربة';

  @override
  String get debugCertificatePreviewDesc =>
      'اختبار عرض الشهادة دون الحصول عليها فعلياً.';

  @override
  String get debugCertJuz30 => 'جزء 30';

  @override
  String get debugCertSurahBaqarah => 'سورة البقرة';

  @override
  String get debugCertHalfQuran => 'نصف القرآن';

  @override
  String get debugCertFullQuran => 'ختم القرآن';

  @override
  String get backupProgressTitle => 'إدارة الحساب';

  @override
  String get backupProgressDesc =>
      'سجّل دخولك من الإعدادات لإدارة حسابك وميزات العائلة';

  @override
  String get azkarSubtitle => 'اذكر الله كثيراً';

  @override
  String get azkarContentUnderReview =>
      'محتوى الأذكار قيد المراجعة والاعتماد، وسيظهر هنا فور اعتماده.';

  @override
  String zikrCount(Object count) {
    return '$count ذكر';
  }

  @override
  String azkarCount(Object count) {
    return '$count أذكار';
  }

  @override
  String duaCount(Object count) {
    return '$count دعاء';
  }

  @override
  String get azkarIndex => 'فهرس الأذكار';

  @override
  String zikrNumber(Object number) {
    return 'ذكر رقم $number';
  }

  @override
  String completedCount(Object completed, Object total) {
    return '$completed من $total مكتمل';
  }

  @override
  String get zikrCopied => 'تم نسخ الذكر';

  @override
  String get sharedFromTalia => 'تمت المشاركة من تطبيق تالية للقرآن';

  @override
  String get zikrCompleted => 'اكتمل الذكر';

  @override
  String tapToTasbeeh(Object total) {
    return 'اضغط للتسبيح (من $total)';
  }

  @override
  String get azkarCompletedTitle => 'تم بحمد الله';

  @override
  String get azkarSectionsAndServices => 'استكشف المزيد';

  @override
  String get azkarWirdCompletedToday => 'اكتمل ورد اليوم بنجاح ✨';

  @override
  String get azkarMorningHeroSubtitle => 'ابدأ يومك بذكر الله وطمأنينة القلب';

  @override
  String get azkarEveningHeroSubtitle => 'اختم يومك بالسكينة والاستغفار';

  @override
  String get azkarReviewWird => 'مراجعة الورد';

  @override
  String get azkarStartWirdNow => 'ابدأ الورد الآن';

  @override
  String get azkarFreeTasbeeh => 'مسبحة حرة';

  @override
  String get azkarFreeTasbeehSubtitle => 'تسبيح واستغفار حر';

  @override
  String get azkarSearchHint => 'ابحث في الأدعية والأذكار...';

  @override
  String get azkarFavorites => 'المفضلة';

  @override
  String get azkarFavoritesEmptyTitle => 'لا توجد أدعية في المفضلة';

  @override
  String get azkarFavoritesEmptyDesc =>
      'اضغط على علامة الإشارة المرجعية بجانب أي دعاء لحفظه هنا';

  @override
  String get azkarFavoriteAdd => 'إضافة إلى المفضلة';

  @override
  String get azkarFavoriteRemove => 'إزالة من المفضلة';

  @override
  String get azkarSearchNoResultsTitle => 'لا توجد نتائج مطابقة';

  @override
  String get azkarSearchNoResultsDesc => 'لم نجد أي أدعية تطابق بحثك';

  @override
  String get azkarSearchClear => 'مسح البحث';

  @override
  String get azkarVirtueOrSource => 'فضل الذكر / المصدر';

  @override
  String get azkarVirtueAndSource => 'فضل الذكر والمصدر';

  @override
  String get azkarVirtue => 'فضل الذكر';

  @override
  String get azkarSource => 'المصدر';

  @override
  String get azkarAutoAdvanceOn => 'الانتقال التلقائي مفعّل';

  @override
  String get azkarAutoAdvanceOff => 'الانتقال التلقائي معطّل';

  @override
  String get azkarSmartWird => 'ورد ذكي';

  @override
  String get azkarSmartWirdSubtitle => 'ورد مبني على وقتك الآن';

  @override
  String azkarSmartWirdDone(int count) {
    return 'أكملت $count من الورد الذكي اليوم';
  }

  @override
  String get azkarSmartWirdResume => 'متابعة';

  @override
  String get azkarSmartWirdCompleted => 'اكتمل الورد الذكي';

  @override
  String get azkarQuietNight => 'الليلة الهادئة';

  @override
  String get azkarQuietNightSubtitle => 'قراءة متدفقة بلا عدّاد';

  @override
  String get azkarQuietNightExit => 'إنهاء القراءة الهادئة';

  @override
  String get azkarPlayRecitation => 'تشغيل التلاوة';

  @override
  String get azkarPauseRecitation => 'إيقاف التلاوة مؤقتًا';

  @override
  String get azkarShareWird => 'شارك تقدم الورد';

  @override
  String get azkarTasbeehResetTitle => 'تصفير المسبحة';

  @override
  String get azkarTasbeehResetDesc => 'هل تريد إعادة تعيين العداد إلى الصفر؟';

  @override
  String get azkarTasbeehResetConfirm => 'تصفير';

  @override
  String get azkarTasbeehResetTooltip => 'تصفير العداد';

  @override
  String get azkarTasbeehOpenTarget => 'مفتوح';

  @override
  String azkarTasbeehTargetLabel(int target) {
    return 'الهدف: $target';
  }

  @override
  String azkarTasbeehRound(int round) {
    return 'دورة $round';
  }

  @override
  String get azkarTasbeehTapHint => 'انقر في أي مكان في الدائرة للتسبيح';

  @override
  String azkarTasbeehTapSemantics(int count) {
    return 'انقر للتسبيح، العداد الحالي $count';
  }

  @override
  String get azkarCompletedDesc => 'اكتملت جميع الأذكار في هذه الفئة';

  @override
  String get generalAzkarSubtitle => 'مجموعة من الأذكار الشاملة';

  @override
  String get duasSubtitle => 'أدعية من القرآن والسنة ودعاء ختم القرآن';

  @override
  String totalSurahsAyahs(Object ayahs, Object surahs) {
    return '$surahs سورة • $ayahs آية';
  }

  @override
  String get yearActivity => 'نشاط السنة';

  @override
  String activityTooltip(Object count) {
    return '$count نشاط';
  }

  @override
  String get less => 'أقل';

  @override
  String get more => 'أكثر';

  @override
  String get memorizedAyahs => 'الآيات المحفوظة';

  @override
  String get startedAyahsLabel => 'آيات بدأ حفظها';

  @override
  String get reviewedAyahsTotalLabel => 'إجمالي المراجعات';

  @override
  String get overdueReviewsLabel => 'مراجعات متأخرة';

  @override
  String get retentionRateLabel => 'معدل الاحتفاظ';

  @override
  String get lastReviewLabel => 'آخر مراجعة';

  @override
  String get lastMemorizedLabel => 'آخر آية محفوظة';

  @override
  String get homeEngagementTitle => 'نشاطك';

  @override
  String get homeWeeklyActivityLabel => 'هذا الأسبوع';

  @override
  String get homeDueTodayLabel => 'مستحق اليوم';

  @override
  String get homeXpLevelLabel => 'المستوى';

  @override
  String get homeActivityHeatmapTitle => 'خريطة النشاط';

  @override
  String get memorizedSurahsLabel => 'السور المحفوظة';

  @override
  String get memorizedJuzLabel => 'الأجزاء المحفوظة';

  @override
  String get earnCertificatesHint =>
      'احفظ السور والأجزاء كاملة لتحصل على شهادات التميز!';

  @override
  String certificateTitleJuz(Object juz) {
    return 'شهادة حفظ الجزء $juz';
  }

  @override
  String get certificateTitleSurah => 'شهادة حفظ سورة';

  @override
  String certificateTitleSurahNamed(Object surahName) {
    return 'شهادة حفظ سورة $surahName';
  }

  @override
  String get certificateTitleHalfQuran => 'شهادة حفظ نصف القرآن الكريم';

  @override
  String get certificateTitleFullQuran => 'شهادة ختم القرآن الكريم كاملاً';

  @override
  String get saveFormatTitle => 'اختر صيغة الحفظ';

  @override
  String get saveAsImage => 'حفظ كصورة (في الاستوديو)';

  @override
  String get saveAsPdf => 'حفظ كملف PDF';

  @override
  String get certificateShareError => 'حدث خطأ أثناء المشاركة';

  @override
  String get certificateGalleryPermissionError =>
      'يجب منح صلاحية الوصول للاستوديو لحفظ الشهادة';

  @override
  String get certificateGallerySaveSuccess =>
      'تم حفظ الشهادة في الاستوديو بنجاح ✓';

  @override
  String get certificateSaveError => 'حدث خطأ أثناء الحفظ';

  @override
  String get certificatePdfError => 'حدث خطأ أثناء إنشاء ملف PDF';

  @override
  String get certificateNotFound => 'لم يتم العثور على الشهادة';

  @override
  String shareCertificateJuz(Object juz) {
    return 'بفضل الله أتممت حفظ الجزء $juz من القرآن الكريم 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙';
  }

  @override
  String shareCertificateSurah(Object surahName) {
    return 'بفضل الله أتممت حفظ سورة $surahName من القرآن الكريم 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙';
  }

  @override
  String get shareCertificateHalfQuran =>
      'بفضل الله أتممت حفظ نصف القرآن الكريم 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙';

  @override
  String get shareCertificateFullQuran =>
      'بفضل الله أتممت حفظ القرآن الكريم كاملاً 📖\nانضم إليّ في تطبيق تالية لحفظ القرآن 🌙';

  @override
  String get achievementTitleFirstPage => 'الصفحة الأولى';

  @override
  String get achievementDescFirstPage => 'اقرأ أول صفحة من القرآن';

  @override
  String get achievementTitleTenPages => '١٠ صفحات';

  @override
  String get achievementDescTenPages => 'اقرأ ١٠ صفحات من القرآن';

  @override
  String get achievementTitleFiftyPages => '٥٠ صفحة';

  @override
  String get achievementDescFiftyPages => 'اقرأ ٥٠ صفحة من القرآن';

  @override
  String get achievementTitleJuzRead => 'جزء كامل';

  @override
  String get achievementDescJuzRead => 'اقرأ جزءاً كاملاً (٢٠ صفحة)';

  @override
  String get achievementTitleFiveJuzRead => '٥ أجزاء';

  @override
  String get achievementDescFiveJuzRead => 'اقرأ ٥ أجزاء من القرآن';

  @override
  String get achievementTitleHalfQuranRead => 'نصف القرآن';

  @override
  String get achievementDescHalfQuranRead => 'اقرأ نصف القرآن الكريم';

  @override
  String get achievementTitleFullQuranRead => 'ختم القرآن';

  @override
  String get achievementDescFullQuranRead => 'اقرأ القرآن الكريم كاملاً';

  @override
  String get achievementTitleFirstAyah => 'أول آية';

  @override
  String get achievementDescFirstAyah => 'احفظ أول آية من القرآن';

  @override
  String get achievementTitleTenAyahs => '١٠ آيات';

  @override
  String get achievementDescTenAyahs => 'احفظ ١٠ آيات';

  @override
  String get achievementTitleFiftyAyahs => '٥٠ آية';

  @override
  String get achievementDescFiftyAyahs => 'احفظ ٥٠ آية';

  @override
  String get achievementTitleHundredAyahs => '١٠٠ آية';

  @override
  String get achievementDescHundredAyahs => 'احفظ ١٠٠ آية';

  @override
  String get achievementTitleFirstSurah => 'أول سورة';

  @override
  String get achievementDescFirstSurah => 'احفظ سورة كاملة';

  @override
  String get achievementTitleFiveSurahs => '٥ سور';

  @override
  String get achievementDescFiveSurahs => 'احفظ ٥ سور كاملة';

  @override
  String get achievementTitleTenSurahs => '١٠ سور';

  @override
  String get achievementDescTenSurahs => 'احفظ ١٠ سور كاملة';

  @override
  String get achievementTitleJuzAmma => 'جزء عمّ';

  @override
  String get achievementDescJuzAmma => 'احفظ جزء عمّ كاملاً';

  @override
  String get achievementTitleOneJuzMemorized => 'جزء محفوظ';

  @override
  String get achievementDescOneJuzMemorized => 'احفظ جزءاً كاملاً';

  @override
  String get achievementTitleFiveJuzMemorized => '٥ أجزاء محفوظة';

  @override
  String get achievementDescFiveJuzMemorized => 'احفظ ٥ أجزاء من القرآن';

  @override
  String get achievementTitleTenJuzMemorized => '١٠ أجزاء';

  @override
  String get achievementDescTenJuzMemorized => 'احفظ ١٠ أجزاء من القرآن';

  @override
  String get achievementTitleHalfQuranMemorized => 'نصف القرآن';

  @override
  String get achievementDescHalfQuranMemorized => 'احفظ نصف القرآن الكريم';

  @override
  String get achievementTitleFullQuranMemorized => 'حافظ القرآن';

  @override
  String get achievementDescFullQuranMemorized => 'احفظ القرآن الكريم كاملاً';

  @override
  String get achievementTitleThreeDayStreak => '٣ أيام متتالية';

  @override
  String get achievementDescThreeDayStreak => 'حافظ على ٣ أيام متتالية';

  @override
  String get achievementTitleWeekStreak => 'أسبوع كامل';

  @override
  String get achievementDescWeekStreak => 'حافظ على ٧ أيام متتالية';

  @override
  String get achievementTitleTwoWeekStreak => 'أسبوعان';

  @override
  String get achievementDescTwoWeekStreak => 'حافظ على ١٤ يوماً متتالية';

  @override
  String get achievementTitleMonthStreak => 'شهر كامل';

  @override
  String get achievementDescMonthStreak => 'حافظ على ٣٠ يوماً متتالية';

  @override
  String get achievementTitleNinetyDayStreak => '٩٠ يوماً';

  @override
  String get achievementDescNinetyDayStreak => 'حافظ على ٩٠ يوماً متتالية';

  @override
  String get achievementTitleYearStreak => 'سنة كاملة';

  @override
  String get achievementDescYearStreak => 'حافظ على ٣٦٥ يوماً متتالياً';

  @override
  String bookmarksCountItem(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'علامات',
      one: 'علامة',
    );
    return '$count $_temp0';
  }

  @override
  String get memorizationPathReset => 'تمت اعادة ضبط مسار الحفظ';

  @override
  String get settingsSectionAccount => 'الحساب';

  @override
  String get settingsSectionAppearance => 'المظهر';

  @override
  String get settingsSectionQuranMemorization => 'القرآن والحفظ';

  @override
  String get settingsSectionKidsGuardian => 'الأطفال وولي الأمر';

  @override
  String get settingsSectionProgressAchievements => 'التقدم والإنجازات';

  @override
  String get settingsSectionHelpTutorial => 'المساعدة والدليل';

  @override
  String get settingsSectionPrivacySecurity => 'الخصوصية والأمان';

  @override
  String get settingsSectionAboutTalia => 'حول تالية';

  @override
  String get settingsBackgroundPlaybackTitle => 'التشغيل في الخلفية';

  @override
  String get settingsBackgroundPlaybackSubtitle =>
      'تستمر التلاوة بعد مغادرة التطبيق، ويمكن التحكم بها من شريط الإشعارات.';

  @override
  String get settingsHubPractice => 'الممارسة';

  @override
  String get settingsHubReminders => 'التنبيهات والتذكيرات';

  @override
  String get settingsHubSupport => 'الدعم';

  @override
  String get settingsRemindersGeneral => 'عام';

  @override
  String get settingsRemindersMemorization => 'تذكيرات الحفظ';

  @override
  String get settingsRemindersWorship => 'الأذكار والعبادة';

  @override
  String get settingsRemindersPrayer => 'الصلاة والأذان';

  @override
  String get settingsRemindersProgress => 'التقدم';

  @override
  String get notificationPermissionBlockedTitle =>
      'إشعارات التطبيق معطلة في إعدادات الهاتف';

  @override
  String get notificationPermissionBlockedBody =>
      'لن تصلك تذكيرات المراجعة أو الأذكار حتى يتم السماح بالإشعارات من إعدادات النظام.';

  @override
  String get notificationOpenSystemSettings => 'فتح إعدادات الهاتف';

  @override
  String get notificationStatusBlocked =>
      'أذونات الإشعارات معطلة في إعدادات النظام';

  @override
  String notificationStatusSummary(int enabled, int total) {
    return '$enabled من $total تذكيرات مفعّلة';
  }

  @override
  String get notificationTestInteractiveTitle => 'تجربة الإشعارات';

  @override
  String get notificationTestInteractiveSubtitle =>
      'أرسل إشعارًا تجريبيًا للتأكد أن التنبيهات تعمل';

  @override
  String get notificationPrayerPermissionBlockedBody =>
      'لن تصلك تنبيهات الصلاة حتى تسمح بالإشعارات من إعدادات الهاتف.';

  @override
  String get notificationConfigurePrayerTimes => 'إعداد مواقيت الصلاة';

  @override
  String get notificationTestPickerTitle => 'اختر إشعارًا لتجربته';

  @override
  String get notificationTestPickerSubtitle =>
      'سيصلك إشعار تجريبي مع أزرار تفاعل.';

  @override
  String get notificationTestReviewTitle => 'مراجعة اليوم 📖';

  @override
  String get notificationTestReviewBody =>
      'لديك 5 آيات مستحقة للمراجعة اليوم ⚡';

  @override
  String get notificationTestStreakTitle => 'حماية المواظبة 🔥';

  @override
  String get notificationTestStreakBody =>
      'لم تراجع اليوم بعد — حافظ على مواظبتك الآن 🔥';

  @override
  String get notificationTestSuccess => 'تم إرسال الإشعار التجريبي بنجاح ✨';

  @override
  String get notificationSettingsSaveFailed =>
      'تعذر حفظ التغيير. حاول مرة أخرى.';

  @override
  String get notificationSettingsSchedulingFailed =>
      'تم حفظ التغيير، لكن تعذر تحديث التنبيهات. حاول مرة أخرى.';

  @override
  String get prayerChooseCityForAccurateTimes =>
      'اختر مدينتك لإظهار مواقيت صلاة دقيقة.';

  @override
  String get prayerChooseCityAction => 'اختيار المدينة';

  @override
  String get settingsGuestStatusTitle => 'تستخدم تالية كضيف';

  @override
  String get settingsGuestStatusSubtitle =>
      'يبقى تقدمك المحلي على هذا الجهاز. أنشئ حساباً لإدارة الحساب وميزات العائلة.';

  @override
  String get settingsSignInCreateAccount => 'تسجيل الدخول / إنشاء حساب';

  @override
  String get settingsSignedInStatus => 'تم تسجيل الدخول إلى حسابك';

  @override
  String get settingsPrivacyPolicySubtitle => 'كيف نحفظ بياناتك وخصوصيتك';

  @override
  String get settingsMemorizationPathNotSelected => 'لم يتم اختيار مسار';

  @override
  String get settingsMemorizationPathNotSelectedDesc =>
      'اختر مسار الكبار أو الأطفال عند فتح تبويب الحفظ.';

  @override
  String get settingsResetPathKeeps => 'سيبقى: الإنجازات والسجل والشهادات';

  @override
  String get settingsResetPathChanges =>
      'سيتغير: المسار المختار والخطة الحالية';

  @override
  String get settingsResetPathInstruction =>
      'اكتب \"اعادة ضبط\" لتأكيد العملية.';

  @override
  String get settingsResetPathConfirmPhrase => 'اعادة ضبط';

  @override
  String get settingsDeleteAccountTitle => 'حذف الحساب';

  @override
  String get settingsDeleteAccountSubtitle => 'يحذف الحساب السحابي فقط';

  @override
  String settingsDeleteAccountWarning(Object email) {
    return 'سيتم حذف حساب Supabase المرتبط بـ $email وبياناته السحابية.\n\nلن يتم حذف تقدم القرآن المحلي، أو الحفظ، أو مسار الأطفال، أو الحفظ الذكي من هذا الجهاز.\n\nهل تريد المتابعة؟';
  }

  @override
  String get settingsAccountDeletedMessage =>
      'تم حذف الحساب السحابي. بقي تقدمك المحلي محفوظاً على هذا الجهاز.';

  @override
  String settingsVersion(Object version) {
    return 'الإصدار $version';
  }

  @override
  String settingsBuild(Object buildNumber) {
    return 'رقم البناء $buildNumber';
  }

  @override
  String get resetMemorizationPath => 'اعادة ضبط / تغيير المسار';

  @override
  String get memorizationPath => 'مسار الحفظ';

  @override
  String get kidsAndGuardian => 'الأطفال وولي الأمر';

  @override
  String get parentDashboardTitle => 'لوحة ولي الأمر';

  @override
  String get parentDashboardSubtitle =>
      'تابع حفظ الطفل والمكافآت والربط عن بعد';

  @override
  String get parentModeSubtitle => 'فعّل لمتابعة حفظ طفلك والربط عن بعد';

  @override
  String get resetMemorizationPathQuestion => 'اعادة ضبط مسار الحفظ؟';

  @override
  String get resetMemorizationIdentityWarning =>
      'سيؤدي هذا إلى إلغاء المسار المختار وحالة ربط ولي الأمر، ولكنه سيحتفظ بإعدادات الحفظ الذكي الخاصة بك.';

  @override
  String get confirmResetMemorizationPath => 'تأكيد إعادة الضبط';

  @override
  String get resetMemorizationPathTileTitle => 'اعادة ضبط المسار';

  @override
  String get resetMemorizationPathTileSubtitle =>
      'اختر مسار الكبار أو الأطفال مرة أخرى بدون فقدان إعدادات الحفظ الذكي.';

  @override
  String get resetMemorizationPathPreserveProgressDesc =>
      'تغيير مسار الحفظ بين مسار الكبار والأطفال، مع الاحتفاظ ببيانات الحفظ.';

  @override
  String get resetMemorizationPathPreserveProgressDialog =>
      'هذا سيقوم بإلغاء مسار الحفظ الحالي لتتمكن من اختيار مسار جديد. لن تفقد آياتك المحفوظة.';

  @override
  String completePreviousSurahFirst(Object surahName) {
    return 'أكمل $surahName أولاً';
  }

  @override
  String get linkGuardianNow => 'ربط ولي الأمر الآن';

  @override
  String get continueWithoutGuardian => 'المتابعة بدون ولي أمر';

  @override
  String get guardianLinkTitle => 'ربط حساب ولي الأمر';

  @override
  String get guardianLinkDesc =>
      'اختر ما إذا كنت تريد ربط ولي أمر بهذا المسار لمتابعة حفظ الطفل.';

  @override
  String get guardianCreateCodeMessage =>
      'قم بإنشاء رمز جديد صالح لمدة 15 دقيقة.';

  @override
  String get guardianCodeUsedMessage => 'لا يمكن استخدام هذا الرمز مرة أخرى.';

  @override
  String get guardianCreateNewCode => 'إنشاء رمز جديد';

  @override
  String get guardianCodeExpired => 'انتهت صلاحية الرمز';

  @override
  String get guardianCodeAlreadyUsed => 'تم استخدام الرمز مسبقاً';

  @override
  String guardianPairingValidUntil(Object time) {
    return 'صالح حتى الساعة $time';
  }

  @override
  String guardianPairingExpiresIn(int minutes) {
    return 'ينتهي خلال $minutes دقيقة';
  }

  @override
  String get guardianPairingExpired => 'انتهت صلاحية الرمز';

  @override
  String get guardianPairingStepsTitle => 'خطوات الربط';

  @override
  String get guardianPairingStepOpenParentDevice =>
      'افتح تالية على جهاز ولي الأمر';

  @override
  String get guardianPairingStepOpenDashboard =>
      'اذهب إلى الإعدادات > لوحة ولي الأمر';

  @override
  String get guardianPairingStepScanOrEnterCode =>
      'امسح رمز QR أو أدخل الرمز يدوياً';

  @override
  String get guardianRegenerateCode => 'تجديد الرمز';

  @override
  String get guardianSignInRequired =>
      'سجّل دخولك للوصول إلى أدوات ولي الأمر. يبقى تقدمك المحلي على هذا الجهاز.';

  @override
  String get guardianSignInAction => 'تسجيل الدخول أو إنشاء حساب';

  @override
  String get guardianGuestContinueKids => 'متابعة حفظ الأطفال';

  @override
  String get guardianLinkingTemporarilyBlocked => 'الربط متوقف مؤقتاً';

  @override
  String get guardianLinkingFailedTitle => 'تعذر ربط ولي الأمر';

  @override
  String get guardianLinkingTimeoutMessage =>
      'استغرق ربط ولي الأمر وقتاً طويلاً. تحقق من الاتصال وحاول مجدداً، أو تابع بدون ولي أمر الآن.';

  @override
  String get splashSubtitle => 'اقرأ، احفظ، راجع، وانمُ مع القرآن.';

  @override
  String get splashFeatureRead => 'اقرأ';

  @override
  String get splashFeatureMemorize => 'احفظ';

  @override
  String get splashFeatureReview => 'راجع';

  @override
  String get splashFeatureGrow => 'انمُ';

  @override
  String get onboardingStartJourney => 'ابدأ رحلتك';

  @override
  String get onboardingSlide1Title => 'مصحفك اليومي بتلاوة وتدبر';

  @override
  String get onboardingSlide1Subtitle =>
      'قراءة مصحفية أصيلة، خطوط عثمانية مريحة للعين، واستماع لكبار القراء، وخطط ختمة بالوتيرة التي تناسبك.';

  @override
  String get onboardingBentoMushafSurah => 'سورة الإسراء';

  @override
  String get onboardingBentoListeningTitle => 'تلاوات متقنة';

  @override
  String get onboardingBentoListeningDesc => 'استماع وتكرار صوتي';

  @override
  String get onboardingBentoKhatmahTitle => 'خطط الختمة';

  @override
  String get onboardingBentoKhatmahDesc => 'وتيرة يومية تناسبك';

  @override
  String get onboardingBentoKhatmahBadge => 'ورد يومي';

  @override
  String get onboardingSlide2Title => 'احفظ القرآن ورسّخه بذكاء';

  @override
  String get onboardingSlide2Subtitle =>
      'تقنيات تكرار ذكية ومتباعدة تقيس قوة حفظك وتمنع النسيان قبل وقوعه.';

  @override
  String get onboardingBentoMasteryTitle => 'نسبة الإتقان والتثبيت';

  @override
  String get onboardingBentoMasteryValue => '٩٨٪ متقن';

  @override
  String get onboardingBentoActiveRecallTitle => 'استرجاع نشط';

  @override
  String get onboardingBentoActiveRecallDesc => 'إخفاء الكلمات للاختبار الذاتي';

  @override
  String get onboardingBentoReviewScheduleTitle => 'مراجعة ذكية';

  @override
  String get onboardingBentoReviewScheduleDesc => 'تذكير تلقائي لمنع النسيان';

  @override
  String get onboardingBentoStatusMastered => 'متقن راسخ';

  @override
  String get onboardingBentoStatusDueSoon => 'مراجعة قريبة';

  @override
  String get onboardingBentoStatusNew => 'جديد';

  @override
  String get onboardingBentoSmartAlert => 'تذكير ذكي';

  @override
  String get onboardingSlide3Title => 'ورد مستمر وتجربة لكل العائلة';

  @override
  String get onboardingSlide3Subtitle =>
      'ابنِ عادة قرآنية يومية لا تنقطع، مع مسار تفاعلي ممتع مخصص للأطفال، وبدون إنترنت.';

  @override
  String get onboardingBentoStreakTitle => 'سلسلة الورد اليومي';

  @override
  String get onboardingBentoStreakDays => '٧ أيام متواصلة 🔥';

  @override
  String get onboardingBentoOfflineBadge => 'يعمل دون إنترنت';

  @override
  String get onboardingBentoKidsTeaserTitle => 'مسار براعم تالية';

  @override
  String get onboardingBentoKidsTeaserDesc => 'نجوم، أصوات ومكافآت محفزة';

  @override
  String get onboardingPillarReadTitle => 'تلاوة ومصحف أصيل';

  @override
  String get onboardingPillarMemorizeTitle => 'حفظ ومراجعة ذكية';

  @override
  String get onboardingPillarHabitTitle => 'ورد واستمرارية';

  @override
  String get onboardingChooseExpTitle => 'اختر التجربة المناسبة';

  @override
  String get onboardingChooseExpSubtitle =>
      'خصص تجربة تالية لتلائم احتياجك. يمكنك تبديل المسار دائماً من الإعدادات.';

  @override
  String get onboardingAdultPathTitle => 'مسار الكبار واليافعين';

  @override
  String get onboardingAdultPathSubtitle =>
      'مساحة قرآنية مركزة للقراءة والحفظ والمراجعة ومتابعة التقدم.';

  @override
  String get onboardingKidsPathTitle => 'مسار البراعم والأطفال';

  @override
  String get onboardingKidsPathSubtitle =>
      'رحلة تفاعلية ممتعة بالمهام المبسطة والتكرار الإيجابي والمكافآت.';

  @override
  String get onboardingKidsFeatureMissions => 'مهام قصيرة وميسرة';

  @override
  String get onboardingKidsFeatureAudio => 'استماع وتكرار تفاعلي';

  @override
  String get onboardingKidsFeatureStars => 'نجوم ومكافآت تشجيعية';

  @override
  String get onboardingEnterAsGuest => 'المتابعة كضيف';

  @override
  String get onboardingSignInAccount => 'تسجيل الدخول / إنشاء حساب';

  @override
  String get onboardingAyahReference => 'سورة المزمّل ٤';

  @override
  String get onboardingOfflineTrustLine =>
      'يعمل دون إنترنت، بياناتك محفوظة على جهازك';

  @override
  String get onboardingErrorGeneric =>
      'تعذّر إكمال الإعداد. تأكد من توفر مساحة على الجهاز ثم حاول مجدداً، أو تخطَّ الإعداد الآن.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get memorizationPathTitle => 'مسار الحفظ';

  @override
  String get memorizationPathQuestion => 'من سيستخدم هذه الميزة؟';

  @override
  String get memorizationPathDescription =>
      'اختر المسار المناسب لك أو لطفلك لتجربة حفظ مخصصة.';

  @override
  String get memorizationPathAdultsTitle => 'مسار البالغين';

  @override
  String get memorizationPathAdultsDesc =>
      'خطة حفظ مرنة مع مراجعة ذكية وتتبع يومي للإنجاز.';

  @override
  String get memorizationPathKidsTitle => 'مسار الأطفال';

  @override
  String get memorizationPathKidsDesc =>
      'رحلة حفظ تفاعلية ممتعة بإشراف ولي الأمر.';

  @override
  String get kidsJourneyTitle => 'رحلة الحفظ';

  @override
  String get kidsJourneySubtitle => 'استمع، كرر، واجمع النجوم خطوة بخطوة';

  @override
  String get kidsJourneyMapTitle => 'خريطة الحفظ';

  @override
  String get kidsJourneyMotivation => 'مع كل آية تقترب أكثر من كتاب الله';

  @override
  String get kidsJourneySignpost1 => 'رحلتنا إلى القرآن أجمل';

  @override
  String get kidsJourneySignpost2 => 'كل خطوة نور';

  @override
  String get kidsJourneySignpost3 => 'نكمل حفظ كتاب الله';

  @override
  String kidsPointsValue(int points) {
    return '$points نقطة';
  }

  @override
  String kidsLevelValue(int level) {
    return 'مستوى $level';
  }

  @override
  String get kidsStartFirstStageToday => 'ابدأ أول مرحلة اليوم';

  @override
  String kidsStageAyahRange(int stage, int startAyah, int endAyah) {
    return 'المرحلة $stage: الآيات $startAyah-$endAyah';
  }

  @override
  String get remoteGuardianLinkTitle => 'ربط ولي الأمر عن بعد';

  @override
  String get createQr => 'إنشاء QR';

  @override
  String get renew => 'تجديد';

  @override
  String get remoteGuardianLinkInstruction =>
      'افتح لوحة ولي الأمر على الجهاز الآخر وامسح الرمز.';

  @override
  String kidsStageTitle(int stage) {
    return 'مرحلة $stage';
  }

  @override
  String kidsStageProgress(
    int startAyah,
    int endAyah,
    int completed,
    int total,
  ) {
    return 'الآيات $startAyah-$endAyah • $completed/$total';
  }

  @override
  String get quranLongPressHint =>
      'اضغط مطولاً على الآية للاستماع أو إضافة علامة';

  @override
  String get readPageConfirmed => 'تم احتساب الصفحة';

  @override
  String get dailyPlanRatingWeakDesc => 'احتجت للمصحف';

  @override
  String get dailyPlanRatingAverageDesc => 'أخطاء بسيطة';

  @override
  String get dailyPlanRatingExcellentDesc => 'بدون خطأ';

  @override
  String get dailyPlanRatingHintTitle => 'كيف تختار التقييم؟';

  @override
  String get dailyPlanRatingHintBody =>
      'التقييم يحدد موعد المراجعة القادمة: ضعيف للمراجعة القريبة، متوسط للمراجعة المعتدلة، وممتاز للمراجعة بعد فترة أطول.';

  @override
  String get understood => 'فهمت';

  @override
  String get hifzSkipHintTitle => 'تخطي الآية';

  @override
  String get hifzSkipHintBody => 'سنضيف هذه الآية للمراجعة لاحقاً، لا تقلق.';

  @override
  String get accuracyEasyTitle => 'متسامح';

  @override
  String get accuracyEasyDesc => 'مناسب للأطفال والمبتدئين';

  @override
  String get accuracyMediumTitle => 'متوازن';

  @override
  String get accuracyMediumDesc => 'للممارسة اليومية';

  @override
  String get accuracyHardTitle => 'دقيق';

  @override
  String get accuracyHardDesc => 'للمتقدمين';

  @override
  String accuracyRequiredPercent(int percent) {
    return '$percent% مطلوبة';
  }

  @override
  String get parentGuardianMode => 'أنا ولي أمر';

  @override
  String get qcfPocTitle => 'تجربة عرض QCF';

  @override
  String get qcfPocIntro =>
      'شاشة مؤقتة لاختبار العرض البصري للقرآن داخل منطقة الحفظ.';

  @override
  String get qcfPocNoProduction =>
      'هذه الشاشة لا تغيّر منطق الحفظ أو حالة الحفظ أو التقدم أو القفل أو نقاط التحقق.';

  @override
  String get qcfPocVisualOnly =>
      'يُستخدم qcf_quran_plus هنا لعرض آيات القرآن بصرياً فقط.';

  @override
  String get qcfPocSingleVerse => 'آية واحدة';

  @override
  String get qcfPocMultipleVerses => 'عدة آيات';

  @override
  String get qcfPocLastVerse => 'آخر آية';

  @override
  String get qcfPocFullPage => 'صفحة مصحف كاملة';

  @override
  String get qcfPocFindings => 'النتائج';

  @override
  String get qcfPocSupported => 'مدعوم';

  @override
  String get qcfPocLimited => 'محدود';

  @override
  String get qcfPocUnsupported => 'غير مدعوم';

  @override
  String get qcfPocStatus => 'الحالة';

  @override
  String get qcfPocAlBaqarah255 => 'البقرة ٢٥٥';

  @override
  String get qcfPocAlFatihah => 'الفاتحة ١-٧';

  @override
  String get qcfPocAlIkhlas => 'الإخلاص ١-٤';

  @override
  String get qcfPocAshSharh8 => 'الشرح ٨';

  @override
  String get qcfPocFullPageSample => 'معاينة صفحة المصحف ١';

  @override
  String get qcfPocVerseSupported => 'تظهر الآية بصرياً باستخدام أدوات QCF.';

  @override
  String get qcfPocMultiVerseSupported =>
      'تظهر الآيات المجموعة بصرياً من السورة نفسها.';

  @override
  String get qcfPocFullPageSupported =>
      'عرض الصفحة الكاملة متاح داخل معاينة محددة.';

  @override
  String get qcfPocNoLimitations => 'لم تظهر قيود في هذه التجربة المعزولة.';

  @override
  String get qcfPocLimitationInstruction =>
      'يجب مراجعة أي قيد يظهر هنا قبل تغيير شاشات الحفظ الفعلية.';

  @override
  String get parentDashboardCardSubtitle => 'تابع حفظ الطفل والمكافآت';

  @override
  String get viewDashboard => 'عرض اللوحة';

  @override
  String get resumeWhereYouLeft => 'استكمال من حيث توقفت';

  @override
  String get resumeAction => 'استكمال';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get lastSavedReading => 'آخر قراءة محفوظة';

  @override
  String get incompleteHifzSession => 'جلسة حفظ غير مكتملة';

  @override
  String get dailyMemorizationPlan => 'خطة حفظ يومية';

  @override
  String get incompleteKidsSession => 'جلسة طفل غير مكتملة';

  @override
  String get previousHifzQuiz => 'اختبار حفظ سابق';

  @override
  String get savedPreviousActivity => 'نشاط سابق محفوظ';

  @override
  String get completeTodaysHifz => 'أكمل ورد الحفظ اليوم';

  @override
  String get planReadySmallStep => 'خطتك جاهزة، خطوة صغيرة تكفي.';

  @override
  String get readTodaysPortion => 'اقرأ ورد اليوم';

  @override
  String get onePageMakesProgress => 'صفحة واحدة تجعل التقدّم واضحاً.';

  @override
  String get timeForDhikr => 'حان وقت الذكر';

  @override
  String get startShortAzkarNow => 'ابدأ بأذكار قصيرة الآن.';

  @override
  String get followChildJourney => 'تابع رحلة الطفل';

  @override
  String get reviewProgressOrReward => 'راجع التقدم أو أضف مكافأة مشجعة.';

  @override
  String get startQuranStepNow => 'ابدأ خطوة قرآنية الآن';

  @override
  String get chooseReadingOrMemorization =>
      'اختر قراءة أو حفظاً بسيطاً لهذا اليوم.';

  @override
  String get kidsFirstMissionToday => 'مهمتك الأولى اليوم';

  @override
  String kidsCompleteStageToday(int stage) {
    return 'أكمل المرحلة $stage اليوم';
  }

  @override
  String get kidsFirstMissionSubtitle =>
      'ابدأ بالاستماع والتكرار، وكل خطوة تقربك من نجمة جديدة.';

  @override
  String kidsRemainingAyahs(int count) {
    return 'تبقى $count آيات في هذه المرحلة.';
  }

  @override
  String notificationEverydayAt(String time) {
    return 'كل يوم الساعة $time';
  }

  @override
  String get kidsGamifiedWelcome => 'مرحباً بطل الحفظ!';

  @override
  String kidsGamifiedWelcomeNamed(String name) {
    return 'مرحباً يا $name، بطل الحفظ!';
  }

  @override
  String kidsGamifiedLevelProgress(int level, int progress) {
    return 'المستوى $level — $progress/100';
  }

  @override
  String kidsGamifiedStarsCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText نجمة',
      many: '$countText نجمة',
      few: '$countText نجمات',
      two: 'نجمتان',
      one: 'نجمة واحدة',
      zero: '$countText نجمة',
    );
    return '$_temp0';
  }

  @override
  String get kidsGamifiedLastMission => 'مهمتك الآن';

  @override
  String get kidsGamifiedContinueNow => 'استكمل الآن';

  @override
  String get kidsGamifiedMushaf => 'المصحف';

  @override
  String get kidsGamifiedJourney => 'رحلتي';

  @override
  String get kidsGamifiedMissions => 'المهام';

  @override
  String kidsGamifiedHouseTitle(int number) {
    return 'بيت الحفظ $number';
  }

  @override
  String kidsGamifiedReviewHouseTitle(int number) {
    return 'بيت المراجعة $number';
  }

  @override
  String kidsGamifiedAyahRange(int startAyah, int endAyah) {
    return 'الآيات $startAyah-$endAyah';
  }

  @override
  String kidsGamifiedProgressCount(int completed, int total) {
    return '$completed/$total';
  }

  @override
  String get kidsGamifiedLockedStage => 'هذا البيت مغلق الآن';

  @override
  String kidsGamifiedDailyLimitReached(int count) {
    return 'أنجزت مهام اليوم، ما شاء الله! عُد غداً لبيت جديد.';
  }

  @override
  String get kidsGamifiedCurrentStage => 'مهمتك الحالية';

  @override
  String get kidsGamifiedCompletedStage => 'أحسنت، اكتمل البيت';

  @override
  String get kidsGamifiedNeedsReview => 'جاهز للمراجعة';

  @override
  String get kidsGamifiedListenStep => 'استمع';

  @override
  String get kidsGamifiedListenStepSubtitle => 'اسمع الآية بتأنٍ وتركيز';

  @override
  String get kidsGamifiedRepeatStep => 'ردد';

  @override
  String get kidsGamifiedRepeatStepSubtitle => 'كرر خلف القارئ حتى تثبت الآية';

  @override
  String get kidsGamifiedTestStep => 'اختبر نفسك';

  @override
  String get kidsGamifiedTestStepSubtitle => 'حاول التسميع بدون مساعدة';

  @override
  String get kidsGamifiedTryFromMemory => 'جرّب من ذاكرتك';

  @override
  String get kidsGamifiedTryToRemember => 'حاول تتذكّر الآية';

  @override
  String get kidsGamifiedGiveMeTheStart => 'أعطني البداية';

  @override
  String get kidsGamifiedFirstWordShown => 'هذه أول كلمة، أكمل أنت';

  @override
  String get kidsGamifiedReviewChallenge => '⭐ تحدّي المراجعة';

  @override
  String get kidsGamifiedReviewChallengeSubtitle =>
      'هل تتذكّرها؟ سمّعها من ذاكرتك';

  @override
  String get kidsGamifiedRemindMe => 'ذكّرني';

  @override
  String get kidsWelcomeBackTitle => 'أهلاً بعودتك!';

  @override
  String get kidsWelcomeBackSubtitle => 'نبدأ بخطوة سهلة';

  @override
  String get kidsGamifiedEnoughForToday =>
      'أحسنت! هذا وقت كافٍ لليوم، يمكنك التوقف.';

  @override
  String get parentSupportTip =>
      'جرّبا معاً: استمعا للآية مرتين، ثم دع طفلك يبدأ بأول كلمة';

  @override
  String get kidsGamifiedStartMission => 'ابدأ المهمة';

  @override
  String get kidsGamifiedListenAndRepeat => 'استمع وكرر';

  @override
  String get kidsGamifiedRecordYourVoice => 'سجل تلاوتك';

  @override
  String get kidsGamifiedRecordingInProgress => 'جاري التسجيل...';

  @override
  String get kidsGamifiedDoneRecording => 'انتهيت من التسجيل';

  @override
  String get kidsGamifiedAudioUnavailable =>
      'الصوت غير متاح الآن، حاول مرة أخرى بعد قليل.';

  @override
  String get kidsManualCompleteAction => 'أتممت الحفظ بنفسي';

  @override
  String get kidsManualCompleteHint =>
      'لا يتوفر الصوت أو الميكروفون؟ يمكن لولي الأمر تأكيد إتمام الحفظ.';

  @override
  String kidsGamifiedListenFirst(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText مرة',
      few: '$countText مرات',
      two: 'مرتين',
      one: 'مرة واحدة',
    );
    return 'استمع للآية $_temp0 قبل تسجيل تلاوتك.';
  }

  @override
  String get kidsGamifiedAudioLoading => 'جاري تجهيز التلاوة...';

  @override
  String get kidsGamifiedWellDone => 'أحسنت!';

  @override
  String kidsGamifiedEarnedStars(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText نجمة',
      many: '$countText نجمة',
      few: '$countText نجمات',
      two: 'نجمتان',
      one: 'نجمة واحدة',
      zero: '$countText نجمة',
    );
    return '+$_temp0';
  }

  @override
  String kidsGamifiedEarnedGems(int count) {
    return '+$count جوهرة';
  }

  @override
  String get kidsGamifiedNextStage => 'التالي';

  @override
  String get kidsGamifiedReturnToMap => 'العودة للخريطة';

  @override
  String get kidsGamifiedJourneyComplete =>
      'أتممت رحلة الحفظ الحالية، بارك الله فيك!';

  @override
  String get kidsGamifiedFallbackMessage =>
      'سنعود للتجربة القديمة للحفاظ على تقدمك.';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get passwordResetEmailSent =>
      '✅ تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني';

  @override
  String get forgotPasswordEnterEmail =>
      'أدخل بريدك الإلكتروني أولاً لإعادة تعيين كلمة المرور';

  @override
  String get updatePasswordTitle => 'تعيين كلمة مرور جديدة';

  @override
  String get updatePasswordSubtitle => 'أدخل كلمة مرور قوية جديدة لحسابك.';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordUpdated =>
      'تم تحديث كلمة المرور بنجاح. سجل الدخول مرة أخرى.';

  @override
  String get updatePasswordButton => 'تحديث كلمة المرور';

  @override
  String get invalidPasswordRecoveryLink =>
      'رابط إعادة التعيين غير صالح أو انتهت صلاحيته. اطلب رسالة إعادة تعيين جديدة.';

  @override
  String get dailyPlanQuizAction => 'مراجعة بالتسميع';

  @override
  String get dailyPlanNewAyahs => 'آيات جديدة للحفظ';

  @override
  String get dailyPlanNearRevision => 'مراجعة قريبة (آخر ٥ أيام)';

  @override
  String get dailyPlanFarRevision => 'مراجعة بعيدة';

  @override
  String get dailyPlanRetentionReview => 'مراجعة تثبيت';

  @override
  String get dailyPlanRetentionReviewHint =>
      'مراجعة اختيارية لتثبيت الآيات التي حفظتها بالفعل.';

  @override
  String get dailyPlanCompletedTitle => 'ما شاء الله! أكملت خطة اليوم';

  @override
  String dailyPlanCompletedSubtitle(int count) {
    return 'أتممت $count عناصر بنجاح.\nثابر على هذا المستوى.';
  }

  @override
  String get dailyPlanNewAyahsShort => 'آيات جديدة';

  @override
  String get dailyPlanReviewShort => 'مراجعة';

  @override
  String get dailyPlanBlessingAction => 'بارك الله فيك ✨';

  @override
  String dailyPlanRatingExcellent(int ayahNumber) {
    return '✅ ممتاز! تم جدولة مراجعة الآية $ayahNumber بعد فترة أطول';
  }

  @override
  String get dailyPlanRatingAverage =>
      '⏰ متوسط، سيتم المراجعة خلال فترة معتدلة';

  @override
  String dailyPlanRatingWeak(int ayahNumber) {
    return '🔁 ضعيف، ستتم مراجعة الآية $ayahNumber غداً';
  }

  @override
  String get performanceWeak => 'ضعيف';

  @override
  String get performanceAverage => 'متوسط';

  @override
  String get performanceExcellent => 'ممتاز';

  @override
  String get dailyPlanListenBeforeRating => 'استمع للآية قبل التقييم';

  @override
  String get reviewQuizTitle => 'مراجعة بالتسميع';

  @override
  String get memorizationSessionTitle => 'جلسة الحفظ';

  @override
  String get memorizationHubReviewSectionTitle => 'المراجعة';

  @override
  String get memorizationHubReviewSectionSubtitle =>
      'سمّع ما حفظته من ذاكرتك، ويقيّم التطبيق تسميعك.';

  @override
  String get memorizationHubReviewCardDescription =>
      'سمّع الآيات المستحقة للمراجعة من حفظك.';

  @override
  String get memorizationHubDailyPlanSubtitle =>
      'وجهتك الأساسية للحفظ والمراجعة اليومية.';

  @override
  String get memorizationHubContinuePlanDescription =>
      'افتح ورد الحفظ والمراجعة الحالي.';

  @override
  String get memorizationHubViewPlanTitle => 'تفاصيل خطة اليوم';

  @override
  String get memorizationHubPracticeSectionTitle => 'التدريب';

  @override
  String get memorizationHubPracticeSectionSubtitle =>
      'اختر سورة أو تدرب بالتسميع الصوتي.';

  @override
  String get memorizationHubPracticeBySurahTitle => 'تدرّب بالسورة';

  @override
  String get memorizationHubPracticeBySurahDescription =>
      'تسميع صوتي واضح: اختر سورة وابدأ جلسة الحفظ.';

  @override
  String get listeningReviewTitle => 'اختبار الاستماع';

  @override
  String get listeningReviewHubDescription =>
      'اسمع آية من محفوظك: حدّد سورتها أو أكمل ما بعدها.';

  @override
  String get listeningReviewStartPrompt => 'اختر نوع الجولة';

  @override
  String get listeningReviewModeWhichSurah => 'من أي سورة؟';

  @override
  String get listeningReviewModeNextAyah => 'أكمل التالية';

  @override
  String get listeningReviewModeMixed => 'مختلط';

  @override
  String listeningReviewLastScore(int correct, int total) {
    return 'آخر جولة: $correct من $total';
  }

  @override
  String get listeningReviewNotEnoughTitle => 'احفظ بضع آيات أولًا';

  @override
  String get listeningReviewNotEnoughBody =>
      'يحتاج اختبار الاستماع إلى 5 آيات محفوظة على الأقل يمكن تشغيلها.';

  @override
  String get listeningReviewErrorBody => 'تعذّر تحضير الجولة. حاول مرة أخرى.';

  @override
  String get listeningReviewRetry => 'إعادة المحاولة';

  @override
  String listeningReviewQuestionProgress(int current, int total) {
    return 'السؤال $current من $total';
  }

  @override
  String listeningReviewReplay(int remaining) {
    return 'أعد الاستماع ($remaining)';
  }

  @override
  String get listeningReviewWhichSurahPrompt => 'من أي سورة هذه الآية؟';

  @override
  String listeningReviewNextAyahPrompt(String surah) {
    return 'سورة $surah: اتلُ الآية التالية';
  }

  @override
  String get listeningReviewRecord => 'ابدأ التسميع';

  @override
  String get listeningReviewStopRecord => 'إنهاء التسميع';

  @override
  String get listeningReviewCantRecord => 'لا أستطيع التسجيل';

  @override
  String get listeningReviewReveal => 'أظهر الآية';

  @override
  String get listeningReviewGradeMastered => 'أتقنت';

  @override
  String get listeningReviewGradeHesitant => 'ترددت';

  @override
  String get listeningReviewGradeForgot => 'نسيت';

  @override
  String get listeningReviewCorrect => 'إجابة صحيحة';

  @override
  String get listeningReviewWrong => 'ليست هذه';

  @override
  String get listeningReviewNext => 'التالي';

  @override
  String get listeningReviewResultTitle => 'انتهت الجولة';

  @override
  String listeningReviewResultScore(int correct, int total) {
    return '$correct من $total';
  }

  @override
  String get listeningReviewWeakLinksTitle => 'روابط تحتاج مراجعة';

  @override
  String get listeningReviewNoWeakLinks => 'لا توجد روابط ضعيفة في هذه الجولة';

  @override
  String listeningReviewAyahRef(String surah, int ayah) {
    return 'سورة $surah، الآية $ayah';
  }

  @override
  String get listeningReviewNewRound => 'جولة جديدة';

  @override
  String get listeningReviewAudioPlaying => 'جارٍ تشغيل الآية…';

  @override
  String listeningReviewBreakdownWhichSurah(int correct, int total) {
    return 'من أي سورة؟: $correct من $total';
  }

  @override
  String listeningReviewBreakdownNextAyah(int correct, int total) {
    return 'أكمل التالية: $correct من $total';
  }

  @override
  String get memorizationHubSettingsSectionSubtitle =>
      'اضبط خطة الحفظ بدون تغيير المسار.';

  @override
  String get memorizationHubPlanSettingsTitle => 'إعدادات الخطة';

  @override
  String get memorizationHubPlanSettingsDescription =>
      'عدّل الخطة اليومية أو إعدادات مسار الحفظ.';

  @override
  String get memorizationHubKidsMissionSectionSubtitle =>
      'ابدأ من المهمة النشطة للطفل.';

  @override
  String get memorizationHubKidsMissionCardDescription =>
      'ابدأ مهمة الحفظ التالية في رحلة الأطفال.';

  @override
  String get memorizationHubKidsJourneyTitle => 'الرحلة';

  @override
  String get memorizationHubKidsJourneySubtitle =>
      'شاهد مراحل الطفل الحالية والقادمة.';

  @override
  String get memorizationHubKidsJourneyDescription =>
      'شاهد المراحل الحالية والقادمة.';

  @override
  String get memorizationHubKidsRewardsTitle => 'المكافآت / التقدم';

  @override
  String get memorizationHubKidsRewardsSubtitle =>
      'راجع نجوم الطفل ونقاطه من شاشة التقدم.';

  @override
  String get memorizationHubKidsRewardsDescription =>
      'راجع النقاط والنجوم من شاشة التقدم.';

  @override
  String get memorizationHubHeaderSubtitle => 'مكان واحد لكل مسارات الحفظ';

  @override
  String get backAction => 'العودة';

  @override
  String get hifzKidsRedirectedFromAdult =>
      'هذا المسار مخصص للبالغين. سيتم توجيهك لمسار الأطفال.';

  @override
  String get parentDashboardLastSession => 'آخر جلسة';

  @override
  String get parentDashboardNoSessionsYet => 'لا توجد جلسات مسجلة بعد.';

  @override
  String parentDashboardSessionSummary(
    int surahId,
    int ayahNumber,
    int repeats,
    int points,
  ) {
    return 'سورة $surahId • آية $ayahNumber\n$repeats تكرارات • $points نقطة';
  }

  @override
  String get parentDashboardDone => 'تم';

  @override
  String get parentDashboardPinMismatch => 'رمزا PIN غير متطابقين';

  @override
  String get parentDashboardPinHelp =>
      'هذا الرمز يحمي لوحة ولي الأمر على هذا الجهاز';

  @override
  String get parentDashboardPinConfirm => 'تأكيد PIN';

  @override
  String get parentDashboardCreatePinTitle => 'أنشئ رمز ولي الأمر';

  @override
  String get parentDashboardSavePinButton => 'حفظ الرمز';

  @override
  String get parentDashboardEnterPinTitle => 'أدخل رمز ولي الأمر';

  @override
  String get parentDashboardEnterButton => 'دخول';

  @override
  String get parentDashboardEnterLinkingCode => 'إدخال رمز الربط';

  @override
  String get parentDashboardResetPin =>
      'اعادة ضبط على هذا الجهاز — سيطلب إنشاء رمز جديد';

  @override
  String get parentDashboardForgotPin => 'نسيت الرمز؟';

  @override
  String get parentDashboardForgotPinTitle => 'استعادة رمز ولي الأمر';

  @override
  String parentDashboardForgotPinBody(String email) {
    return 'للتأكد أنك ولي الأمر، أدخل كلمة مرور حسابك $email. بعدها تنشئ رمزاً جديداً، وتبقى المكافآت والإعدادات كما هي.';
  }

  @override
  String get parentDashboardForgotPinConfirm => 'تحقّق';

  @override
  String get parentDashboardAccountPasswordIncorrect =>
      'كلمة مرور الحساب غير صحيحة';

  @override
  String get parentDashboardAccountCheckUnavailable =>
      'تعذّر التحقق من الحساب الآن. تأكد من الاتصال بالإنترنت وحاول مرة أخرى.';

  @override
  String get parentDashboardChangePin => 'تغيير رمز ولي الأمر';

  @override
  String get parentDashboardChangePinConfirm =>
      'ستنشئ رمزاً جديداً الآن. تبقى المكافآت والإعدادات كما هي.';

  @override
  String get guardianErrorSignInRequired =>
      'سجّل الدخول بحسابك أولاً ثم أعد المحاولة.';

  @override
  String get guardianErrorCloudUnavailable =>
      'ربط الأطفال غير متاح في هذا الإصدار لأن المزامنة السحابية غير مفعّلة.';

  @override
  String get guardianErrorOnlyForChildren =>
      'ربط ولي الأمر متاح لحسابات الأطفال فقط.';

  @override
  String get guardianErrorAlreadyLinked => 'هذا الحساب مرتبط بولي أمر بالفعل.';

  @override
  String get guardianErrorParentModeAdultsOnly =>
      'وضع ولي الأمر متاح لمسار الكبار فقط.';

  @override
  String get guardianErrorLinkCodeInvalid =>
      'رمز الربط غير صحيح أو انتهت صلاحيته. اطلب من الطفل إنشاء رمز جديد ثم أعد المحاولة.';

  @override
  String get guardianErrorChildHasGuardian =>
      'هذا الطفل مرتبط بولي أمر آخر. يجب فك الربط الحالي أولاً.';

  @override
  String get guardianErrorSameAccount =>
      'لا يمكن ربط الطفل بنفس الحساب. يجب أن يستخدم الطفل حساباً مختلفاً عن حساب ولي الأمر.';

  @override
  String get parentRewardErrorTitleRequired => 'اكتب اسم المكافأة أولاً.';

  @override
  String get parentRewardErrorLimitReached => 'يمكن إضافة 3 مكافآت فقط.';

  @override
  String childErrorNicknameInvalid(int max) {
    return 'اكتب اسماً من حرف واحد إلى $max حرفاً.';
  }

  @override
  String childErrorAgeInvalid(int min, int max) {
    return 'اختر عمراً بين $min و$max سنة.';
  }

  @override
  String get guardianErrorChildNotLinked => 'هذا الطفل لم يعد مرتبطاً بحسابك.';

  @override
  String get childErrorIdentityUpdateUnavailable =>
      'تعديل بيانات الطفل غير متاح حالياً. حاول لاحقاً.';

  @override
  String childAgeYears(int age) {
    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$age سنة',
      few: '$age سنوات',
      two: 'سنتان',
      one: 'سنة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get childEditIdentity => 'تعديل اسم الطفل وعمره';

  @override
  String get childIdentitySaved =>
      'تم حفظ بيانات الطفل، وتظهر على جهازه بعد المزامنة التالية.';

  @override
  String get kidsLinkGuardianTileTitle => 'ربط ولي الأمر';

  @override
  String get kidsLinkGuardianTileSubtitle =>
      'يحتاج رمز ولي الأمر. بعد الربط يتابع ولي الأمر تقدّمك من جهازه.';

  @override
  String get parentDashboardTodaySummary => 'ملخص اليوم';

  @override
  String get parentDashboardTodayEmpty =>
      'اليوم: لا توجد جلسات بعد. شجعه على جلسة قصيرة.';

  @override
  String parentDashboardTodayCompleted(int count) {
    return 'اليوم: أكمل الطفل $count جلسة. شجعه على المراجعة القادمة.';
  }

  @override
  String get parentDashboardTodaySessions => 'جلسات اليوم';

  @override
  String get parentDashboardTodayPoints => 'نقاط اليوم';

  @override
  String get parentDashboardAddReward => 'إضافة مكافأة';

  @override
  String get parentDashboardShowLastSession => 'عرض آخر جلسة';

  @override
  String get parentDashboardChildSummary => 'ملخص الطفل';

  @override
  String get parentDashboardPoints => 'نقاط';

  @override
  String get parentDashboardStars => 'نجوم';

  @override
  String get parentDashboardWeekSessions => 'جلسات الأسبوع';

  @override
  String get parentDashboardChildReminder => 'تذكير الطفل';

  @override
  String get parentDashboardDailyReminder => 'تذكير يومي الساعة 6:30 مساءً';

  @override
  String get parentDashboardReminderSubtitle =>
      'يمكن تغيير الوقت لاحقًا من إعدادات ولي الأمر';

  @override
  String get parentDashboardRemoteFollowup => 'المتابعة عن بعد';

  @override
  String get parentDashboardScanQr => 'مسح QR';

  @override
  String get parentDashboardManualEntry => 'إدخال يدوي';

  @override
  String get parentDashboardNoRemoteChild =>
      'لا يوجد طفل مرتبط عن بعد حتى الآن.';

  @override
  String parentDashboardRemoteChildSummary(int ayahs, int points) {
    return '$ayahs آية • $points نقطة';
  }

  @override
  String parentDashboardMemorizedSummary(
    int memorized,
    int total,
    int percent,
  ) {
    return '$memorized/$total آية محفوظة • $percent%';
  }

  @override
  String parentDashboardReviewsSummary(int completed, int overdue) {
    return '$completed مراجعة مكتملة • $overdue متأخرة';
  }

  @override
  String parentDashboardStreakSummary(int days) {
    return 'التتابع: $days يوم';
  }

  @override
  String parentDashboardCertificatesSummary(int count) {
    return '$count شهادة تم الحصول عليها';
  }

  @override
  String get parentDashboardRemoveChild => 'إزالة الطفل';

  @override
  String get parentDashboardRemoveChildConfirmTitle => 'إزالة الطفل؟';

  @override
  String parentDashboardRemoveChildConfirmBody(String name) {
    return 'سيؤدي هذا إلى فصل $name عن حسابك. يمكنك الربط مرة أخرى لاحقًا برمز جديد.';
  }

  @override
  String get parentDashboardReminders => 'التذكيرات';

  @override
  String get parentDashboardNotSet => 'غير محدد';

  @override
  String get parentDashboardEditChild => 'تعديل بيانات الطفل';

  @override
  String get parentDashboardChildLinked => 'تم ربط الطفل بنجاح';

  @override
  String get parentDashboardRewardAdded => 'تمت إضافة المكافأة';

  @override
  String get parentDashboardRemoteRewardAdded => 'تم إرسال المكافأة للطفل';

  @override
  String get parentDashboardReminderSaved => 'تم تحديث التذكير';

  @override
  String get parentDashboardChildRemoved => 'تمت إزالة الطفل';

  @override
  String get parentDashboardRewardsTitle => 'مكافآت ولي الأمر';

  @override
  String get parentDashboardRewardHint => 'مثال: وقت لعب إضافي';

  @override
  String get parentDashboardRewardEmpty =>
      'أضف مكافآت تظهر للطفل عند تحقيق هدفه الأسبوعي.';

  @override
  String get parentDashboardRewardLocked => 'مقفلة';

  @override
  String get parentDashboardRewardUnlocked => 'مفتوحة';

  @override
  String get parentDashboardRewardClaimed => 'تم استلامها';

  @override
  String get parentDashboardRecentSessions => 'آخر الجلسات';

  @override
  String get parentDashboardNoKidsSessions => 'لا توجد جلسات أطفال بعد.';

  @override
  String parentDashboardLogTitle(int surahId, int ayahNumber) {
    return 'سورة $surahId • آية $ayahNumber';
  }

  @override
  String parentDashboardLogSubtitle(int repeats, int points) {
    return '$repeats تكرارات • $points نقطة';
  }

  @override
  String get dailyPlanSettingsTooltip => 'إعدادات مسار الحفظ الذكي';

  @override
  String get dailyPlanRefreshTooltip => 'تحديث الخطة';

  @override
  String get dailyPlanHeaderTitle => 'خطتك اليومية';

  @override
  String dailyPlanHeaderSummary(
    int total,
    String totalText,
    String completedText,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalText عنصر',
      many: '$totalText عنصرًا',
      few: '$totalText عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: '$totalText عنصر',
    );
    return '$_temp0 • $completedText مكتمل';
  }

  @override
  String dailyPlanProgressCount(String completed, String total) {
    return '$completed من $total';
  }

  @override
  String get dailyPlanAllDoneShort => '✅ أحسنت! أكملت خطتك اليوم';

  @override
  String dailyPlanRemainingItems(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تبقّى $countText عنصر',
      many: 'تبقّى $countText عنصرًا',
      few: 'تبقّى $countText عناصر',
      two: 'تبقّى عنصران',
      one: 'تبقّى عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String dailyPlanAyahTitle(int ayahNumber) {
    return 'آية $ayahNumber';
  }

  @override
  String dailyPlanSurahAyahTitle(String surah, String ayahNumber) {
    return '$surah، آية $ayahNumber';
  }

  @override
  String dailyPlanRecordStats(int strength, int reviews) {
    return 'قوة: $strength • مراجعات: $reviews';
  }

  @override
  String get dailyPlanNewLabel => 'جديدة';

  @override
  String get dailyPlanEmptyTitle => 'أحسنت! لا توجد مراجعات مطلوبة اليوم';

  @override
  String get dailyPlanEmptySubtitle => 'تفقّد غداً لمتابعة جدولك';

  @override
  String get dailyPlanNoPlanTitle => 'لم تنشئ خطة حفظ بعد';

  @override
  String get dailyPlanNoPlanSubtitle =>
      'أنشئ خطتك لتظهر لك هنا آيات الحفظ والمراجعة كل يوم.';

  @override
  String get dailyPlanCreatePlanAction => 'أنشئ خطتك';

  @override
  String get customPlanDeleteConfirmPhrase => 'حذف الخطة';

  @override
  String get customPlanDeleteTitle => 'تأكيد حذف الخطة';

  @override
  String get customPlanDeleteKeeps => 'سيبقى: الإنجازات، السجل، الشهادات';

  @override
  String get customPlanDeleteRemoves => 'سيُحذف: الخطة الحالية فقط';

  @override
  String get customPlanDeleteInstruction =>
      'اكتب \"حذف الخطة\" لتأكيد العملية.';

  @override
  String get customPlanDeleteAction => 'تأكيد حذف الخطة';

  @override
  String get customPlanSaved => 'تم حفظ الخطة بنجاح ✅';

  @override
  String get customPlanTitle => 'خطتك المخصصة';

  @override
  String get customPlanSubtitle => 'صمّم نظام حفظ يناسبك';

  @override
  String get customPlanName => 'اسم الخطة';

  @override
  String get customPlanNameHint => 'مثال: خطتي لحفظ جزء عمّ';

  @override
  String get customPlanNameRequired => 'يرجى إدخال اسم للخطة';

  @override
  String get customPlanTargetUserTitle => 'الخطة لمن؟';

  @override
  String get customPlanChildFeaturesNote =>
      'سيتم تفعيل ميزات ولي الأمر والمتابعة تلقائياً.';

  @override
  String get customPlanSurahRange => 'نطاق السور';

  @override
  String get customPlanDailyLoad => 'الحِمل اليومي';

  @override
  String get customPlanNewAyahsPerDay => 'آيات جديدة يومياً';

  @override
  String get customPlanAyahUnit => 'آية';

  @override
  String get customPlanSchedule => 'الجدول الزمني';

  @override
  String get customPlanDaysPerWeek => 'أيام الحفظ في الأسبوع';

  @override
  String get customPlanDayUnit => 'يوم';

  @override
  String get customPlanSessionDuration => 'مدة الجلسة';

  @override
  String get customPlanMinuteUnit => 'دقيقة';

  @override
  String get customPlanDifficulty => 'مستوى الصعوبة';

  @override
  String get customPlanAdvanced => 'تخصيص متقدم';

  @override
  String get customPlanAdvancedSubtitle => 'إعدادات المراجعة القريبة والبعيدة';

  @override
  String get customPlanSaveAndStart => 'حفظ وبدء الخطة';

  @override
  String get customPlanDeleteCurrent => 'حذف الخطة الحالية';

  @override
  String get customPlanFromSurah => 'من سورة';

  @override
  String get customPlanToSurah => 'إلى سورة';

  @override
  String get customPlanFromAyah => 'من آية رقم';

  @override
  String get customPlanInvalidAyah => 'أدخل رقم آية صحيح';

  @override
  String customPlanSurahAyahLimit(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText آية',
      many: '$countText آية',
      few: '$countText آيات',
      two: 'آيتان',
      one: 'آية واحدة',
      zero: '$countText آية',
    );
    return 'هذه السورة فيها $_temp0';
  }

  @override
  String get customPlanAdult => 'كبير';

  @override
  String get customPlanChild => 'طفل';

  @override
  String get customPlanDifficultyEasy => 'سهل';

  @override
  String get customPlanDifficultyModerate => 'متوسط';

  @override
  String get customPlanDifficultyChallenging => 'صعب';

  @override
  String get customPlanNearRevision => 'المراجعة القريبة';

  @override
  String get customPlanNearRevisionSubtitle => 'مراجعة آيات آخر 5 أيام';

  @override
  String get customPlanNearRevisionCount => 'عدد آيات المراجعة القريبة';

  @override
  String get customPlanFarRevision => 'المراجعة البعيدة';

  @override
  String get customPlanFarRevisionSubtitle => 'تكرار ذكي للآيات القديمة';

  @override
  String get customPlanFarRevisionCount => 'عدد آيات المراجعة البعيدة';

  @override
  String get customPlanEstimatedDuration => 'المدة المقدّرة للإنهاء';

  @override
  String customPlanApproxWeeks(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText أسبوع',
      many: '$countText أسبوعًا',
      few: '$countText أسابيع',
      two: 'أسبوعان',
      one: 'أسبوع واحد',
      zero: '$countText أسبوع',
    );
    return '$_temp0 تقريبًا';
  }

  @override
  String customPlanApproxMonths(int count) {
    return '$count شهر تقريباً';
  }

  @override
  String customPlanApproxYears(String count) {
    return '$count سنة تقريباً';
  }

  @override
  String customPlanEstimatedScope(
    int surahs,
    String surahsText,
    int ayahs,
    String ayahsText,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      surahs,
      locale: localeName,
      other: '$surahsText سورة',
      many: '$surahsText سورة',
      few: '$surahsText سور',
      two: 'سورتان',
      one: 'سورة واحدة',
      zero: '$surahsText سورة',
    );
    String _temp1 = intl.Intl.pluralLogic(
      ayahs,
      locale: localeName,
      other: '$ayahsText آية',
      many: '$ayahsText آية',
      few: '$ayahsText آيات',
      two: 'آيتان',
      one: 'آية واحدة',
      zero: '$ayahsText آية',
    );
    return '$_temp0 • ~$_temp1';
  }

  @override
  String get customPlanQuickPresetTitle => 'اختر قالباً سريعاً';

  @override
  String get customPlanPresetLight => 'خفيف';

  @override
  String get customPlanPresetLightDesc => '٣ آيات/يوم • ٥ أيام • ٢٠ دقيقة';

  @override
  String get customPlanPresetLightName => 'خطة خفيفة';

  @override
  String get customPlanPresetBalanced => 'متوازن';

  @override
  String get customPlanPresetBalancedDesc => '٥ آيات/يوم • ٦ أيام • ٣٠ دقيقة';

  @override
  String get customPlanPresetBalancedName => 'خطة متوازنة';

  @override
  String get customPlanPresetIntensive => 'مكثف';

  @override
  String get customPlanPresetIntensiveDesc =>
      '١٠ آيات/يوم • كل الأسبوع • ٥٠ دقيقة';

  @override
  String get customPlanPresetIntensiveName => 'خطة مكثفة';

  @override
  String get customPlanPresetJuzAmma => 'جزء عم';

  @override
  String get customPlanPresetJuzAmmaDesc =>
      'من الناس إلى النبأ • ٣ آيات/يوم • ٢٠ دقيقة';

  @override
  String customPlanMinutesLimitHint(String minutes, String count) {
    return 'في $minutes دقيقة يتسع وقت الجلسة لنحو $count آيات جديدة فقط. زد مدة الجلسة لتحقيق هدفك اليومي.';
  }

  @override
  String get customPlanPresetJuzAmmaName => 'خطة جزء عم';

  @override
  String get customPlanSummaryTitle => 'ملخص الخطة';

  @override
  String customPlanSummaryRange(Object startSurah, Object endSurah) {
    return 'النطاق: $startSurah ← $endSurah';
  }

  @override
  String customPlanSummaryLoad(
    int ayahsPerDay,
    String ayahsText,
    int daysPerWeek,
    String daysText,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      ayahsPerDay,
      locale: localeName,
      other: '$ayahsText آية',
      many: '$ayahsText آية',
      few: '$ayahsText آيات',
      two: 'آيتان',
      one: 'آية واحدة',
      zero: '$ayahsText آية',
    );
    String _temp1 = intl.Intl.pluralLogic(
      daysPerWeek,
      locale: localeName,
      other: '$daysText يوم',
      many: '$daysText يومًا',
      few: '$daysText أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '$daysText يوم',
    );
    return '$_temp0 يوميًا • $_temp1 أسبوعيًا';
  }

  @override
  String customPlanSummarySession(
    int minutes,
    String minutesText,
    String difficulty,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutesText دقيقة',
      many: '$minutesText دقيقة',
      few: '$minutesText دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '$minutesText دقيقة',
    );
    return '$_temp0 للجلسة • مستوى $difficulty';
  }

  @override
  String get memorizationPathSelectionFailedTitle => 'تعذر حفظ اختيارك';

  @override
  String get memorizationPathConfirmTitle => 'ماذا سيحدث بعد ذلك؟';

  @override
  String get memorizationPathCanChangeLater =>
      'يمكن تغييره من الإعدادات لاحقاً بدون فقدان تقدمك.';

  @override
  String get parentDashboardLinkAction => 'ربط';

  @override
  String get parentDashboardRemoteRewardTitle => 'مكافأة للطفل';

  @override
  String get parentDashboardScanChildCodeTitle => 'مسح رمز الطفل';

  @override
  String get homeParentToolsTitle => 'أدوات ولي الأمر';

  @override
  String get homeParentToolsSubtitle => 'تابع تقدم طفلك ومكافآته';

  @override
  String get homeParentToolsAction => 'فتح لوحة ولي الأمر';

  @override
  String get guestUpgradeTitle => 'إدارة الحساب';

  @override
  String get guestUpgradeMessage => 'أنشئ حساباً لإدارة الحساب وميزات العائلة.';

  @override
  String get guestUpgradeLocalProgress => 'يبقى تقدمك المحلي على هذا الجهاز.';

  @override
  String get parentDashboardGuestSubtitle =>
      'سجّل دخولك لإدارة حسابك والوصول إلى أدوات ولي الأمر. يبقى تقدمك المحلي على هذا الجهاز.';

  @override
  String get kidsQuranTitle => 'قرآن الأطفال';

  @override
  String get kidsQuranSubtitle => 'اقرأ بهدوء وتنقل بين الصفحات على مهلك.';

  @override
  String get kidsQuranBackToHome => 'العودة لصفحة الأطفال';

  @override
  String kidsQuranPageLabel(int pageNumber) {
    return 'صفحة $pageNumber';
  }

  @override
  String get kidsQuranLongPressHint => 'اضغط مطولاً على أي آية لتسمعها';

  @override
  String get kidsQuranListenPage => 'استمع للصفحة';

  @override
  String get kidsQuranPausePage => 'إيقاف';

  @override
  String get parentDashboardPinInvalid => 'أدخل رمزًا من 4 أرقام';

  @override
  String get parentDashboardPinIncorrect => 'رمز غير صحيح';

  @override
  String get parentDashboardLinking => 'جارٍ التحقق من رمز الربط…';

  @override
  String get parentDashboardUnlinking => 'جارٍ إزالة ربط ولي الأمر…';

  @override
  String get guardianLinkingSlowHint =>
      'تستغرق العملية وقتًا أطول من المعتاد. يمكنك المتابعة والربط لاحقًا.';

  @override
  String get bookmarkSaveError => 'حدث خطأ أثناء حفظ العلامة المرجعية';

  @override
  String get longPressToUndo => 'اضغط مطولاً للتراجع';

  @override
  String get hifzReviewPassedTitle => 'تم اجتياز المراجعة';

  @override
  String get hifzReviewTimeTitle => 'حان وقت المراجعة';

  @override
  String get hifzReviewFullSurahHint => 'راجع السورة كاملة قبل إنهائها';

  @override
  String hifzReviewRangeHint(int startAyah, int endAyah) {
    return 'راجع الآيات من $startAyah إلى $endAyah قبل الانتقال للآية التالية';
  }

  @override
  String get hifzEvaluatingReview => 'جارِ تقييم المراجعة...';

  @override
  String get hifzLeaveSessionMessage =>
      'هل تريد الخروج من جلسة الحفظ؟ سيتم حفظ تقدمك الحالي.';

  @override
  String get memorizationExitSessionMessage =>
      'هل تريد إكمال هذه الجلسة لاحقًا من حيث توقفت، أم التخلّي عنها؟ ستُضاف الآيات التي أخفقت فيها ولم تجتزها إلى المراجعة عند التخلّي.';

  @override
  String get memorizationExitSessionTitle => 'الخروج من الجلسة؟';

  @override
  String get memorizationSaveAndLeave => 'أكمل لاحقًا';

  @override
  String get memorizationDiscardSession => 'التخلّي عن الجلسة';

  @override
  String hifzAyahNumberLabel(int ayahNumber) {
    return 'آية $ayahNumber';
  }

  @override
  String get hifzEvaluatingAyah => 'جارِ التقييم...';

  @override
  String get hifzRecordingAyahHint => 'يتم التسجيل، اقرأ الآية من حفظك...';

  @override
  String get hifzExcellentMemorization => 'ممتاز! حفظ متقن.';

  @override
  String get hifzNeedsAyahReview => 'تحتاج إلى مراجعة هذه الآية.';

  @override
  String get hifzNoVoiceRecognized => '(لم يتم التعرف على صوت)';

  @override
  String get hifzRecordingReviewHint => 'يتم التسجيل، اقرأ المقطع من حفظك...';

  @override
  String get hifzFinishRecitation => 'إنهاء التسميع';

  @override
  String get hifzFinishSession => 'إنهاء الجلسة';

  @override
  String get hifzNextAyah => 'الآية التالية';

  @override
  String get hifzReviewNotPassed => 'لم يتم اجتياز المراجعة. حاول مرة أخرى.';

  @override
  String get hifzStartRecitation => 'ابدأ التسميع';

  @override
  String get hifzAudioPlaybackFailed =>
      'فشل تشغيل الصوت. تحقق من الاتصال بالइंटترنت.';

  @override
  String get hifzReviewSaveFailed => 'فشل حفظ تقدم المراجعة. حاول مرة أخرى.';

  @override
  String get hifzMemorizationSaveFailed => 'فشل حفظ تقدم الحفظ. حاول مرة أخرى.';

  @override
  String hifzSurahLockedMessage(String surahName) {
    return 'هذه السورة مقفلة حالياً. أكمل حفظ سورة $surahName أولاً لفتحها.';
  }

  @override
  String get kidsAudioPlaybackFailed =>
      'لم يعمل الصوت الآن. جرّب مرة أخرى أو اطلب من ولي الأمر الاتصال بالإنترنت.';

  @override
  String get smartCoachMemorizedReviewDueTitle => 'مراجعة تثبيت مستحقة';

  @override
  String smartCoachMemorizedReviewDueSubtitle(String surahName) {
    return 'راجع الآيات المحفوظة من سورة $surahName لتثبيت حفظك.';
  }

  @override
  String get homeContinueTodaysPlan => 'أكمل خطة اليوم';

  @override
  String get homeCurrentMission => 'المهمة الحالية';

  @override
  String get homeStartKidsMission => 'ابدأ مهمة الطفل الحالية.';

  @override
  String get homeChooseKidsPath => 'اختر مسار الطفل أو تابع المهمة الحالية.';

  @override
  String homeDailyWirdPage(Object page) {
    return 'قراءة الصفحة $page من القرآن الكريم';
  }

  @override
  String homeDailyWirdSurah(Object surah) {
    return 'قراءة سورة $surah من القرآن الكريم';
  }

  @override
  String get homeDailyWird => 'الورد اليومي';

  @override
  String homeDailyWirdSurahPage(Object page, Object surah) {
    return 'سورة $surah — صفحة $page';
  }

  @override
  String get homeTodaysPlan => 'خطة اليوم';

  @override
  String get homeKidsProgress => 'تقدم الطفل';

  @override
  String get homeYourProgress => 'تقدمك';

  @override
  String get homeActionQuran => 'القرآن';

  @override
  String get homeActionReadToday => 'اقرأ وردك';

  @override
  String get homeActionTodaysPlan => 'خطة اليوم';

  @override
  String get homeActionContinuePlan => 'تابع حفظك';

  @override
  String get homeActionProgress => 'التقدم';

  @override
  String get homeActionReviewGains => 'راجع إنجازك';

  @override
  String get homeActionSettings => 'الإعدادات';

  @override
  String get homeActionTuneApp => 'خصص تجربتك';

  @override
  String get homeGoToSettings => 'انتقل إلى الإعدادات';

  @override
  String get notificationDailyReviewTitle => 'جاهز نراجع سوا؟ 📖';

  @override
  String notificationDailyReviewBodyCount(Object count) {
    return 'عندك $count آية مستنية مراجعتك النهاردة.. يلا خطوة بخطوة! ✨';
  }

  @override
  String get notificationDailyReviewBody =>
      'يلا بينا نرجع للمصحف ونثبت حفظ اليوم 🌸';

  @override
  String get notificationStreakMercyTitle => 'الله رحيم — سلسلتك مستنياك 🌿';

  @override
  String get notificationStreakMercyBody =>
      'فاتك يوم، وسلسلتك رجعت من جديد… كمّل وردك النهاردة 🤍';

  @override
  String notificationStreakAlertTitle(Object count) {
    return '⚠️ متضيعش إنجاز $count يوم!';
  }

  @override
  String notificationStreakGentleTitle(Object count) {
    return 'سلسلتك من $count يوم مستنياك';
  }

  @override
  String get notificationStreakGentleBody =>
      'دقايق مراجعة النهاردة تحافظ على سلسلتك.. وقت ما تحب 🌿';

  @override
  String get notificationSmartReminderTitle => 'وقت قراءتك المعتاد';

  @override
  String get notificationSmartReminderBody =>
      'الوقت ده عادةً بتقرا فيه.. في آيات مستنياك.';

  @override
  String get notificationChannelStreakGentleName => 'تذكير لطيف بالسلسلة';

  @override
  String get notificationChannelStreakGentleDescription =>
      'تذكير هادئ قبل تنبيه حماية السلسلة';

  @override
  String get notificationChannelSmartName => 'تذكير ذكي';

  @override
  String get notificationChannelSmartDescription =>
      'تذكيرات في وقت قراءتك المعتاد';

  @override
  String get notificationStreakAlertBody =>
      'فاضل تكة صغيرة وتكمل وردك النهاردة.. متكسلش، تقدر تعملها! 🔥';

  @override
  String get notificationActionReviewStart => '⚡ ابدأ المراجعة';

  @override
  String get notificationActionDailyWird => '📖 الورد اليومي';

  @override
  String get notificationActionStreakProtect => '🔥 احمي السلسلة الآن';

  @override
  String get notificationActionReadWird => '📖 قراءة الورد';

  @override
  String get notificationActionReadDailyAyah => '✨ قراءة آية اليوم';

  @override
  String get notificationActionShareAyah => '↗️ مشاركة الآية';

  @override
  String get notificationActionMorningAzkar => '☀️ قراءة أذكار الصباح';

  @override
  String get notificationActionEveningAzkar => '🌙 قراءة أذكار المساء';

  @override
  String get notificationActionDailyDua => '🤲 قراءة أدعية اليوم';

  @override
  String get notificationActionAzkar => '✨ الأذكار';

  @override
  String get notificationActionKidsReview => '🌟 ابدأ التسميع يا بطل';

  @override
  String get notificationActionReadKahf => '📖 قراءة سورة الكهف';

  @override
  String get notificationActionOpenMushaf => '✨ المصحف';

  @override
  String get notificationActionTahajjudDua => '🤲 أدعية قيام الليل';

  @override
  String get notificationActionFollowKhatmah => '📖 متابعة الختمة';

  @override
  String get notificationActionReadQuran => '📖 قراءة القرآن';

  @override
  String get notificationActionPostPrayerAzkar => '📿 أذكار بعد الصلاة';

  @override
  String get notificationChannelRemindersName => 'تذكيرات تالية';

  @override
  String get notificationChannelRemindersDescription =>
      'تذكيرات يومية للمراجعة والحفظ';

  @override
  String get notificationChannelStreakName => 'حماية السلسلة';

  @override
  String get notificationChannelStreakDescription =>
      'تنبيهات للحفاظ على سلسلة أيام الحفظ';

  @override
  String get notificationChannelDailyAyahName => 'آية اليوم';

  @override
  String get notificationChannelDailyAyahDescription =>
      'آية يومية من القرآن الكريم مع التدبر';

  @override
  String get notificationChannelMorningAzkarName => 'أذكار الصباح';

  @override
  String get notificationChannelMorningAzkarDescription =>
      'تذكيرات أذكار الصباح';

  @override
  String get notificationChannelEveningAzkarName => 'أذكار المساء';

  @override
  String get notificationChannelEveningAzkarDescription =>
      'تذكيرات أذكار المساء';

  @override
  String get notificationChannelDailyDuaName => 'دعاء اليوم';

  @override
  String get notificationChannelDailyDuaDescription =>
      'تذكيرات دعاء اليوم والابتهالات';

  @override
  String get notificationChannelKidsName => 'تسميع الأطفال';

  @override
  String get notificationChannelKidsDescription =>
      'تذكيرات مراجعة وتسميع الأطفال';

  @override
  String get notificationChannelKahfName => 'سورة الكهف';

  @override
  String get notificationChannelKahfDescription =>
      'تذكيرات قراءة سورة الكهف يوم الجمعة';

  @override
  String get notificationChannelTahajjudName => 'قيام الليل والوتر';

  @override
  String get notificationChannelTahajjudDescription =>
      'تذكيرات قيام الليل في الثلث الأخير';

  @override
  String get notificationChannelKhatmahName => 'ورد الختمة';

  @override
  String get notificationChannelKhatmahDescription =>
      'تذكيرات متابعة ورد الختمة';

  @override
  String get notificationChannelMilestonesName => 'احتفالات الإنجاز';

  @override
  String get notificationChannelMilestonesDesc =>
      'احتفال عند إتمام حفظ جزء أو سورة أو ختمة كاملة';

  @override
  String notificationMilestoneJuzTitle(int juz) {
    return '🎉 أتممت حفظ الجزء $juz!';
  }

  @override
  String notificationMilestoneJuzBody(int juz) {
    return 'ما شاء الله، تبارك الله! أكملت حفظ الجزء $juz كاملاً. بارك الله فيك وثبّته في قلبك.';
  }

  @override
  String notificationMilestoneSurahTitle(String surah) {
    return '🎉 أتممت حفظ سورة $surah!';
  }

  @override
  String notificationMilestoneSurahBody(String surah) {
    return 'ما شاء الله! أكملت حفظ سورة $surah كاملة. تقبّل الله منك وجعلها نوراً لك.';
  }

  @override
  String get notificationMilestoneKhatmahTitle =>
      '🎉 أتممت ختمة القرآن الكريم!';

  @override
  String get notificationMilestoneKhatmahBody =>
      'الحمد لله! أتممت ختمة كاملة من القرآن الكريم. تقبّل الله منك وجازاك بأفضل الجزاء.';

  @override
  String get notificationMilestoneStreakTitle => '🔥 ٣٠ يوماً متتالياً!';

  @override
  String get notificationMilestoneStreakBody =>
      'ثلاثون يوماً من المواظبة على المراجعة، ما شاء الله! أكمل سلسلة نورك.';

  @override
  String get notificationChannelPrayerName => 'مواقيت الصلاة والأذان';

  @override
  String get notificationChannelPrayerDescription =>
      'تنبيهات عند دخول وقت الصلاة';

  @override
  String get notificationChannelPrayerAthanName => 'صوت أذان الصلاة';

  @override
  String get notificationChannelPrayerAthanDescription =>
      'تنبيهات الصلوات بمقطع الأذان المرفق';

  @override
  String get notificationChannelPrayerCompanionName => 'مرافق الصلاة';

  @override
  String get notificationChannelPrayerCompanionDescription =>
      'تنبيهات مرافق الصلاة اللطيفة للتأكيد الذاتي';

  @override
  String get notificationActionCompanionConfirm => 'نعم، صليتها';

  @override
  String get notificationActionCompanionPrayNow => 'سأصلي الآن';

  @override
  String get notificationActionCompanionRemindLater => 'ذكرني لاحقاً';

  @override
  String get notificationCompanionPreparationTitle => 'استعداد للصلاة';

  @override
  String notificationCompanionPreparationBody(Object prayer) {
    return 'اقترب وقت صلاة $prayer';
  }

  @override
  String get notificationCompanionCheckInTitle => 'مرافق الصلاة';

  @override
  String notificationCompanionCheckInBody(Object prayer) {
    return 'هل صليت $prayer؟';
  }

  @override
  String get notificationCompanionFollowUpTitle => 'مرافق الصلاة';

  @override
  String notificationCompanionFollowUpBody(Object prayer) {
    return 'تذكير لطيف: هل صليت $prayer؟';
  }

  @override
  String get notificationDailyAyahTitle => 'آية تفتح لك يومك ✨';

  @override
  String get notificationDailyAyahBody =>
      'خدلك دقيقة روق بالك مع وردك النهاردة من القرآن الكريم 🌿';

  @override
  String get notificationMorningAzkarTitle => 'صبحك الله بالخير ☀️';

  @override
  String get notificationMorningAzkarBody =>
      'يلا ابدأ يومك بذكر الله وطمئن قلبك.. أذكار الصباح في انتظارك';

  @override
  String get notificationEveningAzkarTitle => 'مساء الخير والسكينة 🌙';

  @override
  String get notificationEveningAzkarBody =>
      'يومك كان زحمة؟ خذ لحظة هدوء مع أذكار المساء واختم يومك بحفظ الله';

  @override
  String get notificationKidsReviewTitle => 'يلا يا بطل جاهز؟ 🌟';

  @override
  String get notificationKidsReviewBody =>
      'مرحلتك الجديدة مستنياك.. يلا نكمل ونجمع نجوم جديدة! 🚀';

  @override
  String get notificationDailyDuaTitle => 'دعوة من القلب 🤲';

  @override
  String get notificationFridayKahfTitle => 'نور ما بين الجمعتين 🌿';

  @override
  String get notificationWeeklyImpactTitle => 'أثرك هذا الأسبوع 🌿';

  @override
  String notificationWeeklyImpactBody(int count) {
    return '$count أيام من أسبوعك كانت مع القرآن — وكل صفحة فيها أثر باقٍ';
  }

  @override
  String get notificationWeeklyImpactQuietBody =>
      'أسبوع جديد يبدأ — وصفحة واحدة بتفرق 🌱';

  @override
  String get notificationSettingsWeeklyImpact => 'أثر الأسبوع (الجمعة)';

  @override
  String get notificationFridayKahfBody =>
      'جمعة مباركة! لا تنسَ قراءة سورة الكهف اليوم لتضيء لك ما بين الجمعتين ✨';

  @override
  String get notificationTahajjudTitle => 'قيام الليل والدعاء المستجاب 🌙';

  @override
  String get notificationTahajjudBody =>
      'ركعتان في جوف الليل وسؤال لله تعالى في ساعة الاستجابة.. تقبل الله طاعتك 🤲';

  @override
  String get notificationKhatmahTitle => 'ورد الختمة اليومي 📖';

  @override
  String get notificationKhatmahBody =>
      'واصل مسيرتك المباركة مع الختمة.. وردك اليوم بانتظارك 🌿';

  @override
  String notificationKhatmahBodyWithTarget(Object start, Object end) {
    return 'وردك اليوم: من صفحة $start إلى $end.. اقتربت من إتمام الختمة! ✨';
  }

  @override
  String notificationPrayerTitle(Object prayer) {
    return 'حان الآن موعد صلاة $prayer 🕌';
  }

  @override
  String get notificationPrayerBody =>
      'حي على الصلاة، حي على الفلاح.. بارك الله في صلاتك';

  @override
  String get notificationSettingsFridayKahf => 'سورة الكهف (الجمعة)';

  @override
  String get notificationSettingsFridayKahfSub =>
      'تذكير أسبوعي بقراءة سورة الكهف يوم الجمعة';

  @override
  String get notificationSettingsTahajjud => 'قيام الليل والوتر';

  @override
  String get notificationSettingsTahajjudSub =>
      'تذكير يومي في الثلث الأخير من الليل';

  @override
  String get notificationSettingsKhatmah => 'متابعة الختمة';

  @override
  String get notificationSettingsKhatmahSub =>
      'تذكير يومي بالورد المحدد لختمتك الحالية';

  @override
  String get notificationSettingsPrayerTimes => 'مواقيت الصلاة';

  @override
  String get notificationSettingsPrayerTimesSub =>
      'تنبيهات عند حلول أوقات الصلوات الخمس';

  @override
  String get notificationSettingsPrayerAthan => 'الأذان الكامل';

  @override
  String get notificationSettingsPrayerAthanSub =>
      'تشغيل الأذان الكامل عند دخول وقت الصلاة مع إمكانية إيقافه';

  @override
  String get muezzinPickerTitle => 'اختيار المؤذن';

  @override
  String get muezzinPickerSubtitle =>
      'اختر صوت الأذان المفضل لديك، واستمع لمعاينة قبل الحفظ';

  @override
  String get muezzinDefault => 'الأذان الافتراضي';

  @override
  String get muezzinPickerSave => 'حفظ';

  @override
  String get muezzinPreviewPlay => 'معاينة';

  @override
  String get muezzinPreviewStop => 'إيقاف المعاينة';

  @override
  String get muezzinFajrSectionTitle => 'أذان الفجر';

  @override
  String get muezzinFajrSameAsGeneral => 'مثل باقي الصلوات';

  @override
  String get muezzinFajrBadge => 'فجر';

  @override
  String muezzinFajrSummary(String general, String fajr) {
    return '$general للصلوات، و$fajr للفجر';
  }

  @override
  String get notificationSettingsPrayerNeedsTimes =>
      'أكمل إعداد مواقيت الصلاة واختر مدينتك أولًا';

  @override
  String get homeTourTitle => 'تحتاج جولة سريعة؟';

  @override
  String get homeTourDesc => 'افتح الدليل متى أردت من هنا أو من المساعدة.';

  @override
  String get homeTourGuideAction => 'الدليل';

  @override
  String get journeyReviewBeforeNewTitle => 'راجع قبل الحفظ الجديد';

  @override
  String journeyReviewBeforeNewDesc(Object surahAyahLabel) {
    return 'مراجعة قريبة مستحقة في $surahAyahLabel.';
  }

  @override
  String get journeyLongTermReviewTitle => 'مراجعة بعيدة مستحقة';

  @override
  String journeyLongTermReviewDesc(Object surahAyahLabel) {
    return 'حان وقت مراجعة $surahAyahLabel.';
  }

  @override
  String get journeyReviewDifficultAyahTitle => 'راجع الآية الصعبة';

  @override
  String journeyReviewDifficultAyahDesc(Object surahAyahLabel) {
    return 'آخر مراجعة كانت صعبة في $surahAyahLabel.';
  }

  @override
  String get journeyContinueDailyPlanTitle => 'أكمل خطة اليوم';

  @override
  String journeyContinueDailyPlanDesc(Object completed, Object total) {
    return '$completed/$total من مهام اليوم.';
  }

  @override
  String get journeyMemorizeNewAyahsTitle => 'احفظ آيات جديدة';

  @override
  String journeyMemorizeNewAyahsDesc(Object surahAyahLabel) {
    return 'ابدأ بالآيات الجديدة في $surahAyahLabel.';
  }

  @override
  String get journeyCurrentMissionTitle => 'المهمة الحالية';

  @override
  String get journeyCurrentMissionDesc => 'تابع مهمة الطفل الحالية.';

  @override
  String get journeyContinueSessionTitle => 'متابعة جلسة الحفظ';

  @override
  String journeyContinueSessionDesc(Object surahLabel) {
    return 'لديك جلسة حفظ مفتوحة لم تكتمل في $surahLabel.';
  }

  @override
  String get journeyHifzReviewDueTitle => 'مراجعة الحفظ مستحقة';

  @override
  String get journeyHifzReviewDueDesc =>
      'راجع مواضع الحفظ المستحقة في مسار الحفظ.';

  @override
  String get journeyFallbackSurah => 'السورة';

  @override
  String journeyAyahLabel(Object start) {
    return '، الآية $start';
  }

  @override
  String journeyAyahsLabel(Object end, Object start) {
    return '، الآيات $start–$end';
  }

  @override
  String get tutorialS1Title => 'البداية مع تالية';

  @override
  String get tutorialS1Cat => 'البدء';

  @override
  String get tutorialS1Does =>
      'تبدأ تالية بتعريف قصير تختار فيه مسار الكبار أو الأطفال، ثم تنقلك إلى الرئيسية. يمكنك استخدامها كضيف وتسجيل الدخول لاحقًا.';

  @override
  String get tutorialS1Open =>
      'يظهر عند أول فتح للتطبيق. بعد ذلك استخدم الشريط السفلي للتنقل بين الرئيسية والقرآن والحفظ والأذكار والتقدم.';

  @override
  String get tutorialS1Useful =>
      'مفيد للمستخدم الجديد الذي يريد فهم خريطة التطبيق قبل القراءة أو الحفظ.';

  @override
  String get tutorialS1Step1 => 'أنهِ صفحات التعريف، أو اضغط «تخطي».';

  @override
  String get tutorialS1Step2 =>
      'اختر مسار الكبار أو الأطفال، ثم تابع كضيف أو سجّل الدخول.';

  @override
  String get tutorialS1Step3 =>
      'استخدم الشريط السفلي للانتقال بين الأقسام الأساسية.';

  @override
  String get tutorialS1Tip1 =>
      'ابدأ من الرئيسية فهي تجمع قراءة اليوم وتقدمك والاختصارات.';

  @override
  String get tutorialS1Tip2 =>
      'يمكنك تغيير مسار الحفظ لاحقًا من الإعدادات ثم «القرآن والحفظ».';

  @override
  String get tutorialS1Note1 =>
      'تسجيل الدخول اختياري. بدونه يبقى تقدمك على هذا الجهاز.';

  @override
  String get tutorialS1Note2 => 'الإعدادات خلف أيقونة الترس أعلى الرئيسية.';

  @override
  String get tutorialS2Title => 'الصفحة الرئيسية';

  @override
  String get tutorialS2Cat => 'البدء';

  @override
  String get tutorialS2Does =>
      'تعرض الرئيسية الصلاة القادمة، وبطاقة رئيسية لما تفعله بعد ذلك، والورد اليومي، وسلسلتك ونقاطك، وآية اليوم، ونشاطك الأخير.';

  @override
  String get tutorialS2Open => 'اضغط تبويب الرئيسية في الشريط السفلي.';

  @override
  String get tutorialS2Useful =>
      'أفضل نقطة انطلاق يومية: القراءة والحفظ والمتابعة في شاشة واحدة.';

  @override
  String get tutorialS2Step1 =>
      'اضغط البطاقة الرئيسية لاستكمال القراءة أو استئناف جلسة أو فتح خطة اليوم.';

  @override
  String get tutorialS2Step2 => 'اضغط «شيء آخر» لعرض خيارات أخرى.';

  @override
  String get tutorialS2Step3 => 'افتح الإعدادات من أيقونة الترس أعلى الصفحة.';

  @override
  String get tutorialS2Step4 =>
      'اضغط «اختيار المدينة» لتحديد مدينتك لمواقيت الصلاة.';

  @override
  String get tutorialS2Tip1 =>
      'الحلقة تُظهر نسبة ما حفظته من القرآن كله فتنمو ببطء. النقاط السبع هي آخر سبعة أيام وتنتهي باليوم.';

  @override
  String get tutorialS2Tip2 =>
      'اضغط الأيقونات تحت آية اليوم لمشاركتها أو فتحها في المصحف أو الاستماع إليها.';

  @override
  String get tutorialS2Note1 =>
      'بعض البطاقات تظهر فقط عند وجود بيانات، مثل ختمة بدأتها أو موضع قراءة محفوظ.';

  @override
  String get tutorialS2Note2 => 'يمكن إخفاء بطاقة الحساب بعلامة ✕.';

  @override
  String get tutorialS3Title => 'قراءة القرآن';

  @override
  String get tutorialS3Cat => 'القرآن';

  @override
  String get tutorialS3Does =>
      'يعرض تبويب القرآن السور والأجزاء وعلاماتك المرجعية. ويعرض القارئ صفحة المصحف بألوان التجويد مع الصوت والعلامات ووضع التركيز.';

  @override
  String get tutorialS3Open =>
      'اضغط تبويب القرآن ثم اختر سورة أو جزءًا. ويمكنك فتح ورد اليوم من الرئيسية.';

  @override
  String get tutorialS3Useful =>
      'للورد اليومي، وللبحث عن آية، وللقراءة قبل جلسة الحفظ.';

  @override
  String get tutorialS3Step1 =>
      'اختر سورة من القائمة، أو استخدم مربع البحث في الأعلى.';

  @override
  String get tutorialS3Step2 => 'اسحب لتقليب الصفحة.';

  @override
  String get tutorialS3Step3 =>
      'اضغط على الآية مطولًا للاستماع إليها أو نسخها أو وضع علامة أو مشاركتها أو بدء حفظها.';

  @override
  String get tutorialS3Step4 =>
      'افتح القائمة (النقاط الثلاث) للانتقال إلى صفحة أو سورة أو جزء، أو اختيار القارئ، أو تشغيل ألوان التجويد وإيقافها، أو الدخول إلى وضع التركيز.';

  @override
  String get tutorialS3Step5 =>
      'ابقَ في الصفحة بضع ثوانٍ أثناء القراءة: تُحتسب مقروءة تلقائيًا.';

  @override
  String get tutorialS3Tip1 => 'استمع إلى الآية قبل حفظها لتضبط النطق.';

  @override
  String get tutorialS3Tip2 =>
      'بطاقة «أكمل القراءة» في تبويب القرآن تعيدك إلى آخر صفحة.';

  @override
  String get tutorialS3Note1 => 'نص القرآن مضمّن في التطبيق فيُعرض دون اتصال.';

  @override
  String get tutorialS3Note2 => 'الصوت يحتاج اتصالًا ما لم يكن مخزّنًا مسبقًا.';

  @override
  String get tutorialS4Title => 'البحث والعلامات المرجعية';

  @override
  String get tutorialS4Cat => 'القرآن';

  @override
  String get tutorialS4Does =>
      'ابحث عن سورة باسمها أو عن آية بكلماتها، واحفظ الآيات المهمة كعلامات مرجعية.';

  @override
  String get tutorialS4Open =>
      'استخدم مربع البحث أعلى تبويب القرآن أو أيقونة البحث في الرئيسية. وللعلامات تبويب خاص في شاشة القرآن.';

  @override
  String get tutorialS4Useful =>
      'لجمع آيات المراجعة أو الآيات المتشابهة أو مواضع تريد الرجوع إليها.';

  @override
  String get tutorialS4Step1 => 'اكتب اسم سورة أو كلمات من آية.';

  @override
  String get tutorialS4Step2 => 'افتح السورة أو الآية من النتائج.';

  @override
  String get tutorialS4Step3 =>
      'اضغط الآية مطولًا في القارئ واختر «إشارة مرجعية».';

  @override
  String get tutorialS4Step4 =>
      'افتح تبويب الإشارة المرجعية للرجوع إلى الآيات المحفوظة أو حذفها.';

  @override
  String get tutorialS4Tip1 =>
      'ضع علامة عند بداية كل مقطع حفظ لتعود إليه بسرعة.';

  @override
  String get tutorialS4Tip2 => 'البحث يتجاهل التشكيل فيمكنك الكتابة بدونه.';

  @override
  String get tutorialS4Note1 =>
      'بحث الآيات يعرض 50 نتيجة كحد أقصى: أضف كلمات لتضييقه.';

  @override
  String get tutorialS4Note2 => 'حذف علامة لا يؤثر في أي تقدم قراءة أو حفظ.';

  @override
  String get tutorialS5Title => 'الحفظ خطوة بخطوة';

  @override
  String get tutorialS5Cat => 'الحفظ';

  @override
  String get tutorialS5Does =>
      'يجمع تبويب الحفظ خطة اليوم والتدرب بالسورة واختبار الاستماع والمراجعة بالتسميع. وتمر كل آية بالتعلّم ثم الحفظ ثم التسميع.';

  @override
  String get tutorialS5Open =>
      'اضغط تبويب الحفظ. وعند أول استخدام تختار مسار الكبار أو الأطفال.';

  @override
  String get tutorialS5Useful =>
      'للحفظ المنهجي مع مراجعات متباعدة حتى يثبت ما تحفظه.';

  @override
  String get tutorialS5Step1 => 'أنشئ خطة، أو اختر سورة من «تدرّب بالسورة».';

  @override
  String get tutorialS5Step2 => 'التعلّم: استمع إلى الآية واقرأها.';

  @override
  String get tutorialS5Step3 =>
      'الحفظ: جرّب دون النظر، واستعن بالتلميحات (أول كلمة، أوائل الكلمات، إظهار الآية) عند الحاجة فقط.';

  @override
  String get tutorialS5Step4 =>
      'التسميع: سجّل تلاوتك، أو قيّم نفسك بصدق إن لم يتوفر التعرّف على الكلام. ثم تُسمَّع مجموعة الآيات معًا.';

  @override
  String get tutorialS5Tip1 =>
      'التلميحات تُسجَّل وتؤثر في موعد عودة الآية للمراجعة.';

  @override
  String get tutorialS5Tip2 =>
      'غيّر صرامة التحقق من التسميع من الإعدادات ثم «القرآن والحفظ» ثم «مستوى الدقة».';

  @override
  String get tutorialS5Note1 =>
      'الخروج من الجلسة يسألك: أكمل لاحقًا أم تخلَّ عنها.';

  @override
  String get tutorialS5Note2 =>
      'إن لم يتوفر التعرّف على الكلام أو إذن الميكروفون فالتقييم الذاتي مسار معتمد.';

  @override
  String get tutorialS6Title => 'الأذكار اليومية والعداد';

  @override
  String get tutorialS6Cat => 'الأذكار';

  @override
  String get tutorialS6Does =>
      'أذكار الصباح والمساء وأذكار عامة وأدعية، مع عداد تكرار وفهرس ومسبحة حرة وورد ذكي يتبع وقت اليوم.';

  @override
  String get tutorialS6Open =>
      'اضغط تبويب الأذكار ثم اختر الصباح أو المساء أو الأذكار العامة أو الأدعية أو الورد الذكي أو المسبحة الحرة.';

  @override
  String get tutorialS6Useful =>
      'للورد الصباحي والمسائي وجلسات التسبيح ومشاركة دعاء بسرعة.';

  @override
  String get tutorialS6Step1 =>
      'اختر فئة؛ وتظهر فئة الوقت الحالي مميّزة في الأعلى.';

  @override
  String get tutorialS6Step2 =>
      'اضغط العداد مرة لكل تكرار؛ وينتقل إلى الذكر التالي عند الإتمام.';

  @override
  String get tutorialS6Step3 => 'افتح الفهرس للانتقال إلى ذكر محدد.';

  @override
  String get tutorialS6Step4 =>
      'غيّر حجم الخط، وانسخ الذكر أو شاركه عند الحاجة.';

  @override
  String get tutorialS6Step5 => 'عند الانتهاء أعد ضبط الجلسة أو ارجع.';

  @override
  String get tutorialS6Tip1 =>
      'فعّل تذكيرات الصباح والمساء من الإعدادات ثم «الإشعارات».';

  @override
  String get tutorialS6Tip2 => 'اضغط العداد مطولًا للتراجع عن آخر عدّة.';

  @override
  String get tutorialS6Note1 => 'الأذكار مضمّنة في التطبيق وتعمل دون اتصال.';

  @override
  String get tutorialS6Note2 =>
      'العدّادات لجلسة اليوم الحالي، وليست شهادة حفظ.';

  @override
  String get tutorialS7Title => 'الخطة اليومية والمراجعة';

  @override
  String get tutorialS7Cat => 'الحفظ';

  @override
  String get tutorialS7Does =>
      'تقدّم خطتك كل يوم آيات جديدة ومراجعات. وتعود المراجعات بجدول يعتمد على جودة تسميعك فيثبت ما تحفظه.';

  @override
  String get tutorialS7Open =>
      'الحفظ ثم «أكمل خطة اليوم»، أو البطاقة الرئيسية في الرئيسية.';

  @override
  String get tutorialS7Useful =>
      'لحفظ متدرج مع مراجعة ذكية بدل الاعتماد على الذاكرة وحدها.';

  @override
  String get tutorialS7Step1 => 'افتح «أكمل خطة اليوم» من تبويب الحفظ.';

  @override
  String get tutorialS7Step2 => 'أتمم آيات اليوم الجديدة.';

  @override
  String get tutorialS7Step3 =>
      'ابدأ «مراجعة بالتسميع» عندما تستحق آيات المراجعة: تعرض الشارة عددها.';

  @override
  String get tutorialS7Step4 =>
      'افتح «تفاصيل خطة اليوم» لترى ما أُنجز وما بقي.';

  @override
  String get tutorialS7Step5 =>
      'جرّب «اختبار الاستماع» بعد حفظ بضع آيات: يشغّل آية ويطلب منك ذكر سورتها أو إكمالها.';

  @override
  String get tutorialS7Tip1 =>
      'قيّم نفسك بصدق: فهو يحدد قوة الآية وموعد عودتها.';

  @override
  String get tutorialS7Tip2 =>
      'إن بدت الخطة ثقيلة فخفّض عدد الآيات اليومية من «إعدادات الخطة».';

  @override
  String get tutorialS7Note1 =>
      'في أيام الراحة (حسب أيام الأسبوع المحددة) تحصل على المراجعات فقط.';

  @override
  String get tutorialS7Note2 =>
      'يحتاج اختبار الاستماع إلى خمس آيات محفوظة على الأقل.';

  @override
  String get tutorialS8Title => 'إعداد خطتك';

  @override
  String get tutorialS8Cat => 'الحفظ';

  @override
  String get tutorialS8Does =>
      'أنشئ خطتك من قالب سريع أو من الصفر: الاسم ونطاق السور والآيات اليومية وأيام الأسبوع ومدة الجلسة والصعوبة والمراجعات.';

  @override
  String get tutorialS8Open =>
      'الحفظ ثم «أنشئ خطتك»، أو «إعدادات الخطة» لاحقًا.';

  @override
  String get tutorialS8Useful =>
      'لهدف محدد مثل حفظ جزء بعينه، أو لتنظيم حفظ طفل.';

  @override
  String get tutorialS8Step1 =>
      'اختر قالبًا سريعًا (خفيف، متوازن، مكثف، جزء عم) أو املأ الحقول بنفسك.';

  @override
  String get tutorialS8Step2 =>
      'اختر نطاق السور. إن اخترت «طفل» فستُنقل إلى مسار الأطفال، لأن خطط الأطفال تُدار منه.';

  @override
  String get tutorialS8Step3 =>
      'اضبط عدد الآيات اليومية وأيام الأسبوع ومدة الجلسة.';

  @override
  String get tutorialS8Step4 =>
      'اختر الصعوبة وشغّل المراجعة القريبة والبعيدة أو أوقفها.';

  @override
  String get tutorialS8Step5 => 'احفظ الخطة وابدأها.';

  @override
  String get tutorialS8Tip1 =>
      'مدة الجلسة تحدد الآيات الجديدة بنحو أربع دقائق للآية. وتظهر ملاحظة إن قصرت الدقائق عن هدفك.';

  @override
  String get tutorialS8Tip2 => 'ابدأ بقدر صغير لتبني العادة ثم زِد.';

  @override
  String get tutorialS8Note1 => 'يمكن حذف الخطة من شاشة الإعداد نفسها.';

  @override
  String get tutorialS8Note2 => 'مدة الإنهاء الظاهرة في الشاشة تقدير تقريبي.';

  @override
  String get tutorialS9Title => 'وضع الأطفال وأدوات ولي الأمر';

  @override
  String get tutorialS9Cat => 'الحفظ';

  @override
  String get tutorialS9Does =>
      'رحلة بيوت حفظ للأطفال بنجوم ومستويات واستماع متكرر، مع أدوات لولي الأمر للمتابعة.';

  @override
  String get tutorialS9Open =>
      'اختر مسار الأطفال. ويُضبط رمز ولي الأمر أثناء إعداد الطفل. وتظهر أدوات ولي الأمر في الرئيسية بعد تسجيل الدخول.';

  @override
  String get tutorialS9Useful =>
      'للأطفال والمبتدئين، أو لولي أمر يريد متابعة النجوم والجلسات والمكافآت.';

  @override
  String get tutorialS9Step1 =>
      'اختر مسار الأطفال، ثم أدخل اسم الطفل وعمره وسورة البداية ورمز ولي أمر من أربعة أرقام.';

  @override
  String get tutorialS9Step2 =>
      'في رئيسية الأطفال اضغط «استكمل الآن»، واستمع إلى الآية ثلاث مرات، ثم جرّب من حفظك.';

  @override
  String get tutorialS9Step3 =>
      'إن لم يعمل التسجيل فاضغط «أتممت الحفظ بنفسي»: يدخل ولي الأمر الرمز للتأكيد.';

  @override
  String get tutorialS9Step4 =>
      'تابع خريطة الرحلة: تُفتح البيوت واحدًا بعد آخر كلما أتممت المهام.';

  @override
  String get tutorialS9Tip1 =>
      'حافظ على سرية الرمز: فهو يحمي أيضًا الخروج من مسار الأطفال.';

  @override
  String get tutorialS9Tip2 =>
      'استخدم تبويب المصحف في رئيسية الأطفال ليقرأ الطفل في القرآن.';

  @override
  String get tutorialS9Note1 => 'ربط طفل من جهاز آخر يحتاج إلى حساب.';

  @override
  String get tutorialS9Note2 =>
      'طفل واحد لكل جهاز: يستخدم بقية الأطفال أجهزتهم الخاصة مرتبطة بولي الأمر.';

  @override
  String get tutorialS10Title => 'التقدم والإنجازات والشهادات';

  @override
  String get tutorialS10Cat => 'التقدم';

  @override
  String get tutorialS10Does =>
      'يعرض إحصاءات القراءة والحفظ وسلسلتك اليومية والإنجازات وشهاداتك، ويتيح مشاركة تقدمك.';

  @override
  String get tutorialS10Open => 'اضغط تبويب التقدم في الشريط السفلي.';

  @override
  String get tutorialS10Useful =>
      'للمراجعة الأسبوعية والاحتفال بالإنجازات ومتابعة الاستمرار.';

  @override
  String get tutorialS10Step1 =>
      'راجع البطاقات العليا لأيام السلسلة والصفحات المقروءة والنقاط والمراجعات.';

  @override
  String get tutorialS10Step2 =>
      'افتح قسمي القراءة والحفظ لمعرفة الصفحات والآيات والسور والأجزاء.';

  @override
  String get tutorialS10Step3 =>
      'بدّل فلاتر الإنجازات بين الكل والقراءة والحفظ والسلسلة.';

  @override
  String get tutorialS10Step4 =>
      'اضغط إنجازًا مفتوحًا لعرض التفاصيل والمشاركة.';

  @override
  String get tutorialS10Step5 =>
      'تظهر شهاداتك عند إتمام سورة أو جزء أو القرآن كله.';

  @override
  String get tutorialS10Tip1 =>
      'قراءة الختمة تُحتسب في سلسلتك لكن لا تدخل في إحصاءات القراءة الحرة.';

  @override
  String get tutorialS10Tip2 => 'الشهادات تعتمد على حفظ حقيقي للآيات المطلوبة.';

  @override
  String get tutorialS10Note1 => 'بعض الإحصاءات تظهر فقط بعد أن تبدأ الحفظ.';

  @override
  String get tutorialS10Note2 => 'لا تتم المشاركة إلا عندما تختارها.';

  @override
  String get tutorialS11Title => 'الإعدادات والحساب والإشعارات';

  @override
  String get tutorialS11Cat => 'الإعدادات';

  @override
  String get tutorialS11Does =>
      'تجمع حسابك وملفك الشخصي واللغة والمظهر وإعدادات القرآن والحفظ ومواقيت الصلاة والإشعارات ومعلومات التطبيق.';

  @override
  String get tutorialS11Open => 'اضغط أيقونة الترس في الرئيسية.';

  @override
  String get tutorialS11Useful =>
      'لتخصيص التطبيق وحماية تقدمك وضبط تذكيرات تناسب يومك.';

  @override
  String get tutorialS11Step1 =>
      'سجّل الدخول أو أنشئ حسابًا بالبريد وكلمة المرور لإدارة حسابك.';

  @override
  String get tutorialS11Step2 => 'عدّل اسمك من الملف الشخصي.';

  @override
  String get tutorialS11Step3 =>
      'اختر العربية أو English، والمظهر الفاتح أو الداكن أو الأسود الكامل أو حسب النظام.';

  @override
  String get tutorialS11Step4 =>
      'من «القرآن والحفظ» اضبط التشغيل في الخلفية ومستوى الدقة، أو أعد ضبط المسار.';

  @override
  String get tutorialS11Step5 =>
      'من «مواقيت الصلاة» اختر مدينتك وطريقة الحساب.';

  @override
  String get tutorialS11Step6 =>
      'من «الإشعارات» فعّل أو أوقف تذكيرات المراجعة والسلسلة والأذكار والصلاة.';

  @override
  String get tutorialS11Tip1 =>
      'اكتب اسمك بالعربية ليظهر على الشهادات بشكل جميل.';

  @override
  String get tutorialS11Tip2 =>
      'أعد ضبط المسار من «القرآن والحفظ» للتبديل بين الكبار والأطفال.';

  @override
  String get tutorialS11Note1 => 'تحتاج الإشعارات إلى إذن النظام لتعمل.';

  @override
  String get tutorialS11Note2 => 'اللغة والمظهر محفوظان على هذا الجهاز.';

  @override
  String get tutorialS12Title => 'العمل دون اتصال وبياناتك';

  @override
  String get tutorialS12Cat => 'الإعدادات';

  @override
  String get tutorialS12Does =>
      'نصوص القرآن والأذكار مضمّنة في التطبيق. وتُحفظ تقدّمك وخططك وإعداداتك على الجهاز، ومع الحساب يُزامَن بعضها عبر الإنترنت.';

  @override
  String get tutorialS12Open =>
      'لا توجد شاشة منفصلة: يعمل تلقائيًا أثناء استخدامك التطبيق.';

  @override
  String get tutorialS12Useful =>
      'لفهم ما يعمل دون اتصال وتجنب فقدان تقدم مهم.';

  @override
  String get tutorialS12Step1 => 'اقرأ القرآن واستخدم الأذكار حتى دون إنترنت.';

  @override
  String get tutorialS12Step2 =>
      'واصل القراءة والحفظ: يُحفظ التقدم على الجهاز.';

  @override
  String get tutorialS12Step3 =>
      'سجّل الدخول عندما تريد ميزات الحساب أو استعادة تقدم حفظك.';

  @override
  String get tutorialS12Tip1 =>
      'على جهاز جديد سجّل الدخول لاستعادة ما يدعمه حسابك.';

  @override
  String get tutorialS12Tip2 => 'اتصل بالإنترنت لتشغيل تلاوات غير مخزّنة.';

  @override
  String get tutorialS12Note1 =>
      'مسح بيانات التطبيق من إعدادات النظام يزيل كل ما لم يُحفظ في حسابك.';

  @override
  String get tutorialS12Note2 =>
      'تسجيل الخروج يزيل خطة الختمة وسجلها من هذا الجهاز: فهما محفوظان هنا فقط.';

  @override
  String get tutorialS14Note2 =>
      'قد تحتاج التنبيهات الدقيقة إلى إذن المنبّهات الدقيقة في إعدادات الهاتف.';

  @override
  String get tutorialS14Note1 => 'تُحسب المواقيت على الجهاز فتعمل دون اتصال.';

  @override
  String get tutorialS14Tip2 =>
      'إن لم تعرف الطريقة الأنسب فاختر ما تعتمده الجهة الرسمية في بلدك.';

  @override
  String get tutorialS14Tip1 =>
      'إن لم تكن مدينتك في القائمة فاستخدم موقعًا مخصصًا: انسخ إحداثياتها من تطبيق الخرائط.';

  @override
  String get tutorialS14Step4 =>
      'فعّل وضع سكينة الصلاة إن أردت أن تتوقف التلاوة عند دخول وقت الصلاة.';

  @override
  String get tutorialS14Step3 =>
      'فعّل تنبيهات الصلاة: تُفعَّل تلقائيًا أول مرة تحدد فيها موقعًا.';

  @override
  String get tutorialS14Step2 =>
      'اختر طريقة الحساب (تلقائي حسب البلد افتراضيًا) وحساب وقت العصر.';

  @override
  String get tutorialS14Step1 =>
      'اختر البلد والمدينة، أو «موقع مخصص» لإدخال الإحداثيات.';

  @override
  String get tutorialS14Useful =>
      'لمعرفة مواقيت الصلاة أينما كنت مع تنبيه عند حلول الوقت.';

  @override
  String get tutorialS14Open =>
      'في الرئيسية اضغط «اختيار المدينة»، أو افتح الإعدادات ثم «مواقيت الصلاة».';

  @override
  String get tutorialS14Does =>
      'تعرض الرئيسية مواقيت الصلاة والصلاة القادمة، ويمكنها تنبيهك عند كل صلاة.';

  @override
  String get tutorialS14Cat => 'الإعدادات';

  @override
  String get tutorialS14Title => 'مواقيت الصلاة والتنبيهات';

  @override
  String get tutorialS13Note2 =>
      'تُحفظ على هذا الجهاز فقط، وتُحذف عند تسجيل الخروج.';

  @override
  String get tutorialS13Note1 =>
      'الختمة منفصلة عن القراءة الحرة: لا يحرّك أحدهما موضع الآخر.';

  @override
  String get tutorialS13Tip2 => 'إن تأخرت فاستخدم خيارات اللوحة للتعويض.';

  @override
  String get tutorialS13Tip1 => 'يمكنك إهداء الختمة لشخص عزيز عند إنشائها.';

  @override
  String get tutorialS13Step4 =>
      'إن قرأت من مصحف ورقي فاستخدم «تسجيل» لإدخال الصفحات.';

  @override
  String get tutorialS13Step3 => 'اقرأ ورد اليوم: تُسجَّل كل صفحة تقرؤها.';

  @override
  String get tutorialS13Step2 =>
      'ابدأ الختمة واضغط «متابعة القراءة» في اللوحة.';

  @override
  String get tutorialS13Step1 =>
      'اختر عدد الصفحات يوميًا أو المدة، ويمكنك تحديد صفحة البداية.';

  @override
  String get tutorialS13Useful =>
      'لقراءة القرآن بانتظام بهدف واضح، كما في رمضان.';

  @override
  String get tutorialS13Open =>
      'في الرئيسية اضغط «ابدأ ختمتك»، أو افتح بطاقة الختمة بعد أن تبدأها.';

  @override
  String get tutorialS13Does =>
      'خطط لقراءة القرآن كاملًا بالوتيرة التي تختارها: صفحات يوميًا أو عدد أيام. وتتابع تالية تقدمك صفحة بصفحة وتحفظ سجل الختمات المكتملة.';

  @override
  String get tutorialS13Cat => 'القرآن';

  @override
  String get tutorialS13Title => 'الختمة: قراءة القرآن كاملًا';

  @override
  String get tutorialCategoryTitle => 'الفئة';

  @override
  String get tutorialWhatItDoesTitle => 'ماذا تفعل؟';

  @override
  String get tutorialHowToOpenTitle => 'كيف أصل إليها؟';

  @override
  String get tutorialStepsTitle => 'خطوات الاستخدام';

  @override
  String get tutorialTipsTitle => 'تلميحات';

  @override
  String get tutorialNotesTitle => 'ملاحظات فنية';

  @override
  String get tutorialWhenUsefulTitle => 'متى تكون مفيدة؟';

  @override
  String certificateCelebrationMultiple(int count) {
    return 'لقد حصلت على $count شهادات جديدة';
  }

  @override
  String certificateCelebrationSingle(String title) {
    return 'لقد حصلت على $title';
  }

  @override
  String get learningAlertReduceNewTitle => 'تقليل الحفظ الجديد';

  @override
  String get learningAlertReduceNewSubtitle =>
      'حِملك الدراسي ثقيل، ركز على المراجعة';

  @override
  String get learningAlertFocusWeakTitle => 'ركز على الآيات الصعبة';

  @override
  String get learningAlertFocusWeakSubtitle =>
      'لديك آيات صعبة تحتاج مراجعة مكثفة';

  @override
  String get learningAlertGenericTitle => 'تنبيه تعليمي';

  @override
  String get learningAlertGenericSubtitle => 'مطلوب اتخاذ إجراء';

  @override
  String get reviewBacklogTitle => 'تراكم المراجعة';

  @override
  String reviewBacklogSubtitle(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لديك $countText آية متأخرة',
      few: 'لديك $countText آيات متأخرة',
      two: 'لديك آيتان متأخرتان',
      one: 'لديك آية واحدة متأخرة',
    );
    return '$_temp0';
  }

  @override
  String get smartPlanCustomTitle => 'خطة مخصصة';

  @override
  String get smartPlanReviewTitle => 'خطة المراجعة';

  @override
  String get smartPlanTodayTitle => 'خطة اليوم';

  @override
  String get smartPlanSubtitle => 'أكمل رحلة حفظك';

  @override
  String get dailyWirdTitle => 'الورد اليومي';

  @override
  String get dailyWirdSubtitle => 'اقرأ وردك اليومي';

  @override
  String get khatmahContinueTitle => 'متابعة الختمة';

  @override
  String get khatmahContinueSubtitle => 'أكمل قراءة ختمتك';

  @override
  String get exploreAzkarTitle => 'وقت الذكر';

  @override
  String get exploreAzkarSubtitle => 'ابدأ أذكارك اليومية';

  @override
  String get exploreMissionTitle => 'المهمة الحالية';

  @override
  String get exploreMissionSubtitle => 'ابدأ مهمتك الحالية';

  @override
  String get exploreQuranTitle => 'القرآن الكريم';

  @override
  String get exploreQuranSubtitle => 'اقرأ القرآن';

  @override
  String get parentDashboardLinkHint => 'talia-kids-link:...';

  @override
  String get familyDashboardTitle => 'لوحة العائلة';

  @override
  String get familyDashboardMyChildren => 'أطفالي';

  @override
  String get familyDashboardAddChild => 'ربط طفل جديد';

  @override
  String get familyDashboardNoChildren => 'لم يتم ربط أي طفل بعد';

  @override
  String get familyDashboardNoChildrenHint =>
      'على جهاز طفلك: افتح مسار الأطفال ← اضغط ⚙ ← «ربط ولي الأمر»، ثم امسح الرمز الظاهر أو اكتبه هنا.';

  @override
  String get familyDashboardTodaySummaryTitle => 'اليوم في عائلتنا';

  @override
  String familyDashboardTodaySummary(int count, int points) {
    return '$count نشط اليوم، $points نقطة';
  }

  @override
  String get familyDashboardLocalBadge => 'على هذا الجهاز';

  @override
  String familyDashboardChildActiveToday(int points) {
    return '$points نقطة اليوم';
  }

  @override
  String get familyDashboardChildNoActivity => 'لا نشاط اليوم';

  @override
  String get familyDashboardNicknameSaved => 'تم حفظ الاسم';

  @override
  String childDetailTitle(String name) {
    return 'تقدم $name';
  }

  @override
  String childDetailTodayActivity(int sessions, int points) {
    return '$sessions جلسة، $points نقطة اليوم';
  }

  @override
  String get childDetailNoActivity => 'لا نشاط اليوم';

  @override
  String get childDetailMemorizationProgress => 'تقدم الحفظ';

  @override
  String get childDetailRecentSessions => 'آخر الجلسات';

  @override
  String childDetailRewards(int count) {
    return 'المكافآت ($count)';
  }

  @override
  String get childDetailAddReward => 'إضافة مكافأة';

  @override
  String get childDetailOpenFullDashboard => 'فتح لوحة التحكم الكاملة';

  @override
  String get kidsPreparing => 'جارٍ التحضير...';

  @override
  String get kidsUnexpectedError => 'يبدو أن شيئًا ما حدث!';

  @override
  String get v2LearningTitle => 'تعلّم الآية';

  @override
  String get v2LearningSubtitle => 'استمع واقرأ الآية بهدوء قبل محاولة حفظها.';

  @override
  String get v2StartMemorizing => 'انتقل للحفظ';

  @override
  String get v2MemorizingTitle => 'احفظ الآية';

  @override
  String get v2MemorizingSubtitle => 'درّب ذاكرتك. التلميحات متاحة هنا فقط.';

  @override
  String get v2ReadyToRecite => 'أنا جاهز للتسميع';

  @override
  String get v2FirstWordHint => 'أول كلمة';

  @override
  String get v2ShowAyahHint => 'إظهار الآية';

  @override
  String get v2RecitationTitle => 'سمّع من حفظك';

  @override
  String get v2RecitationSubtitle =>
      'النص مخفي الآن. سجّل تسميعك بدون تلميحات.';

  @override
  String get v2StartRecording => 'بدء التسجيل';

  @override
  String get v2StopRecording => 'إيقاف التسجيل';

  @override
  String get v2ManualRecallAction => 'أتممت التسميع من حفظي (تقييم ذاتي)';

  @override
  String get v2SelfGradeAction => 'قيّم تسميعك بنفسك';

  @override
  String get v2SelfGradeTitle => 'كيف كان تسميعك من حفظك؟';

  @override
  String get v2SelfGradeMastered => 'أتقنتها';

  @override
  String get v2SelfGradeMasteredHint => 'سمّعتها كاملة دون تردّد';

  @override
  String get v2SelfGradeHesitated => 'تردّدت قليلاً';

  @override
  String get v2SelfGradeHesitatedHint =>
      'سمّعتها مع توقف أو خطأ بسيط؛ ستُراجَع قريباً';

  @override
  String get v2SelfGradeForgot => 'لم أتذكّرها';

  @override
  String get v2SelfGradeForgotHint => 'سنعيدها معك الآن';

  @override
  String get v2SelfGradeRevealHint =>
      'سمّع من حفظك أولاً، ثم اكشف النص وقارن قبل أن تقيّم.';

  @override
  String get v2SelfGradeRevealAction => 'اعرض الآية وقارن';

  @override
  String get v2BlockRevealAction => 'اعرض المقطع وقارن';

  @override
  String get v2BlockGradeMastered => 'سمّعت المقطع كاملاً دون تعثّر';

  @override
  String get v2BlockGradeHesitated => 'تردّدت في آية';

  @override
  String get v2BlockGradeForgot => 'نسيت آية';

  @override
  String get v2StumbledAyahTitle => 'في أي آية تعثّرت؟';

  @override
  String v2StumbledAyahOption(int ayahNumber) {
    return 'الآية $ayahNumber';
  }

  @override
  String get v2ManualRecallHint =>
      'لا يتوفر الميكروفون؟ أكّد أنك تسمّعت من حفظك وسيُسجَّل التقدم.';

  @override
  String get v2ManualBlockReviewAction => 'قيّم تسميع المقطع بنفسك';

  @override
  String get v2RemediationTitle => 'مراجعة قصيرة';

  @override
  String get v2RemediationSubtitle =>
      'استمع واقرأ الآية مرة أخرى، ثم ارجع لمحاولة التسميع.';

  @override
  String get v2TryAgain => 'أحاول مرة أخرى';

  @override
  String get v2BlockReviewPendingTitle => 'مراجعة المقطع';

  @override
  String get v2BlockReviewPendingSubtitle =>
      'أنهيت الآيات منفردة. الخطوة التالية تسميع المقطع كاملاً من الذاكرة.';

  @override
  String get v2StartBlockReview => 'ابدأ مراجعة المقطع';

  @override
  String get v2BlockReviewTitle => 'سمّع المقطع كاملاً';

  @override
  String v2BlockReviewSubtitle(String startAyah, String endAyah) {
    return 'النص مخفي الآن. سجّل الآيات من $startAyah إلى $endAyah كاملة بدون تلميحات.';
  }

  @override
  String get v2CompletionTitle => 'اكتملت الجلسة';

  @override
  String get v2CompletionSubtitle => 'تم حفظ آيات هذا المقطع بنجاح.';

  @override
  String get closingMomentLabel => 'لحظة ختام';

  @override
  String closingSummaryMemorization(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText آية',
      many: '$countText آية',
      few: '$countText آيات',
      two: 'آيتين',
      one: 'آية واحدة',
      zero: '$countText آية',
    );
    return 'تعلّمتَ $_temp0 في هذه الجلسة، وبالمراجعة تثبت في حفظك بإذن الله.';
  }

  @override
  String get closingSummaryReview =>
      'أتممتَ مراجعتك بثبات — ثبتها الله في قلبك.';

  @override
  String get v2ReviewSessionTitle => 'مراجعة الحفظ';

  @override
  String get v2HintSchedulingNotice =>
      'التلميحات تُسجَّل وتؤثر على جدولة مراجعتك القادمة.';

  @override
  String dailyPlanBacklogNotice(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لديك $countText آية مستحقة للمراجعة.',
      few: 'لديك $countText آيات مستحقة للمراجعة.',
      two: 'لديك آيتان مستحقتان للمراجعة.',
      one: 'لديك آية واحدة مستحقة للمراجعة.',
    );
    return '$_temp0 أكمل مراجعات اليوم لتُفتح الآيات الجديدة.';
  }

  @override
  String get dailyPlanStartReview => 'ابدأ مراجعة اليوم';

  @override
  String get dailyPlanReviewDayNotice =>
      'اليوم يوم مراجعة في خطتك: لا آيات جديدة، ثبّت ما حفظت.';

  @override
  String closingSummaryKhatmahWird(String start, String end) {
    return 'أتممتَ ورد اليوم — من صفحة $start إلى $end — أثرٌ باقٍ بإذن الله.';
  }

  @override
  String get closingDuaButton => 'دعاء الختام';

  @override
  String get closingDua =>
      'اللَّهُمَّ اجْعَلْ مَا حَفِظْتُ نُورًا لِي فِي قَلْبِي، وَذِكْرًا لِي عِنْدَكَ، وَاجْعَلْهُ نَاصِرًا لِي، وَانْفَعْنِي بِمَا عَلَّمْتَنِي وَعَلِّمْنِي مَا يَنْفَعُنِي.';

  @override
  String get closingDuaAmen => 'آمين';

  @override
  String get closingDone => 'تم بحمد الله';

  @override
  String get closingRestNote => 'خذ نفسًا… حفظك ينتظرك غدًا بإذن الله.';

  @override
  String get v2MemorizationHub => 'مركز الحفظ';

  @override
  String v2NextPlanItem(int count) {
    return 'التالي في خطة اليوم ($count متبقية)';
  }

  @override
  String get v2TryWithoutHint => 'حاول من غير تلميح';

  @override
  String get v2FirstWordRevealed => 'تم كشف أول كلمة';

  @override
  String get v2Evaluating => 'جارٍ التقييم...';

  @override
  String get v2RecordingNow => 'يتم التسجيل الآن';

  @override
  String get v2PressRecord => 'اضغط التسجيل عندما تكون جاهزًا';

  @override
  String get v2MicrophoneUnavailable =>
      'التعرّف على الكلام غير متوفر على هذا الجهاز. قيّم تسميعك بنفسك.';

  @override
  String get v2TryRecordingAgain => 'حاول التسجيل مجددًا';

  @override
  String get v2NoSpeechDetected => 'لم نسمع تلاوة. سجّل مرة أخرى.';

  @override
  String get v2MicrophonePermissionDenied => 'يلزم السماح بالميكروفون للتسجيل.';

  @override
  String get v2MicrophoneOpenSettings =>
      'الوصول للميكروفون محظور. افتح الإعدادات للسماح به.';

  @override
  String get v2AudioPlaybackFailed => 'تعذر تشغيل صوت الآية. حاول مرة أخرى.';

  @override
  String v2RemediationAttempts(int count) {
    return 'عدد المحاولات التي تحتاج مراجعة: $count';
  }

  @override
  String v2AyahRange(String startAyah, String endAyah) {
    return 'الآيات من $startAyah إلى $endAyah';
  }

  @override
  String v2BlockProgress(String passed, String total) {
    return 'اجتزتَ $passed من $total.';
  }

  @override
  String v2AyahOfBlock(String current, String total) {
    return 'الآية $current من $total';
  }

  @override
  String get v2EvaluatingBlock => 'جارٍ تقييم المقطع...';

  @override
  String get v2RecordingBlock => 'يتم تسجيل المقطع الآن';

  @override
  String get v2Playing => 'يتم التشغيل';

  @override
  String get v2ListenToAyah => 'استمع للآية';

  @override
  String get v2Passed => 'تم تسميعها';

  @override
  String get v2Retries => 'محاولات';

  @override
  String get v2ResultExcellent => 'أحسنت! تسميع متقن';

  @override
  String get v2ResultPassed => 'تم اجتياز الآية';

  @override
  String get v2ResultRetrying => 'اقتربت! حاول مرة أخرى';

  @override
  String get v2ResultNeedsWork => 'يلزم مراجعة الآية';

  @override
  String v2ResultSimilarity(int score) {
    return 'نسبة التطابق: $score%';
  }

  @override
  String get v2ResultManualGrade => 'تم تقييم التسميع ذاتيًا';

  @override
  String get v2ResultContinue => 'متابعة';

  @override
  String get v2ResultRetryNow => 'أعد التسميع الآن';

  @override
  String get v2ResultReviewAyah => 'راجع الآية';

  @override
  String get v2ResultWordsCorrect => 'صحيحة';

  @override
  String get v2ResultWordsMissing => 'ناقصة';

  @override
  String get v2ResultWordsWrong => 'خاطئة';

  @override
  String get v2ResultWordsExtra => 'زيادة';

  @override
  String get v2LoopOff => 'تكرار: بدون';

  @override
  String get v2LoopThree => 'تكرار: 3 مرات';

  @override
  String get v2LoopInfinite => 'تكرار: مستمر';

  @override
  String get v2MaskedWordsHint => 'إظهار الكلمات المخفية';

  @override
  String get v2MaskedWordsRevealed => 'الكلمات مخفية — حاول التذكر';

  @override
  String get v2MaskedWordsFull => 'إخفاء الكلمات';

  @override
  String get v2FirstLettersHint => 'أوائل الكلمات';

  @override
  String get v2FirstLettersRevealed => 'ظهرت أوائل الكلمات — حاول التذكر';

  @override
  String countAyahs(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText آية',
      many: '$countText آية',
      few: '$countText آيات',
      two: 'آيتان',
      one: 'آية واحدة',
      zero: '$countText آية',
    );
    return '$_temp0';
  }

  @override
  String streakDaysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوم',
      many: 'يومًا',
      few: 'أيام',
    );
    return '$_temp0';
  }

  @override
  String get v2SurahLoadFailed => 'تعذر تحميل بيانات السورة.';

  @override
  String get v2NoAyahsInRange => 'لا توجد آيات في النطاق المحدد.';

  @override
  String get kidsRecordingUnavailable =>
      'لم يعمل الميكروفون الآن. جرّب مرة أخرى أو اطلب مساعدة ولي الأمر.';

  @override
  String get kidsRecordingNotCaptured =>
      'لم نسمع تلاوتك بوضوح. اضغط وسجّل الآية مرة أخرى.';

  @override
  String get kidsRecitationMismatch =>
      'الآية لم تتطابق. استمع للآية مرة أخرى ثم سجّل تلاوتك.';

  @override
  String kidsRecitationCloseMatch(int matched, int total) {
    return 'أنت قريب جدًا! أصبت $matched من $total كلمات. استمع مرة أخرى وحاول من جديد.';
  }

  @override
  String get kidsJourneyCompleteHint =>
      'أتممت الفاتحة وجزء عمّ كاملاً! أخبر وليّ أمرك بهذا الإنجاز العظيم.';

  @override
  String get kidsAyahAlreadyCompleted =>
      'أكملت هذه الآية من قبل. ارجع للخريطة للمتابعة.';

  @override
  String get accountSwitchOfflineDataDiscarded =>
      'تعذر رفع التقدم غير المتزامن للحساب السابق، لذا تمت إزالته من هذا الجهاز.';

  @override
  String get startYourJourneyWithQuran => 'ابدأ رحلتك مع القرآن';

  @override
  String get startNow => 'ابدأ الآن';

  @override
  String get kidsJourneyBetaTitle => 'رحلة الحفظ الجديدة';

  @override
  String get kidsJourneyBetaDescription =>
      'تفعيل مهمة اليوم والمراجعة المتباعدة مع إمكانية الرجوع.';

  @override
  String get kidsGuidanceAudioTitle => 'صوت المرشد';

  @override
  String get kidsGuidanceAudioDescription =>
      'إرشادات قصيرة لا تعمل أثناء تلاوة القرآن.';

  @override
  String get kidsSessionGoalTitle => 'مدة الجلسة المستهدفة';

  @override
  String kidsSessionGoalValue(int minutes) {
    return '$minutes دقائق';
  }

  @override
  String get kidsSetupReminderTime => 'وقت التذكير';

  @override
  String get kidsSetupWeeklyGoal => 'الهدف الأسبوعي';

  @override
  String kidsSetupWeeklyGoalValue(int sessions) {
    return '$sessions جلسات أسبوعياً';
  }

  @override
  String get kidsSetupStartingSurah => 'سورة البداية';

  @override
  String parentCommitmentDays(int count) {
    return '$count أيام التزام';
  }

  @override
  String parentDueReviews(int count) {
    return '$count مراجعات مستحقة';
  }

  @override
  String parentNeedsSupport(int count) {
    return '$count آيات تحتاج دعمًا';
  }

  @override
  String parentAverageDuration(int minutes) {
    return 'متوسط $minutes د';
  }

  @override
  String parentHintUses(int count) {
    return '$count تلميحات';
  }

  @override
  String get khatmahStartAction => 'ابدأ ختمة';

  @override
  String get khatmahResumeAction => 'استئناف';

  @override
  String get khatmahNoPlanTitle => 'لا توجد ختمة حالية';

  @override
  String get khatmahNoPlanDescription =>
      'ابدأ ختمة جديدة بالوتيرة التي تناسبك.';

  @override
  String get khatmahPausedSummary => 'الختمة متوقفة مؤقتاً — استأنف للمتابعة';

  @override
  String get khatmahExistingActivePlan => 'لديك ختمة نشطة بالفعل';

  @override
  String get khatmahExistingPausedPlan => 'لديك ختمة متوقفة مؤقتاً بالفعل';

  @override
  String get khatmahViewCurrentPlan => 'عرض الختمة الحالية';

  @override
  String get khatmahEndCurrentPlan => 'إنهاء الختمة الحالية';

  @override
  String get khatmahEndCurrentConfirmTitle => 'إنهاء الختمة الحالية؟';

  @override
  String khatmahEndCurrentConfirmDescription(String title) {
    return 'سيتم حذف خطة \"$title\". بعد ذلك يمكنك اختيار بدء خطة جديدة.';
  }

  @override
  String get khatmahEndPlanAction => 'إنهاء الختمة';

  @override
  String get khatmahStartNewKhatmah => 'ابدأ ختمة جديدة';

  @override
  String get khatmahChooseYourDailyReadingPaceToCompleteThe =>
      'اختر خطتك اليومية المناسبة لقراءة القرآن الكريم بهدوء وسكينة';

  @override
  String get khatmahDailyPages => 'الصفحات اليومية';

  @override
  String khatmahPages(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText صفحة',
      many: '$countText صفحة',
      few: '$countText صفحات',
      two: 'صفحتان',
      one: 'صفحة واحدة',
      zero: '$countText صفحة',
    );
    return '$_temp0';
  }

  @override
  String get khatmahOrCustomPagesPerDay => 'أو عدد مخصص يومياً';

  @override
  String get khatmahOrChooseDuration => 'أو اختر مدة الختمة';

  @override
  String get khatmahStartFromPage => 'ابدأ من الصفحة (اختياري)';

  @override
  String get khatmahStartFromPageHint =>
      'بعد الصفحة ٦٠٤ تكمل من الصفحة ١ حتى تتم الختمة';

  @override
  String khatmahDurationDays(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText يوم',
      many: '$countText يومًا',
      few: '$countText أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '$countText يوم',
    );
    return '$_temp0';
  }

  @override
  String get khatmahDurationRamadan => 'رمضان (جزء يومياً)';

  @override
  String get khatmahEG5 => 'مثال: 5';

  @override
  String get khatmahEstimatedDuration => 'المدة التقديرية';

  @override
  String khatmahDays(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText يوم',
      many: '$countText يومًا',
      few: '$countText أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '$countText يوم',
    );
    return '$_temp0';
  }

  @override
  String get khatmahExpectedCompletion => 'موعد الختام المتوقع';

  @override
  String get khatmahStartKhatmah => 'ابدأ الختمة';

  @override
  String get khatmahPhysicalMushafProgressSavedSuccessfully =>
      'تم تسجيل القراءة بنجاح';

  @override
  String get khatmahEndKhatmah => 'إنهاء الختمة';

  @override
  String get khatmahAreYouSureYouWantToEndThis =>
      'هل أنت متأكد من رغبتك في إنهاء هذه الختمة؟ يمكنك دائماً البدء من جديد بهدوء وبدون أي حرج.';

  @override
  String get khatmahCancel => 'إلغاء';

  @override
  String get khatmahUnableToSaveKhatmahProgress => 'تعذر حفظ تقدم الختمة.';

  @override
  String get khatmahRetry => 'إعادة المحاولة';

  @override
  String get khatmahLiving => 'حي';

  @override
  String get khatmahDeceased => 'متوفى';

  @override
  String khatmahDedicatedTo(String v1) {
    return 'إهداء إلى: $v1';
  }

  @override
  String get khatmahKhatmahDashboard => 'لوحة الختمة';

  @override
  String get khatmahUnableToLoadYourKhatmah => 'تعذر تحميل الختمة';

  @override
  String get khatmahCheckYourConnectionAndTryAgain =>
      'تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get khatmahReload => 'إعادة المحاولة';

  @override
  String get khatmahQuranKhatmah => 'ختمة القرآن الكريم';

  @override
  String get khatmahTodaySWirdCompleted => 'أتممت ورد اليوم';

  @override
  String get khatmahTodaySWird => 'ورد اليوم';

  @override
  String khatmahPagesTo(String v1, String v2) {
    return 'من صفحة $v1 إلى صفحة $v2';
  }

  @override
  String get khatmahResuming => 'جارٍ الاستئناف';

  @override
  String get khatmahContinueReading => 'متابعة القراءة';

  @override
  String get khatmahReadFromPhysicalMushaf => 'قرأت من المصحف الورقي؟';

  @override
  String get khatmahLog => 'تسجيل';

  @override
  String get khatmahCalmAdaptiveControls => 'خيارات التكيّف الهادئ';

  @override
  String get khatmahEndDateRecalibratedSmoothly =>
      'تمت إعادة ضبط موعد الختام بهدوء وسكينة';

  @override
  String get khatmahCalmAdjust => 'تعديل هادئ';

  @override
  String get khatmahAdded1PageDayMildCompensation =>
      'تمت إضافة صفحة يومياً للتعويض الخفيف';

  @override
  String get khatmahMildBoost => 'تعويض خفيف';

  @override
  String get khatmahAdjustPreviewTitle => 'تعديل جدول الختمة';

  @override
  String khatmahAdjustPreviewBody(int pages, String pagesText, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pagesText صفحة',
      many: '$pagesText صفحة',
      few: '$pagesText صفحات',
      two: 'صفحتان',
      one: 'صفحة واحدة',
      zero: '$pagesText صفحة',
    );
    return 'الورد اليومي: $_temp0\nالختام المتوقع: $date';
  }

  @override
  String get khatmahApplyAdjustment => 'تطبيق';

  @override
  String get khatmahLoadFailureHint =>
      'تعذّرت قراءة بيانات الختمة على هذا الجهاز. أعد المحاولة.';

  @override
  String get khatmahPause => 'إيقاف مؤقت';

  @override
  String get khatmahResume => 'استئناف';

  @override
  String get khatmahLogPhysicalMushafReading => 'تسجيل قراءة من المصحف';

  @override
  String get khatmahEnterTheLastPageReadFromYourPhysical =>
      'أدخل رقم آخر صفحة قرأتها من المصحف الورقي (1 - 604):';

  @override
  String get khatmahPageNumber => 'رقم الصفحة';

  @override
  String khatmahEG(String v1) {
    return 'مثال: $v1';
  }

  @override
  String get khatmahSaveProgress => 'حفظ التقدم';

  @override
  String get khatmahNoSavedCompletionAvailable => 'لا توجد ختمة مكتملة محفوظة';

  @override
  String get khatmahPagesLabel => 'الصفحات';

  @override
  String get khatmahDuration => 'المدة';

  @override
  String get khatmahCompleted => 'تاريخ الختام';

  @override
  String get khatmahDedicationOfReward => 'إهداء ثواب الختمة';

  @override
  String get khatmahReadDuAKhatmAlQuran => 'قراءة دعاء ختم القرآن';

  @override
  String get khatmahShareAchievement => 'مشاركة الإنجاز';

  @override
  String get khatmahBackToHome => 'العودة للرئيسية';

  @override
  String get khatmahDuACopiedToClipboard => 'تم نسخ الدعاء بنجاح';

  @override
  String get khatmahDuAKhatmAlQuran => 'دعاء ختم القرآن';

  @override
  String get khatmahDecreaseFontSize => 'تصغير الخط';

  @override
  String get khatmahIncreaseFontSize => 'تكبير الخط';

  @override
  String get khatmahCopyDuA => 'نسخ الدعاء';

  @override
  String khatmahPagesLeft(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText صفحة متبقية',
      few: '$countText صفحات متبقية',
      two: 'صفحتان متبقيتان',
      one: 'صفحة واحدة متبقية',
    );
    return '$_temp0';
  }

  @override
  String khatmahEstCompletion(String v1) {
    return 'الختام المتوقع: $v1';
  }

  @override
  String get khatmahDedicateKhatmahToSomeone => 'إهداء الختمة لشخص عزيز';

  @override
  String get khatmahRecipientName => 'اسم المهدى له';

  @override
  String get khatmahEGMyBelovedMother => 'مثال: والدتي الغالية';

  @override
  String get khatmahRelationship => 'صلة القرابة';

  @override
  String get khatmahCondition => 'الحالة';

  @override
  String get khatmahSickRecovery => 'مريض';

  @override
  String get khatmahSpecialNoteDuAOptional => 'ملاحظة أو دعاء خاص (اختياري)';

  @override
  String khatmahPageOfOfTodaySWird(String v1, String v2, String v3) {
    return 'صفحة $v1 ($v2 من $v3 من ورد اليوم)';
  }

  @override
  String get khatmahSaveExit => 'إنهاء القراءة';

  @override
  String get khatmahPaceOnTrack => 'في الموعد — أحسنت';

  @override
  String khatmahPaceAhead(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText يوماً',
      few: '$countText أيام',
      two: 'يومين',
      one: 'يوم واحد',
    );
    return 'متقدم — ستختم قبل موعدك ب$_temp0';
  }

  @override
  String get khatmahRedistributeAction => 'أعد التوزيع للحفاظ على الموعد';

  @override
  String get khatmahRedistributed =>
      'أُعيد توزيع الصفحات للحفاظ على موعد الختام';

  @override
  String khatmahPaceBehind(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText صفحة',
      few: '$countText صفحات',
      two: 'صفحتين',
      one: 'صفحة واحدة',
    );
    return 'متأخر $_temp0 عن موعد الختام';
  }

  @override
  String khatmahThroughWirdEnd(String page) {
    return 'حتى نهاية ورد اليوم (ص $page)';
  }

  @override
  String get khatmahCongratulations => 'مبارك ختم القرآن الكريم';

  @override
  String khatmahShareSummary(String title, int days, String daysText) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysText يوم',
      many: '$daysText يومًا',
      few: '$daysText أيام',
      two: 'يومين',
      one: 'يوم واحد',
    );
    return 'أتممت ختمة القرآن الكريم ($title) في $_temp0.\nعبر تطبيق تالية القرآني';
  }

  @override
  String khatmahUserNote(String note) {
    return 'ملاحظة شخصية كتبتها: $note';
  }

  @override
  String khatmahTodayRange(String start, String end, String completed) {
    return 'ورد اليوم: الصفحات $start - $end$completed';
  }

  @override
  String get khatmahDailyCompletedSuffix => ' — مكتمل';

  @override
  String get khatmahProgress => 'تقدم الختمة';

  @override
  String khatmahProgressValue(String completed, String total, String percent) {
    return '$completed من $total صفحة، $percent بالمئة';
  }

  @override
  String get khatmahSetupSaveError => 'تعذر بدء الختمة. حاول مرة أخرى.';

  @override
  String get khatmahEndError => 'تعذر إنهاء الختمة. حاول مرة أخرى.';

  @override
  String get khatmahDedicationPreference =>
      'إهداء الختمة متاح للحي والمتوفى، والمتوفى أولى، والله أعلى وأعلم.';

  @override
  String get khatmahWriteYourOwnNote => 'اكتب ملاحظتك الشخصية هنا';

  @override
  String get khatmahPhysicalRangeHint =>
      'سجّل نطاق الصفحات الذي قرأته من الصفحة التالية غير المقروءة.';

  @override
  String khatmahConfirmRange(String start, String end) {
    return 'سيتم تسجيل الصفحات من $start إلى $end شاملة الطرفين.';
  }

  @override
  String khatmahRangeValidation(String start) {
    return 'أدخل صفحة من $start إلى ٦٠٤ لتأكيد النطاق.';
  }

  @override
  String get khatmahIsPaused => 'الختمة متوقفة مؤقتاً';

  @override
  String get khatmahProgressNotSaved => 'لم يتم حفظ التقدم';

  @override
  String get khatmahSaving => 'جارٍ الحفظ…';

  @override
  String get khatmahDuaLoadError => 'تعذر تحميل الدعاء. حاول مرة أخرى.';

  @override
  String get khatmahSuggestedDua => 'دعاء عام مقترح بعد الختم';

  @override
  String get khatmahDuaPendingReview =>
      'مراجعة النص والمصدر معلّقة. هذا دعاء عام مقترح، وليس صيغة مخصوصة لازمة للختم أو منسوبة للنبي ﷺ. لم يوثّق مصدر هذا النص بعد.';

  @override
  String get khatmahGeneralGuidance => 'دعاء عام';

  @override
  String get khatmahRelationshipParent => 'والد / والدة';

  @override
  String get khatmahRelationshipMother => 'الأم';

  @override
  String get khatmahRecipientGender => 'المُهدى إليه';

  @override
  String get khatmahRecipientMale => 'ذكر';

  @override
  String get khatmahRecipientFemale => 'أنثى';

  @override
  String get khatmahEditDedication => 'تعديل الإهداء';

  @override
  String get khatmahDedicationSaved => 'حُفظ الإهداء';

  @override
  String khatmahWirdJuz(String juz) {
    return 'ورد اليوم: الجزء $juz';
  }

  @override
  String get khatmahRepeatSameSettings => 'ختمة جديدة بنفس الإعدادات';

  @override
  String khatmahHistoryStats(String count, String avg, String fastest) {
    return '$count ختمات • المتوسط $avg يوماً • الأسرع $fastest يوماً';
  }

  @override
  String get khatmahJuzMapTitle => 'خريطة الختمة';

  @override
  String khatmahJuzMapCell(String juz, String read, String total) {
    return 'الجزء $juz: $read من $total صفحة';
  }

  @override
  String get khatmahCatchUpTitle => 'كيف تحب أن تعوّض؟';

  @override
  String khatmahCatchUpOption(String pages, String date) {
    return '$pages صفحة يومياً — الختم $date';
  }

  @override
  String get khatmahRelationshipFather => 'الأب';

  @override
  String get khatmahRelationshipFriend => 'صديق';

  @override
  String get khatmahRelationshipRelative => 'قريب';

  @override
  String get khatmahRelationshipOther => 'أخرى';

  @override
  String get khatmahRecentCompletions => 'الختمات المكتملة حديثاً';

  @override
  String get khatmahHistoryEmpty => 'لا توجد شهادات ختمة محفوظة بعد.';

  @override
  String get khatmahHistoryLoadError =>
      'تعذر تحميل شهادات الختمة المحفوظة. حاول مرة أخرى.';

  @override
  String get khatmahHistoryCorrupt =>
      'بعض شهادات الختمة المحفوظة غير صالحة وتم حجبها. حاول مرة أخرى بعد استعادة بياناتك.';

  @override
  String get khatmahReopenCertificate => 'فتح الشهادة مجدداً';

  @override
  String khatmahCompletedOn(String date) {
    return 'اكتملت في $date';
  }

  @override
  String get brandName => 'تاليــة';

  @override
  String get xpLabel => 'XP';

  @override
  String countOfTotal(int count, int total) {
    return '$count من $total';
  }

  @override
  String get homeTodayTitle => 'اليوم';

  @override
  String get homeTodayReading => 'ورد القراءة';

  @override
  String get homeTodayMemorize => 'الحفظ';

  @override
  String get homeTodayReview => 'المراجعة';

  @override
  String get homeTodayAzkar => 'الأذكار';

  @override
  String get homeTodayDone => 'مكتمل';

  @override
  String get homeTodayTodo => 'متبقٍ';

  @override
  String get homeStreakAtRisk => 'سلسلتك في خطر';

  @override
  String homeFreezesAvailable(int count) {
    return '$count تجميد متاح';
  }

  @override
  String get homeAyahOfDay => 'آية اليوم';

  @override
  String get surahRevelationMeccan => 'مكية';

  @override
  String get surahRevelationMedinan => 'مدنية';

  @override
  String ayahOfDaySurahMeta(String revelation, int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText آية',
      many: '$countText آية',
      few: '$countText آيات',
      two: 'آيتان',
      one: 'آية واحدة',
      zero: '$countText آية',
    );
    return '$revelation، $_temp0';
  }

  @override
  String get ayahOfDayReadSurah => 'اقرأ السورة كاملة';

  @override
  String get homeAyahContextFriday => 'آية ليوم الجمعة';

  @override
  String get homeAyahContextRamadanStart => 'آية لبداية رمضان';

  @override
  String get homeAyahContextRamadan => 'آية لرمضان';

  @override
  String get homeAyahContextLastTenNights => 'آية للعشر الأواخر';

  @override
  String get homeAyahContextDhulHijjah => 'آية لأيام الحج';

  @override
  String get homeAyahContextArafah => 'آية ليوم عرفة';

  @override
  String get homeAyahContextEidAlAdha => 'آية لعيد الأضحى';

  @override
  String get homeAyahContextReading => 'آية لرحلة القراءة';

  @override
  String get homeAyahContextMemorization => 'آية لرحلة الحفظ';

  @override
  String get homeAyahContextSmartReview => 'آية للمراجعة';

  @override
  String get homeAyahContextAzkar => 'آية للأذكار';

  @override
  String get homeAyahContextChildJourney => 'آية لرحلة الطفل';

  @override
  String homeResumeListening(String surah) {
    return 'أكمل الاستماع، $surah';
  }

  @override
  String get homeSomethingElse => 'شيء آخر';

  @override
  String homeMinutes(String count) {
    return '$count د';
  }

  @override
  String get homeOccasionFriday => 'الجمعة، سورة الكهف';

  @override
  String get homeOccasionRamadan => 'رمضان';

  @override
  String get homeOccasionLastTenNights => 'العشر الأواخر';

  @override
  String get homeSlotFridayTitle => 'سورة الكهف';

  @override
  String get homeSlotFridayBody => 'يستحب قراءة سورة الكهف يوم الجمعة.';

  @override
  String get homeSlotRamadanTitle => 'قراءة رمضان';

  @override
  String get homeSlotRamadanBody => 'شهر مبارك — واصل وردك اليومي.';

  @override
  String get homeSlotLastTenTitle => 'العشر الأواخر';

  @override
  String get homeSlotLastTenBody =>
      'التمس ليلة القدر بمزيد من القراءة والقيام.';

  @override
  String get homeSlotStreakBody =>
      'سجّل نشاط اليوم قبل منتصف الليل لتحافظ على سلسلتك.';

  @override
  String get homeSlotKhatmahTitle => 'الختمة قاربت الاكتمال';

  @override
  String get homeSlotKhatmahBody => 'أنت قريب من إتمام هذه الختمة.';

  @override
  String get homeSlotOpen => 'افتح';

  @override
  String get homeWeeklyReflectionTitle => 'هذا الأسبوع';

  @override
  String homeWeeklyReflectionBody(int days, int count) {
    return '$days أيام نشاط، $count أعمال';
  }

  @override
  String get homeFirstRunTitle => 'ابدأ خطوتك الأولى';

  @override
  String get homeFirstRunBody => 'اقرأ صفحة، أو ابدأ الحفظ، أو ابدأ ختمة.';

  @override
  String get homeFirstRunRead => 'اقرأ القرآن';

  @override
  String get homeFirstRunMemorize => 'ابدأ الحفظ';

  @override
  String homeChildStreak(int count) {
    return 'سلسلة $count يوم';
  }

  @override
  String get homeSearchTitle => 'البحث في القرآن';

  @override
  String get homeSearchNoResults => 'لا توجد سور أو آيات مطابقة';

  @override
  String get homePrayerTimes => 'مواقيت الصلاة';

  @override
  String get homePrayerTimesEnabled => 'إظهار الصلاة التالية في الرئيسية';

  @override
  String get homePrayerCountry => 'البلد';

  @override
  String get homePrayerCity => 'المدينة';

  @override
  String get homePrayerMethod => 'طريقة الحساب';

  @override
  String get prayerMethodAuto => 'تلقائي حسب البلد';

  @override
  String homePrayerChip(String name, int minutes) {
    return '$name بعد $minutes د';
  }

  @override
  String prayerTimelineNext(String name, String timeRemaining) {
    return 'أذان $name خلال $timeRemaining';
  }

  @override
  String prayerTimelineSunriseNext(String timeRemaining) {
    return 'الشروق خلال $timeRemaining';
  }

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get prayerMethodMwl => 'رابطة العالم الإسلامي';

  @override
  String get prayerMethodEgyptian => 'الهيئة المصرية';

  @override
  String get prayerMethodUmmAlQura => 'أم القرى';

  @override
  String get prayerMethodKarachi => 'كراتشي';

  @override
  String get prayerMethodNorthAmerica => 'إسنا';

  @override
  String get prayerMethodDubai => 'دبي';

  @override
  String get prayerMethodKuwait => 'الكويت';

  @override
  String get prayerMethodQatar => 'قطر';

  @override
  String get prayerMethodSingapore => 'سنغافورة وماليزيا وإندونيسيا';

  @override
  String get prayerMethodTurkey => 'تركيا (رئاسة الشؤون الدينية)';

  @override
  String get prayerMethodMoonSighting => 'لجنة رؤية الهلال';

  @override
  String get prayerMadhabTitle => 'حساب وقت العصر';

  @override
  String get prayerCustomLocation => 'موقع مخصص (إحداثيات)';

  @override
  String get prayerCustomLatitude => 'خط العرض';

  @override
  String get prayerCustomLongitude => 'خط الطول';

  @override
  String get prayerCustomHint =>
      'مدينتك غير موجودة؟ انسخ إحداثياتها من تطبيق الخرائط.';

  @override
  String prayerCustomTimeZone(String zone) {
    return 'المنطقة الزمنية: $zone';
  }

  @override
  String get prayerCustomSave => 'حفظ الموقع';

  @override
  String get prayerCustomSaved =>
      'حُفظ الموقع. تُحسب مواقيت الصلاة الآن لإحداثياتك.';

  @override
  String get prayerCustomInvalid =>
      'تحقق من الإحداثيات: خط العرض بين ‎-90‎ و‎90‎، وخط الطول بين ‎-180‎ و‎180‎.';

  @override
  String get prayerCustomTimeZoneUnavailable =>
      'تعذّر تحديد المنطقة الزمنية لجهازك.';

  @override
  String get prayerMadhabAuto => 'تلقائي حسب المدينة';

  @override
  String get prayerMadhabShafi => 'الجمهور (الشافعي والمالكي والحنبلي)';

  @override
  String get prayerMadhabHanafi => 'الحنفي';

  @override
  String get homeBrandSubtitle => 'تالية القرآن';

  @override
  String homeWelcomeUser(String name) {
    return 'مرحبا بك $name';
  }

  @override
  String get homeContinueRecitation => 'أكمل تلاوتك';

  @override
  String get homeContinueAction => 'متابعة';

  @override
  String homeAyahRange(String start, String end) {
    return 'الآيات $start إلى $end';
  }

  @override
  String homeAyahProgressCount(
    String currentText,
    int total,
    String totalText,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalText آية',
      few: '$totalText آيات',
      two: 'آيتين',
      one: 'آية واحدة',
    );
    return '$currentText من $_temp0';
  }

  @override
  String homePageProgressCount(
    String currentText,
    int total,
    String totalText,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalText صفحة',
      few: '$totalText صفحات',
      two: 'صفحتين',
      one: 'صفحة واحدة',
    );
    return '$currentText من $_temp0';
  }

  @override
  String get homeTileListen => 'تسميع';

  @override
  String get homeTileListenHint => 'استمع وسمّع';

  @override
  String get homeTileReview => 'مراجعة';

  @override
  String get homeTileReviewHint => 'ثبّت ما حفظت';

  @override
  String get homeTileMemorize => 'حفظ';

  @override
  String get homeTileMemorizeHint => 'أضف آيات جديدة';

  @override
  String get homeTileRead => 'قراءة';

  @override
  String get homeTileReadHint => 'افتح المصحف';

  @override
  String get homeDailyChallenge => 'التحدي اليومي';

  @override
  String homeDailyChallengePages(int count) {
    return 'أكمل $count صفحات اليوم';
  }

  @override
  String get homeDailyChallengeTasks => 'أكمل مهام اليوم';

  @override
  String homeChallengeProgress(int current, int total) {
    return '$current من $total';
  }

  @override
  String homeStreakDays(int count) {
    return '$count يوم مواظبة';
  }

  @override
  String get homeQuranJourney => 'رحلتك مع القرآن';

  @override
  String get homeJourneyMemorization => 'الحفظ';

  @override
  String get homeJourneyKhatmah => 'الختمة';

  @override
  String homeJourneyMemorizedAyahs(int count) {
    return '$count آية محفوظة';
  }

  @override
  String homeJourneyKhatmahPages(int current, int total) {
    return '$current من $total صفحة';
  }

  @override
  String get homeJourneyNotStartedTitle => 'لم تبدأ رحلتك بعد';

  @override
  String get homeJourneyNotStartedBody =>
      'ابدأ الحفظ أو افتح ختمة، وسيتابع التطبيق تقدّمك الفعلي هنا';

  @override
  String get homeJourneyStartMemorization => 'ابدأ الحفظ';

  @override
  String get homeSurahsCompleted => 'مكتمل';

  @override
  String get homeSurahsInProgress => 'جاري';

  @override
  String get homeSurahsRemaining => 'متبقٍ';

  @override
  String get homeRecentActivity => 'نشاطك الأخير';

  @override
  String get homeActivityViewAll => 'عرض الكل';

  @override
  String get homeActivityEmpty => 'ابدأ القراءة أو الحفظ ليظهر نشاطك هنا';

  @override
  String get homeActivityReading => 'قراءة';

  @override
  String get homeActivityMemorize => 'حفظ';

  @override
  String get homeActivityReview => 'مراجعة';

  @override
  String get homeActivityKhatmah => 'ختمة';

  @override
  String get homeActivityJustNow => 'الآن';

  @override
  String homeActivityMinutesAgo(int count) {
    return 'قبل $count د';
  }

  @override
  String homeActivityHoursAgo(int count) {
    return 'قبل $count س';
  }

  @override
  String get homeActivityYesterday => 'أمس';

  @override
  String homeActivityDaysAgo(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $countText يوم',
      many: 'قبل $countText يومًا',
      few: 'قبل $countText أيام',
      two: 'قبل يومين',
      one: 'قبل يوم',
    );
    return '$_temp0';
  }

  @override
  String get homeActivityCompleted => 'مكتمل';

  @override
  String get homeFooterTagline => 'بالقرآن .. نحيا أجمل';

  @override
  String get quickNavTitle => 'تنقل سريع';

  @override
  String get quickNavGo => 'انتقال';

  @override
  String get quickNavPageHint => 'رقم الصفحة (1-604)';

  @override
  String get homeStartKhatmahTitle => 'ابدأ ختمتك القرآنية الآن';

  @override
  String get homeStartKhatmahSubtitle =>
      'رتّب وِردك اليومي وحدد مدة الختمة لتنال أجر التلاوة المستمرة';

  @override
  String get homeStartKhatmahCta => 'إنشاء ختمة جديدة';

  @override
  String get homeAchievementSheetTitle => 'إنجازاتك ومستواك';

  @override
  String get homeAchievementSheetSubtitle =>
      'واصل التلاوة والحفظ لترقية مستواك القرآني';

  @override
  String get homePrayerTimesSheetTitle => 'مواقيت الصلاة';

  @override
  String get prayerCompanionStatusConfirmed => 'تم التأكيد';

  @override
  String get prayerCompanionStatusUnconfirmedPast => 'لم يتم التأكيد بعد';

  @override
  String get prayerCompanionStatusUpcoming => 'قادمة';

  @override
  String get prayerCompanionStatusPrayNow => 'سأصلي الآن';

  @override
  String get prayerCompanionStatusRemindLater => 'تم ضبط تذكير';

  @override
  String get prayerCompanionStatusNotYet => 'ليس بعد';

  @override
  String get prayerCompanionActionConfirm => 'صليت';

  @override
  String get prayerCompanionActionPrayNow => 'سأصلي الآن';

  @override
  String get prayerCompanionActionRemindLater => 'ذكرني لاحقاً';

  @override
  String get prayerCompanionActionNotYet => 'ليس بعد';

  @override
  String prayerCompanionConfirmedCount(int confirmed, int total) {
    return 'تم تأكيد $confirmed من $total';
  }

  @override
  String prayerCompanionRowSemantics(String prayer, String status) {
    return '$prayer: $status';
  }

  @override
  String get prayerCompanionSettingsTitle => 'مرافق الصلاة';

  @override
  String get microReviewTitle => 'لمحة مراجعة';

  @override
  String get microReviewQuestion => 'من حفظك القديم… لسه فاكرها؟';

  @override
  String microReviewReference(String surah, String ayah) {
    return 'سورة $surah، آية $ayah';
  }

  @override
  String get microReviewRevealHint => 'جرّب تفتكرها… ثم اضغط لعرضها';

  @override
  String get microReviewRecite => 'سمّع نفسك';

  @override
  String get prayerSerenityTitle => 'وضع سكينة الصلاة';

  @override
  String get prayerSerenitySubtitle => 'نوقف التلاوة بهدوء عند دخول وقت الصلاة';

  @override
  String get prayerSerenityNotificationTitle => 'حان وقت اللقاء 🕌';

  @override
  String get prayerSerenityNotificationBody =>
      'أوقفنا التلاوة بهدوء… حان وقت الصلاة، تقبّل الله';

  @override
  String get prayerCompanionEnable => 'تفعيل مرافق الصلاة';

  @override
  String get prayerCompanionPreparation => 'تذكير الاستعداد';

  @override
  String get prayerCompanionPreparationDisabled => 'معطّل';

  @override
  String prayerCompanionMinutesValue(int minutes) {
    return '$minutes دقائق';
  }

  @override
  String get prayerCompanionCheckIn => 'تذكير بعد الصلاة';

  @override
  String get prayerCompanionCheckInSub =>
      'يصل تذكير لطيف بعد 20 دقيقة من وقت الصلاة.';

  @override
  String get prayerCompanionFollowUp => 'السماح بتذكير لاحق واحد';

  @override
  String get prayerCompanionFollowUpSub =>
      'يُرسل مرة واحدة عند اختيار «سأصلي الآن» أو «ذكرني لاحقاً».';

  @override
  String get prayerCompanionLocalOnly =>
      'تُحفظ تأكيداتك على هذا الجهاز فقط ولا تُرفع إلى أي خدمة سحابية.';

  @override
  String get prayerCompanionClear => 'مسح تأكيدات الصلاة';

  @override
  String get prayerCompanionClearSub =>
      'يحذف التأكيدات المحفوظة على هذا الجهاز.';

  @override
  String get prayerCompanionClearConfirmTitle => 'مسح التأكيدات؟';

  @override
  String get prayerCompanionClearConfirmBody =>
      'هل تريد مسح التأكيدات المحفوظة على هذا الجهاز؟';

  @override
  String get prayerCompanionClearConfirmButton => 'مسح';

  @override
  String get prayerCompanionClearCancel => 'إلغاء';

  @override
  String get prayerCompanionClearFailed =>
      'تعذّر مسح التأكيدات. حاول مرة أخرى.';

  @override
  String get prayerCompanionCleared => 'تم مسح التأكيدات.';

  @override
  String get weekdayMonday => 'الاثنين';

  @override
  String get weekdayTuesday => 'الثلاثاء';

  @override
  String get weekdayWednesday => 'الأربعاء';

  @override
  String get weekdayThursday => 'الخميس';

  @override
  String get weekdayFriday => 'الجمعة';

  @override
  String get weekdaySaturday => 'السبت';

  @override
  String get weekdaySunday => 'الأحد';

  @override
  String get notificationExactAlarmRequest => 'تفعيل التنبيهات الدقيقة';

  @override
  String get notificationExactAlarmExplanation =>
      'تضمن وصول تنبيه الصلاة والأذان في وقتهما بالضبط';

  @override
  String get notificationExactAlarmGranted =>
      'تم تفعيل دقة تنبيهات مواقيت الصلاة.';

  @override
  String get notificationExactAlarmDenied =>
      'ستصلك التنبيهات في وقتها تقريبًا بالوضع العادي، ويمكنك تفعيل الدقة الكاملة لاحقًا من إعدادات الهاتف.';

  @override
  String get notificationTestFailed =>
      'تعذر إرسال الإشعار. تحقّق من إذن الإشعارات في إعدادات الهاتف.';

  @override
  String get notificationQuietHours => 'الساعات الهادئة';

  @override
  String get notificationQuietHoursSub =>
      'ينقل التذكيرات العادية خارج الفترة المحددة. مواقيت الصلاة لا تتغير.';

  @override
  String get notificationQuietHoursStart => 'البداية';

  @override
  String get notificationQuietHoursEnd => 'النهاية';

  @override
  String get notificationSmartReminder => 'تذكير ذكي';

  @override
  String get notificationSmartReminderSub =>
      'يستخدم أوقات فتحك الأخيرة على الجهاز لاختيار وقت التذكير.';

  @override
  String memorizationHubReviewDueBadge(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText آية مستحقة للمراجعة',
      few: '$countText آيات مستحقة للمراجعة',
      two: 'آيتان مستحقتان للمراجعة',
      one: 'آية واحدة مستحقة للمراجعة',
    );
    return '$_temp0';
  }

  @override
  String get memorizationHubReviewDueNone => 'لا مراجعات مستحقة الآن';

  @override
  String dailyPlanNextReviewInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أيام',
      one: 'يوم',
      zero: 'اليوم',
    );
    return 'المراجعة القادمة بعد $_temp0';
  }

  @override
  String get dailyPlanStrengthWeak => 'حفظ ضعيف';

  @override
  String get dailyPlanStrengthLearning => 'قيد الترسيت';

  @override
  String get dailyPlanStrengthStrong => 'حفظ متين';

  @override
  String get memorizedPageAction => 'حفظ هذه الصفحة';

  @override
  String get memorizedPageSubtext => 'ابدأ جلسة حفظ لآيات الصفحة الحالية';

  @override
  String get memorizedPageUnavailable =>
      'حفظ الصفحة متاح عندما تنتمي كل آياتها لسورة واحدة.';

  @override
  String customPlanDirectionForward(String from, String to) {
    return 'اتجاه الحفظ: تصاعدي (من $from إلى $to)';
  }

  @override
  String customPlanDirectionBackward(String from, String to) {
    return 'اتجاه الحفظ: تنازلي (من $from إلى $to)';
  }

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String fieldTooLong(int maxLength) {
    return 'لا يمكن أن يتجاوز $maxLength حرفاً';
  }

  @override
  String get progressDueReviewsLabel => 'مراجعات مستحقة';

  @override
  String progressStreakDaysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوم',
      many: 'يوماً',
      few: 'أيام',
      two: 'يومان',
      one: 'يوم',
      zero: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get progressNextMilestoneTitle => 'إنجازك القادم';

  @override
  String progressNextMilestoneRemaining(int remaining) {
    return 'باقي $remaining للوصول';
  }

  @override
  String get progressAllAchievementsUnlocked =>
      'ما شاء الله! أتممت جميع الإنجازات، ثبّتك الله';

  @override
  String progressDueReviewsNudge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لديك $count آية مستحقة للمراجعة',
      few: 'لديك $count آيات مستحقة للمراجعة',
      two: 'لديك آيتان مستحقتان للمراجعة',
      one: 'لديك آية واحدة مستحقة للمراجعة',
    );
    return '$_temp0';
  }

  @override
  String get progressStartReview => 'ابدأ المراجعة';

  @override
  String progressActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم نشاط',
      many: '$count يوماً من النشاط',
      few: '$count أيام نشاط',
      two: 'يوما نشاط',
      one: 'يوم نشاط واحد',
      zero: 'لا توجد أيام نشاط بعد',
    );
    return '$_temp0';
  }

  @override
  String get progressXpToNextLevel => 'نحو المستوى التالي';
}
