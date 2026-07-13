// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Talia';

  @override
  String get home => 'Home';

  @override
  String get quran => 'Quran';

  @override
  String get hifz => 'Memorize';

  @override
  String get azkar => 'Azkar';

  @override
  String get progress => 'Progress';

  @override
  String get greetingMorning => 'Good Morning';

  @override
  String get greetingAfternoon => 'Good Afternoon';

  @override
  String get greetingEvening => 'Good Evening';

  @override
  String get greetingNight => 'Blessed Night';

  @override
  String get dailyWird => 'Daily Wird';

  @override
  String get continueReading => 'Continue Reading';

  @override
  String get startMemorizing => 'Start Memorizing';

  @override
  String get surahList => 'Surah List';

  @override
  String get surahDetails => 'Surah Details';

  @override
  String get juz => 'Juz';

  @override
  String get ayah => 'Ayah';

  @override
  String get ayahs => 'Ayahs';

  @override
  String get surah => 'Surah';

  @override
  String get surahs => 'Surahs';

  @override
  String get meccan => 'Meccan';

  @override
  String get medinan => 'Medinan';

  @override
  String get searchSurah => 'Search surah or ayah';

  @override
  String get memorization => 'Memorization';

  @override
  String get selectSurah => 'Select a Surah to Memorize';

  @override
  String get selectAyah => 'Select Ayah';

  @override
  String get startFrom => 'Start From';

  @override
  String get markMemorized => 'I\'ve Memorized This';

  @override
  String get nextAyah => 'Next Ayah';

  @override
  String get prevAyah => 'Previous Ayah';

  @override
  String get memorized => 'Memorized';

  @override
  String get review => 'Review';

  @override
  String get newAyah => 'New Ayah';

  @override
  String get hifzProgress => 'Memorization Progress';

  @override
  String get morningAzkar => 'Morning Azkar';

  @override
  String get eveningAzkar => 'Evening Azkar';

  @override
  String get generalAzkar => 'General Azkar';

  @override
  String get duas => 'Duas';

  @override
  String get count => 'Count';

  @override
  String get done => 'Done';

  @override
  String get reset => 'Reset';

  @override
  String get overallProgress => 'Overall Progress';

  @override
  String get streak => 'Streak';

  @override
  String get days => 'Days';

  @override
  String get day => 'Day';

  @override
  String get achievements => 'Achievements';

  @override
  String get yourStreak => 'Your Streak';

  @override
  String get quranProgress => 'Quran Progress';

  @override
  String get memorizedSurahs => 'Memorized Surahs';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get loading => 'Loading...';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noData => 'No data found';

  @override
  String get emptyState => 'Nothing here yet';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get ofLabel => 'of';

  @override
  String get completed => 'Completed';

  @override
  String get inProgress => 'In Progress';

  @override
  String get notStarted => 'Not Started';

  @override
  String get bismillah => 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  @override
  String get basmala => 'Basmala';

  @override
  String get streakMessage1 => 'Keep going, you\'re on track!';

  @override
  String get streakMessage2 => 'Amazing! Another day with the Quran';

  @override
  String get streakMessage3 => 'MashaAllah! Incredible consistency';

  @override
  String get achievementFirstSurah => 'First Surah Memorized';

  @override
  String get achievementWeekStreak => 'Full Week Streak';

  @override
  String get achievementQuran10 => '10% of the Quran';

  @override
  String get fontSize => 'Font Size';

  @override
  String get small => 'Small';

  @override
  String get medium => 'Medium';

  @override
  String get large => 'Large';

  @override
  String get extraLarge => 'Extra Large';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get tafsir => 'Tafsir';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get undo => 'Undo';

  @override
  String get copied => 'Copied';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get name => 'Name';

  @override
  String get age => 'Age';

  @override
  String get enterName => 'Enter your name';

  @override
  String get enterAge => 'Enter your age';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get shareAchievement => 'Share Achievement';

  @override
  String shareAchievementText(Object description, Object title) {
    return '🏆 A new milestone in my Quran journey: \"$title\"\n📖 $description\n\nWith Talia, every step becomes visible progress and an achievement worth sharing.';
  }

  @override
  String shareAchievementWithName(
    Object description,
    Object name,
    Object title,
  ) {
    return '🏆 A new milestone in $name\'s Quran journey: \"$title\"\n📖 $description\n\nWith Talia, every step becomes visible progress and an achievement worth sharing.';
  }

  @override
  String shareMemorizationAchievementText(Object description, Object title) {
    return '🌟 A blessed memorization milestone: \"$title\"\n🧠 $description\n\nTalia supports the memorization journey with clear structure, steady motivation, and progress worth celebrating.';
  }

  @override
  String shareMemorizationAchievementWithName(
    Object description,
    Object name,
    Object title,
  ) {
    return '🌟 A blessed memorization milestone for $name: \"$title\"\n🧠 $description\n\nTalia supports the memorization journey with clear structure, steady motivation, and progress worth celebrating.';
  }

  @override
  String get shareProgress => 'Share Progress';

  @override
  String shareProgressText(Object ayahs, Object pages, Object streak) {
    return '📊 Here is a snapshot of my Quran journey with Talia:\n📖 $pages pages read\n🧠 $ayahs ayahs memorized\n🔥 $streak days of consistency\n\nTalia helps turn daily effort into a steady Quran habit with clear progress and meaningful motivation.';
  }

  @override
  String shareProgressWithName(
    Object ayahs,
    Object name,
    Object pages,
    Object streak,
  ) {
    return '📊 Here is a snapshot of $name\'s Quran journey with Talia:\n📖 $pages pages read\n🧠 $ayahs ayahs memorized\n🔥 $streak days of consistency\n\nTalia helps turn daily effort into a steady Quran habit with clear progress and meaningful motivation.';
  }

  @override
  String get viewAll => 'View All';

  @override
  String get reading => 'Reading';

  @override
  String get page => 'Page';

  @override
  String get pages => 'Pages';

  @override
  String get pagesRead => 'Pages Read';

  @override
  String get readingProgress => 'Reading Progress';

  @override
  String get memorizationProgressTitle => 'Memorization Progress';

  @override
  String get smartMemorization => 'Smart Memorization';

  @override
  String get smartMemorizationSubtitle =>
      'Adaptive plan • Smart review • Self-assess';

  @override
  String get recitationAccuracy => 'Recitation Accuracy';

  @override
  String get notifications => 'Notifications';

  @override
  String get about => 'About';

  @override
  String get systemDefault => 'System Default';

  @override
  String get changeMemorizationPath => 'Change Memorization Path';

  @override
  String get adultPath => 'Adult Path';

  @override
  String get adultPathDesc => 'Start from Al-Fatihah and Al-Baqarah';

  @override
  String get beginnerPath => 'Beginner Path';

  @override
  String get beginnerPathDesc => 'Start from Juz Amma (An-Nas) backwards';

  @override
  String get chooseMemorizationPath => 'Choose your memorization path';

  @override
  String get audioPlayError => 'Failed to play audio. Check your connection.';

  @override
  String get micPermissionError =>
      'The app needs microphone permission for voice recitation. Please allow it from device settings.';

  @override
  String get speechUnavailableError =>
      'Voice recitation is unavailable on this device right now.';

  @override
  String get openSettingsAction => 'Open Settings';

  @override
  String get account => 'Account';

  @override
  String get accuracyLevel => 'Accuracy Level';

  @override
  String get streakProtection => 'Streak Protection';

  @override
  String get morningAzkarReminder => 'Morning Azkar Reminder';

  @override
  String get eveningAzkarReminder => 'Evening Azkar Reminder';

  @override
  String get dailyDuaReminder => 'Daily Dua';

  @override
  String get dailyDuaTime => 'Everyday at 9:00 AM';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get createAccount => 'Create Account';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordTooShort => 'At least 6 characters';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get loginSuccess => 'Signed in successfully ✓';

  @override
  String get signupSuccess => 'Account created successfully ✓';

  @override
  String get confirmationEmailSent =>
      '✅ Confirmation email sent. Check your inbox';

  @override
  String get resendConfirmation => 'Resend';

  @override
  String get authEmailAlreadyRegistered =>
      'This email is already registered. Try signing in.';

  @override
  String get authConfirmEmailFirst =>
      'Please confirm your email first. Check your inbox.';

  @override
  String get authInvalidCredentials => 'Email or password is incorrect';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Please wait and try again.';

  @override
  String get authNoInternet => 'No internet connection';

  @override
  String get authAccountNotFound => 'No account found for this email';

  @override
  String get authSignupFailed => 'Failed to create account';

  @override
  String get authSigninFailed => 'Failed to sign in';

  @override
  String get authSignoutFailed => 'Failed to sign out';

  @override
  String get authGenericError => 'Something went wrong. Try again.';

  @override
  String get authPasswordSameAsOld => 'Password must be different.';

  @override
  String get authSessionExpired =>
      'Session expired. Please request a new link.';

  @override
  String get profileSavedToCloud => 'Signed in to your account';

  @override
  String get guestModeWarning =>
      'Sign in to manage your account, recovery, and family features.';

  @override
  String get signOutWarning =>
      'Do you want to sign out? Local progress on this device will remain available.';

  @override
  String get dailyReviewReminder => 'Daily Review Reminder';

  @override
  String get dailyReviewTime => 'Everyday at 8:00 PM';

  @override
  String get streakProtectionDesc => 'Alert at 10:00 PM if no review';

  @override
  String get morningAzkarTime => 'Everyday at 6:00 AM';

  @override
  String get eveningAzkarTime => 'Everyday at 6:00 PM';

  @override
  String get taliaDescription =>
      'A premium app for memorizing and reviewing the Holy Quran';

  @override
  String get settingsAppBrand => 'Talia';

  @override
  String get tutorialGuideTitle => 'Talia user guide';

  @override
  String get tutorialGuideSubtitle => 'Learn every feature and how to use it';

  @override
  String get arabicNameHint =>
      '💡 It is better to enter the name in Arabic to appear nicely in certificates';

  @override
  String get invalidAge => 'Enter a valid age between 1 and 120';

  @override
  String get profileSaveError => 'Failed to save profile';

  @override
  String get accuracySaveError => 'Failed to save accuracy level';

  @override
  String get reviewReminderSaveError => 'Failed to update review reminder';

  @override
  String get streakReminderSaveError => 'Failed to update streak alert';

  @override
  String get morningAzkarSaveError => 'Failed to update morning Azkar reminder';

  @override
  String get eveningAzkarSaveError => 'Failed to update evening Azkar reminder';

  @override
  String get dailyDuaSaveError => 'Failed to update daily dua reminder';

  @override
  String get difficultyEasy => 'Easy (70%)';

  @override
  String get difficultyMedium => 'Medium (85%)';

  @override
  String get difficultyHard => 'Hard (92%)';

  @override
  String get bookmarkSaved => 'Bookmark saved';

  @override
  String get bookmarkAdded => 'Bookmark added ✓';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelStudent => 'Student';

  @override
  String get levelHafez => 'Hafez';

  @override
  String get levelSheikh => 'Sheikh';

  @override
  String get levelImam => 'Imam';

  @override
  String get juzCountLabel => 'Juz';

  @override
  String get ayahsRead => 'Ayahs Read';

  @override
  String get learning => 'Learning';

  @override
  String get reviewing => 'Review';

  @override
  String get all => 'All';

  @override
  String get streakTerm => 'Streak';

  @override
  String get achieved => 'Achieved!';

  @override
  String get adultsTrack => 'Adults Track';

  @override
  String get memorizedTerm => 'Memorized';

  @override
  String get reviewingPrefix => 'Reviewing: ';

  @override
  String get kidsTrack => 'Kids Track';

  @override
  String get points => 'Points';

  @override
  String get stars => 'Stars';

  @override
  String get myCertificates => 'My Certificates';

  @override
  String get juzSaved => 'Memorized Juz';

  @override
  String get removeBookmarkTitle => 'Remove bookmark?';

  @override
  String get goBack => 'Go Back';

  @override
  String get taliaUser => 'Talia User';

  @override
  String get startFatihah => 'Start reading Surah Al-Fatihah';

  @override
  String surahAyahFormat(Object surahName, Object ayahNumber) {
    return 'Surah $surahName, Ayah $ayahNumber';
  }

  @override
  String get saveProgress => 'Save your progress';

  @override
  String get syncProgressDesc =>
      'Sign in to manage your account, recovery, and family features';

  @override
  String get later => 'Later';

  @override
  String get congratulations => 'Congratulations!';

  @override
  String get completedJuzAmma => 'You have successfully memorized Juz Amma.';

  @override
  String get completedQuran =>
      'You have successfully memorized the entire Holy Quran.';

  @override
  String get continueMemorizing => 'Continue Memorizing';

  @override
  String get view => 'View';

  @override
  String get endSessionTitle => 'End Session?';

  @override
  String get endSessionDesc =>
      'Are you sure you want to end the session? Your current progress will be lost.';

  @override
  String get continueAction => 'Continue';

  @override
  String get exitAction => 'Exit';

  @override
  String get listen => 'Listen';

  @override
  String get finish => 'Finish';

  @override
  String get skip => 'Skip';

  @override
  String get tryAgainAction => 'Try Again';

  @override
  String get youRecited => 'You recited:';

  @override
  String get listeningInProgress => 'Listening...';

  @override
  String get tapToRecord => 'Tap to recite';

  @override
  String get adultPathTitle => 'Adult Path (Forward)';

  @override
  String get adultPathSubtitle => 'Al-Fatihah to An-Nas';

  @override
  String get beginnerPathTitle => 'Beginner Path (Backward)';

  @override
  String get beginnerPathSubtitle => 'An-Nas to Al-Fatihah';

  @override
  String get lockedSurahText => 'Complete the previous Surah to unlock';

  @override
  String bestStreak(Object count) {
    return 'Best: $count';
  }

  @override
  String get consecutiveDays => 'Consecutive days';

  @override
  String miniProgressOf(Object total, Object unit) {
    return '$unit of $total';
  }

  @override
  String dailyPlanSummary(Object ayahs, Object minutes) {
    return '$ayahs ayahs daily • $minutes min';
  }

  @override
  String get debugCertificatePreview => 'Debug: Certificate Preview';

  @override
  String get debugCertificatePreviewDesc =>
      'Test certificate rendering without earning one.';

  @override
  String get debugCertJuz30 => 'Juz 30';

  @override
  String get debugCertSurahBaqarah => 'Surah Al-Baqarah';

  @override
  String get debugCertHalfQuran => 'Half Quran';

  @override
  String get debugCertFullQuran => 'Full Quran';

  @override
  String get backupProgressTitle => 'Manage your account';

  @override
  String get backupProgressDesc =>
      'Sign in from Settings to manage your account and family features';

  @override
  String get azkarSubtitle => 'Remember Allah often';

  @override
  String zikrCount(Object count) {
    return '$count zikr';
  }

  @override
  String azkarCount(Object count) {
    return '$count azkar';
  }

  @override
  String duaCount(Object count) {
    return '$count duas';
  }

  @override
  String get azkarIndex => 'Azkar Index';

  @override
  String zikrNumber(Object number) {
    return 'Zikr #$number';
  }

  @override
  String completedCount(Object completed, Object total) {
    return '$completed of $total completed';
  }

  @override
  String get zikrCopied => 'Zikr copied';

  @override
  String get sharedFromTalia => 'Shared from Talia Quran';

  @override
  String get zikrCompleted => 'Zikr completed';

  @override
  String tapToTasbeeh(Object total) {
    return 'Tap to count (of $total)';
  }

  @override
  String get azkarCompletedTitle => 'Completed, by Allah\'s grace';

  @override
  String get azkarCompletedDesc => 'All azkar in this category are complete';

  @override
  String get generalAzkarSubtitle => 'A collection of comprehensive azkar';

  @override
  String get duasSubtitle => 'Duas from the Quran and Sunnah';

  @override
  String totalSurahsAyahs(Object ayahs, Object surahs) {
    return '$surahs Surahs • $ayahs Ayahs';
  }

  @override
  String get yearActivity => 'Year activity';

  @override
  String activityTooltip(Object count) {
    return '$count activities';
  }

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String get memorizedAyahs => 'Ayahs Memorized';

  @override
  String get startedAyahsLabel => 'Ayahs Started';

  @override
  String get reviewedAyahsTotalLabel => 'Total Reviews';

  @override
  String get overdueReviewsLabel => 'Overdue Reviews';

  @override
  String get retentionRateLabel => 'Retention Rate';

  @override
  String get lastReviewLabel => 'Last review';

  @override
  String get lastMemorizedLabel => 'Last memorized';

  @override
  String get homeEngagementTitle => 'Your activity';

  @override
  String get homeWeeklyActivityLabel => 'This week';

  @override
  String get homeDueTodayLabel => 'Due today';

  @override
  String get homeXpLevelLabel => 'Level';

  @override
  String get homeActivityHeatmapTitle => 'Activity heatmap';

  @override
  String get memorizedSurahsLabel => 'Surahs Memorized';

  @override
  String get memorizedJuzLabel => 'Juz Memorized';

  @override
  String get earnCertificatesHint =>
      'Memorize complete Surahs and Juz to earn certificates!';

  @override
  String certificateTitleJuz(Object juz) {
    return 'Juz $juz Certificate';
  }

  @override
  String get certificateTitleSurah => 'Surah Certificate';

  @override
  String certificateTitleSurahNamed(Object surahName) {
    return 'Surah $surahName Certificate';
  }

  @override
  String get certificateTitleHalfQuran => 'Half Quran Certificate';

  @override
  String get certificateTitleFullQuran => 'Full Quran Certificate';

  @override
  String get saveFormatTitle => 'Choose save format';

  @override
  String get saveAsImage => 'Save as image (Gallery)';

  @override
  String get saveAsPdf => 'Save as PDF';

  @override
  String get certificateShareError => 'An error occurred while sharing';

  @override
  String get certificateGalleryPermissionError =>
      'Gallery permission is required to save the certificate';

  @override
  String get certificateGallerySaveSuccess => 'Certificate saved to gallery ✓';

  @override
  String get certificateSaveError => 'An error occurred while saving';

  @override
  String get certificatePdfError => 'An error occurred while creating the PDF';

  @override
  String get certificateNotFound => 'Certificate not found';

  @override
  String shareCertificateJuz(Object juz) {
    return 'By Allah\'s grace, I memorized Juz $juz of the Holy Quran 📖\nJoin me on Talia for Quran memorization 🌙';
  }

  @override
  String shareCertificateSurah(Object surahName) {
    return 'By Allah\'s grace, I memorized Surah $surahName of the Holy Quran 📖\nJoin me on Talia for Quran memorization 🌙';
  }

  @override
  String get shareCertificateHalfQuran =>
      'By Allah\'s grace, I memorized half of the Holy Quran 📖\nJoin me on Talia for Quran memorization 🌙';

  @override
  String get shareCertificateFullQuran =>
      'By Allah\'s grace, I memorized the entire Holy Quran 📖\nJoin me on Talia for Quran memorization 🌙';

  @override
  String get achievementTitleFirstPage => 'First Page';

  @override
  String get achievementDescFirstPage => 'Read your first page of the Quran';

  @override
  String get achievementTitleTenPages => '10 Pages';

  @override
  String get achievementDescTenPages => 'Read 10 pages of the Quran';

  @override
  String get achievementTitleFiftyPages => '50 Pages';

  @override
  String get achievementDescFiftyPages => 'Read 50 pages of the Quran';

  @override
  String get achievementTitleJuzRead => 'Complete Juz';

  @override
  String get achievementDescJuzRead => 'Read one complete Juz (20 pages)';

  @override
  String get achievementTitleFiveJuzRead => '5 Juz';

  @override
  String get achievementDescFiveJuzRead => 'Read 5 Juz of the Quran';

  @override
  String get achievementTitleHalfQuranRead => 'Half Quran';

  @override
  String get achievementDescHalfQuranRead => 'Read half of the Holy Quran';

  @override
  String get achievementTitleFullQuranRead => 'Complete Quran';

  @override
  String get achievementDescFullQuranRead => 'Read the entire Holy Quran';

  @override
  String get achievementTitleFirstAyah => 'First Ayah';

  @override
  String get achievementDescFirstAyah =>
      'Memorize your first ayah of the Quran';

  @override
  String get achievementTitleTenAyahs => '10 Ayahs';

  @override
  String get achievementDescTenAyahs => 'Memorize 10 ayahs';

  @override
  String get achievementTitleFiftyAyahs => '50 Ayahs';

  @override
  String get achievementDescFiftyAyahs => 'Memorize 50 ayahs';

  @override
  String get achievementTitleHundredAyahs => '100 Ayahs';

  @override
  String get achievementDescHundredAyahs => 'Memorize 100 ayahs';

  @override
  String get achievementTitleFirstSurah => 'First Surah';

  @override
  String get achievementDescFirstSurah => 'Memorize a complete Surah';

  @override
  String get achievementTitleFiveSurahs => '5 Surahs';

  @override
  String get achievementDescFiveSurahs => 'Memorize 5 complete Surahs';

  @override
  String get achievementTitleTenSurahs => '10 Surahs';

  @override
  String get achievementDescTenSurahs => 'Memorize 10 complete Surahs';

  @override
  String get achievementTitleJuzAmma => 'Juz Amma';

  @override
  String get achievementDescJuzAmma => 'Memorize 564 ayahs (Juz Amma)';

  @override
  String get achievementTitleOneJuzMemorized => 'Memorized Juz';

  @override
  String get achievementDescOneJuzMemorized => 'Memorize one complete Juz';

  @override
  String get achievementTitleFiveJuzMemorized => '5 Memorized Juz';

  @override
  String get achievementDescFiveJuzMemorized => 'Memorize 5 Juz of the Quran';

  @override
  String get achievementTitleTenJuzMemorized => '10 Juz';

  @override
  String get achievementDescTenJuzMemorized => 'Memorize 10 Juz of the Quran';

  @override
  String get achievementTitleHalfQuranMemorized => 'Half Quran';

  @override
  String get achievementDescHalfQuranMemorized =>
      'Memorize half of the Holy Quran';

  @override
  String get achievementTitleFullQuranMemorized => 'Hafiz of Quran';

  @override
  String get achievementDescFullQuranMemorized =>
      'Memorize the entire Holy Quran';

  @override
  String get achievementTitleThreeDayStreak => '3-Day Streak';

  @override
  String get achievementDescThreeDayStreak => 'Keep a 3-day streak';

  @override
  String get achievementTitleWeekStreak => 'Full Week';

  @override
  String get achievementDescWeekStreak => 'Keep a 7-day streak';

  @override
  String get achievementTitleTwoWeekStreak => 'Two Weeks';

  @override
  String get achievementDescTwoWeekStreak => 'Keep a 14-day streak';

  @override
  String get achievementTitleMonthStreak => 'Full Month';

  @override
  String get achievementDescMonthStreak => 'Keep a 30-day streak';

  @override
  String get achievementTitleNinetyDayStreak => '90 Days';

  @override
  String get achievementDescNinetyDayStreak => 'Keep a 90-day streak';

  @override
  String get achievementTitleYearStreak => 'Full Year';

  @override
  String get achievementDescYearStreak => 'Keep a 365-day streak';

  @override
  String bookmarksCountItem(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bookmarks',
      one: 'bookmark',
    );
    return '$count $_temp0';
  }

  @override
  String get memorizationPathReset => 'Memorization path has been reset';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionQuranMemorization => 'Quran & Memorization';

  @override
  String get settingsSectionKidsGuardian => 'Kids & Guardian';

  @override
  String get settingsSectionProgressAchievements => 'Progress & Achievements';

  @override
  String get settingsSectionHelpTutorial => 'Help & Tutorial';

  @override
  String get settingsSectionPrivacySecurity => 'Privacy & Security';

  @override
  String get settingsSectionAboutTalia => 'About Talia';

  @override
  String get settingsGuestStatusTitle => 'Using Talia as guest';

  @override
  String get settingsGuestStatusSubtitle =>
      'Your local progress remains on this device. Create an account for account management and family features.';

  @override
  String get settingsSignInCreateAccount => 'Sign in / Create account';

  @override
  String get settingsSignedInStatus => 'Signed in to your account';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'How your data and privacy are handled';

  @override
  String get settingsMemorizationPathNotSelected => 'No path selected';

  @override
  String get settingsMemorizationPathNotSelectedDesc =>
      'Choose adult or kids memorization when you start Memorization Plus.';

  @override
  String get settingsResetPathKeeps =>
      'Keeps: achievements, history, and certificates';

  @override
  String get settingsResetPathChanges =>
      'Changes: selected path and current plan';

  @override
  String get settingsResetPathInstruction => 'Type \"Reset path\" to confirm.';

  @override
  String get settingsResetPathConfirmPhrase => 'Reset path';

  @override
  String get settingsDeleteAccountTitle => 'Delete account';

  @override
  String get settingsDeleteAccountSubtitle => 'Deletes the cloud account only';

  @override
  String settingsDeleteAccountWarning(Object email) {
    return 'This deletes the Supabase account for $email and its cloud data.\n\nLocal Quran, Hifz, Kids, and Smart memorization progress on this device will not be deleted.\n\nDo you want to continue?';
  }

  @override
  String get settingsAccountDeletedMessage =>
      'Cloud account deleted. Your local progress remains on this device.';

  @override
  String settingsVersion(Object version) {
    return 'Version $version';
  }

  @override
  String settingsBuild(Object buildNumber) {
    return 'Build $buildNumber';
  }

  @override
  String get resetMemorizationPath => 'Reset / Change path';

  @override
  String get memorizationPath => 'Memorization Path';

  @override
  String get kidsAndGuardian => 'Kids and Guardian';

  @override
  String get parentDashboardTitle => 'Parent Dashboard';

  @override
  String get parentDashboardSubtitle =>
      'Track your child\'s memorization, rewards, and remote link';

  @override
  String get parentModeSubtitle =>
      'Enable this to follow your child\'s memorization and remote link';

  @override
  String get resetMemorizationPathQuestion => 'Reset memorization path?';

  @override
  String get resetMemorizationIdentityWarning =>
      'This will clear the selected path and guardian link state, while keeping your smart memorization settings.';

  @override
  String get confirmResetMemorizationPath => 'Confirm reset';

  @override
  String get resetMemorizationPathTileTitle => 'Reset path';

  @override
  String get resetMemorizationPathTileSubtitle =>
      'Choose the adult or kids path again without losing smart memorization settings.';

  @override
  String get resetMemorizationPathPreserveProgressDesc =>
      'Switch between the adult and kids memorization paths while keeping your memorization data.';

  @override
  String get resetMemorizationPathPreserveProgressDialog =>
      'This will clear the current memorization path so you can choose a new one. Your memorized ayahs will not be lost.';

  @override
  String completePreviousSurahFirst(Object surahName) {
    return 'Complete $surahName first';
  }

  @override
  String get linkGuardianNow => 'Link guardian now';

  @override
  String get continueWithoutGuardian => 'Continue without guardian';

  @override
  String get guardianLinkTitle => 'Link guardian account';

  @override
  String get guardianLinkDesc =>
      'Choose whether to link a guardian to this path so they can follow the child\'s memorization.';

  @override
  String get guardianCreateCodeMessage =>
      'Create a new code valid for 15 minutes.';

  @override
  String get guardianCodeUsedMessage => 'This code cannot be used again.';

  @override
  String get guardianCreateNewCode => 'Create new code';

  @override
  String get guardianCodeExpired => 'Code expired';

  @override
  String get guardianCodeAlreadyUsed => 'Code already used';

  @override
  String guardianPairingValidUntil(Object time) {
    return 'Valid until $time';
  }

  @override
  String guardianPairingExpiresIn(int minutes) {
    return 'Expires in $minutes min';
  }

  @override
  String get guardianPairingExpired => 'Code expired';

  @override
  String get guardianPairingStepsTitle => 'Pairing steps';

  @override
  String get guardianPairingStepOpenParentDevice =>
      'Open Talia on the guardian device';

  @override
  String get guardianPairingStepOpenDashboard =>
      'Go to Settings > Guardian Dashboard';

  @override
  String get guardianPairingStepScanOrEnterCode =>
      'Scan the QR code or enter the code manually';

  @override
  String get guardianRegenerateCode => 'Regenerate code';

  @override
  String get guardianSignInRequired =>
      'Sign in to access guardian tools. Your local progress remains on this device.';

  @override
  String get guardianSignInAction => 'Sign in or create account';

  @override
  String get guardianGuestContinueKids => 'Continue Kids memorization';

  @override
  String get guardianLinkingTemporarilyBlocked => 'Linking temporarily blocked';

  @override
  String get guardianLinkingFailedTitle => 'Failed to link guardian';

  @override
  String get guardianLinkingTimeoutMessage =>
      'Guardian linking took too long. Check your connection and try again, or continue without guardian for now.';

  @override
  String get splashSubtitle =>
      'Read, memorize, review, and grow with the Quran.';

  @override
  String get splashFeatureRead => 'Read';

  @override
  String get splashFeatureMemorize => 'Memorize';

  @override
  String get splashFeatureReview => 'Review';

  @override
  String get splashFeatureGrow => 'Grow';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Talia';

  @override
  String get onboardingWelcomeSubtitle =>
      'A complete Quran journey for daily reading, memorization, review, Azkar, and steady progress.';

  @override
  String get onboardingUserTypeTitle => 'Who is using Talia?';

  @override
  String get onboardingUserTypeSubtitle =>
      'Choose the experience that fits this device. You can change memorization paths later from settings.';

  @override
  String get onboardingUserTypeAdult => 'Adult';

  @override
  String get onboardingUserTypeAdultDesc =>
      'A focused Quran workspace for reading, memorization, review, and progress.';

  @override
  String get onboardingUserTypeChild => 'Child';

  @override
  String get onboardingUserTypeChildDesc =>
      'A simpler memorization journey with missions, repetition, stars, and rewards.';

  @override
  String get onboardingMainGoalTitle => 'Choose your main goal';

  @override
  String get onboardingMainGoalSubtitle =>
      'This sets the first destination after setup. The rest of Talia remains available.';

  @override
  String get onboardingGoalDailyReading => 'Daily Reading';

  @override
  String get onboardingGoalDailyReadingDesc =>
      'Start with the Quran reader and a clear daily portion.';

  @override
  String get onboardingGoalMemorizationDesc =>
      'Set up Memorization Plus for a structured adult path.';

  @override
  String get onboardingGoalSmartReview => 'Review / Improve retention';

  @override
  String get onboardingGoalSmartReviewDesc =>
      'Save review as your goal and start from the existing memorization setup.';

  @override
  String get onboardingGoalAzkarDesc =>
      'Begin with morning, evening, and general Azkar.';

  @override
  String get onboardingGoalKidsJourney => 'Kids Quran Journey';

  @override
  String get onboardingGoalKidsJourneyDesc =>
      'Start the child-friendly Quran memorization path.';

  @override
  String get onboardingGoalKidsRewards => 'Memorization with rewards';

  @override
  String get onboardingGoalKidsRewardsDesc =>
      'Use listening, repetition, points, and stars to encourage consistency.';

  @override
  String get onboardingSmartReviewNoteTitle => 'Review setup';

  @override
  String get onboardingSmartReviewNoteDesc =>
      'Talia will save review as your goal and route you to the existing memorization setup. A separate Smart Coach is not enabled in this step.';

  @override
  String get onboardingHighlightsTitle => 'What Talia includes';

  @override
  String get onboardingHighlightsAdultSubtitle =>
      'A focused set of tools for steady Quran habits.';

  @override
  String get onboardingHighlightsChildSubtitle =>
      'A protected child journey with local guest access.';

  @override
  String get onboardingFeatureQuranReader => 'Quran reader';

  @override
  String get onboardingFeatureQuranReaderDesc =>
      'Read from a respectful Mushaf-style experience.';

  @override
  String get onboardingFeatureMemorizationPlus => 'Memorization Plus';

  @override
  String get onboardingFeatureMemorizationPlusDesc =>
      'Use plans, daily practice, and review-adjacent tools.';

  @override
  String get onboardingFeatureKidsJourney => 'Kids gamified journey';

  @override
  String get onboardingFeatureKidsJourneyDesc =>
      'Guide children through small missions with rewards.';

  @override
  String get onboardingFeatureProgressCertificates =>
      'Progress and certificates';

  @override
  String get onboardingFeatureProgressCertificatesDesc =>
      'Track visible progress and celebrate milestones.';

  @override
  String get onboardingFeatureAzkar => 'Azkar';

  @override
  String get onboardingFeatureAzkarDesc =>
      'Keep daily remembrance close to your Quran routine.';

  @override
  String get onboardingFeatureGuardian => 'Guardian linking';

  @override
  String get onboardingFeatureGuardianDesc =>
      'Guardian follow-up requires sign-in, while child guest mode remains available.';

  @override
  String get onboardingFinalTitle => 'Final setup';

  @override
  String get onboardingFinalSubtitle =>
      'Confirm your path and choose whether to continue locally or sign in.';

  @override
  String get onboardingSummaryUserType => 'User type';

  @override
  String get onboardingSummaryGoal => 'Main goal';

  @override
  String get onboardingGuardianNoteTitle => 'Guardian follow-up';

  @override
  String get onboardingGuardianNoteDesc =>
      'Guardian linking requires sign-in. A child can still continue as a guest on this device.';

  @override
  String get onboardingContinueAsGuest => 'Continue as guest';

  @override
  String get onboardingSignInCreate => 'Sign in / Create account';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStartNow => 'Start now';

  @override
  String get onboardingQuranTitle => 'A real Mushaf experience';

  @override
  String get onboardingQuranDesc =>
      'Read the Holy Quran in an experience that feels close to the printed Mushaf, with familiar pages and respectful visual design.';

  @override
  String get onboardingSmartTitle => 'Smart memorization and review';

  @override
  String get onboardingSmartDesc =>
      'Flexible memorization plans, smart reviews, and self-rating help you strengthen ayahs without pressure.';

  @override
  String get onboardingKidsTitle => 'A joyful journey for kids';

  @override
  String get onboardingKidsDesc =>
      'A simple kids path with listening, repetition, stars, and guardian follow-up.';

  @override
  String get memorizationPathTitle => 'Memorization path';

  @override
  String get memorizationPathQuestion => 'Who will use this feature?';

  @override
  String get memorizationPathDescription =>
      'Choose the path that fits you or your child for a personalized memorization experience.';

  @override
  String get memorizationPathAdultsTitle => 'Adult path';

  @override
  String get memorizationPathAdultsDesc =>
      'A flexible memorization plan with smart review and daily progress tracking.';

  @override
  String get memorizationPathKidsTitle => 'Kids path';

  @override
  String get memorizationPathKidsDesc =>
      'A fun interactive memorization journey with guardian supervision.';

  @override
  String get kidsJourneyTitle => 'Memorization journey';

  @override
  String get kidsJourneySubtitle =>
      'Listen, repeat, and collect stars step by step';

  @override
  String get kidsJourneyMapTitle => 'Memorization map';

  @override
  String kidsPointsValue(int points) {
    return '$points points';
  }

  @override
  String kidsLevelValue(int level) {
    return 'Level $level';
  }

  @override
  String get kidsStartFirstStageToday => 'Start your first stage today';

  @override
  String kidsStageAyahRange(int stage, int startAyah, int endAyah) {
    return 'Stage $stage: ayahs $startAyah-$endAyah';
  }

  @override
  String get remoteGuardianLinkTitle => 'Remote guardian link';

  @override
  String get createQr => 'Create QR';

  @override
  String get renew => 'Renew';

  @override
  String get remoteGuardianLinkInstruction =>
      'Open the guardian dashboard on the other device and scan the code.';

  @override
  String kidsStageTitle(int stage) {
    return 'Stage $stage';
  }

  @override
  String kidsStageProgress(
    int startAyah,
    int endAyah,
    int completed,
    int total,
  ) {
    return 'Ayahs $startAyah-$endAyah • $completed/$total';
  }

  @override
  String get quranLongPressHint =>
      'Long-press an ayah to listen or add a bookmark';

  @override
  String get readPageConfirmed => 'Page counted';

  @override
  String get dailyPlanRatingWeakDesc => 'Needed the Mushaf';

  @override
  String get dailyPlanRatingAverageDesc => 'Small mistakes';

  @override
  String get dailyPlanRatingExcellentDesc => 'No mistakes';

  @override
  String get dailyPlanRatingHintTitle => 'How to choose a rating';

  @override
  String get dailyPlanRatingHintBody =>
      'Your rating affects the next review: weak means sooner review, average means moderate spacing, and excellent means a longer gap.';

  @override
  String get understood => 'Got it';

  @override
  String get hifzSkipHintTitle => 'Skip ayah';

  @override
  String get hifzSkipHintBody =>
      'We will add this ayah to review later, no worries.';

  @override
  String get accuracyEasyTitle => 'Lenient';

  @override
  String get accuracyEasyDesc => 'Best for kids and beginners';

  @override
  String get accuracyMediumTitle => 'Balanced';

  @override
  String get accuracyMediumDesc => 'For daily practice';

  @override
  String get accuracyHardTitle => 'Strict';

  @override
  String get accuracyHardDesc => 'For advanced learners';

  @override
  String accuracyRequiredPercent(int percent) {
    return '$percent% required';
  }

  @override
  String get parentGuardianMode => 'I am a parent/guardian';

  @override
  String get qcfPocTitle => 'QCF rendering proof of concept';

  @override
  String get qcfPocIntro =>
      'Temporary visual test screen for Quran rendering inside the memorization area.';

  @override
  String get qcfPocNoProduction =>
      'This screen does not change Hifz logic, memorization state, progress, locks, unlocks, or checkpoints.';

  @override
  String get qcfPocVisualOnly =>
      'qcf_quran_plus is used here only for visual Quran rendering.';

  @override
  String get qcfPocSingleVerse => 'Single verse';

  @override
  String get qcfPocMultipleVerses => 'Multiple verses';

  @override
  String get qcfPocLastVerse => 'Last verse';

  @override
  String get qcfPocFullPage => 'Full mushaf page';

  @override
  String get qcfPocFindings => 'Findings';

  @override
  String get qcfPocSupported => 'Supported';

  @override
  String get qcfPocLimited => 'Limited';

  @override
  String get qcfPocUnsupported => 'Unsupported';

  @override
  String get qcfPocStatus => 'Status';

  @override
  String get qcfPocAlBaqarah255 => 'Al-Baqarah 255';

  @override
  String get qcfPocAlFatihah => 'Al-Fatiha 1-7';

  @override
  String get qcfPocAlIkhlas => 'Al-Ikhlas 1-4';

  @override
  String get qcfPocAshSharh8 => 'Ash-Sharh 8';

  @override
  String get qcfPocFullPageSample => 'Mushaf page 1 preview';

  @override
  String get qcfPocVerseSupported =>
      'Verse text renders visually with QCF helpers.';

  @override
  String get qcfPocMultiVerseSupported =>
      'Grouped verses render visually from the same surah.';

  @override
  String get qcfPocFullPageSupported =>
      'Full page rendering is available in a constrained preview.';

  @override
  String get qcfPocNoLimitations =>
      'No limitation observed in this isolated POC.';

  @override
  String get qcfPocLimitationInstruction =>
      'Any limitation listed here must be reviewed before production Hifz screens change.';

  @override
  String get parentDashboardCardSubtitle =>
      'Track child\'s memorization & rewards';

  @override
  String get viewDashboard => 'View Dashboard';

  @override
  String get resumeWhereYouLeft => 'Resume where you left off';

  @override
  String get resumeAction => 'Resume';

  @override
  String get notNow => 'Not now';

  @override
  String get lastSavedReading => 'Last saved reading';

  @override
  String get incompleteHifzSession => 'Incomplete memorization session';

  @override
  String get dailyMemorizationPlan => 'Daily memorization plan';

  @override
  String get incompleteKidsSession => 'Incomplete kids session';

  @override
  String get previousHifzQuiz => 'Previous memorization quiz';

  @override
  String get savedPreviousActivity => 'Saved previous activity';

  @override
  String get completeTodaysHifz => 'Complete today\'s memorization';

  @override
  String get planReadySmallStep =>
      'Your plan is ready, a small step is enough.';

  @override
  String get readTodaysPortion => 'Read today\'s portion';

  @override
  String get onePageMakesProgress => 'One page makes progress clear.';

  @override
  String get timeForDhikr => 'Time for Dhikr';

  @override
  String get startShortAzkarNow => 'Start with short Azkar now.';

  @override
  String get followChildJourney => 'Follow the child\'s journey';

  @override
  String get reviewProgressOrReward =>
      'Review progress or add an encouraging reward.';

  @override
  String get startQuranStepNow => 'Start a Quran step now';

  @override
  String get chooseReadingOrMemorization =>
      'Choose reading or simple memorization for today.';

  @override
  String get kidsFirstMissionToday => 'Your first mission today';

  @override
  String kidsCompleteStageToday(int stage) {
    return 'Complete stage $stage today';
  }

  @override
  String get kidsFirstMissionSubtitle =>
      'Start listening and repeating, every step brings you closer to a new star.';

  @override
  String kidsRemainingAyahs(int count) {
    return '$count ayahs remaining in this stage.';
  }

  @override
  String notificationEverydayAt(String time) {
    return 'Everyday at $time';
  }

  @override
  String get kidsGamifiedWelcome => 'Welcome, memorization hero!';

  @override
  String kidsGamifiedLevelProgress(int level, int progress) {
    return 'Level $level — $progress/100';
  }

  @override
  String kidsGamifiedStarsCount(int count) {
    return '$count stars';
  }

  @override
  String get kidsGamifiedLastMission => 'Last mission';

  @override
  String get kidsGamifiedContinueNow => 'Continue now';

  @override
  String get kidsGamifiedMushaf => 'Mushaf';

  @override
  String get kidsGamifiedJourney => 'My journey';

  @override
  String get kidsGamifiedMissions => 'Missions';

  @override
  String kidsGamifiedHouseTitle(int number) {
    return 'Memorization House $number';
  }

  @override
  String kidsGamifiedReviewHouseTitle(int number) {
    return 'Review House $number';
  }

  @override
  String kidsGamifiedAyahRange(int startAyah, int endAyah) {
    return 'Ayahs $startAyah-$endAyah';
  }

  @override
  String kidsGamifiedProgressCount(int completed, int total) {
    return '$completed/$total';
  }

  @override
  String get kidsGamifiedLockedStage => 'This house is locked for now';

  @override
  String get kidsGamifiedCurrentStage => 'Your current mission';

  @override
  String get kidsGamifiedCompletedStage => 'Well done, house completed';

  @override
  String get kidsGamifiedNeedsReview => 'Ready for review';

  @override
  String get kidsGamifiedListenStep => 'Listen';

  @override
  String get kidsGamifiedListenStepSubtitle => 'Listen carefully to the ayah';

  @override
  String get kidsGamifiedRepeatStep => 'Repeat';

  @override
  String get kidsGamifiedRepeatStepSubtitle =>
      'Repeat after the reciter until it settles';

  @override
  String get kidsGamifiedTestStep => 'Test yourself';

  @override
  String get kidsGamifiedTestStepSubtitle => 'Try reciting without help';

  @override
  String get kidsGamifiedStartMission => 'Start mission';

  @override
  String get kidsGamifiedListenAndRepeat => 'Listen and repeat';

  @override
  String get kidsGamifiedRecordYourVoice => 'Record your recitation';

  @override
  String get kidsGamifiedRecordingInProgress => 'Recording...';

  @override
  String get kidsGamifiedDoneRecording => 'Done Recording';

  @override
  String get kidsGamifiedAudioUnavailable =>
      'Audio is unavailable right now. Please try again soon.';

  @override
  String kidsGamifiedListenFirst(int count) {
    return 'Listen to the ayah $count times before recording your voice.';
  }

  @override
  String get kidsGamifiedAudioLoading => 'Preparing recitation...';

  @override
  String get kidsGamifiedWellDone => 'Well done!';

  @override
  String kidsGamifiedEarnedStars(int count) {
    return '+$count stars';
  }

  @override
  String kidsGamifiedEarnedGems(int count) {
    return '+$count gems';
  }

  @override
  String get kidsGamifiedNextStage => 'Next';

  @override
  String get kidsGamifiedReturnToMap => 'Return to map';

  @override
  String get kidsGamifiedJourneyComplete =>
      'You completed the current memorization journey. May Allah bless you!';

  @override
  String get kidsGamifiedFallbackMessage =>
      'We will return to the old experience to protect your progress.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get passwordResetEmailSent =>
      '✅ A password reset link has been sent to your email';

  @override
  String get forgotPasswordEnterEmail =>
      'Enter your email first to reset your password';

  @override
  String get updatePasswordTitle => 'Set a new password';

  @override
  String get updatePasswordSubtitle =>
      'Enter a strong new password for your account.';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordUpdated =>
      'Password updated successfully. Please sign in again.';

  @override
  String get updatePasswordButton => 'Update password';

  @override
  String get invalidPasswordRecoveryLink =>
      'This reset link is invalid or expired. Request a new password reset email.';

  @override
  String get onboardingGoalQuestion => 'What would you like to do first?';

  @override
  String get onboardingGoalSubtitle =>
      'Choose a clear starting point. You can still use the rest of the app later.';

  @override
  String get onboardingGoalReading => 'Reading';

  @override
  String get onboardingGoalMemorization => 'Memorization for me';

  @override
  String get onboardingGoalChild => 'Follow a child';

  @override
  String get onboardingGoalAzkar => 'Azkar';

  @override
  String get dailyPlanQuizAction => 'Review Session';

  @override
  String get dailyPlanNewAyahs => 'New ayahs to memorize';

  @override
  String get dailyPlanNearRevision => 'Near review (last 5 days)';

  @override
  String get dailyPlanFarRevision => 'Far review';

  @override
  String get dailyPlanRetentionReview => 'Retention Review';

  @override
  String get dailyPlanRetentionReviewHint =>
      'Optional review for ayahs you have already memorized.';

  @override
  String get dailyPlanCompletedTitle =>
      'MashaAllah! You completed Today\'s Plan';

  @override
  String dailyPlanCompletedSubtitle(int count) {
    return 'You completed $count items successfully.\nKeep going with this steady pace.';
  }

  @override
  String get dailyPlanNewAyahsShort => 'New ayahs';

  @override
  String get dailyPlanReviewShort => 'Review';

  @override
  String get dailyPlanBlessingAction => 'May Allah bless you ✨';

  @override
  String dailyPlanRatingExcellent(int ayahNumber) {
    return '✅ Excellent! Ayah $ayahNumber was scheduled for a longer review interval';
  }

  @override
  String get dailyPlanRatingAverage =>
      '⏰ Good effort, this will be reviewed after a moderate interval';

  @override
  String dailyPlanRatingWeak(int ayahNumber) {
    return '🔁 Needs practice, ayah $ayahNumber will be reviewed tomorrow';
  }

  @override
  String get performanceWeak => 'Needs practice';

  @override
  String get performanceAverage => 'Good';

  @override
  String get performanceExcellent => 'Excellent';

  @override
  String get dailyPlanListenBeforeRating => 'Listen to the ayah before rating';

  @override
  String get reviewQuizTitle => 'Review Session';

  @override
  String get memorizationSessionTitle => 'Memorization Session';

  @override
  String get memorizationHubReviewSectionTitle => 'Review Session';

  @override
  String get memorizationHubReviewSectionSubtitle =>
      'Review memorized ayahs through guided recitation (speech-to-text).';

  @override
  String get memorizationHubReviewCardDescription =>
      'Open a V2 recitation session for ayahs you have already memorized.';

  @override
  String get backAction => 'Back';

  @override
  String get hifzKidsRedirectedFromAdult =>
      'This path is for adults. You will be taken to the Kids path.';

  @override
  String get parentDashboardLastSession => 'Last session';

  @override
  String get parentDashboardNoSessionsYet => 'No sessions recorded yet.';

  @override
  String parentDashboardSessionSummary(
    int surahId,
    int ayahNumber,
    int repeats,
    int points,
  ) {
    return 'Surah $surahId • Ayah $ayahNumber\n$repeats repeats • $points points';
  }

  @override
  String get parentDashboardDone => 'Done';

  @override
  String get parentDashboardPinMismatch => 'PIN codes do not match';

  @override
  String get parentDashboardPinHelp =>
      'This code protects the parent dashboard on this device';

  @override
  String get parentDashboardPinConfirm => 'Confirm PIN';

  @override
  String get parentDashboardCreatePinTitle => 'Create parent PIN';

  @override
  String get parentDashboardSavePinButton => 'Save PIN';

  @override
  String get parentDashboardEnterPinTitle => 'Enter parent PIN';

  @override
  String get parentDashboardEnterButton => 'Enter';

  @override
  String get parentDashboardEnterLinkingCode => 'Enter linking code';

  @override
  String get parentDashboardResetPin =>
      'Reset on this device — a new code will be required';

  @override
  String get parentDashboardTodaySummary => 'Today';

  @override
  String get parentDashboardTodayEmpty =>
      'Today: no sessions yet. Encourage a short session.';

  @override
  String parentDashboardTodayCompleted(int count) {
    return 'Today: the child completed $count sessions. Encourage the next review.';
  }

  @override
  String get parentDashboardTodaySessions => 'Today\'s sessions';

  @override
  String get parentDashboardTodayPoints => 'Today\'s points';

  @override
  String get parentDashboardAddReward => 'Add reward';

  @override
  String get parentDashboardShowLastSession => 'Show last session';

  @override
  String get parentDashboardChildSummary => 'Child summary';

  @override
  String get parentDashboardPoints => 'Points';

  @override
  String get parentDashboardStars => 'Stars';

  @override
  String get parentDashboardWeekSessions => 'Week sessions';

  @override
  String get parentDashboardChildReminder => 'Child reminder';

  @override
  String get parentDashboardDailyReminder => 'Daily reminder at 6:30 PM';

  @override
  String get parentDashboardReminderSubtitle =>
      'The time can be changed later from parent settings';

  @override
  String get parentDashboardRemoteFollowup => 'Remote follow-up';

  @override
  String get parentDashboardScanQr => 'Scan QR';

  @override
  String get parentDashboardManualEntry => 'Manual entry';

  @override
  String get parentDashboardNoRemoteChild => 'No remote child is linked yet.';

  @override
  String parentDashboardRemoteChildSummary(int ayahs, int points) {
    return '$ayahs ayahs • $points points';
  }

  @override
  String parentDashboardMemorizedSummary(
    int memorized,
    int total,
    int percent,
  ) {
    return '$memorized/$total ayahs memorized • $percent%';
  }

  @override
  String parentDashboardReviewsSummary(int completed, int overdue) {
    return '$completed reviews completed • $overdue overdue';
  }

  @override
  String parentDashboardStreakSummary(int days) {
    return 'Streak: $days days';
  }

  @override
  String parentDashboardCertificatesSummary(int count) {
    return '$count certificates earned';
  }

  @override
  String get parentDashboardRemoveChild => 'Remove child';

  @override
  String get parentDashboardRemoveChildConfirmTitle => 'Remove child?';

  @override
  String parentDashboardRemoveChildConfirmBody(String name) {
    return 'This will unlink $name from your account. You can link again later with a new code.';
  }

  @override
  String get parentDashboardChildRemoved => 'Child removed';

  @override
  String get parentDashboardRewardsTitle => 'Parent rewards';

  @override
  String get parentDashboardRewardHint => 'Example: extra play time';

  @override
  String get parentDashboardRewardEmpty =>
      'Add rewards that appear for the child after reaching the weekly goal.';

  @override
  String get parentDashboardRewardLocked => 'Locked';

  @override
  String get parentDashboardRewardUnlocked => 'Unlocked';

  @override
  String get parentDashboardRewardClaimed => 'Claimed';

  @override
  String get parentDashboardRecentSessions => 'Recent sessions';

  @override
  String get parentDashboardNoKidsSessions => 'No kids sessions yet.';

  @override
  String parentDashboardLogTitle(int surahId, int ayahNumber) {
    return 'Surah $surahId • Ayah $ayahNumber';
  }

  @override
  String parentDashboardLogSubtitle(int repeats, int points) {
    return '$repeats repeats • $points points';
  }

  @override
  String get dailyPlanSettingsTooltip => 'Smart memorization path settings';

  @override
  String get dailyPlanRefreshTooltip => 'Refresh plan';

  @override
  String get dailyPlanHeaderTitle => 'Today\'s Plan';

  @override
  String dailyPlanHeaderSummary(int total, int completed) {
    return '$total items • $completed completed';
  }

  @override
  String dailyPlanProgressCount(int completed, int total) {
    return '$completed of $total';
  }

  @override
  String get dailyPlanAllDoneShort =>
      'Well done! You completed your plan today';

  @override
  String dailyPlanRemainingItems(int count) {
    return '$count items remaining';
  }

  @override
  String dailyPlanAyahTitle(int ayahNumber) {
    return 'Ayah $ayahNumber';
  }

  @override
  String dailyPlanRecordStats(int strength, int reviews) {
    return 'Strength: $strength • Reviews: $reviews';
  }

  @override
  String get dailyPlanNewLabel => 'New';

  @override
  String get dailyPlanEmptyTitle => 'Well done! No reviews are due today';

  @override
  String get dailyPlanEmptySubtitle =>
      'Check again tomorrow to continue your schedule';

  @override
  String get customPlanDeleteConfirmPhrase => 'Delete plan';

  @override
  String get customPlanDeleteTitle => 'Confirm plan deletion';

  @override
  String get customPlanDeleteKeeps =>
      'Keeps: achievements, history, and certificates';

  @override
  String get customPlanDeleteRemoves => 'Deletes: current plan only';

  @override
  String get customPlanDeleteInstruction => 'Type \"Delete plan\" to confirm.';

  @override
  String get customPlanDeleteAction => 'Confirm delete';

  @override
  String get customPlanSaved => 'Plan saved successfully ✅';

  @override
  String get customPlanTitle => 'Your custom plan';

  @override
  String get customPlanSubtitle => 'Design a memorization system that fits you';

  @override
  String get customPlanName => 'Plan name';

  @override
  String get customPlanNameHint => 'Example: My Juz Amma plan';

  @override
  String get customPlanNameRequired => 'Enter a plan name';

  @override
  String get customPlanTargetUserTitle => 'Who is this plan for?';

  @override
  String get customPlanChildFeaturesNote =>
      'Parent follow-up features will be enabled automatically.';

  @override
  String get customPlanSurahRange => 'Surah range';

  @override
  String get customPlanDailyLoad => 'Daily load';

  @override
  String get customPlanNewAyahsPerDay => 'New ayahs per day';

  @override
  String get customPlanAyahUnit => 'ayah';

  @override
  String get customPlanSchedule => 'Schedule';

  @override
  String get customPlanDaysPerWeek => 'Memorization days per week';

  @override
  String get customPlanDayUnit => 'day';

  @override
  String get customPlanSessionDuration => 'Session duration';

  @override
  String get customPlanMinuteUnit => 'min';

  @override
  String get customPlanDifficulty => 'Difficulty level';

  @override
  String get customPlanAdvanced => 'Advanced settings';

  @override
  String get customPlanAdvancedSubtitle => 'Near and far review settings';

  @override
  String get customPlanSaveAndStart => 'Save and start plan';

  @override
  String get customPlanDeleteCurrent => 'Delete current plan';

  @override
  String get customPlanFromSurah => 'From Surah';

  @override
  String get customPlanToSurah => 'To Surah';

  @override
  String get customPlanFromAyah => 'From ayah number';

  @override
  String get customPlanInvalidAyah => 'Enter a valid ayah number';

  @override
  String customPlanSurahAyahLimit(int maxAyah) {
    return 'This Surah has $maxAyah ayahs';
  }

  @override
  String get customPlanAdult => 'Adult';

  @override
  String get customPlanChild => 'Child';

  @override
  String get customPlanDifficultyEasy => 'Easy';

  @override
  String get customPlanDifficultyModerate => 'Moderate';

  @override
  String get customPlanDifficultyChallenging => 'Challenging';

  @override
  String get customPlanNearRevision => 'Near review';

  @override
  String get customPlanNearRevisionSubtitle =>
      'Review ayahs from the last 5 days';

  @override
  String get customPlanNearRevisionCount => 'Near review ayah count';

  @override
  String get customPlanFarRevision => 'Far review';

  @override
  String get customPlanFarRevisionSubtitle =>
      'Smart repetition for older ayahs';

  @override
  String get customPlanFarRevisionCount => 'Far review ayah count';

  @override
  String get customPlanEstimatedDuration => 'Estimated completion time';

  @override
  String customPlanApproxWeeks(int count) {
    return '$count weeks approx.';
  }

  @override
  String customPlanApproxMonths(int count) {
    return '$count months approx.';
  }

  @override
  String customPlanApproxYears(String count) {
    return '$count years approx.';
  }

  @override
  String customPlanEstimatedScope(int surahs, int ayahs) {
    return '$surahs Surahs • ~$ayahs ayahs';
  }

  @override
  String get customPlanQuickPresetTitle => 'Choose a quick template';

  @override
  String get customPlanPresetLight => 'Light';

  @override
  String get customPlanPresetLightDesc => '3 ayahs/day • 5 days • 10 minutes';

  @override
  String get customPlanPresetLightName => 'Light plan';

  @override
  String get customPlanPresetBalanced => 'Balanced';

  @override
  String get customPlanPresetBalancedDesc =>
      '5 ayahs/day • 6 days • 15 minutes';

  @override
  String get customPlanPresetBalancedName => 'Balanced plan';

  @override
  String get customPlanPresetIntensive => 'Intensive';

  @override
  String get customPlanPresetIntensiveDesc =>
      '10 ayahs/day • every day • 30 minutes';

  @override
  String get customPlanPresetIntensiveName => 'Intensive plan';

  @override
  String get customPlanPresetJuzAmma => 'Juz Amma';

  @override
  String get customPlanPresetJuzAmmaDesc =>
      'From An-Nas to Al-Fil • 3 ayahs/day';

  @override
  String get customPlanPresetJuzAmmaName => 'Juz Amma plan';

  @override
  String get customPlanSummaryTitle => 'Plan summary';

  @override
  String customPlanSummaryRange(Object startSurah, Object endSurah) {
    return 'Range: $startSurah → $endSurah';
  }

  @override
  String customPlanSummaryLoad(int ayahsPerDay, int daysPerWeek) {
    return '$ayahsPerDay ayahs daily • $daysPerWeek days weekly';
  }

  @override
  String customPlanSummarySession(int minutes, Object difficulty) {
    return '$minutes minutes per session • $difficulty level';
  }

  @override
  String get memorizationPathSelectionFailedTitle =>
      'Could not save your choice';

  @override
  String get memorizationPathConfirmTitle => 'What happens next?';

  @override
  String get memorizationPathCanChangeLater =>
      'You can change this later from Settings without losing progress.';

  @override
  String get parentDashboardLinkAction => 'Link';

  @override
  String get parentDashboardRemoteRewardTitle => 'Reward for the child';

  @override
  String get parentDashboardScanChildCodeTitle => 'Scan child code';

  @override
  String get homeParentToolsTitle => 'Parent / Guardian Tools';

  @override
  String get homeParentToolsSubtitle =>
      'Monitor your child’s progress and rewards';

  @override
  String get homeParentToolsAction => 'Open Parent Dashboard';

  @override
  String get guestUpgradeTitle => 'Manage your account';

  @override
  String get guestUpgradeMessage =>
      'Create an account for account management and family features.';

  @override
  String get guestUpgradeLocalProgress =>
      'Your local progress remains on this device.';

  @override
  String get parentDashboardGuestSubtitle =>
      'Sign in to manage your account and access guardian tools. Your local progress remains on this device.';

  @override
  String get kidsQuranTitle => 'Kids Quran';

  @override
  String get kidsQuranSubtitle =>
      'Read quietly and move between pages at your pace.';

  @override
  String get kidsQuranBackToHome => 'Back to Kids Home';

  @override
  String kidsQuranPageLabel(int pageNumber) {
    return 'Page $pageNumber';
  }

  @override
  String get kidsQuranSwipeHint => 'Swipe gently for the next page';

  @override
  String get parentDashboardPinInvalid => 'Enter a 4-digit code';

  @override
  String get parentDashboardPinIncorrect => 'Incorrect code';

  @override
  String get parentDashboardLinking => 'Verifying pairing code…';

  @override
  String get parentDashboardUnlinking => 'Removing guardian link…';

  @override
  String get parentDashboardRewardAdded => 'Reward added';

  @override
  String get parentDashboardRemoteRewardAdded => 'Reward sent to child';

  @override
  String get parentDashboardChildLinked => 'Child linked successfully';

  @override
  String get parentDashboardReminderSaved => 'Reminder updated';

  @override
  String get guardianLinkingSlowHint =>
      'This is taking longer than expected. You can continue and link later.';

  @override
  String get bookmarkSaveError => 'Failed to save bookmark';

  @override
  String get longPressToUndo => 'Long-press to undo';

  @override
  String get hifzReviewPassedTitle => 'Review passed';

  @override
  String get hifzReviewTimeTitle => 'Time to review';

  @override
  String get hifzReviewFullSurahHint =>
      'Review the full surah before finishing it';

  @override
  String hifzReviewRangeHint(int startAyah, int endAyah) {
    return 'Review ayahs $startAyah to $endAyah before moving to the next ayah';
  }

  @override
  String get hifzEvaluatingReview => 'Evaluating review…';

  @override
  String get hifzLeaveSessionMessage =>
      'Do you want to leave the memorization session? Your current progress will be saved.';

  @override
  String hifzAyahNumberLabel(int ayahNumber) {
    return 'Ayah $ayahNumber';
  }

  @override
  String get hifzEvaluatingAyah => 'Evaluating...';

  @override
  String get hifzRecordingAyahHint => 'Recording, recite from memory...';

  @override
  String get hifzExcellentMemorization => 'Excellent! Perfect memorization.';

  @override
  String get hifzNeedsAyahReview => 'You need to review this Ayah.';

  @override
  String get hifzNoVoiceRecognized => '(No voice recognized)';

  @override
  String get hifzRecordingReviewHint =>
      'Recording — recite the passage from memory…';

  @override
  String get hifzFinishRecitation => 'Finish recitation';

  @override
  String get hifzFinishSession => 'Finish session';

  @override
  String get hifzNextAyah => 'Next ayah';

  @override
  String get hifzReviewNotPassed => 'Review not passed. Try again.';

  @override
  String get hifzStartRecitation => 'Start recitation';

  @override
  String get hifzAudioPlaybackFailed =>
      'Audio playback failed. Check your internet connection.';

  @override
  String get hifzReviewSaveFailed =>
      'Failed to save review progress. Try again.';

  @override
  String get hifzMemorizationSaveFailed =>
      'Failed to save memorization progress. Try again.';

  @override
  String hifzSurahLockedMessage(String surahName) {
    return 'This surah is locked. Complete $surahName first to unlock it.';
  }

  @override
  String get kidsAudioPlaybackFailed =>
      'Audio didn\'t work. Try again or ask a parent to check the internet connection.';

  @override
  String get smartCoachMemorizedReviewDueTitle => 'Retention review due';

  @override
  String smartCoachMemorizedReviewDueSubtitle(String surahName) {
    return 'Review memorized ayahs in Surah $surahName to keep them strong.';
  }

  @override
  String get homeContinueTodaysPlan => 'Continue Today\'s Plan';

  @override
  String get homeCurrentMission => 'Current Mission';

  @override
  String get homeStartKidsMission => 'Start the child\'s current mission.';

  @override
  String get homeChooseKidsPath =>
      'Choose the kids path or continue the current mission.';

  @override
  String homeDailyWirdPage(Object page) {
    return 'Read page $page of the Holy Quran';
  }

  @override
  String homeDailyWirdSurah(Object surah) {
    return 'Read Surah $surah of the Holy Quran';
  }

  @override
  String get homeDailyWird => 'Daily Wird';

  @override
  String homeDailyWirdSurahPage(Object page, Object surah) {
    return 'Surah $surah — Page $page';
  }

  @override
  String get homeTodaysPlan => 'Today\'s Plan';

  @override
  String get homeKidsProgress => 'Kids Progress';

  @override
  String get homeYourProgress => 'Your Progress';

  @override
  String get homeActionQuran => 'Quran';

  @override
  String get homeActionReadToday => 'Read today';

  @override
  String get homeActionTodaysPlan => 'Today\'s Plan';

  @override
  String get homeActionContinuePlan => 'Continue today\'s plan';

  @override
  String get homeActionProgress => 'Progress';

  @override
  String get homeActionReviewGains => 'Review gains';

  @override
  String get homeActionSettings => 'Settings';

  @override
  String get homeActionTuneApp => 'Tune app';

  @override
  String get homeGoToSettings => 'Go to Settings';

  @override
  String get notificationDailyReviewTitle => 'Daily Review Time 📖';

  @override
  String notificationDailyReviewBodyCount(Object count) {
    return 'You have $count ayahs to review today';
  }

  @override
  String get notificationDailyReviewBody =>
      'It\'s time for your daily memorization review';

  @override
  String notificationStreakAlertTitle(Object count) {
    return '⚠️ Don\'t lose your $count day streak!';
  }

  @override
  String get notificationStreakAlertBody =>
      'You haven\'t reviewed today yet — you still can';

  @override
  String get notificationDailyAyahTitle => 'Ayah of the Day ✨';

  @override
  String get notificationDailyAyahBody =>
      'Read your daily Wird from the Holy Quran';

  @override
  String get notificationMorningAzkarTitle => 'Morning Azkar ☀️';

  @override
  String get notificationMorningAzkarBody =>
      'Start your day with the remembrance of Allah and peace of mind';

  @override
  String get notificationEveningAzkarTitle => 'Evening Azkar 🌙';

  @override
  String get notificationEveningAzkarBody =>
      'End your day with the remembrance and protection of Allah';

  @override
  String get notificationKidsReviewTitle => 'Review Time Hero! 🌟';

  @override
  String get notificationKidsReviewBody =>
      'Your new stage is ready, let\'s continue memorizing!';

  @override
  String get notificationDailyDuaTitle => 'Dua of the Day 🤲';

  @override
  String get homeTourTitle => 'Need a quick tour?';

  @override
  String get homeTourDesc => 'Open the guide here or later from Help.';

  @override
  String get homeTourGuideAction => 'Guide';

  @override
  String get journeyReviewBeforeNewTitle => 'Review before new content';

  @override
  String journeyReviewBeforeNewDesc(Object surahAyahLabel) {
    return 'Near revision due in $surahAyahLabel.';
  }

  @override
  String get journeyLongTermReviewTitle => 'Long-term review due';

  @override
  String journeyLongTermReviewDesc(Object surahAyahLabel) {
    return 'Time to review $surahAyahLabel.';
  }

  @override
  String get journeyReviewDifficultAyahTitle => 'Review a difficult ayah';

  @override
  String journeyReviewDifficultAyahDesc(Object surahAyahLabel) {
    return 'Your last review was difficult for $surahAyahLabel.';
  }

  @override
  String get journeyContinueDailyPlanTitle => 'Continue today\'s plan';

  @override
  String journeyContinueDailyPlanDesc(Object completed, Object total) {
    return '$completed of $total items done today.';
  }

  @override
  String get journeyMemorizeNewAyahsTitle => 'Memorize new ayahs';

  @override
  String journeyMemorizeNewAyahsDesc(Object surahAyahLabel) {
    return 'Start new ayahs in $surahAyahLabel.';
  }

  @override
  String get journeyCurrentMissionTitle => 'Current Mission';

  @override
  String get journeyCurrentMissionDesc =>
      'Continue the child\'s current mission.';

  @override
  String get journeyContinueSessionTitle => 'Continue Session';

  @override
  String journeyContinueSessionDesc(Object surahLabel) {
    return 'You have an incomplete memorization session in $surahLabel.';
  }

  @override
  String get journeyHifzReviewDueTitle => 'Hifz review due';

  @override
  String get journeyHifzReviewDueDesc => 'Review due items in your Hifz path.';

  @override
  String get journeyFallbackSurah => 'your surah';

  @override
  String journeyAyahLabel(Object start) {
    return ', ayah $start';
  }

  @override
  String journeyAyahsLabel(Object end, Object start) {
    return ', ayahs $start–$end';
  }

  @override
  String get tutorialS1Title => 'Guide 1';

  @override
  String get tutorialS1Cat => 'Category';

  @override
  String get tutorialS1Does => 'What it does';

  @override
  String get tutorialS1Open => 'How to open';

  @override
  String get tutorialS1Useful => 'When useful';

  @override
  String get tutorialS1Step1 => 'Step 1';

  @override
  String get tutorialS1Step2 => 'Step 2';

  @override
  String get tutorialS1Step3 => 'Step 3';

  @override
  String get tutorialS1Tip1 => 'Tip 1';

  @override
  String get tutorialS1Tip2 => 'Tip 2';

  @override
  String get tutorialS1Note1 => 'Note 1';

  @override
  String get tutorialS1Note2 =>
      'Sign-in is optional; it helps with account management and family features.';

  @override
  String get tutorialS2Title => 'Guide 2';

  @override
  String get tutorialS2Cat => 'Category';

  @override
  String get tutorialS2Does => 'What it does';

  @override
  String get tutorialS2Open => 'How to open';

  @override
  String get tutorialS2Useful => 'When useful';

  @override
  String get tutorialS2Step1 => 'Step 1';

  @override
  String get tutorialS2Step2 => 'Step 2';

  @override
  String get tutorialS2Step3 => 'Step 3';

  @override
  String get tutorialS2Step4 => 'Step 4';

  @override
  String get tutorialS2Tip1 => 'Tip 1';

  @override
  String get tutorialS2Tip2 => 'Tip 2';

  @override
  String get tutorialS2Note1 => 'Note 1';

  @override
  String get tutorialS2Note2 => 'Note 2';

  @override
  String get tutorialS3Title => 'Guide 3';

  @override
  String get tutorialS3Cat => 'Category';

  @override
  String get tutorialS3Does => 'What it does';

  @override
  String get tutorialS3Open => 'How to open';

  @override
  String get tutorialS3Useful => 'When useful';

  @override
  String get tutorialS3Step1 => 'Step 1';

  @override
  String get tutorialS3Step2 => 'Step 2';

  @override
  String get tutorialS3Step3 => 'Step 3';

  @override
  String get tutorialS3Step4 => 'Step 4';

  @override
  String get tutorialS3Step5 => 'Step 5';

  @override
  String get tutorialS3Tip1 => 'Tip 1';

  @override
  String get tutorialS3Tip2 => 'Tip 2';

  @override
  String get tutorialS3Note1 => 'Note 1';

  @override
  String get tutorialS3Note2 => 'Note 2';

  @override
  String get tutorialS4Title => 'Guide 4';

  @override
  String get tutorialS4Cat => 'Category';

  @override
  String get tutorialS4Does => 'What it does';

  @override
  String get tutorialS4Open => 'How to open';

  @override
  String get tutorialS4Useful => 'When useful';

  @override
  String get tutorialS4Step1 => 'Step 1';

  @override
  String get tutorialS4Step2 => 'Step 2';

  @override
  String get tutorialS4Step3 => 'Step 3';

  @override
  String get tutorialS4Step4 => 'Step 4';

  @override
  String get tutorialS4Tip1 => 'Tip 1';

  @override
  String get tutorialS4Tip2 => 'Tip 2';

  @override
  String get tutorialS4Note1 => 'Note 1';

  @override
  String get tutorialS4Note2 => 'Note 2';

  @override
  String get tutorialS5Title => 'Guide 5';

  @override
  String get tutorialS5Cat => 'Category';

  @override
  String get tutorialS5Does => 'What it does';

  @override
  String get tutorialS5Open => 'How to open';

  @override
  String get tutorialS5Useful => 'When useful';

  @override
  String get tutorialS5Step1 => 'Step 1';

  @override
  String get tutorialS5Step2 => 'Step 2';

  @override
  String get tutorialS5Step3 => 'Step 3';

  @override
  String get tutorialS5Step4 => 'Step 4';

  @override
  String get tutorialS5Tip1 => 'Tip 1';

  @override
  String get tutorialS5Tip2 => 'Tip 2';

  @override
  String get tutorialS5Note1 => 'Note 1';

  @override
  String get tutorialS5Note2 => 'Note 2';

  @override
  String get tutorialS6Title => 'Guide 6';

  @override
  String get tutorialS6Cat => 'Category';

  @override
  String get tutorialS6Does => 'What it does';

  @override
  String get tutorialS6Open => 'How to open';

  @override
  String get tutorialS6Useful => 'When useful';

  @override
  String get tutorialS6Step1 => 'Step 1';

  @override
  String get tutorialS6Step2 => 'Step 2';

  @override
  String get tutorialS6Step3 => 'Step 3';

  @override
  String get tutorialS6Step4 => 'Step 4';

  @override
  String get tutorialS6Step5 => 'Step 5';

  @override
  String get tutorialS6Tip1 => 'Tip 1';

  @override
  String get tutorialS6Tip2 => 'Tip 2';

  @override
  String get tutorialS6Note1 => 'Note 1';

  @override
  String get tutorialS6Note2 => 'Note 2';

  @override
  String get tutorialS7Title => 'Guide 7';

  @override
  String get tutorialS7Cat => 'Category';

  @override
  String get tutorialS7Does => 'What it does';

  @override
  String get tutorialS7Open => 'How to open';

  @override
  String get tutorialS7Useful => 'When useful';

  @override
  String get tutorialS7Step1 => 'Step 1';

  @override
  String get tutorialS7Step2 => 'Step 2';

  @override
  String get tutorialS7Step3 => 'Step 3';

  @override
  String get tutorialS7Step4 => 'Step 4';

  @override
  String get tutorialS7Step5 => 'Step 5';

  @override
  String get tutorialS7Tip1 => 'Tip 1';

  @override
  String get tutorialS7Tip2 => 'Tip 2';

  @override
  String get tutorialS7Note1 => 'Note 1';

  @override
  String get tutorialS7Note2 => 'Note 2';

  @override
  String get tutorialS8Title => 'Guide 8';

  @override
  String get tutorialS8Cat => 'Category';

  @override
  String get tutorialS8Does => 'What it does';

  @override
  String get tutorialS8Open => 'How to open';

  @override
  String get tutorialS8Useful => 'When useful';

  @override
  String get tutorialS8Step1 => 'Step 1';

  @override
  String get tutorialS8Step2 => 'Step 2';

  @override
  String get tutorialS8Step3 => 'Step 3';

  @override
  String get tutorialS8Step4 => 'Step 4';

  @override
  String get tutorialS8Step5 => 'Step 5';

  @override
  String get tutorialS8Tip1 => 'Tip 1';

  @override
  String get tutorialS8Tip2 => 'Tip 2';

  @override
  String get tutorialS8Note1 => 'Note 1';

  @override
  String get tutorialS8Note2 => 'Note 2';

  @override
  String get tutorialS9Title => 'Guide 9';

  @override
  String get tutorialS9Cat => 'Category';

  @override
  String get tutorialS9Does => 'What it does';

  @override
  String get tutorialS9Open => 'How to open';

  @override
  String get tutorialS9Useful => 'When useful';

  @override
  String get tutorialS9Step1 => 'Step 1';

  @override
  String get tutorialS9Step2 => 'Step 2';

  @override
  String get tutorialS9Step3 => 'Step 3';

  @override
  String get tutorialS9Step4 => 'Step 4';

  @override
  String get tutorialS9Tip1 => 'Tip 1';

  @override
  String get tutorialS9Tip2 => 'Tip 2';

  @override
  String get tutorialS9Note1 => 'Note 1';

  @override
  String get tutorialS9Note2 => 'Note 2';

  @override
  String get tutorialS10Title => 'Guide 10';

  @override
  String get tutorialS10Cat => 'Category';

  @override
  String get tutorialS10Does => 'What it does';

  @override
  String get tutorialS10Open => 'How to open';

  @override
  String get tutorialS10Useful => 'When useful';

  @override
  String get tutorialS10Step1 => 'Step 1';

  @override
  String get tutorialS10Step2 => 'Step 2';

  @override
  String get tutorialS10Step3 => 'Step 3';

  @override
  String get tutorialS10Step4 => 'Step 4';

  @override
  String get tutorialS10Step5 => 'Step 5';

  @override
  String get tutorialS10Tip1 => 'Tip 1';

  @override
  String get tutorialS10Tip2 => 'Tip 2';

  @override
  String get tutorialS10Note1 => 'Note 1';

  @override
  String get tutorialS10Note2 => 'Note 2';

  @override
  String get tutorialS11Title => 'Guide 11';

  @override
  String get tutorialS11Cat => 'Category';

  @override
  String get tutorialS11Does => 'What it does';

  @override
  String get tutorialS11Open => 'How to open';

  @override
  String get tutorialS11Useful => 'When useful';

  @override
  String get tutorialS11Step1 => 'Step 1';

  @override
  String get tutorialS11Step2 => 'Step 2';

  @override
  String get tutorialS11Step3 => 'Step 3';

  @override
  String get tutorialS11Step4 => 'Step 4';

  @override
  String get tutorialS11Step5 => 'Step 5';

  @override
  String get tutorialS11Step6 => 'Step 6';

  @override
  String get tutorialS11Tip1 => 'Tip 1';

  @override
  String get tutorialS11Tip2 => 'Tip 2';

  @override
  String get tutorialS11Note1 => 'Note 1';

  @override
  String get tutorialS11Note2 => 'Note 2';

  @override
  String get tutorialS12Title => 'Guide 12';

  @override
  String get tutorialS12Cat => 'Category';

  @override
  String get tutorialS12Does => 'What it does';

  @override
  String get tutorialS12Open => 'How to open';

  @override
  String get tutorialS12Useful => 'When useful';

  @override
  String get tutorialS12Step1 => 'Step 1';

  @override
  String get tutorialS12Step2 => 'Step 2';

  @override
  String get tutorialS12Step3 => 'Step 3';

  @override
  String get tutorialS12Tip1 => 'Tip 1';

  @override
  String get tutorialS12Tip2 => 'Tip 2';

  @override
  String get tutorialS12Note1 => 'Note 1';

  @override
  String get tutorialS12Note2 => 'Note 2';

  @override
  String get tutorialCategoryTitle => 'Category';

  @override
  String get tutorialWhatItDoesTitle => 'What it does?';

  @override
  String get tutorialHowToOpenTitle => 'How to access it?';

  @override
  String get tutorialStepsTitle => 'Steps to use';

  @override
  String get tutorialTipsTitle => 'Tips';

  @override
  String get tutorialNotesTitle => 'Technical notes';

  @override
  String get tutorialWhenUsefulTitle => 'When is it useful?';

  @override
  String certificateCelebrationMultiple(int count) {
    return 'You earned $count new certificates!';
  }

  @override
  String certificateCelebrationSingle(String title) {
    return 'You earned $title';
  }

  @override
  String get learningAlertReduceNewTitle => 'Reduce New Memorization';

  @override
  String get learningAlertReduceNewSubtitle =>
      'Your workload is heavy, focus on review';

  @override
  String get learningAlertFocusWeakTitle => 'Focus on Weak Ayahs';

  @override
  String get learningAlertFocusWeakSubtitle =>
      'You have difficult ayahs to review';

  @override
  String get learningAlertGenericTitle => 'Learning Alert';

  @override
  String get learningAlertGenericSubtitle => 'Action required';

  @override
  String get reviewBacklogTitle => 'Review Backlog';

  @override
  String reviewBacklogSubtitle(String overdue) {
    return 'You have $overdue overdue ayahs';
  }

  @override
  String get smartPlanCustomTitle => 'Custom Plan';

  @override
  String get smartPlanReviewTitle => 'Review Plan';

  @override
  String get smartPlanTodayTitle => 'Todays Plan';

  @override
  String get smartPlanSubtitle => 'Continue your memorization journey';

  @override
  String get dailyWirdTitle => 'Daily Wird';

  @override
  String get dailyWirdSubtitle => 'Read your daily portion';

  @override
  String get exploreAzkarTitle => 'Time for Dhikr';

  @override
  String get exploreAzkarSubtitle => 'Start your daily Azkar';

  @override
  String get exploreMissionTitle => 'Current Mission';

  @override
  String get exploreMissionSubtitle => 'Start your current mission';

  @override
  String get exploreQuranTitle => 'Quran';

  @override
  String get exploreQuranSubtitle => 'Read the Quran';

  @override
  String get parentDashboardLinkHint => 'talia-kids-link:...';
}
