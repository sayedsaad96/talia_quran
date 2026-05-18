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
  String get profileSavedToCloud => 'Your progress is saved to the cloud';

  @override
  String get guestModeWarning =>
      'Sign in to save your progress across all devices.';

  @override
  String get signOutWarning =>
      'Do you want to sign out? Your cloud progress will not be deleted.';

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
      'Sign in to save and sync your progress across all devices';

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
  String get backupProgressTitle => 'Back up your progress!';

  @override
  String get backupProgressDesc =>
      'Sign in from Settings to protect your progress';

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
  String get resetMemorizationPath => 'Reset / Change path';

  @override
  String get linkGuardianNow => 'Link guardian now';

  @override
  String get continueWithoutGuardian => 'Continue without guardian';

  @override
  String get guardianCodeExpired => 'Code expired';

  @override
  String get guardianCodeAlreadyUsed => 'Code already used';

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
}
