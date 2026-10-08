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
  String get playPageRecitation => 'Play Page';

  @override
  String get pauseRecitation => 'Pause Recitation';

  @override
  String get stopRecitation => 'Stop Recitation';

  @override
  String get changeReciter => 'Change Reciter';

  @override
  String get closePlayer => 'Close Player';

  @override
  String get moreOptions => 'More';

  @override
  String get reciterActiveChip => 'Active';

  @override
  String get emptyBookmarksTitle => 'No bookmarks yet';

  @override
  String get emptyBookmarksHint =>
      'Long-press any ayah while reading to save it as a bookmark and reach it easily here';

  @override
  String get exitDialogTitle => 'Recitation is playing';

  @override
  String exitDialogBody(String surah) {
    return 'You are listening to $surah.\nContinue listening in the background with notification controls, or stop the recitation and exit?';
  }

  @override
  String get currentSurah => 'the current surah';

  @override
  String get exitDialogContinueBackground => 'Continue in background';

  @override
  String get exitDialogStopAndExit => 'Stop recitation and exit';

  @override
  String get exitDialogStayInApp => 'Stay in the app';

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
  String get settingsPageSubtitle => 'Customize Talia to fit your routine';

  @override
  String get settingsQuickPreferences => 'Quick preferences';

  @override
  String get settingsMoreSettings => 'More Settings';

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
  String get errorCacheMessage =>
      'Couldn\'t reach your saved data. Please try again.';

  @override
  String get errorNetworkMessage =>
      'Check your internet connection and try again.';

  @override
  String get errorNotFoundMessage =>
      'The content you\'re looking for wasn\'t found.';

  @override
  String get errorParseMessage =>
      'Something went wrong while reading the content. Please try again.';

  @override
  String get errorUnknownMessage =>
      'Something unexpected happened. Please try again.';

  @override
  String celebrationAyah(String xp) {
    return 'Well done! +$xp XP ⭐';
  }

  @override
  String celebrationPage(String xp) {
    return 'Page complete! +$xp XP 🎯';
  }

  @override
  String get celebrationJuzDone =>
      'You\'ve completed the entire juz, by Allah\'s grace';

  @override
  String get tutorialQuickStartTitle => 'Your quick Talia map';

  @override
  String get tutorialQuickStartSubtitle => 'The five key areas for daily use';

  @override
  String get tutorialQuickStartHint =>
      'Use search or the filters below to open any detailed guide.';

  @override
  String get tutorialShortcutHomeLabel => 'Home';

  @override
  String get tutorialShortcutHomeDesc => 'Daily wird & progress';

  @override
  String get tutorialShortcutQuranLabel => 'Quran';

  @override
  String get tutorialShortcutQuranDesc => 'Mushaf & reading';

  @override
  String get tutorialShortcutHifzLabel => 'Memorize';

  @override
  String get tutorialShortcutHifzDesc => 'Plan & sessions';

  @override
  String get tutorialShortcutAzkarLabel => 'Adhkar';

  @override
  String get tutorialShortcutAzkarDesc => 'Wird & counter';

  @override
  String get tutorialShortcutProgressLabel => 'Progress';

  @override
  String get tutorialShortcutProgressDesc => 'Certificates & achievements';

  @override
  String get splashInitError => 'Couldn\'t finish loading. Please try again.';

  @override
  String get retryLabel => 'Try again';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

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
  String get playSurah => 'Play Surah';

  @override
  String get playPage => 'Recite Page';

  @override
  String get listenToSurah => 'Listen to Surah';

  @override
  String get nowPlaying => 'Now Reciting';

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
  String get clearSearch => 'Clear search';

  @override
  String get selectReciter => 'Choose reciter';

  @override
  String get enterFocusMode => 'Enter focus mode';

  @override
  String get readerGoToPage => 'Go to a page, surah or juz';

  @override
  String get readerTajweedColors => 'Tajweed colors';

  @override
  String get readerTajweedColorsHint =>
      'Color the tajweed rules on the Mushaf page';

  @override
  String get surahInProgressBadge => 'Memorizing';

  @override
  String get exitFocusMode => 'Exit focus mode';

  @override
  String get closeReader => 'Close reader';

  @override
  String hizbNumberLabel(Object number) {
    return 'Hizb $number';
  }

  @override
  String azkarCountOfTotal(String total) {
    return 'of $total';
  }

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
  String get shareMemorizationMilestone => 'Share memorization milestone';

  @override
  String get shareConsistencyStreak => 'Share consistency streak';

  @override
  String get shareApp => 'Share Talia App';

  @override
  String get shareAppText =>
      'Discover Talia Quran 📖✨\nYour smart companion for memorization & recitation\nDownload now: https://play.google.com/store/apps/details?id=com.talia.quran';

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
  String get pureBlackTheme => 'Pure black (OLED)';

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
  String get dailyAyahReminder => 'Daily Ayah';

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
      'Do you want to sign out? Your account progress returns when you sign in again. Your khatmah plan and khatmah history are kept only on this device and will be removed when you sign out.';

  @override
  String get memorizationHubNothingToReview =>
      'Nothing to review yet. Start memorizing first; your ayahs will appear here when their review is due.';

  @override
  String homeMemorizedAyahsCaption(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText ayahs memorized',
      one: '$countText ayah memorized',
      zero: 'No ayahs memorized yet',
    );
    return '$_temp0';
  }

  @override
  String get kidsSetupDiscardTitle => 'Discard child setup?';

  @override
  String get kidsSetupDiscardBody =>
      'The kids path setup isn\'t saved yet. Leave without saving?';

  @override
  String get kidsSetupKeepEditing => 'Keep editing';

  @override
  String get kidsSetupDiscard => 'Leave without saving';

  @override
  String get listeningReviewStartMemorizing => 'Start memorizing';

  @override
  String get customPlanChildSwitchTitle => 'Switch to the kids path?';

  @override
  String get customPlanChildSwitchBody =>
      'Kids plans are managed in the kids path. This ends your adult path and current plan (your achievements, history and certificates are kept), then opens the kids path setup.';

  @override
  String get customPlanChildSwitchConfirm => 'Switch to kids path';

  @override
  String get guestImportTitle => 'Import local memorization data?';

  @override
  String get guestImportBody =>
      'You have memorization progress from before you signed in. Move it to this account so it appears in your progress and reviews.';

  @override
  String get guestImportConfirm => 'Import';

  @override
  String get guestImportLater => 'Not now';

  @override
  String guestImportDone(String countText) {
    return 'Imported $countText memorization records.';
  }

  @override
  String get signOutPendingDataTitle => 'Unsynced progress';

  @override
  String get signOutPendingDataWarning =>
      'Some memorization progress has not reached the cloud yet. Signing out now will delete it from this device.';

  @override
  String get signOutAnyway => 'Sign out anyway';

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
  String get tutorialGuideHeroSubtitle =>
      'Talia\'s knowledge hub and feature guide';

  @override
  String tutorialGuideTopicsCount(String count) {
    return 'Topics: $count';
  }

  @override
  String tutorialGuideTipsCount(String count) {
    return 'Tips & explanations: $count';
  }

  @override
  String get tutorialGuideSearchHint => 'Search for a feature or a step...';

  @override
  String get tutorialGuideNoResults => 'No matching results';

  @override
  String get tutorialGuideNoResultsHint =>
      'Try a shorter word, like: Quran, memorization, azkar, notifications.';

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
  String get dailyAyahSaveError => 'Failed to update daily ayah reminder';

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
  String get restoringProgress => 'Restoring your data…';

  @override
  String get retrySyncAfterError => 'Retry';

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
  String get azkarContentUnderReview =>
      'Azkar content is being reviewed and will appear here once approved.';

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
  String get azkarSectionsAndServices => 'Explore more';

  @override
  String get azkarWirdCompletedToday => 'Today\'s wird is complete ✨';

  @override
  String get azkarMorningHeroSubtitle =>
      'Begin your day with remembrance and peace of heart';

  @override
  String get azkarEveningHeroSubtitle =>
      'End your day with serenity and forgiveness';

  @override
  String get azkarReviewWird => 'Review wird';

  @override
  String get azkarStartWirdNow => 'Start now';

  @override
  String get azkarFreeTasbeeh => 'Free Tasbeeh';

  @override
  String get azkarFreeTasbeehSubtitle => 'Count freely at your pace';

  @override
  String get azkarSearchHint => 'Search duas and azkar...';

  @override
  String get azkarFavorites => 'Favorites';

  @override
  String get azkarFavoritesEmptyTitle => 'No favorites yet';

  @override
  String get azkarFavoritesEmptyDesc =>
      'Tap the bookmark icon next to any dua to save it here';

  @override
  String get azkarFavoriteAdd => 'Add to favorites';

  @override
  String get azkarFavoriteRemove => 'Remove from favorites';

  @override
  String get azkarSearchNoResultsTitle => 'No matching results';

  @override
  String get azkarSearchNoResultsDesc =>
      'We couldn\'t find any duas for your search';

  @override
  String get azkarSearchClear => 'Clear search';

  @override
  String get azkarVirtueOrSource => 'Virtue / Source';

  @override
  String get azkarVirtueAndSource => 'Virtue & Source';

  @override
  String get azkarVirtue => 'Virtue';

  @override
  String get azkarSource => 'Source';

  @override
  String get azkarAutoAdvanceOn => 'Auto-advance enabled';

  @override
  String get azkarAutoAdvanceOff => 'Auto-advance disabled';

  @override
  String get azkarSmartWird => 'Smart Wird';

  @override
  String get azkarSmartWirdSubtitle => 'A wird built for this moment';

  @override
  String azkarSmartWirdDone(String count) {
    return 'Completed $count smart wird session(s) today';
  }

  @override
  String get azkarSmartWirdResume => 'Resume';

  @override
  String get azkarSmartWirdCompleted => 'Smart wird complete';

  @override
  String get azkarQuietNight => 'Quiet Night';

  @override
  String get azkarQuietNightSubtitle => 'Flowing reading, no counter';

  @override
  String get azkarQuietNightExit => 'End quiet reading';

  @override
  String get azkarPlayRecitation => 'Play recitation';

  @override
  String get azkarPauseRecitation => 'Pause recitation';

  @override
  String get azkarShareWird => 'Share wird progress';

  @override
  String get azkarTasbeehResetTitle => 'Reset counter';

  @override
  String get azkarTasbeehResetDesc => 'Reset the tasbeeh counter to zero?';

  @override
  String get azkarTasbeehResetConfirm => 'Reset';

  @override
  String get azkarTasbeehResetTooltip => 'Reset counter';

  @override
  String get azkarTasbeehOpenTarget => 'Open';

  @override
  String azkarTasbeehTargetLabel(String target) {
    return 'Target: $target';
  }

  @override
  String azkarTasbeehRound(String round) {
    return 'Round $round';
  }

  @override
  String get azkarTasbeehTapHint => 'Tap anywhere in the circle to count';

  @override
  String azkarTasbeehTapSemantics(String count) {
    return 'Tap to count, current $count';
  }

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
  String get achievementDescJuzAmma => 'Memorize all of Juz Amma';

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
  String bookmarksCountItem(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bookmarks',
      one: 'bookmark',
    );
    return '$countText $_temp0';
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
  String get settingsBackgroundPlaybackTitle => 'Background playback';

  @override
  String get settingsBackgroundPlaybackSubtitle =>
      'Recitation keeps playing after you leave the app, with controls in the notification.';

  @override
  String get settingsHubPractice => 'Practice';

  @override
  String get settingsHubReminders => 'Notifications & reminders';

  @override
  String get settingsHubSupport => 'Support';

  @override
  String get settingsRemindersGeneral => 'General';

  @override
  String get settingsRemindersMemorization => 'Memorization reminders';

  @override
  String get settingsRemindersWorship => 'Worship';

  @override
  String get settingsRemindersPrayer => 'Prayer & Adhan';

  @override
  String get settingsRemindersProgress => 'Progress';

  @override
  String get notificationPermissionBlockedTitle =>
      'App notifications are off in phone settings';

  @override
  String get notificationPermissionBlockedBody =>
      'Review and adhkar reminders will not arrive until notifications are allowed in system settings.';

  @override
  String get notificationOpenSystemSettings => 'Open phone settings';

  @override
  String get notificationStatusBlocked =>
      'Notifications are turned off in system settings';

  @override
  String notificationStatusSummary(String enabled, String total) {
    return '$enabled of $total reminders on';
  }

  @override
  String get notificationTestInteractiveTitle => 'Try a notification';

  @override
  String get notificationTestInteractiveSubtitle =>
      'Send a sample reminder to confirm alerts work';

  @override
  String get notificationPrayerPermissionBlockedBody =>
      'Prayer alerts will not arrive until notifications are allowed in phone settings.';

  @override
  String get notificationConfigurePrayerTimes => 'Configure prayer times';

  @override
  String get notificationTestPickerTitle => 'Select a notification to test';

  @override
  String get notificationTestPickerSubtitle =>
      'You will receive a sample notification with action buttons.';

  @override
  String get notificationTestReviewTitle => 'Daily Review 📖';

  @override
  String get notificationTestReviewBody =>
      'You have 5 ayahs due for review today ⚡';

  @override
  String get notificationTestStreakTitle => 'Streak Protection 🔥';

  @override
  String get notificationTestStreakBody =>
      'You haven\'t reviewed today — protect your streak now 🔥';

  @override
  String get notificationTestSuccess => 'Test notification sent successfully ✨';

  @override
  String get notificationSettingsSaveFailed =>
      'Your change could not be saved. Please try again.';

  @override
  String get notificationSettingsSchedulingFailed =>
      'Your change was saved, but reminders could not be updated. Please try again.';

  @override
  String get prayerChooseCityForAccurateTimes =>
      'Choose your city to show accurate prayer times.';

  @override
  String get prayerChooseCityAction => 'Choose city';

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
      'Choose the adult or kids path the next time you open the Memorization tab.';

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
  String get settingsDeleteAccountSubtitle =>
      'Permanently delete your account and its progress';

  @override
  String settingsDeleteAccountWarning(Object email) {
    return 'The account $email, its profile, progress, plans, bookmarks, certificates, guardian links and associated rewards will be deleted from the cloud.\n\nIts local progress, dependent child profiles and pending operations will also be erased from this device. Deletion cannot be undone.\n\nIndependent linked accounts and files saved or shared outside the app remain. Clear app data on your other devices too.\n\nPermanently delete the account?';
  }

  @override
  String get settingsAccountDeletedMessage =>
      'Account deleted and its data cleared from this device.';

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
  String get parentDashboardTitle => 'Family Dashboard';

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
  String guardianPairingExpiresIn(String minutes) {
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
      'Go to Settings → Kids & Guardian → Family Dashboard → “Link New Child”';

  @override
  String get guardianPairingStepScanOrEnterCode =>
      'Scan the QR code or enter the code manually';

  @override
  String get guardianLinkLater => 'Link later';

  @override
  String get guardianLinkLaterHint =>
      'You can link any time from ⚙ in your journey.';

  @override
  String get guardianCheckNow => 'Scanned? Check now';

  @override
  String get guardianLinkedSuccess => 'Linked with your guardian ✓';

  @override
  String get parentDashboardNotLinkCode => 'This isn\'t a Talia link code';

  @override
  String get familyDashboardLinking => 'Linking the child…';

  @override
  String get familyPinOptionalHelp =>
      'Optional on your phone: keeps others out of the Family Dashboard.';

  @override
  String get familyPinSkip => 'Continue without a lock';

  @override
  String get familyPinLockOn => 'Lock the dashboard with a PIN';

  @override
  String get familyPinLockRemove => 'Remove the dashboard lock';

  @override
  String get familyPinLockRemoveConfirm =>
      'The Family Dashboard will open on this device without a PIN. You can lock it again any time.';

  @override
  String get kidsGuardianLinkedBadge => 'Your guardian follows your journey 💚';

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
  String get guardianLinkingFailedTitle => 'Guardian linking failed';

  @override
  String get guardianLinkingTimeoutMessage =>
      'Guardian linking is taking too long. Check your connection and try again, or continue without a guardian for now.';

  @override
  String get splashSubtitle =>
      'Read, memorize, review, and grow with the Quran.';

  @override
  String get splashTagline => 'Your Companion in the Journey of the Quran';

  @override
  String get splashFeatureRead => 'Read';

  @override
  String get splashFeatureMemorize => 'Memorize';

  @override
  String get splashFeatureReview => 'Review';

  @override
  String get splashFeatureGrow => 'Grow';

  @override
  String get onboardingStartJourney => 'Start Your Journey';

  @override
  String get onboardingSlide1Title => 'Your Daily Quran Sanctuary';

  @override
  String get onboardingSlide1Subtitle =>
      'Authentic Uthmani Mushaf, eye-comfort reading, recitations from renowned reciters, and khatmah plans at your own pace.';

  @override
  String get onboardingBentoMushafSurah => 'Surat Al-Isra';

  @override
  String get onboardingBentoListeningTitle => 'Masterful Recitation';

  @override
  String get onboardingBentoListeningDesc => 'Audio listening & repeat';

  @override
  String get onboardingBentoKhatmahTitle => 'Khatmah Plans';

  @override
  String get onboardingBentoKhatmahDesc => 'A daily pace that suits you';

  @override
  String get onboardingBentoKhatmahBadge => 'Daily wird';

  @override
  String get onboardingSlide2Title => 'Smart Memorization & Mastery';

  @override
  String get onboardingSlide2Subtitle =>
      'Intelligent spaced repetition algorithms that track memory strength and prevent forgetting.';

  @override
  String get onboardingBentoMasteryTitle => 'Mastery & Retention';

  @override
  String get onboardingBentoMasteryValue => '98% Mastered';

  @override
  String get onboardingBentoActiveRecallTitle => 'Active Recall';

  @override
  String get onboardingBentoActiveRecallDesc => 'Hide words for self-testing';

  @override
  String get onboardingBentoReviewScheduleTitle => 'Smart Review';

  @override
  String get onboardingBentoReviewScheduleDesc => 'Timely memory refresh';

  @override
  String get onboardingBentoStatusMastered => 'Mastered';

  @override
  String get onboardingBentoStatusDueSoon => 'Due soon';

  @override
  String get onboardingBentoStatusNew => 'New';

  @override
  String get onboardingBentoSmartAlert => 'Smart alert';

  @override
  String get onboardingSlide3Title => 'Daily Habit & Family Journeys';

  @override
  String get onboardingSlide3Subtitle =>
      'Build an unbreakable daily Quran habit, with a fun interactive kids path, even offline.';

  @override
  String get onboardingBentoStreakTitle => 'Daily Streak';

  @override
  String get onboardingBentoStreakDays => '7 Days Streak 🔥';

  @override
  String get onboardingBentoOfflineBadge => 'Works offline';

  @override
  String get onboardingBentoKidsTeaserTitle => 'Talia Kids Journey';

  @override
  String get onboardingBentoKidsTeaserDesc => 'Stars, audios & joyful rewards';

  @override
  String get onboardingPillarReadTitle => 'Authentic Mushaf Reading';

  @override
  String get onboardingPillarMemorizeTitle => 'Smart Memorization & Review';

  @override
  String get onboardingPillarHabitTitle => 'Daily Portion & Continuity';

  @override
  String get onboardingChooseExpTitle => 'Choose Your Experience';

  @override
  String get onboardingChooseExpSubtitle =>
      'Select how you\'d like Talia configured. You can easily switch anytime in settings.';

  @override
  String get onboardingAdultPathTitle => 'Adult & General Journey';

  @override
  String get onboardingAdultPathSubtitle =>
      'A focused workspace for reading, memorization, review, and personal progress.';

  @override
  String get onboardingKidsPathTitle => 'Kids & Buds Journey';

  @override
  String get onboardingKidsPathSubtitle =>
      'A playful, interactive journey with bite-sized missions, positive repetition, and rewards.';

  @override
  String get onboardingKidsFeatureMissions => 'Bite-sized missions';

  @override
  String get onboardingKidsFeatureAudio => 'Interactive audio repetition';

  @override
  String get onboardingKidsFeatureStars => 'Encouraging stars & rewards';

  @override
  String get onboardingEnterAsGuest => 'Continue as guest';

  @override
  String get onboardingSignInAccount => 'Sign in / Create account';

  @override
  String get onboardingAyahReference => 'Al-Muzzammil 73:4';

  @override
  String get onboardingOfflineTrustLine =>
      'Works offline · your data stays on your device';

  @override
  String get onboardingErrorGeneric =>
      'Setup could not finish. Make sure the device has storage space and try again, or skip setup for now.';

  @override
  String get onboardingSkip => 'Skip';

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
  String get kidsJourneyMotivation =>
      'With every ayah, you draw closer to Allah\'s Book';

  @override
  String get kidsJourneySignpost1 => 'Our Quran journey is beautiful';

  @override
  String get kidsJourneySignpost2 => 'Every step is light';

  @override
  String get kidsJourneySignpost3 => 'We continue Allah\'s book';

  @override
  String kidsPointsValue(String points) {
    return '$points points';
  }

  @override
  String kidsLevelValue(String level) {
    return 'Level $level';
  }

  @override
  String get kidsStartFirstStageToday => 'Start your first stage today';

  @override
  String kidsStageAyahRange(String stage, String startAyah, String endAyah) {
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
  String kidsStageTitle(String stage) {
    return 'Stage $stage';
  }

  @override
  String kidsStageProgress(
    String startAyah,
    String endAyah,
    String completed,
    String total,
  ) {
    return 'Ayahs $startAyah-$endAyah • $completed/$total';
  }

  @override
  String get quranLongPressHint =>
      'Long-press an ayah to listen or add a bookmark';

  @override
  String get readPageConfirmed => 'Page counted';

  @override
  String get readPageCounting => 'Counting this page shortly';

  @override
  String get kidsProgressTitle => 'My progress';

  @override
  String get kidsProgressSubtitle =>
      'Your stars, achievements and certificates';

  @override
  String get kidsProgressTaliaStart =>
      'Let\'s begin! Memorize your first ayah to earn your first achievement';

  @override
  String kidsProgressTaliaNew(String title) {
    return 'Masha\'Allah! You earned “$title”';
  }

  @override
  String kidsProgressTaliaNext(String title) {
    return 'You\'re close to “$title”, keep going!';
  }

  @override
  String get kidsProgressTaliaAllDone =>
      'Masha\'Allah! You collected every achievement';

  @override
  String kidsProgressLevel(String levelText) {
    return 'Level $levelText';
  }

  @override
  String get kidsProgressLevelLabel => 'Level';

  @override
  String get kidsProgressStars => 'Stars';

  @override
  String get kidsProgressStreak => 'Days in a row';

  @override
  String get kidsProgressAyahs => 'Ayahs memorized';

  @override
  String get kidsProgressWeekPages => 'Pages this week';

  @override
  String get kidsProgressRecentTitle => 'Recent activity';

  @override
  String get kidsProgressRecentEmpty =>
      'Read or memorize and your activity shows here';

  @override
  String get kidsProgressCertificatesEmpty =>
      'Finish a surah to earn your first certificate';

  @override
  String get kidsAchievementsTitle => 'My achievements';

  @override
  String kidsAchievementsCount(String unlockedText, String totalText) {
    return '$unlockedText of $totalText';
  }

  @override
  String kidsAchievementProgress(String currentText, String targetText) {
    return '$currentText / $targetText';
  }

  @override
  String get kidsAchievementFirstAyah => 'First ayah';

  @override
  String get kidsAchievementAyahs10 => '10 ayahs';

  @override
  String get kidsAchievementAyahs50 => '50 ayahs';

  @override
  String get kidsAchievementAyahs100 => '100 ayahs';

  @override
  String get kidsAchievementFirstSurah => 'First surah';

  @override
  String get kidsAchievementSurahs3 => '3 surahs';

  @override
  String get kidsAchievementSurahs10 => '10 surahs';

  @override
  String get kidsAchievementFirstPage => 'First page';

  @override
  String get kidsAchievementPages10 => '10 pages';

  @override
  String get kidsAchievementPages30 => '30 pages';

  @override
  String get kidsAchievementStreak3 => '3 days in a row';

  @override
  String get kidsAchievementStreak7 => 'A full week';

  @override
  String get kidsAchievementStreak30 => 'A month in a row';

  @override
  String get kidsAchievementFirstStar => 'First star';

  @override
  String get kidsAchievementStars10 => '10 stars';

  @override
  String get kidsAchievementStars50 => '50 stars';

  @override
  String get childDetailProgressTitle =>
      'Progress, achievements and certificates';

  @override
  String get childDetailProgressUnavailable =>
      'The child\'s progress hasn\'t arrived yet. It appears after the child opens the app online.';

  @override
  String get childDetailCertificatesEmpty => 'No certificates yet';

  @override
  String get childDetailCertificateOpenHint =>
      'Tap a certificate to print or share it';

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
  String accuracyRequiredPercent(String percent) {
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
  String kidsCompleteStageToday(String stage) {
    return 'Complete stage $stage today';
  }

  @override
  String get kidsFirstMissionSubtitle =>
      'Start listening and repeating, every step brings you closer to a new star.';

  @override
  String kidsRemainingAyahs(String count) {
    return '$count ayahs remaining in this stage.';
  }

  @override
  String notificationEverydayAt(String time) {
    return 'Everyday at $time';
  }

  @override
  String get kidsGamifiedWelcome => 'Welcome, memorization hero!';

  @override
  String kidsGamifiedWelcomeNamed(String name) {
    return 'Welcome, $name, memorization hero!';
  }

  @override
  String kidsGamifiedLevelProgress(String level, String progress) {
    return 'Level $level — $progress/100';
  }

  @override
  String kidsGamifiedStarsCount(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText stars',
      one: '$countText star',
    );
    return '$_temp0';
  }

  @override
  String get kidsGamifiedLastMission => 'Your mission';

  @override
  String get kidsGamifiedContinueNow => 'Continue now';

  @override
  String get kidsGamifiedMushaf => 'Mushaf';

  @override
  String get kidsGamifiedJourney => 'My journey';

  @override
  String get kidsGamifiedMissions => 'Missions';

  @override
  String kidsGamifiedHouseTitle(String number) {
    return 'Memorization House $number';
  }

  @override
  String kidsGamifiedReviewHouseTitle(String number) {
    return 'Review House $number';
  }

  @override
  String kidsGamifiedAyahRange(String startAyah, String endAyah) {
    return 'Ayahs $startAyah-$endAyah';
  }

  @override
  String kidsGamifiedProgressCount(String completed, String total) {
    return '$completed/$total';
  }

  @override
  String get kidsGamifiedLockedStage => 'This house is locked for now';

  @override
  String kidsGamifiedDailyLimitReached(int count) {
    return 'You finished today\'s missions. MashaAllah! Come back tomorrow for a new house.';
  }

  @override
  String get kidsDailyMissionsTitle => 'Today\'s missions';

  @override
  String get kidsReadingMissionTitle => 'Read a page of your Mushaf';

  @override
  String get kidsMissionDone => 'Done ✓';

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
  String get kidsGamifiedTryFromMemory => 'Try from memory';

  @override
  String get kidsGamifiedTryToRemember => 'Try to remember the ayah';

  @override
  String get kidsGamifiedGiveMeTheStart => 'Give me the start';

  @override
  String get kidsGamifiedFirstWordShown =>
      'Here is the first word — you finish it';

  @override
  String get kidsGamifiedReviewChallenge => '⭐ Review challenge';

  @override
  String get kidsGamifiedReviewChallengeSubtitle =>
      'Do you remember it? Recite it from memory';

  @override
  String get kidsGamifiedRemindMe => 'Remind me';

  @override
  String get kidsTaliaListenBubble => 'Listen with me, then repeat it!';

  @override
  String get kidsTaliaRecallBubble => 'You can do it! Take your time';

  @override
  String get kidsTaliaRecordingBubble => 'I am listening…';

  @override
  String get kidsTaliaReviewBubble => 'Let\'s see what you remember!';

  @override
  String get kidsTaliaEncourageBubble => 'Great try! One more time';

  @override
  String get kidsTaliaCelebrateBubble => 'Well done! May Allah bless you';

  @override
  String get kidsTaliaGuideBubble => 'Your mission is ready, let\'s go!';

  @override
  String get kidsTaliaWelcomeBackBubble => 'I missed you!';

  @override
  String get kidsTreasuresTitle => 'My treasures';

  @override
  String get kidsTreasuresEmpty =>
      'Memorize your first surah to find your first treasure!';

  @override
  String get kidsRegionBeginning => 'The beginning';

  @override
  String get kidsRegionPalmOasis => 'Palm Oasis';

  @override
  String get kidsRegionFlowerValley => 'Flower Valley';

  @override
  String get kidsRegionStarMountain => 'Star Mountain';

  @override
  String get kidsRegionPearlSea => 'Pearl Sea';

  @override
  String kidsRegionProgress(
    int memorized,
    int total,
    String memorizedText,
    String totalText,
  ) {
    return '$memorizedText of $totalText surahs';
  }

  @override
  String get kidsTaliaFarewellBubble => 'Great work today! See you tomorrow';

  @override
  String get kidsTaliaJourneyDoneBubble => 'You finished the whole journey!';

  @override
  String get kidsTaliaMapBubble => 'Let\'s continue the adventure!';

  @override
  String get kidsTaliaStageReadyBubble => 'Are you ready?';

  @override
  String get kidsWelcomeBackTitle => 'Welcome back!';

  @override
  String get kidsWelcomeBackSubtitle => 'Let\'s start with an easy step';

  @override
  String get kidsGamifiedEnoughForToday =>
      'Well done! That\'s enough time for today — you can stop here.';

  @override
  String get parentSupportTip =>
      'Try together: listen to the ayah twice, then let your child start with the first word';

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
  String get kidsManualCompleteAction => 'I finished memorizing';

  @override
  String get kidsManualCompleteHint =>
      'Audio or microphone unavailable? A guardian can confirm completion.';

  @override
  String kidsGamifiedListenFirst(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText times',
      one: 'once',
    );
    return 'Listen to the ayah $_temp0 before recording your voice.';
  }

  @override
  String get kidsGamifiedAudioLoading => 'Preparing recitation...';

  @override
  String get kidsGamifiedWellDone => 'Well done!';

  @override
  String kidsGamifiedEarnedStars(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText stars',
      one: '$countText star',
    );
    return '+$_temp0';
  }

  @override
  String kidsGamifiedEarnedGems(String count) {
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
  String dailyPlanCompletedSubtitle(String count) {
    return 'You completed $count items successfully.\nKeep going with this steady pace.';
  }

  @override
  String get dailyPlanNewAyahsShort => 'New ayahs';

  @override
  String get dailyPlanReviewShort => 'Review';

  @override
  String get dailyPlanBlessingAction => 'May Allah bless you ✨';

  @override
  String dailyPlanRatingExcellent(String ayahNumber) {
    return '✅ Excellent! Ayah $ayahNumber was scheduled for a longer review interval';
  }

  @override
  String get dailyPlanRatingAverage =>
      '⏰ Good effort, this will be reviewed after a moderate interval';

  @override
  String dailyPlanRatingWeak(String ayahNumber) {
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
  String get memorizationHubReviewSectionTitle => 'Review';

  @override
  String get memorizationHubReviewSectionSubtitle =>
      'Recite what you memorized from memory; the app checks your recitation.';

  @override
  String get memorizationHubReviewCardDescription =>
      'Recite the ayahs due for review from memory.';

  @override
  String get memorizationHubDailyPlanSubtitle =>
      'Your default place for daily memorization and review.';

  @override
  String get memorizationHubContinuePlanDescription =>
      'Open your current memorization and review plan.';

  @override
  String get memorizationHubViewPlanTitle => 'View Today\'s Plan';

  @override
  String get memorizationHubPracticeSectionTitle => 'Practice';

  @override
  String get memorizationHubPracticeSectionSubtitle =>
      'Choose a surah or use recite practice.';

  @override
  String get memorizationHubPracticeBySurahTitle => 'Practice by Surah';

  @override
  String get memorizationHubPracticeBySurahDescription =>
      'Recite Practice: choose a surah and start a speech-to-text session.';

  @override
  String get listeningReviewTitle => 'Listening Quiz';

  @override
  String get listeningReviewHubDescription =>
      'Hear an ayah you memorized: name its surah or recite what comes next.';

  @override
  String get listeningReviewStartPrompt => 'Choose a round type';

  @override
  String get listeningReviewModeWhichSurah => 'Which surah?';

  @override
  String get listeningReviewModeNextAyah => 'Continue the next ayah';

  @override
  String get listeningReviewModeMixed => 'Mixed';

  @override
  String listeningReviewLastScore(String correct, String total) {
    return 'Last round: $correct of $total';
  }

  @override
  String get listeningReviewNotEnoughTitle => 'Memorize a few ayahs first';

  @override
  String get listeningReviewNotEnoughBody =>
      'The listening quiz needs at least 5 memorized ayahs that can be played.';

  @override
  String get listeningReviewErrorBody =>
      'Couldn\'t prepare the round. Please try again.';

  @override
  String get listeningReviewRetry => 'Try again';

  @override
  String listeningReviewQuestionProgress(String current, String total) {
    return 'Question $current of $total';
  }

  @override
  String listeningReviewReplay(String remaining) {
    return 'Replay ($remaining)';
  }

  @override
  String get listeningReviewWhichSurahPrompt =>
      'Which surah is this ayah from?';

  @override
  String listeningReviewNextAyahPrompt(String surah) {
    return 'Surah $surah: recite the next ayah';
  }

  @override
  String get listeningReviewRecord => 'Start reciting';

  @override
  String get listeningReviewStopRecord => 'Stop';

  @override
  String get listeningReviewCantRecord => 'I can\'t record';

  @override
  String get listeningReviewReveal => 'Reveal the ayah';

  @override
  String get listeningReviewGradeMastered => 'Got it';

  @override
  String get listeningReviewGradeHesitant => 'Hesitated';

  @override
  String get listeningReviewGradeForgot => 'Forgot';

  @override
  String get listeningReviewCorrect => 'Correct';

  @override
  String get listeningReviewWrong => 'Not quite';

  @override
  String get listeningReviewNext => 'Next';

  @override
  String get listeningReviewResultTitle => 'Round complete';

  @override
  String listeningReviewResultScore(String correct, String total) {
    return '$correct of $total';
  }

  @override
  String get listeningReviewWeakLinksTitle => 'Links to review';

  @override
  String get listeningReviewNoWeakLinks => 'No weak links this round';

  @override
  String listeningReviewAyahRef(String surah, String ayah) {
    return 'Surah $surah · Ayah $ayah';
  }

  @override
  String get listeningReviewNewRound => 'New round';

  @override
  String get listeningReviewAudioPlaying => 'Playing the ayah…';

  @override
  String listeningReviewBreakdownWhichSurah(String correct, String total) {
    return 'Which surah?: $correct of $total';
  }

  @override
  String listeningReviewBreakdownNextAyah(String correct, String total) {
    return 'Continue the next ayah: $correct of $total';
  }

  @override
  String get memorizationHubSettingsSectionSubtitle =>
      'Adjust the plan without changing memorization systems.';

  @override
  String get memorizationHubPlanSettingsTitle => 'Plan Settings';

  @override
  String get memorizationHubPlanSettingsDescription =>
      'Adjust your daily plan or memorization path settings.';

  @override
  String get memorizationHubKidsMissionSectionSubtitle =>
      'Start from the child’s active mission.';

  @override
  String get memorizationHubKidsMissionCardDescription =>
      'Start the next memorization mission in the kids journey.';

  @override
  String get memorizationHubKidsJourneyTitle => 'Journey';

  @override
  String get memorizationHubKidsJourneySubtitle =>
      'See current and upcoming journey stages.';

  @override
  String get memorizationHubKidsJourneyDescription =>
      'See current and upcoming journey stages.';

  @override
  String get memorizationHubKidsRewardsTitle => 'Rewards / Progress';

  @override
  String get memorizationHubKidsRewardsSubtitle =>
      'Review stars and points from Progress.';

  @override
  String get memorizationHubKidsRewardsDescription =>
      'Review points and stars from the Progress screen.';

  @override
  String get memorizationHubHeaderSubtitle =>
      'One place for every memorization path';

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
    String surahId,
    String ayahNumber,
    String repeats,
    String points,
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
  String get parentDashboardForgotPin => 'Forgot the code?';

  @override
  String get parentDashboardForgotPinTitle => 'Recover guardian code';

  @override
  String parentDashboardForgotPinBody(String email) {
    return 'To confirm you are the guardian, enter the password for $email. You will then create a new code; rewards and settings stay as they are.';
  }

  @override
  String get parentDashboardForgotPinConfirm => 'Verify';

  @override
  String get parentDashboardAccountPasswordIncorrect =>
      'Incorrect account password';

  @override
  String get parentDashboardAccountCheckUnavailable =>
      'Couldn\'t verify the account right now. Check your connection and try again.';

  @override
  String get parentDashboardChangePin => 'Change guardian code';

  @override
  String get parentDashboardChangePinConfirm =>
      'You\'ll create a new code now. Rewards and settings stay as they are.';

  @override
  String get guardianErrorSignInRequired =>
      'Sign in to your account first, then try again.';

  @override
  String get guardianErrorCloudUnavailable =>
      'Linking children isn\'t available in this version because cloud sync is not enabled.';

  @override
  String get guardianErrorOnlyForChildren =>
      'Guardian linking is only available for child profiles.';

  @override
  String get guardianErrorAlreadyLinked =>
      'This account is already linked to a guardian.';

  @override
  String get guardianErrorParentModeAdultsOnly =>
      'Guardian mode is only available on the adults path.';

  @override
  String get guardianErrorLinkCodeInvalid =>
      'The linking code is incorrect or has expired. Ask the child to create a new code and try again.';

  @override
  String get guardianErrorChildHasGuardian =>
      'This child is already linked to another guardian. The current link must be removed first.';

  @override
  String get guardianErrorSameAccount =>
      'A child can\'t be linked to the same account. The child needs an account separate from the guardian\'s.';

  @override
  String get parentRewardErrorTitleRequired => 'Enter the reward name first.';

  @override
  String get parentRewardErrorLimitReached => 'You can add up to 3 rewards.';

  @override
  String get parentRewardErrorUnavailable =>
      'This gift isn\'t available for that step right now. Refresh and try again.';

  @override
  String get parentRewardUnlockedFeedback => 'Gift unlocked';

  @override
  String get parentRewardApprovedFeedback => 'Gift hand-over confirmed';

  @override
  String get parentRewardStatusWaitingForChild =>
      'Unlocked, waiting for the child to ask';

  @override
  String get parentRewardStatusRequested => 'The child is asking for it';

  @override
  String get parentRewardUnlockAction => 'Unlock';

  @override
  String get parentRewardApproveAction => 'Confirm hand-over';

  @override
  String familyDashboardOfflineCached(String time) {
    return 'Couldn\'t connect. Showing the data received on $time.';
  }

  @override
  String get familyDashboardRemoteUnavailable =>
      'Couldn\'t load your linked children. Check your connection and try again.';

  @override
  String get kidsHomeMissionsUnavailable =>
      'Couldn\'t load the home missions right now.';

  @override
  String get guardianSessionTileTitle => 'Family Dashboard';

  @override
  String get guardianSessionTileSubtitle =>
      'For the guardian only, needs the PIN';

  @override
  String get guardianSessionBackToChild => 'Back to child';

  @override
  String get kidsGiftsTitle => 'My gifts';

  @override
  String get kidsGiftLocked => 'Reach your goal to unlock this gift';

  @override
  String get kidsGiftUnlocked => 'Your gift is ready!';

  @override
  String get kidsGiftRequested => 'Request sent, waiting for your grown-up';

  @override
  String get kidsGiftClaimed => 'Received, well done!';

  @override
  String get kidsGiftRequestAction => 'I want it!';

  @override
  String childErrorNicknameInvalid(String max) {
    return 'Enter a name of 1 to $max characters.';
  }

  @override
  String childErrorAgeInvalid(String min, String max) {
    return 'Choose an age between $min and $max.';
  }

  @override
  String get guardianErrorChildNotLinked =>
      'This child is no longer linked to your account.';

  @override
  String get guardianUnlinkTileTitle => 'Remove guardian link';

  @override
  String get guardianUnlinkTileSubtitle =>
      'Needs the PIN and an internet connection';

  @override
  String get guardianUnlinkConfirmTitle => 'Remove the guardian link?';

  @override
  String get guardianUnlinkConfirmBody =>
      'Your guardian won\'t follow your progress anymore, and no new missions or gifts will arrive. Gifts you received stay; unfinished gifts and missions disappear from this device. You can link again later.';

  @override
  String get guardianUnlinkAction => 'Remove link';

  @override
  String get guardianUnlinkDone => 'Guardian link removed';

  @override
  String get guardianErrorUnlinkFailed =>
      'Couldn\'t remove the link, so nothing changed. Check you\'re online and signed in, then try again.';

  @override
  String get pinRecoveryUnavailable =>
      'Recovering the PIN needs a connection and an account linked to a guardian, or the request has expired.';

  @override
  String get pinRecoveryTitle => 'Replace a forgotten PIN';

  @override
  String get pinRecoveryInstructions =>
      'Ask your guardian to open your page in the family dashboard on their device and approve the request. Then type the code they see and a new PIN.';

  @override
  String get pinRecoveryCodeLabel => 'Guardian\'s code';

  @override
  String get pinRecoveryNewPinLabel => 'New PIN (4 digits)';

  @override
  String get pinRecoveryWrongCode =>
      'The code is wrong, not approved yet, or expired.';

  @override
  String get pinRecoveryDone => 'PIN changed';

  @override
  String get pinRecoveryRequestTitle => 'PIN change request';

  @override
  String get pinRecoveryRequestBody =>
      'Your child\'s device asked to change the PIN. Approve only if you\'re with them or asked for it yourself.';

  @override
  String get pinRecoveryApproveAction => 'Approve and show code';

  @override
  String get pinRecoveryCodeTitle => 'One-time code';

  @override
  String pinRecoveryCodeBody(String time) {
    return 'Type this code on your child\'s device with a new PIN. Valid until $time.';
  }

  @override
  String get guardianErrorUnlinkBeforePathChange =>
      'Couldn\'t remove the guardian link, so the path wasn\'t changed. Check you\'re online and signed in, then try again.';

  @override
  String get resetPathUnlinksGuardianWarning =>
      'This account is linked to a guardian. Changing the path removes the link, so the guardian won\'t follow progress anymore. This needs an internet connection.';

  @override
  String get childErrorIdentityUpdateUnavailable =>
      'Editing the child\'s details isn\'t available right now. Try again later.';

  @override
  String childAgeYears(int age, String ageText) {
    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$ageText years old',
      one: '1 year old',
    );
    return '$_temp0';
  }

  @override
  String get childEditIdentity => 'Edit name and age';

  @override
  String get childIdentitySaved =>
      'Saved. The child\'s device shows the change after its next sync.';

  @override
  String get kidsLinkGuardianTileTitle => 'Link guardian';

  @override
  String get kidsLinkGuardianTileSubtitle =>
      'Needs the guardian\'s code. Once linked, your guardian follows your progress from their device.';

  @override
  String get parentDashboardTodaySummary => 'Today';

  @override
  String get parentDashboardTodayEmpty =>
      'Today: no sessions yet. Encourage a short session.';

  @override
  String parentDashboardTodayCompleted(String count) {
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
  String get parentDashboardDailyReminder => 'Daily reminder for the child';

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
  String parentDashboardRemoteChildSummary(String ayahs, String points) {
    return '$ayahs ayahs • $points points';
  }

  @override
  String parentDashboardMemorizedSummary(
    String memorized,
    String total,
    String percent,
  ) {
    return '$memorized/$total ayahs memorized • $percent%';
  }

  @override
  String parentDashboardReviewsSummary(String completed, String overdue) {
    return '$completed reviews completed • $overdue overdue';
  }

  @override
  String parentDashboardStreakSummary(String days) {
    return 'Streak: $days days';
  }

  @override
  String parentDashboardCertificatesSummary(String count) {
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
  String get parentDashboardReminders => 'Reminders';

  @override
  String get parentDashboardNotSet => 'Not Set';

  @override
  String get parentDashboardEditChild => 'Edit Child Details';

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
  String parentDashboardLogTitle(String surahId, String ayahNumber) {
    return 'Surah $surahId • Ayah $ayahNumber';
  }

  @override
  String parentDashboardLogSubtitle(String repeats, String points) {
    return '$repeats repeats • $points points';
  }

  @override
  String get dailyPlanSettingsTooltip => 'Smart memorization path settings';

  @override
  String get dailyPlanRefreshTooltip => 'Refresh plan';

  @override
  String get dailyPlanHeaderTitle => 'Today\'s Plan';

  @override
  String dailyPlanHeaderSummary(
    int total,
    String totalText,
    String completedText,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalText items',
      one: '$totalText item',
    );
    return '$_temp0 • $completedText completed';
  }

  @override
  String dailyPlanProgressCount(String completed, String total) {
    return '$completed of $total';
  }

  @override
  String get dailyPlanAllDoneShort =>
      'Well done! You completed your plan today';

  @override
  String dailyPlanRemainingItems(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText items',
      one: '$countText item',
    );
    return '$_temp0 remaining';
  }

  @override
  String dailyPlanAyahTitle(String ayahNumber) {
    return 'Ayah $ayahNumber';
  }

  @override
  String dailyPlanSurahAyahTitle(String surah, String ayahNumber) {
    return '$surah · Ayah $ayahNumber';
  }

  @override
  String dailyPlanRecordStats(String strength, String reviews) {
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
  String get dailyPlanNoPlanTitle =>
      'You haven\'t created a memorization plan yet';

  @override
  String get dailyPlanNoPlanSubtitle =>
      'Create your plan to see your daily memorization and review ayahs here.';

  @override
  String get dailyPlanCreatePlanAction => 'Create your plan';

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
  String customPlanSurahAyahLimit(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText ayahs',
      one: '$countText ayah',
    );
    return 'This Surah has $_temp0';
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
  String customPlanApproxWeeks(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText weeks',
      one: '$countText week',
    );
    return '$_temp0 approx.';
  }

  @override
  String customPlanApproxMonths(String count) {
    return '$count months approx.';
  }

  @override
  String customPlanApproxYears(String count) {
    return '$count years approx.';
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
      other: '$surahsText Surahs',
      one: '$surahsText Surah',
    );
    String _temp1 = intl.Intl.pluralLogic(
      ayahs,
      locale: localeName,
      other: '$ayahsText ayahs',
      one: '$ayahsText ayah',
    );
    return '$_temp0 • ~$_temp1';
  }

  @override
  String get customPlanQuickPresetTitle => 'Choose a quick template';

  @override
  String get customPlanPresetLight => 'Light';

  @override
  String get customPlanPresetLightDesc => '3 ayahs/day • 5 days • 20 minutes';

  @override
  String get customPlanPresetLightName => 'Light plan';

  @override
  String get customPlanPresetBalanced => 'Balanced';

  @override
  String get customPlanPresetBalancedDesc =>
      '5 ayahs/day • 6 days • 30 minutes';

  @override
  String get customPlanPresetBalancedName => 'Balanced plan';

  @override
  String get customPlanPresetIntensive => 'Intensive';

  @override
  String get customPlanPresetIntensiveDesc =>
      '10 ayahs/day • every day • 50 minutes';

  @override
  String get customPlanPresetIntensiveName => 'Intensive plan';

  @override
  String get customPlanPresetJuzAmma => 'Juz Amma';

  @override
  String get customPlanPresetJuzAmmaDesc =>
      'From An-Nas to An-Naba • 3 ayahs/day • 20 minutes';

  @override
  String customPlanMinutesLimitHint(String minutes, String count) {
    return '$minutes minutes leave room for only about $count new ayahs. Lengthen the session to reach your daily goal.';
  }

  @override
  String get customPlanPresetJuzAmmaName => 'Juz Amma plan';

  @override
  String get customPlanSummaryTitle => 'Plan summary';

  @override
  String customPlanSummaryRange(Object startSurah, Object endSurah) {
    return 'Range: $startSurah → $endSurah';
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
      other: '$ayahsText ayahs',
      one: '$ayahsText ayah',
    );
    String _temp1 = intl.Intl.pluralLogic(
      daysPerWeek,
      locale: localeName,
      other: '$daysText days',
      one: '$daysText day',
    );
    return '$_temp0 daily • $_temp1 weekly';
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
      other: '$minutesText minutes',
      one: '$minutesText minute',
    );
    return '$_temp0 per session • $difficulty level';
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
  String kidsQuranPageLabel(String pageNumber) {
    return 'Page $pageNumber';
  }

  @override
  String get kidsQuranLongPressHint => 'Long-press any ayah to hear it';

  @override
  String get kidsQuranListenPage => 'Listen to the page';

  @override
  String get kidsQuranPausePage => 'Pause';

  @override
  String get kidsReaderConfirmPage => 'I read this page';

  @override
  String get kidsReaderPageConfirmed => 'Well done! Your reading is saved';

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
  String hifzReviewRangeHint(String startAyah, String endAyah) {
    return 'Review ayahs $startAyah to $endAyah before moving to the next ayah';
  }

  @override
  String get hifzEvaluatingReview => 'Evaluating review…';

  @override
  String get hifzLeaveSessionMessage =>
      'Do you want to leave the memorization session? Your current progress will be saved.';

  @override
  String get memorizationExitSessionMessage =>
      'Continue this session later from where you stopped, or discard it? Failed, unpassed Ayahs will be added to review when discarded.';

  @override
  String get memorizationExitSessionTitle => 'Leave this session?';

  @override
  String get memorizationSaveAndLeave => 'Continue later';

  @override
  String get memorizationDiscardSession => 'Discard session';

  @override
  String hifzAyahNumberLabel(String ayahNumber) {
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
  String get notificationStreakMercyTitle =>
      'Allah is Merciful — your streak awaits you 🌿';

  @override
  String get notificationStreakMercyBody =>
      'You missed a day, and your streak has been re-lit… continue your reading today 🤍';

  @override
  String notificationStreakAlertTitle(Object count) {
    return '⚠️ Don\'t lose your $count day streak!';
  }

  @override
  String notificationStreakGentleTitle(Object count) {
    return 'Your $count-day streak is waiting';
  }

  @override
  String get notificationStreakGentleBody =>
      'A few minutes of review today keeps your streak alive. Whenever you\'re ready 🌿';

  @override
  String get notificationSmartReminderTitle => 'Time for your usual reading';

  @override
  String get notificationSmartReminderBody =>
      'It\'s usually your reading time — a few ayahs are waiting for you.';

  @override
  String get notificationChannelStreakGentleName => 'Gentle streak reminder';

  @override
  String get notificationChannelStreakGentleDescription =>
      'A quiet reminder before the streak protection alert';

  @override
  String get notificationChannelSmartName => 'Smart reminder';

  @override
  String get notificationChannelSmartDescription =>
      'Reminders at your usual reading time';

  @override
  String get notificationStreakAlertBody =>
      'You haven\'t reviewed today yet — you still can';

  @override
  String get notificationActionReviewStart => '⚡ Start review';

  @override
  String get notificationActionDailyWird => '📖 Daily wird';

  @override
  String get notificationActionStreakProtect => '🔥 Protect your streak';

  @override
  String get notificationActionReadWird => '📖 Read the wird';

  @override
  String get notificationActionReadDailyAyah => '✨ Read ayah of the day';

  @override
  String get notificationActionShareAyah => '↗️ Share the ayah';

  @override
  String get notificationActionMorningAzkar => '☀️ Morning azkar';

  @override
  String get notificationActionEveningAzkar => '🌙 Evening azkar';

  @override
  String get notificationActionDailyDua => '🤲 Read today\'s duas';

  @override
  String get notificationActionAzkar => '✨ Azkar';

  @override
  String get notificationActionKidsReview => '🌟 Start reciting, champ';

  @override
  String get notificationActionReadKahf => '📖 Read Surah Al-Kahf';

  @override
  String get notificationActionOpenMushaf => '✨ The Quran';

  @override
  String get notificationActionTahajjudDua => '🤲 Night prayer duas';

  @override
  String get notificationActionFollowKhatmah => '📖 Continue khatmah';

  @override
  String get notificationActionReadQuran => '📖 Read the Quran';

  @override
  String get notificationActionPostPrayerAzkar => '📿 Post-prayer azkar';

  @override
  String get notificationChannelRemindersName => 'Talia reminders';

  @override
  String get notificationChannelRemindersDescription =>
      'Daily review and memorization reminders';

  @override
  String get notificationChannelStreakName => 'Streak protection';

  @override
  String get notificationChannelStreakDescription =>
      'Alerts to protect your memorization streak';

  @override
  String get notificationChannelDailyAyahName => 'Ayah of the Day';

  @override
  String get notificationChannelDailyAyahDescription =>
      'A daily ayah from the Holy Quran with reflection';

  @override
  String get notificationChannelMorningAzkarName => 'Morning azkar';

  @override
  String get notificationChannelMorningAzkarDescription =>
      'Morning azkar reminders';

  @override
  String get notificationChannelEveningAzkarName => 'Evening azkar';

  @override
  String get notificationChannelEveningAzkarDescription =>
      'Evening azkar reminders';

  @override
  String get notificationChannelDailyDuaName => 'Dua of the Day';

  @override
  String get notificationChannelDailyDuaDescription =>
      'Daily dua and supplication reminders';

  @override
  String get notificationChannelKidsName => 'Kids recitation';

  @override
  String get notificationChannelKidsDescription =>
      'Kids review and recitation reminders';

  @override
  String get notificationChannelKahfName => 'Surah Al-Kahf';

  @override
  String get notificationChannelKahfDescription =>
      'Friday Surah Al-Kahf reading reminders';

  @override
  String get notificationChannelTahajjudName => 'Night prayer & Witr';

  @override
  String get notificationChannelTahajjudDescription =>
      'Qiyam al-layl reminders in the last third of the night';

  @override
  String get notificationChannelKhatmahName => 'Khatmah wird';

  @override
  String get notificationChannelKhatmahDescription =>
      'Khatmah progress reminders';

  @override
  String get notificationChannelMilestonesName => 'Achievement celebrations';

  @override
  String get notificationChannelMilestonesDesc =>
      'Celebrations when you complete a juz, a surah, or a full khatmah';

  @override
  String notificationMilestoneJuzTitle(String juz) {
    return '🎉 Juz $juz memorized!';
  }

  @override
  String notificationMilestoneJuzBody(String juz) {
    return 'Masha\'Allah, tabarak Allah! You have completed memorizing all of Juz $juz. May Allah keep it firm in your heart.';
  }

  @override
  String notificationMilestoneSurahTitle(String surah) {
    return '🎉 Surah $surah memorized!';
  }

  @override
  String notificationMilestoneSurahBody(String surah) {
    return 'Masha\'Allah! You have completed memorizing Surah $surah. May Allah bless it and make it a light for you.';
  }

  @override
  String get notificationMilestoneKhatmahTitle =>
      '🎉 Khatmah of the Noble Quran complete!';

  @override
  String get notificationMilestoneKhatmahBody =>
      'Alhamdulillah! You have completed a full khatmah of the Quran. May Allah accept it from you and reward you with the best of rewards.';

  @override
  String get notificationMilestoneStreakTitle => '🔥 30 consecutive days!';

  @override
  String get notificationMilestoneStreakBody =>
      'Thirty days of steady review, masha\'Allah! Keep your chain of light going.';

  @override
  String get notificationChannelPrayerName => 'Prayer times & Adhan';

  @override
  String get notificationChannelPrayerDescription =>
      'Alerts when a prayer time enters';

  @override
  String get notificationChannelPrayerAthanName => 'Prayer athan sound';

  @override
  String get notificationChannelPrayerAthanDescription =>
      'Prayer alerts with the bundled athan clip';

  @override
  String get notificationChannelPrayerCompanionName => 'Prayer Companion';

  @override
  String get notificationChannelPrayerCompanionDescription =>
      'Gentle Prayer Companion self-confirmation reminders';

  @override
  String get notificationActionCompanionConfirm => 'Yes, I prayed it';

  @override
  String get notificationActionCompanionPrayNow => 'I will pray now';

  @override
  String get notificationActionCompanionRemindLater => 'Remind me later';

  @override
  String get notificationCompanionPreparationTitle => 'Get ready for prayer';

  @override
  String notificationCompanionPreparationBody(Object prayer) {
    return '$prayer prayer is coming up soon';
  }

  @override
  String get notificationCompanionCheckInTitle => 'Prayer Companion';

  @override
  String notificationCompanionCheckInBody(Object prayer) {
    return 'Did you pray $prayer?';
  }

  @override
  String get notificationCompanionFollowUpTitle => 'Prayer Companion';

  @override
  String notificationCompanionFollowUpBody(Object prayer) {
    return 'A gentle reminder: did you pray $prayer?';
  }

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
  String get notificationDailyDuaBody =>
      'Today\'s dua is waiting for you in Talia';

  @override
  String get notificationFridayKahfTitle => 'Surah Al-Kahf Reminder 🌿';

  @override
  String get notificationWeeklyImpactTitle => 'Your impact this week 🌿';

  @override
  String notificationWeeklyImpactBody(String count) {
    return '$count days of your week were with the Quran — every page leaves a lasting impact';
  }

  @override
  String get notificationWeeklyImpactQuietBody =>
      'A new week begins — one page makes a difference 🌱';

  @override
  String get notificationSettingsWeeklyImpact => 'Weekly impact (Friday)';

  @override
  String get notificationFridayKahfBody =>
      'Blessed Friday! Remember to read Surah Al-Kahf today to illuminate your week ✨';

  @override
  String get notificationTahajjudTitle => 'Tahajjud & Night Prayer 🌙';

  @override
  String get notificationTahajjudBody =>
      'A peaceful moment for prayer and supplication in the last third of the night.. May Allah accept your prayers 🤲';

  @override
  String get notificationKhatmahTitle => 'Daily Khatmah Reading 📖';

  @override
  String get notificationKhatmahBody =>
      'Continue your blessed journey with your Quran Khatmah today 🌿';

  @override
  String notificationKhatmahBodyWithTarget(Object start, Object end) {
    return 'Today\'s portion: page $start to $end.. Keep going! ✨';
  }

  @override
  String notificationPrayerTitle(Object prayer) {
    return 'Time for $prayer Prayer 🕌';
  }

  @override
  String get notificationPrayerBody =>
      'Come to prayer, come to success.. May Allah bless your prayer';

  @override
  String get notificationSettingsFridayKahf => 'Surah Al-Kahf (Friday)';

  @override
  String get notificationSettingsFridayKahfSub =>
      'Weekly Friday reminder to read Surah Al-Kahf';

  @override
  String get notificationSettingsTahajjud => 'Tahajjud & Night Prayer';

  @override
  String get notificationSettingsTahajjudSub =>
      'Daily reminder in the last third of the night';

  @override
  String get notificationSettingsKhatmah => 'Khatmah Progress';

  @override
  String get notificationSettingsKhatmahSub =>
      'Daily reminder for your active Khatmah target';

  @override
  String get notificationSettingsPrayerTimes => 'Prayer Times';

  @override
  String get notificationSettingsPrayerTimesSub =>
      'Reminders at the time of each of the 5 daily prayers';

  @override
  String get notificationSettingsPrayerAthan => 'Full Adhan';

  @override
  String get notificationSettingsPrayerAthanSub =>
      'Plays the full adhan at prayer time with a stop control';

  @override
  String get muezzinPickerTitle => 'Choose muezzin';

  @override
  String get muezzinPickerSubtitle =>
      'Pick your favorite adhan voice and preview it before saving';

  @override
  String get muezzinDefault => 'Default adhan';

  @override
  String get muezzinPickerSave => 'Save';

  @override
  String get muezzinPreviewPlay => 'Preview';

  @override
  String get muezzinPreviewStop => 'Stop preview';

  @override
  String get muezzinFajrSectionTitle => 'Fajr adhan';

  @override
  String get muezzinFajrSameAsGeneral => 'Same as other prayers';

  @override
  String get muezzinFajrBadge => 'Fajr';

  @override
  String muezzinFajrSummary(String general, String fajr) {
    return '$general for prayers, $fajr for Fajr';
  }

  @override
  String get notificationSettingsPrayerNeedsTimes =>
      'Set up prayer times and choose your city first';

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
  String get tutorialS1Title => 'Getting started with Talia';

  @override
  String get tutorialS1Cat => 'Start';

  @override
  String get tutorialS1Does =>
      'Talia opens with a short intro, lets you choose the adult or kids path, then takes you to Home. You can use it as a guest and sign in later.';

  @override
  String get tutorialS1Open =>
      'It appears the first time you open the app. Afterwards, use the bottom bar to move between Home, Quran, Memorization, Adhkar and Progress.';

  @override
  String get tutorialS1Useful =>
      'Helpful for new users who want the map of the app before reading or memorizing.';

  @override
  String get tutorialS1Step1 => 'Go through the intro pages, or tap Skip.';

  @override
  String get tutorialS1Step2 =>
      'Choose the adult or kids path, then continue as a guest or sign in.';

  @override
  String get tutorialS1Step3 =>
      'Use the bottom bar to move between the main sections.';

  @override
  String get tutorialS1Tip1 =>
      'Start from Home: it gathers today\'s reading, your progress and shortcuts.';

  @override
  String get tutorialS1Tip2 =>
      'You can change the memorization path later in Settings > Quran & Memorization.';

  @override
  String get tutorialS1Note1 =>
      'Signing in is optional. Without it your progress stays on this device.';

  @override
  String get tutorialS1Note2 =>
      'Settings are behind the gear icon at the top of Home.';

  @override
  String get tutorialS2Title => 'Home';

  @override
  String get tutorialS2Cat => 'Start';

  @override
  String get tutorialS2Does =>
      'Home shows the next prayer, a main card for what to do next, today\'s wird, your streak and XP, the ayah of the day and your recent activity.';

  @override
  String get tutorialS2Open => 'Tap Home in the bottom bar.';

  @override
  String get tutorialS2Useful =>
      'The best daily starting point: reading, memorizing and follow-up in one screen.';

  @override
  String get tutorialS2Step1 =>
      'Tap the main card to continue reading, resume a session or open today\'s plan.';

  @override
  String get tutorialS2Step2 => 'Tap \"Something else\" to see other options.';

  @override
  String get tutorialS2Step3 => 'Open Settings with the gear icon at the top.';

  @override
  String get tutorialS2Step4 =>
      'Tap \"Choose city\" to set your city for prayer times.';

  @override
  String get tutorialS2Tip1 =>
      'The ring shows the share of the whole Quran you have memorized, so it grows slowly. The seven dots are the last seven days, ending today.';

  @override
  String get tutorialS2Tip2 =>
      'Tap the icons under the ayah of the day to share it, open it in the Mushaf or listen to it.';

  @override
  String get tutorialS2Note1 =>
      'Some cards appear only when there is data, such as a started khatmah or a saved reading position.';

  @override
  String get tutorialS2Note2 => 'The account card can be dismissed with the X.';

  @override
  String get tutorialS3Title => 'Reading the Quran';

  @override
  String get tutorialS3Cat => 'Quran';

  @override
  String get tutorialS3Does =>
      'The Quran tab lists the surahs, the juz and your bookmarks. The reader shows the Mushaf page with tajweed colors, audio, bookmarks and a focus mode.';

  @override
  String get tutorialS3Open =>
      'Tap Quran, then choose a surah or a juz. You can also open today\'s wird from Home.';

  @override
  String get tutorialS3Useful =>
      'For your daily wird, looking up an ayah, or reading before a memorization session.';

  @override
  String get tutorialS3Step1 =>
      'Choose a surah from the list, or use the search box at the top.';

  @override
  String get tutorialS3Step2 => 'Swipe to turn the page.';

  @override
  String get tutorialS3Step3 =>
      'Long-press an ayah to listen to it, copy it, bookmark it, share it or start memorizing it.';

  @override
  String get tutorialS3Step4 =>
      'Open the menu with the three dots to go to a page, surah or juz, choose a reciter, switch tajweed colors on or off, or enter focus mode.';

  @override
  String get tutorialS3Step5 =>
      'Stay on a page for a few seconds while reading: it is counted as read automatically.';

  @override
  String get tutorialS3Tip1 =>
      'Listen to an ayah before memorizing it to get the pronunciation right.';

  @override
  String get tutorialS3Tip2 =>
      'The Continue reading card on the Quran tab takes you back to your last page.';

  @override
  String get tutorialS3Note1 =>
      'The Quran text is bundled with the app, so it displays without a connection.';

  @override
  String get tutorialS3Note2 =>
      'Audio needs a connection unless it was already cached.';

  @override
  String get tutorialS4Title => 'Search and bookmarks';

  @override
  String get tutorialS4Cat => 'Quran';

  @override
  String get tutorialS4Does =>
      'Find a surah by name or an ayah by its words, and keep important ayahs as bookmarks.';

  @override
  String get tutorialS4Open =>
      'Use the search box at the top of the Quran tab, or the search icon on Home. Bookmarks have their own tab on the Quran screen.';

  @override
  String get tutorialS4Useful =>
      'For collecting ayahs to review, similar ayahs, or places you want to come back to.';

  @override
  String get tutorialS4Step1 => 'Type a surah name or words from an ayah.';

  @override
  String get tutorialS4Step2 => 'Open the surah or the ayah from the results.';

  @override
  String get tutorialS4Step3 =>
      'Long-press an ayah in the reader and choose Bookmark.';

  @override
  String get tutorialS4Step4 =>
      'Open the Bookmark tab to return to saved ayahs or remove them.';

  @override
  String get tutorialS4Tip1 =>
      'Bookmark the start of each memorization section to return to it quickly.';

  @override
  String get tutorialS4Tip2 =>
      'Search ignores diacritics, so you can type plain Arabic.';

  @override
  String get tutorialS4Note1 =>
      'Ayah search shows at most 50 results: add more words to narrow it.';

  @override
  String get tutorialS4Note2 =>
      'Removing a bookmark does not affect any reading or memorization progress.';

  @override
  String get tutorialS5Title => 'Memorizing step by step';

  @override
  String get tutorialS5Cat => 'Memorization';

  @override
  String get tutorialS5Does =>
      'The Memorization tab brings together today\'s plan, practice by surah, the listening quiz and reviews by recitation. Every ayah goes through learn, memorize and recite.';

  @override
  String get tutorialS5Open =>
      'Tap Memorization. On first use you choose the adult or kids path.';

  @override
  String get tutorialS5Useful =>
      'For systematic memorization with spaced reviews, so what you memorize stays.';

  @override
  String get tutorialS5Step1 =>
      'Create a plan, or pick a surah under Practice by Surah.';

  @override
  String get tutorialS5Step2 => 'Learn: listen to the ayah and read it.';

  @override
  String get tutorialS5Step3 =>
      'Memorize: try without looking, and use the hints (first word, first letters, show the ayah) only when needed.';

  @override
  String get tutorialS5Step4 =>
      'Recite: record your recitation, or grade yourself honestly if speech recognition is unavailable. A block of ayahs is then recited together.';

  @override
  String get tutorialS5Tip1 =>
      'Hints are recorded and affect when the ayah comes back for review.';

  @override
  String get tutorialS5Tip2 =>
      'Change how strict recitation checking is in Settings > Quran & Memorization > Accuracy level.';

  @override
  String get tutorialS5Note1 =>
      'Leaving a session asks whether to continue later or discard it.';

  @override
  String get tutorialS5Note2 =>
      'Without speech recognition or microphone permission, grading yourself is a fully supported route.';

  @override
  String get tutorialS6Title => 'Daily adhkar and the counter';

  @override
  String get tutorialS6Cat => 'Adhkar';

  @override
  String get tutorialS6Does =>
      'Morning and evening adhkar, general adhkar and duas, with a repetition counter, an index, free tasbeeh and a smart wird that follows the time of day.';

  @override
  String get tutorialS6Open =>
      'Tap Adhkar, then choose morning, evening, general adhkar, duas, smart wird or free tasbeeh.';

  @override
  String get tutorialS6Useful =>
      'For the morning and evening wird, tasbeeh sessions, and sharing a dua quickly.';

  @override
  String get tutorialS6Step1 =>
      'Choose a category; the one for the current time is highlighted at the top.';

  @override
  String get tutorialS6Step2 =>
      'Tap the counter once for each repetition; it moves to the next dhikr when you finish.';

  @override
  String get tutorialS6Step3 => 'Open the index to jump to a specific dhikr.';

  @override
  String get tutorialS6Step4 =>
      'Change the text size, copy or share the dhikr when needed.';

  @override
  String get tutorialS6Step5 =>
      'When you finish, reset the session or go back.';

  @override
  String get tutorialS6Tip1 =>
      'Turn on morning and evening reminders in Settings > Notifications.';

  @override
  String get tutorialS6Tip2 =>
      'Press and hold the counter to undo the last count.';

  @override
  String get tutorialS6Note1 =>
      'The adhkar are bundled with the app and work offline.';

  @override
  String get tutorialS6Note2 =>
      'Counters belong to the current day\'s session; they are not a memorization certificate.';

  @override
  String get tutorialS7Title => 'Daily plan and reviews';

  @override
  String get tutorialS7Cat => 'Memorization';

  @override
  String get tutorialS7Does =>
      'Your plan serves new ayahs and reviews every day. Reviews return on a schedule based on how well you recited, so what you memorize stays firm.';

  @override
  String get tutorialS7Open =>
      'Memorization > Continue Today\'s Plan, or the main card on Home.';

  @override
  String get tutorialS7Useful =>
      'For steady memorization with smart review instead of relying on memory alone.';

  @override
  String get tutorialS7Step1 =>
      'Open Continue Today\'s Plan from the Memorization tab.';

  @override
  String get tutorialS7Step2 => 'Finish the new ayahs of the day.';

  @override
  String get tutorialS7Step3 =>
      'Do the Review Session when ayahs are due: the badge shows how many.';

  @override
  String get tutorialS7Step4 =>
      'Open View Today\'s Plan to see what is done and what remains.';

  @override
  String get tutorialS7Step5 =>
      'Try the Listening Quiz once you have memorized a few ayahs: it plays an ayah and asks you to name its surah or continue it.';

  @override
  String get tutorialS7Tip1 =>
      'Grade yourself honestly: it decides how strong the ayah is and when it returns.';

  @override
  String get tutorialS7Tip2 =>
      'If the plan feels heavy, lower the daily ayahs in Plan Settings.';

  @override
  String get tutorialS7Note1 =>
      'On rest days (set by days per week) you get reviews only.';

  @override
  String get tutorialS7Note2 =>
      'The Listening Quiz needs at least five memorized ayahs.';

  @override
  String get tutorialS8Title => 'Setting up your plan';

  @override
  String get tutorialS8Cat => 'Memorization';

  @override
  String get tutorialS8Does =>
      'Create your plan from a quick preset or from scratch: name, surah range, ayahs per day, days per week, session length, difficulty and reviews.';

  @override
  String get tutorialS8Open =>
      'Memorization > Create plan, or Plan Settings later.';

  @override
  String get tutorialS8Useful =>
      'For a specific goal, such as memorizing a particular juz, or planning a child\'s memorization.';

  @override
  String get tutorialS8Step1 =>
      'Pick a quick preset (Light, Balanced, Intensive, Juz Amma) or fill in the fields yourself.';

  @override
  String get tutorialS8Step2 =>
      'Choose the surah range. Choosing Child takes you to the kids path, where kids plans are managed.';

  @override
  String get tutorialS8Step3 =>
      'Set ayahs per day, days per week and session length.';

  @override
  String get tutorialS8Step4 =>
      'Choose the difficulty and turn near and far revision on or off.';

  @override
  String get tutorialS8Step5 => 'Save and start the plan.';

  @override
  String get tutorialS8Tip1 =>
      'The session length limits new ayahs, at about four minutes each. A note appears if the minutes are too short for your goal.';

  @override
  String get tutorialS8Tip2 => 'Start small to build a habit, then increase.';

  @override
  String get tutorialS8Note1 =>
      'The plan can be deleted from the setup screen.';

  @override
  String get tutorialS8Note2 =>
      'The finishing time shown on the screen is an estimate.';

  @override
  String get tutorialS9Title => 'Kids mode and parent tools';

  @override
  String get tutorialS9Cat => 'Memorization';

  @override
  String get tutorialS9Does =>
      'A journey of memorization houses with stars, levels and repeated listening for children, plus parent tools for follow-up.';

  @override
  String get tutorialS9Open =>
      'Choose the kids path. The parent PIN is set during kids setup. Parent tools appear on Home once you are signed in.';

  @override
  String get tutorialS9Useful =>
      'For children and beginners, or for a parent who wants to follow stars, sessions and rewards.';

  @override
  String get tutorialS9Step1 =>
      'Choose the kids path, then enter the child\'s name, age, starting surah and a four-digit parent PIN.';

  @override
  String get tutorialS9Step2 =>
      'On the kids home tap Continue now, listen to the ayah three times, then try from memory.';

  @override
  String get tutorialS9Step3 =>
      'If recording does not work, tap \"I finished memorizing\": the parent enters the PIN to confirm.';

  @override
  String get tutorialS9Step4 =>
      'Follow the journey map: houses open one after another as missions are completed.';

  @override
  String get tutorialS9Tip1 =>
      'Keep the PIN private: it also protects leaving the kids path.';

  @override
  String get tutorialS9Tip2 =>
      'Use the Mushaf tab on the kids home to let the child read in the Quran.';

  @override
  String get tutorialS9Note1 =>
      'Linking a child from another device needs an account.';

  @override
  String get tutorialS9Note2 =>
      'One child per device: more children use their own devices, linked to the guardian.';

  @override
  String get tutorialS10Title => 'Progress, achievements and certificates';

  @override
  String get tutorialS10Cat => 'Progress';

  @override
  String get tutorialS10Does =>
      'Shows your reading and memorization statistics, your daily streak, achievements, your certificates, and lets you share your progress.';

  @override
  String get tutorialS10Open => 'Tap Progress in the bottom bar.';

  @override
  String get tutorialS10Useful =>
      'For a weekly review, celebrating achievements and tracking consistency.';

  @override
  String get tutorialS10Step1 =>
      'Review the top cards for streak days, pages read, XP and reviews.';

  @override
  String get tutorialS10Step2 =>
      'Open the reading and memorization sections for pages, ayahs, surahs and juz.';

  @override
  String get tutorialS10Step3 =>
      'Switch the achievement filters between all, reading, memorization and streak.';

  @override
  String get tutorialS10Step4 =>
      'Tap an unlocked achievement for details and sharing.';

  @override
  String get tutorialS10Step5 =>
      'Your certificates appear when you complete a surah, a juz or the whole Quran.';

  @override
  String get tutorialS10Tip1 =>
      'Reading a khatmah counts toward your streak, but not toward free-reading statistics.';

  @override
  String get tutorialS10Tip2 =>
      'Certificates depend on genuinely memorizing the required ayahs.';

  @override
  String get tutorialS10Note1 =>
      'Some statistics appear only after you start memorizing.';

  @override
  String get tutorialS10Note2 =>
      'Sharing happens only when you choose to share.';

  @override
  String get tutorialS11Title => 'Settings, account and notifications';

  @override
  String get tutorialS11Cat => 'Settings';

  @override
  String get tutorialS11Does =>
      'Gathers your account and profile, language and theme, Quran and memorization settings, prayer times, notifications and information about the app.';

  @override
  String get tutorialS11Open => 'Tap the gear icon on Home.';

  @override
  String get tutorialS11Useful =>
      'For personalizing the app, protecting your progress and setting reminders that suit your day.';

  @override
  String get tutorialS11Step1 =>
      'Sign in or create an account with an email and password to manage your account.';

  @override
  String get tutorialS11Step2 => 'Edit your name under Profile.';

  @override
  String get tutorialS11Step3 =>
      'Choose Arabic or English, and the light, dark, pure black or system theme.';

  @override
  String get tutorialS11Step4 =>
      'Under Quran & Memorization, set background playback and the accuracy level, or reset your path.';

  @override
  String get tutorialS11Step5 =>
      'Under Prayer times, choose your city and calculation method.';

  @override
  String get tutorialS11Step6 =>
      'Under Notifications, turn reminders for reviews, streak, adhkar and prayers on or off.';

  @override
  String get tutorialS11Tip1 =>
      'Write your name in Arabic so it looks right on certificates.';

  @override
  String get tutorialS11Tip2 =>
      'Reset the path under Quran & Memorization to switch between adult and kids.';

  @override
  String get tutorialS11Note1 =>
      'Notifications need the system permission to work.';

  @override
  String get tutorialS11Note2 =>
      'Language and theme are stored on this device.';

  @override
  String get tutorialS12Title => 'Working offline and your data';

  @override
  String get tutorialS12Cat => 'Settings';

  @override
  String get tutorialS12Does =>
      'The Quran and adhkar texts are bundled with the app. Your progress, plans and settings are stored on the device. With an account, some of it also syncs online.';

  @override
  String get tutorialS12Open =>
      'There is no separate screen: it works automatically while you use the app.';

  @override
  String get tutorialS12Useful =>
      'For understanding what works offline and avoiding the loss of important progress.';

  @override
  String get tutorialS12Step1 =>
      'Read the Quran and use the adhkar even without internet.';

  @override
  String get tutorialS12Step2 =>
      'Keep reading and memorizing: progress is saved on the device.';

  @override
  String get tutorialS12Step3 =>
      'Sign in when you want account features or to restore your memorization progress.';

  @override
  String get tutorialS12Tip1 =>
      'On a new device, sign in to restore what your account supports.';

  @override
  String get tutorialS12Tip2 =>
      'Connect to the internet to play recitations that are not cached.';

  @override
  String get tutorialS12Note1 =>
      'Clearing the app\'s data in system settings removes anything not saved to your account.';

  @override
  String get tutorialS12Note2 =>
      'Signing out removes your khatmah plan and history from this device: they are stored only here.';

  @override
  String get tutorialS14Note2 =>
      'Reliable alerts may need the exact-alarm permission in phone settings.';

  @override
  String get tutorialS14Note1 =>
      'Times are calculated on the device, so they work offline.';

  @override
  String get tutorialS14Tip2 =>
      'If you are unsure which method fits, pick the one your local authority uses.';

  @override
  String get tutorialS14Tip1 =>
      'If your city is not listed, use a custom location: copy its coordinates from a maps app.';

  @override
  String get tutorialS14Step4 =>
      'Turn on prayer calm mode if you want recitation to pause when prayer time starts.';

  @override
  String get tutorialS14Step3 =>
      'Turn on prayer alerts: they switch on automatically the first time you set a location.';

  @override
  String get tutorialS14Step2 =>
      'Choose the calculation method (automatic by country by default) and the Asr calculation.';

  @override
  String get tutorialS14Step1 =>
      'Choose your country and city, or Custom location to enter coordinates.';

  @override
  String get tutorialS14Useful =>
      'For knowing prayer times wherever you are, with an alert when it is time.';

  @override
  String get tutorialS14Open =>
      'On Home tap Choose city, or open Settings > Prayer times.';

  @override
  String get tutorialS14Does =>
      'Shows prayer times and the next prayer on Home, and can alert you at each prayer.';

  @override
  String get tutorialS14Cat => 'Settings';

  @override
  String get tutorialS14Title => 'Prayer times and alerts';

  @override
  String get tutorialS13Note2 =>
      'It is stored only on this device, and is removed when you sign out.';

  @override
  String get tutorialS13Note1 =>
      'The khatmah is separate from free reading: neither moves the other\'s position.';

  @override
  String get tutorialS13Tip2 =>
      'If you fall behind, use the options on the dashboard to catch up.';

  @override
  String get tutorialS13Tip1 =>
      'You can dedicate the khatmah to someone you love when you create it.';

  @override
  String get tutorialS13Step4 =>
      'If you read from a printed Mushaf, use Record to enter the pages.';

  @override
  String get tutorialS13Step3 =>
      'Read the day\'s wird: each page you read is recorded.';

  @override
  String get tutorialS13Step2 =>
      'Start the khatmah and tap Continue reading on the dashboard.';

  @override
  String get tutorialS13Step1 =>
      'Choose pages per day or a duration, and optionally a start page.';

  @override
  String get tutorialS13Useful =>
      'For reading the Quran regularly with a clear goal, such as in Ramadan.';

  @override
  String get tutorialS13Open =>
      'On Home tap Start your khatmah, or open the khatmah card once you have started one.';

  @override
  String get tutorialS13Does =>
      'Plan a full reading of the Quran at the pace you choose, by pages per day or by number of days. Talia tracks your progress page by page and keeps a history of completed khatmahs.';

  @override
  String get tutorialS13Cat => 'Quran';

  @override
  String get tutorialS13Title => 'Khatmah: reading the whole Quran';

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
  String certificateCelebrationMultiple(String count) {
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
  String reviewBacklogSubtitle(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText overdue ayahs',
      one: '$countText overdue ayah',
    );
    return 'You have $_temp0';
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
  String get khatmahContinueTitle => 'Continue Khatmah';

  @override
  String get khatmahContinueSubtitle => 'Continue your Quran completion plan';

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
  String get parentDashboardLinkHint => 'e.g. A1B2-C3D4-E5F6';

  @override
  String get familyDashboardTitle => 'Family Dashboard';

  @override
  String get familyDashboardMyChildren => 'My Children';

  @override
  String get familyDashboardAddChild => 'Link New Child';

  @override
  String get familyDashboardNoChildren => 'No children linked yet';

  @override
  String get familyDashboardNoChildrenHint =>
      'On your child\'s device: open the kids track → tap ⚙ → “Link guardian”, then scan the code shown or type it here.';

  @override
  String get familyDashboardTodaySummaryTitle => 'Today in Our Family';

  @override
  String familyDashboardTodaySummary(String count, String points) {
    return '$count active today · $points pts';
  }

  @override
  String get familyDashboardLocalBadge => 'On this device';

  @override
  String familyDashboardChildActiveToday(String points) {
    return '$points pts today';
  }

  @override
  String get familyDashboardChildNoActivity => 'No activity today';

  @override
  String get familyDashboardNicknameSaved => 'Name saved';

  @override
  String childDetailTitle(String name) {
    return '$name\'s Progress';
  }

  @override
  String childDetailTodayActivity(String sessions, String points) {
    return '$sessions sessions · $points pts today';
  }

  @override
  String get childDetailNoActivity => 'No activity today';

  @override
  String get childDetailMemorizationProgress => 'Memorization Progress';

  @override
  String get childDetailActivityTitle => 'Child activity';

  @override
  String get childDetailActivityNotReceived =>
      'No activity has arrived from the child\'s device yet';

  @override
  String childDetailActivityUpdatedAt(String date) {
    return 'Last updated: $date';
  }

  @override
  String childDetailActivityStreak(String days, String longest) {
    return 'Current streak: $days · Longest: $longest';
  }

  @override
  String childDetailActivityActiveDays(String days) {
    return 'Active days in the last 30: $days';
  }

  @override
  String childDetailActivityPages(String total, String today) {
    return 'Pages read: $total · Today: $today';
  }

  @override
  String get childDetailRecentSessions => 'Recent Sessions';

  @override
  String childDetailRewards(String count) {
    return 'Rewards ($count)';
  }

  @override
  String get childDetailAddReward => 'Add Reward';

  @override
  String get childDetailOpenFullDashboard => 'Open Full Dashboard';

  @override
  String get kidsPreparing => 'Getting things ready...';

  @override
  String get kidsUnexpectedError => 'Something went wrong!';

  @override
  String get v2LearningTitle => 'Learn the ayah';

  @override
  String get v2LearningSubtitle => 'Listen and read before trying to memorize.';

  @override
  String get v2StartMemorizing => 'Start memorizing';

  @override
  String get v2MemorizingTitle => 'Memorize the ayah';

  @override
  String get v2MemorizingSubtitle =>
      'Practice from memory. Hints are only available here.';

  @override
  String get v2ReadyToRecite => 'I am ready';

  @override
  String get v2FirstWordHint => 'First word';

  @override
  String get v2ShowAyahHint => 'Show ayah';

  @override
  String get v2RecitationTitle => 'Recite from memory';

  @override
  String get v2RecitationSubtitle =>
      'The ayah text is hidden. Record without hints.';

  @override
  String get v2StartRecording => 'Start recording';

  @override
  String get v2StopRecording => 'Stop recording';

  @override
  String get v2ManualRecallAction => 'I recited it from memory (self-grade)';

  @override
  String get v2SelfGradeAction => 'Grade your recitation yourself';

  @override
  String get v2SelfGradeTitle => 'How did your recitation from memory go?';

  @override
  String get v2SelfGradeMastered => 'Mastered';

  @override
  String get v2SelfGradeMasteredHint => 'Recited it fully without hesitation';

  @override
  String get v2SelfGradeHesitated => 'Hesitated a little';

  @override
  String get v2SelfGradeHesitatedHint =>
      'Recited with a pause or small slip; it will come back soon';

  @override
  String get v2SelfGradeForgot => 'Could not recall it';

  @override
  String get v2SelfGradeForgotHint => 'We will go over it again now';

  @override
  String get v2SelfGradeRevealHint =>
      'Recite from memory first, then reveal the text and compare before grading.';

  @override
  String get v2SelfGradeRevealAction => 'Show the ayah to compare';

  @override
  String get v2BlockRevealAction => 'Show the block to compare';

  @override
  String get v2BlockGradeMastered =>
      'Recited the whole block without stumbling';

  @override
  String get v2BlockGradeHesitated => 'Hesitated on an ayah';

  @override
  String get v2BlockGradeForgot => 'Forgot an ayah';

  @override
  String get v2StumbledAyahTitle => 'Where did you stumble?';

  @override
  String v2StumbledAyahOption(String ayahNumber) {
    return 'Ayah $ayahNumber';
  }

  @override
  String get v2ManualRecallHint =>
      'No microphone? Confirm you recited from memory and your progress will be saved.';

  @override
  String get v2ManualBlockReviewAction => 'Grade the block recitation yourself';

  @override
  String get v2RemediationTitle => 'Short remediation';

  @override
  String get v2RemediationSubtitle =>
      'Listen and read again, then return to recitation.';

  @override
  String get v2TryAgain => 'Try again';

  @override
  String get v2BlockReviewPendingTitle => 'Block review';

  @override
  String get v2BlockReviewPendingSubtitle =>
      'All individual ayahs passed. Next, recite the full block from memory.';

  @override
  String get v2StartBlockReview => 'Start Block Review';

  @override
  String get v2BlockReviewTitle => 'Recite the full block';

  @override
  String v2BlockReviewSubtitle(String startAyah, String endAyah) {
    return 'Text is hidden. Record ayahs $startAyah-$endAyah together without hints.';
  }

  @override
  String get v2CompletionTitle => 'Session complete';

  @override
  String get v2CompletionSubtitle =>
      'This memorization block has been completed.';

  @override
  String get closingMomentLabel => 'A moment of closure';

  @override
  String closingSummaryMemorization(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText ayahs',
      one: '$countText ayah',
    );
    return 'You learned $_temp0 this session — reviews will make them stick, in shaa Allah.';
  }

  @override
  String get closingSummaryReview =>
      'Your review is complete — may it stay firmly rooted in your heart.';

  @override
  String get v2ReviewSessionTitle => 'Review Session';

  @override
  String get v2HintSchedulingNotice =>
      'Hints are recorded and shape your next review schedule.';

  @override
  String dailyPlanBacklogNotice(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText ayahs',
      one: '$countText ayah',
    );
    return 'You have $_temp0 due for review. Finish today\'s reviews to unlock new ayahs.';
  }

  @override
  String get dailyPlanStartReview => 'Start today\'s review';

  @override
  String get dailyPlanReviewDayNotice =>
      'Today is a review day in your plan: no new ayahs, strengthen what you\'ve memorized.';

  @override
  String closingSummaryKhatmahWird(String start, String end) {
    return 'You completed today\'s wird — pages $start to $end — a lasting impact, in shaa Allah.';
  }

  @override
  String get closingDuaButton => 'Closing dua';

  @override
  String get closingDua =>
      'O Allah, make what I have memorized a light in my heart and a remembrance with You. Make it a supporter for me, benefit me with what You have taught me, and teach me what benefits me.';

  @override
  String get closingDuaAmen => 'Ameen';

  @override
  String get closingDone => 'Done, praise be to Allah';

  @override
  String get closingRestNote =>
      'Take a breath… your memorization awaits you tomorrow, in shaa Allah.';

  @override
  String get v2MemorizationHub => 'Memorization Hub';

  @override
  String v2NextPlanItem(String count) {
    return 'Next in today\'s plan ($count left)';
  }

  @override
  String get v2TryWithoutHint => 'Try without a hint first';

  @override
  String get v2FirstWordRevealed => 'First word revealed';

  @override
  String get v2Evaluating => 'Evaluating...';

  @override
  String get v2RecordingNow => 'Recording now';

  @override
  String get v2PressRecord => 'Press record when you are ready';

  @override
  String get v2MicrophoneUnavailable =>
      'Speech recognition is not available on this device. Grade your recitation yourself.';

  @override
  String get v2TryRecordingAgain => 'Try recording again';

  @override
  String get v2NoSpeechDetected =>
      'We could not hear a recitation. Please record again.';

  @override
  String get v2MicrophonePermissionDenied =>
      'Microphone permission is required to record.';

  @override
  String get v2MicrophoneOpenSettings =>
      'Microphone access is blocked. Open Settings to allow it.';

  @override
  String get v2AudioPlaybackFailed =>
      'Could not play the ayah audio. Try again.';

  @override
  String v2RemediationAttempts(String count) {
    return 'Attempts needing remediation: $count';
  }

  @override
  String v2AyahRange(String startAyah, String endAyah) {
    return 'Ayahs $startAyah-$endAyah';
  }

  @override
  String v2BlockProgress(String passed, String total) {
    return '$passed/$total ayahs passed individually.';
  }

  @override
  String v2AyahOfBlock(String current, String total) {
    return 'Ayah $current of $total';
  }

  @override
  String get v2EvaluatingBlock => 'Evaluating block...';

  @override
  String get v2RecordingBlock => 'Recording block now';

  @override
  String get v2Playing => 'Playing';

  @override
  String get v2ListenToAyah => 'Listen to ayah';

  @override
  String get v2Passed => 'Passed';

  @override
  String get v2Retries => 'Retries';

  @override
  String get v2ResultExcellent => 'Excellent! Flawless recitation';

  @override
  String get v2ResultPassed => 'Ayah passed';

  @override
  String get v2ResultRetrying => 'So close! Try again';

  @override
  String get v2ResultNeedsWork => 'This ayah needs review';

  @override
  String v2ResultSimilarity(String score) {
    return 'Match: $score%';
  }

  @override
  String get v2ResultManualGrade => 'Self-graded recitation';

  @override
  String get v2ResultContinue => 'Continue';

  @override
  String get v2ResultRetryNow => 'Recite again now';

  @override
  String get v2ResultReviewAyah => 'Review the ayah';

  @override
  String get v2ResultWordsCorrect => 'correct';

  @override
  String get v2ResultWordsMissing => 'missing';

  @override
  String get v2ResultWordsWrong => 'wrong';

  @override
  String get v2ResultWordsExtra => 'extra';

  @override
  String get v2LoopOff => 'Repeat: off';

  @override
  String get v2LoopThree => 'Repeat: 3x';

  @override
  String get v2LoopInfinite => 'Repeat: endless';

  @override
  String get v2MaskedWordsHint => 'Show masked words';

  @override
  String get v2MaskedWordsRevealed => 'Words are hidden — try to recall';

  @override
  String get v2MaskedWordsFull => 'Hide words';

  @override
  String get v2FirstLettersHint => 'First letters';

  @override
  String get v2FirstLettersRevealed => 'First letters revealed — try to recall';

  @override
  String countAyahs(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText ayahs',
      one: '$countText ayah',
    );
    return '$_temp0';
  }

  @override
  String streakDaysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String get v2SurahLoadFailed => 'Could not load surah data.';

  @override
  String get v2NoAyahsInRange =>
      'No ayahs are available in the selected range.';

  @override
  String get kidsRecordingUnavailable =>
      'The microphone did not work. Try again or ask a parent for help.';

  @override
  String get kidsRecordingNotCaptured =>
      'We could not hear your recitation clearly. Please record the ayah again.';

  @override
  String get kidsRecitationMismatch =>
      'The ayah did not match. Listen again and then record your recitation.';

  @override
  String kidsRecitationCloseMatch(String matched, String total) {
    return 'So close! You got $matched of $total words right. Listen again and try once more.';
  }

  @override
  String get kidsJourneyCompleteHint =>
      'You completed Al-Fatiha and the whole Juz Amma! Tell your parent about this great achievement.';

  @override
  String get kidsHomeMissionInvalidTitle =>
      'Write a mission between 1 and 120 characters';

  @override
  String get kidsPolicyReduceMotion => 'Reduce motion';

  @override
  String get kidsPolicyMaxSuggestions => 'Missions per day';

  @override
  String get kidsPolicyHomeMissions => 'Home missions';

  @override
  String get kidsPolicyConflict => 'Settings changed on another device';

  @override
  String get kidsHomeMissionUnavailable =>
      'This mission is not available for this action';

  @override
  String get kidsPolicyUnavailable =>
      'Couldn\'t load the child\'s settings right now.';

  @override
  String get childDetailHomeMissions => 'Home missions';

  @override
  String get childDetailAddHomeMission => 'Add mission';

  @override
  String get kidsHomeMissionAssigned => 'Waiting for child';

  @override
  String get kidsHomeMissionReportAction => 'I did it!';

  @override
  String get familyChildUnnamed => 'My child';

  @override
  String get familyChildDetailsLoading => 'Loading…';

  @override
  String get kidsHomeMissionsTitle => 'Missions from your guardian';

  @override
  String get kidsHomeMissionNew => 'New mission';

  @override
  String get kidsHomeMissionWaitingGuardian =>
      'You told your guardian. Waiting for them to see it';

  @override
  String get kidsHomeMissionsPaused =>
      'Your guardian paused home missions for now. They\'ll show here again when turned back on.';

  @override
  String get kidsHomeMissionReported => 'Child says it\'s done';

  @override
  String get kidsHomeMissionAcknowledged => 'Seen by guardian';

  @override
  String get kidsHomeMissionAcknowledgeAction => 'Mark as seen';

  @override
  String get kidsHomeMissionSuggestTidy => 'Tidy your room';

  @override
  String get kidsHomeMissionSuggestHelp => 'Help set the table';

  @override
  String get kidsHomeMissionSuggestKind =>
      'Say something kind to a family member';

  @override
  String get kidsHomeMissionSuggestShare => 'Share your toy with someone';

  @override
  String get kidsAyahAlreadyCompleted =>
      'You already completed this ayah. Open the map to continue.';

  @override
  String get accountSwitchOfflineDataDiscarded =>
      'Unsynced progress from the previous account was not uploaded and has been removed from this device.';

  @override
  String get startYourJourneyWithQuran => 'Start your journey with the Quran';

  @override
  String get startNow => 'Start now';

  @override
  String get kidsJourneyBetaTitle => 'New memorization journey';

  @override
  String get kidsJourneyBetaDescription =>
      'Enable Today\'s Mission and spaced review, with the option to return.';

  @override
  String get kidsGuidanceAudioTitle => 'Guide voice';

  @override
  String get kidsGuidanceAudioDescription =>
      'Short prompts that never play over Quran recitation.';

  @override
  String get kidsSessionGoalTitle => 'Target session length';

  @override
  String kidsSessionGoalValue(String minutes) {
    return '$minutes minutes';
  }

  @override
  String get kidsSessionGoalAgeDefault => 'Age default';

  @override
  String get kidsSetupReminderTime => 'Reminder time';

  @override
  String get kidsSetupWeeklyGoal => 'Weekly goal';

  @override
  String kidsSetupWeeklyGoalValue(String sessions) {
    return '$sessions sessions per week';
  }

  @override
  String get kidsSetupStartingSurah => 'Starting surah';

  @override
  String parentCommitmentDays(String count) {
    return '$count commitment days';
  }

  @override
  String parentDueReviews(String count) {
    return '$count reviews due';
  }

  @override
  String parentNeedsSupport(String count) {
    return '$count ayahs need support';
  }

  @override
  String parentAverageDuration(String minutes) {
    return '$minutes min average';
  }

  @override
  String parentHintUses(String count) {
    return '$count hints used';
  }

  @override
  String get khatmahStartAction => 'Start Khatmah';

  @override
  String get khatmahResumeAction => 'Resume';

  @override
  String get khatmahNoPlanTitle => 'No Khatmah plan yet';

  @override
  String get khatmahNoPlanDescription =>
      'Start a new Khatmah at a pace that suits you.';

  @override
  String get khatmahPausedSummary => 'Khatmah paused — Resume to continue';

  @override
  String get khatmahExistingActivePlan => 'You already have an active Khatmah';

  @override
  String get khatmahExistingPausedPlan => 'You already have a paused Khatmah';

  @override
  String get khatmahViewCurrentPlan => 'View current Khatmah';

  @override
  String get khatmahEndCurrentPlan => 'End current Khatmah';

  @override
  String get khatmahEndCurrentConfirmTitle => 'End current Khatmah?';

  @override
  String khatmahEndCurrentConfirmDescription(String title) {
    return 'This deletes \"$title\". You can then choose to start a new plan.';
  }

  @override
  String get khatmahEndPlanAction => 'End Khatmah';

  @override
  String get khatmahChooseYourDailyReadingPaceToCompleteThe =>
      'Choose your daily reading pace to complete the Quran with serenity.';

  @override
  String get khatmahDailyPages => 'Daily Pages';

  @override
  String khatmahPages(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText pages',
      one: '$countText page',
    );
    return '$_temp0';
  }

  @override
  String get khatmahOrCustomPagesPerDay => 'Or custom pages per day';

  @override
  String get khatmahOrChooseDuration => 'Or choose a duration';

  @override
  String get khatmahStartFromPage => 'Start from page (optional)';

  @override
  String get khatmahStartFromPageHint =>
      'After page 604 you continue from page 1 until the khatmah is complete';

  @override
  String khatmahDurationDays(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText days',
      one: '$countText day',
    );
    return '$_temp0';
  }

  @override
  String get khatmahDurationRamadan => 'Ramadan (a juz a day)';

  @override
  String get khatmahEG5 => 'e.g. 5';

  @override
  String get khatmahEstimatedDuration => 'Estimated Duration';

  @override
  String khatmahDays(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText days',
      one: '$countText day',
    );
    return '$_temp0';
  }

  @override
  String get khatmahExpectedCompletion => 'Expected Completion';

  @override
  String get khatmahStartKhatmah => 'Start Khatmah';

  @override
  String get khatmahPhysicalMushafProgressSavedSuccessfully =>
      'Physical Mushaf progress saved successfully';

  @override
  String get khatmahEndKhatmah => 'End Khatmah';

  @override
  String get khatmahAreYouSureYouWantToEndThis =>
      'Are you sure you want to end this Khatmah? You can always start anew whenever you feel ready.';

  @override
  String get khatmahCancel => 'Cancel';

  @override
  String get khatmahUnableToSaveKhatmahProgress =>
      'Unable to save Khatmah progress.';

  @override
  String get khatmahRetry => 'Retry';

  @override
  String get khatmahLiving => 'Living';

  @override
  String get khatmahDeceased => 'Deceased';

  @override
  String khatmahDedicatedTo(String v1) {
    return 'Dedicated to: $v1';
  }

  @override
  String get khatmahKhatmahDashboard => 'Khatmah Dashboard';

  @override
  String get khatmahUnableToLoadYourKhatmah => 'Unable to load your Khatmah';

  @override
  String get khatmahCheckYourConnectionAndTryAgain =>
      'Check your connection and try again.';

  @override
  String get khatmahReload => 'Reload';

  @override
  String get khatmahQuranKhatmah => 'Quran Khatmah';

  @override
  String get khatmahTodaySWirdCompleted => 'Today\'s Wird completed';

  @override
  String get khatmahTodaySWird => 'Today\'s Wird';

  @override
  String khatmahPagesTo(String v1, String v2) {
    return 'Pages $v1 to $v2';
  }

  @override
  String get khatmahResuming => 'Resuming…';

  @override
  String get khatmahContinueReading => 'Continue Reading';

  @override
  String get khatmahReadFromPhysicalMushaf => 'Read from physical Mushaf?';

  @override
  String get khatmahLog => 'Log';

  @override
  String get khatmahCalmAdaptiveControls => 'Calm Adaptive Controls';

  @override
  String get khatmahEndDateRecalibratedSmoothly =>
      'End date recalibrated smoothly';

  @override
  String get khatmahCalmAdjust => 'Calm Adjust';

  @override
  String get khatmahAdded1PageDayMildCompensation =>
      'Added 1 page/day mild compensation';

  @override
  String get khatmahMildBoost => 'Mild Boost';

  @override
  String get khatmahAdjustPreviewTitle => 'Adjust khatmah schedule';

  @override
  String khatmahAdjustPreviewBody(int pages, String pagesText, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pagesText pages',
      one: '$pagesText page',
    );
    return 'Daily wird: $_temp0\nExpected completion: $date';
  }

  @override
  String get khatmahApplyAdjustment => 'Apply';

  @override
  String get khatmahLoadFailureHint =>
      'Couldn\'t read the khatmah data on this device. Please try again.';

  @override
  String get khatmahPause => 'Pause';

  @override
  String get khatmahResume => 'Resume';

  @override
  String get khatmahLogPhysicalMushafReading => 'Log Physical Mushaf Reading';

  @override
  String get khatmahEnterTheLastPageReadFromYourPhysical =>
      'Enter the last page read from your physical Mushaf (1 - 604):';

  @override
  String get khatmahPageNumber => 'Page number';

  @override
  String khatmahEG(String v1) {
    return 'e.g. $v1';
  }

  @override
  String get khatmahSaveProgress => 'Save Progress';

  @override
  String get khatmahNoSavedCompletionAvailable =>
      'No saved completion available';

  @override
  String get khatmahPagesLabel => 'Pages';

  @override
  String get khatmahDuration => 'Duration';

  @override
  String get khatmahCompleted => 'Completed';

  @override
  String get khatmahDedicationOfReward => 'Dedication of Reward';

  @override
  String get khatmahReadDuAKhatmAlQuran => 'Read Du\'a Khatm al-Quran';

  @override
  String get khatmahShareAchievement => 'Share Achievement';

  @override
  String get khatmahBackToHome => 'Back to Home';

  @override
  String get khatmahDuACopiedToClipboard => 'Du\'a copied to clipboard';

  @override
  String get khatmahDuAKhatmAlQuran => 'Du\'a Khatm al-Quran';

  @override
  String get khatmahDecreaseFontSize => 'Decrease font size';

  @override
  String get khatmahIncreaseFontSize => 'Increase font size';

  @override
  String get khatmahCopyDuA => 'Copy du\'a';

  @override
  String khatmahPagesLeft(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText pages',
      one: '$countText page',
    );
    return '$_temp0 left';
  }

  @override
  String khatmahEstCompletion(String v1) {
    return 'Est. completion: $v1';
  }

  @override
  String get khatmahDedicateKhatmahToSomeone => 'Dedicate Khatmah to someone';

  @override
  String get khatmahRecipientName => 'Recipient Name';

  @override
  String get khatmahEGMyBelovedMother => 'e.g. My beloved mother';

  @override
  String get khatmahRelationship => 'Relationship';

  @override
  String get khatmahCondition => 'Condition';

  @override
  String get khatmahSickRecovery => 'Sick / Recovery';

  @override
  String get khatmahSpecialNoteDuAOptional => 'Special Note / Du\'a (Optional)';

  @override
  String khatmahPageOfOfTodaySWird(String v1, String v2, String v3) {
    return 'page $v1 ($v2 of $v3 of today\'s wird)';
  }

  @override
  String get khatmahSaveExit => 'Finish reading';

  @override
  String get khatmahPaceOnTrack => 'On schedule — well done';

  @override
  String khatmahPaceAhead(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText days',
      one: 'a day',
    );
    return 'Ahead — you\'ll finish $_temp0 early';
  }

  @override
  String get khatmahRedistributeAction =>
      'Redistribute to keep the finish date';

  @override
  String get khatmahRedistributed =>
      'Pages redistributed to keep your finish date';

  @override
  String khatmahPaceBehind(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText pages',
      one: '$countText page',
    );
    return '$_temp0 behind the finish date';
  }

  @override
  String get khatmahStartNewKhatmah => 'Start a new khatmah';

  @override
  String khatmahThroughWirdEnd(String page) {
    return 'Through today\'s wird (p. $page)';
  }

  @override
  String get khatmahCongratulations =>
      'Congratulations on completing the Quran';

  @override
  String khatmahShareSummary(String title, int days, String daysText) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysText days',
      one: '$daysText day',
    );
    return 'Completed Quran Khatmah ($title) in $_temp0.\nVia Talia Quran App';
  }

  @override
  String khatmahUserNote(String note) {
    return 'Your personal note: $note';
  }

  @override
  String khatmahTodayRange(String start, String end, String completed) {
    return 'Today: pages $start - $end$completed';
  }

  @override
  String get khatmahDailyCompletedSuffix => ' — completed';

  @override
  String get khatmahProgress => 'Khatmah progress';

  @override
  String khatmahProgressValue(String completed, String total, String percent) {
    return '$completed of $total pages, $percent percent';
  }

  @override
  String get khatmahSetupSaveError =>
      'Unable to start Khatmah. Please try again.';

  @override
  String get khatmahEndError => 'Unable to end Khatmah. Please try again.';

  @override
  String get khatmahDedicationPreference =>
      'Dedication is available for living and deceased recipients. Deceased recipients are preferred, and Allah knows best.';

  @override
  String get khatmahWriteYourOwnNote => 'Write your personal note here';

  @override
  String get khatmahPhysicalRangeHint =>
      'Record the pages you read, starting from the next unread page.';

  @override
  String khatmahConfirmRange(String start, String end) {
    return 'Record pages $start to $end inclusive.';
  }

  @override
  String khatmahRangeValidation(String start) {
    return 'Enter a page from $start to 604 to confirm the range.';
  }

  @override
  String get khatmahIsPaused => 'Khatmah is paused';

  @override
  String get khatmahProgressNotSaved => 'Progress was not saved';

  @override
  String get khatmahSaving => 'Saving…';

  @override
  String get khatmahDuaLoadError =>
      'Unable to load the supplication. Please try again.';

  @override
  String get khatmahSuggestedDua =>
      'Suggested general supplication after Khatmah';

  @override
  String get khatmahDuaPendingReview =>
      'Text and source review pending. This is a suggested general supplication, not a prescribed Khatmah formula or a text attributed to the Prophet. Its source has not yet been verified.';

  @override
  String get khatmahGeneralGuidance => 'General supplication';

  @override
  String get khatmahRelationshipParent => 'Parent';

  @override
  String get khatmahRelationshipMother => 'Mother';

  @override
  String get khatmahRecipientGender => 'Recipient';

  @override
  String get khatmahRecipientMale => 'Male';

  @override
  String get khatmahRecipientFemale => 'Female';

  @override
  String get khatmahEditDedication => 'Edit dedication';

  @override
  String get khatmahDedicationSaved => 'Dedication saved';

  @override
  String khatmahWirdJuz(String juz) {
    return 'Today\'s wird: Juz $juz';
  }

  @override
  String get khatmahRepeatSameSettings => 'New khatmah, same settings';

  @override
  String khatmahHistoryStats(String count, String avg, String fastest) {
    return '$count khatmahs • average $avg days • fastest $fastest days';
  }

  @override
  String get khatmahJuzMapTitle => 'Khatmah map';

  @override
  String khatmahJuzMapCell(String juz, String read, String total) {
    return 'Juz $juz: $read of $total pages';
  }

  @override
  String get khatmahCatchUpTitle => 'How would you like to catch up?';

  @override
  String khatmahCatchUpOption(String pages, String date) {
    return '$pages pages a day — finish $date';
  }

  @override
  String get khatmahRelationshipFather => 'Father';

  @override
  String get khatmahRelationshipFriend => 'Friend';

  @override
  String get khatmahRelationshipRelative => 'Relative';

  @override
  String get khatmahRelationshipOther => 'Other';

  @override
  String get khatmahRecentCompletions => 'Recent Khatmah completions';

  @override
  String get khatmahHistoryEmpty => 'No saved Khatmah certificates yet.';

  @override
  String get khatmahHistoryLoadError =>
      'Unable to load saved Khatmah certificates. Please try again.';

  @override
  String get khatmahHistoryCorrupt =>
      'Some saved Khatmah certificates are invalid and were withheld. Please retry after restoring your data.';

  @override
  String get khatmahReopenCertificate => 'Reopen certificate';

  @override
  String khatmahCompletedOn(String date) {
    return 'Completed on $date';
  }

  @override
  String get brandName => 'تاليــة';

  @override
  String get xpLabel => 'XP';

  @override
  String countOfTotal(String count, String total) {
    return '$count of $total';
  }

  @override
  String get homeTodayTitle => 'Today';

  @override
  String get homeTodayReading => 'Daily reading';

  @override
  String get homeTodayMemorize => 'Memorize';

  @override
  String get homeTodayReview => 'Review';

  @override
  String get homeTodayAzkar => 'Azkar';

  @override
  String get homeTodayDone => 'Done';

  @override
  String get homeTodayTodo => 'To do';

  @override
  String get homeStreakAtRisk => 'Your streak is at risk';

  @override
  String homeFreezesAvailable(String count) {
    return '$count freezes available';
  }

  @override
  String get homeAyahOfDay => 'Ayah of the day';

  @override
  String get surahRevelationMeccan => 'Meccan';

  @override
  String get surahRevelationMedinan => 'Medinan';

  @override
  String ayahOfDaySurahMeta(String revelation, int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText ayahs',
      one: '$countText ayah',
    );
    return '$revelation · $_temp0';
  }

  @override
  String get ayahOfDayReadSurah => 'Read the full surah';

  @override
  String get homeAyahContextFriday => 'An ayah for Friday';

  @override
  String get homeAyahContextRamadanStart => 'An ayah for the start of Ramadan';

  @override
  String get homeAyahContextRamadan => 'An ayah for Ramadan';

  @override
  String get homeAyahContextLastTenNights => 'An ayah for the last ten nights';

  @override
  String get homeAyahContextDhulHijjah => 'An ayah for the days of Hajj';

  @override
  String get homeAyahContextArafah => 'An ayah for the Day of Arafah';

  @override
  String get homeAyahContextEidAlAdha => 'An ayah for Eid al-Adha';

  @override
  String get homeAyahContextReading => 'An ayah for your reading journey';

  @override
  String get homeAyahContextMemorization =>
      'An ayah for your memorization journey';

  @override
  String get homeAyahContextSmartReview => 'An ayah for your review';

  @override
  String get homeAyahContextAzkar => 'An ayah for your adhkar';

  @override
  String get homeAyahContextChildJourney => 'An ayah for the child journey';

  @override
  String homeResumeListening(String surah) {
    return 'Resume listening · $surah';
  }

  @override
  String get homeSomethingElse => 'Something else';

  @override
  String homeMinutes(String count) {
    return '$count min';
  }

  @override
  String get homeOccasionFriday => 'Friday · Surah Al-Kahf';

  @override
  String get homeOccasionRamadan => 'Ramadan';

  @override
  String get homeOccasionLastTenNights => 'Last ten nights';

  @override
  String get homeSlotFridayTitle => 'Surah Al-Kahf';

  @override
  String get homeSlotFridayBody =>
      'It is recommended to read Surah Al-Kahf on Friday.';

  @override
  String get homeSlotRamadanTitle => 'Ramadan reading';

  @override
  String get homeSlotRamadanBody =>
      'A blessed month — keep your daily portion going.';

  @override
  String get homeSlotLastTenTitle => 'Last ten nights';

  @override
  String get homeSlotLastTenBody =>
      'Seek Laylat al-Qadr with extra reading and prayer.';

  @override
  String get homeSlotStreakBody =>
      'Record today\'s activity before midnight to keep your streak.';

  @override
  String get homeSlotKhatmahTitle => 'Khatmah almost complete';

  @override
  String get homeSlotKhatmahBody => 'You are close to finishing this Khatmah.';

  @override
  String get homeSlotOpen => 'Open';

  @override
  String get homeWeeklyReflectionTitle => 'This week';

  @override
  String homeWeeklyReflectionBody(String days, String count) {
    return '$days active days · $count activities';
  }

  @override
  String get homeFirstRunTitle => 'Start your first step';

  @override
  String get homeFirstRunBody =>
      'Read a page, begin memorizing, or start a Khatmah.';

  @override
  String get homeFirstRunRead => 'Read the Quran';

  @override
  String get homeFirstRunMemorize => 'Start memorizing';

  @override
  String homeChildStreak(String count) {
    return '$count-day streak';
  }

  @override
  String get homeSearchTitle => 'Search the Quran';

  @override
  String get homeSearchNoResults => 'No matching ayahs or surahs';

  @override
  String get homePrayerTimes => 'Prayer times';

  @override
  String get homePrayerTimesEnabled => 'Show next prayer on Home';

  @override
  String get homePrayerCountry => 'Country';

  @override
  String get homePrayerCity => 'City';

  @override
  String get homePrayerMethod => 'Calculation method';

  @override
  String get prayerMethodAuto => 'Automatic by country';

  @override
  String homePrayerChip(String name, String minutes) {
    return '$name in $minutes min';
  }

  @override
  String prayerTimelineNext(String name, String timeRemaining) {
    return '$name in $timeRemaining';
  }

  @override
  String prayerTimelineSunriseNext(String timeRemaining) {
    return 'Sunrise in $timeRemaining';
  }

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get prayerMethodMwl => 'Muslim World League';

  @override
  String get prayerMethodEgyptian => 'Egyptian';

  @override
  String get prayerMethodUmmAlQura => 'Umm al-Qura';

  @override
  String get prayerMethodKarachi => 'Karachi';

  @override
  String get prayerMethodNorthAmerica => 'ISNA';

  @override
  String get prayerMethodDubai => 'Dubai';

  @override
  String get prayerMethodKuwait => 'Kuwait';

  @override
  String get prayerMethodQatar => 'Qatar';

  @override
  String get prayerMethodSingapore => 'Singapore, Malaysia & Indonesia';

  @override
  String get prayerMethodTurkey => 'Turkey (Diyanet)';

  @override
  String get prayerMethodMoonSighting => 'Moonsighting Committee';

  @override
  String get prayerMadhabTitle => 'Asr calculation';

  @override
  String get prayerCustomLocation => 'Custom location (coordinates)';

  @override
  String get prayerCustomLatitude => 'Latitude';

  @override
  String get prayerCustomLongitude => 'Longitude';

  @override
  String get prayerCustomHint =>
      'City not listed? Copy its coordinates from a maps app.';

  @override
  String prayerCustomTimeZone(String zone) {
    return 'Time zone: $zone';
  }

  @override
  String get prayerCustomSave => 'Save location';

  @override
  String get prayerCustomSaved =>
      'Location saved. Prayer times now use your coordinates.';

  @override
  String get prayerCustomInvalid =>
      'Check the coordinates: latitude between -90 and 90, longitude between -180 and 180.';

  @override
  String get prayerCustomTimeZoneUnavailable =>
      'Couldn\'t determine your device\'s time zone.';

  @override
  String get prayerMadhabAuto => 'Automatic by city';

  @override
  String get prayerMadhabShafi => 'Majority (Shafi\'i, Maliki, Hanbali)';

  @override
  String get prayerMadhabHanafi => 'Hanafi';

  @override
  String get homeBrandSubtitle => 'Talia Quran';

  @override
  String homeWelcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String get homeContinueRecitation => 'Continue reciting';

  @override
  String get homeContinueAction => 'Continue';

  @override
  String homeAyahRange(String start, String end) {
    return 'Verses $start to $end';
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
      other: '$totalText ayahs',
      one: '$totalText ayah',
    );
    return '$currentText of $_temp0';
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
      other: '$totalText pages',
      one: '$totalText page',
    );
    return '$currentText of $_temp0';
  }

  @override
  String get homeTileListen => 'Recite';

  @override
  String get homeTileListenHint => 'Listen and recite';

  @override
  String get homeTileReview => 'Review';

  @override
  String get homeTileReviewHint => 'Strengthen what you memorized';

  @override
  String get homeTileMemorize => 'Memorize';

  @override
  String get homeTileMemorizeHint => 'Add new ayahs';

  @override
  String get homeTileRead => 'Read';

  @override
  String get homeTileReadHint => 'Open the mushaf';

  @override
  String get homeDailyChallenge => 'Daily challenge';

  @override
  String homeDailyChallengePages(String count) {
    return 'Complete $count pages today';
  }

  @override
  String get homeDailyChallengeTasks => 'Complete today\'s tasks';

  @override
  String homeChallengeProgress(String current, String total) {
    return '$current of $total';
  }

  @override
  String homeStreakDays(String count) {
    return '$count-day streak';
  }

  @override
  String get homeQuranJourney => 'Your journey with the Quran';

  @override
  String get homeJourneyMemorization => 'Memorization';

  @override
  String get homeJourneyKhatmah => 'Khatmah';

  @override
  String homeJourneyMemorizedAyahs(String count) {
    return '$count ayahs memorized';
  }

  @override
  String homeJourneyKhatmahPages(String current, String total) {
    return '$current of $total pages';
  }

  @override
  String get homeJourneyNotStartedTitle => 'Your journey hasn\'t started yet';

  @override
  String get homeJourneyNotStartedBody =>
      'Begin memorizing or open a khatmah, and your real progress will be tracked here';

  @override
  String get homeJourneyStartMemorization => 'Start memorizing';

  @override
  String get homeSurahsCompleted => 'Completed';

  @override
  String get homeSurahsInProgress => 'In progress';

  @override
  String get homeSurahsRemaining => 'Remaining';

  @override
  String get homeRecentActivity => 'Your recent activity';

  @override
  String get homeActivityViewAll => 'View all';

  @override
  String get homeActivityEmpty =>
      'Start reading or memorizing to see activity here';

  @override
  String get homeActivityReading => 'Reading';

  @override
  String get homeActivityMemorize => 'Memorization';

  @override
  String get homeActivityReview => 'Review';

  @override
  String get homeActivityKhatmah => 'Khatmah';

  @override
  String get homeActivityJustNow => 'Just now';

  @override
  String homeActivityMinutesAgo(String count) {
    return '$count min ago';
  }

  @override
  String homeActivityHoursAgo(String count) {
    return '$count h ago';
  }

  @override
  String get homeActivityYesterday => 'Yesterday';

  @override
  String homeActivityDaysAgo(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText days',
      one: '$countText day',
    );
    return '$_temp0 ago';
  }

  @override
  String get homeActivityCompleted => 'Completed';

  @override
  String get homeFooterTagline => 'With the Quran, we live more beautifully';

  @override
  String get quickNavTitle => 'Quick navigation';

  @override
  String get quickNavGo => 'Go';

  @override
  String get quickNavPageHint => 'Page number (1-604)';

  @override
  String get homeStartKhatmahTitle => 'Start Your Quran Khatmah Now';

  @override
  String get homeStartKhatmahSubtitle =>
      'Set your daily portion and pace to maintain a regular Quran habit';

  @override
  String get homeStartKhatmahCta => 'Create New Khatmah';

  @override
  String get homeAchievementSheetTitle => 'Your Achievements & Level';

  @override
  String get homeAchievementSheetSubtitle =>
      'Continue reciting and memorizing to advance your rank';

  @override
  String get homePrayerTimesSheetTitle => 'Prayer Times';

  @override
  String get prayerCompanionStatusConfirmed => 'Confirmed';

  @override
  String get prayerCompanionStatusUnconfirmedPast => 'Not confirmed yet';

  @override
  String get prayerCompanionStatusUpcoming => 'Upcoming';

  @override
  String get prayerCompanionStatusPrayNow => 'Will pray now';

  @override
  String get prayerCompanionStatusRemindLater => 'Reminder set';

  @override
  String get prayerCompanionStatusNotYet => 'Not yet';

  @override
  String get prayerCompanionActionConfirm => 'I prayed';

  @override
  String get prayerCompanionActionPrayNow => 'I will pray now';

  @override
  String get prayerCompanionActionRemindLater => 'Remind me later';

  @override
  String get prayerCompanionActionNotYet => 'Not yet';

  @override
  String prayerCompanionConfirmedCount(String confirmed, String total) {
    return '$confirmed of $total confirmed';
  }

  @override
  String prayerCompanionRowSemantics(String prayer, String status) {
    return '$prayer: $status';
  }

  @override
  String get prayerCompanionSettingsTitle => 'Prayer Companion';

  @override
  String get microReviewTitle => 'Memory flash';

  @override
  String get microReviewQuestion =>
      'From your older memorization — do you still recall it?';

  @override
  String microReviewReference(String surah, String ayah) {
    return 'Surah $surah · Ayah $ayah';
  }

  @override
  String get microReviewRevealHint => 'Try to recall it… then tap to reveal';

  @override
  String get microReviewRecite => 'Recite it';

  @override
  String get prayerSerenityTitle => 'Prayer Serenity Mode';

  @override
  String get prayerSerenitySubtitle =>
      'Recitation pauses gently at prayer time';

  @override
  String get prayerSerenityNotificationTitle => 'It is time for the meeting 🕌';

  @override
  String get prayerSerenityNotificationBody =>
      'We paused the recitation gently… it is time for prayer. May Allah accept it';

  @override
  String get prayerCompanionEnable => 'Enable Prayer Companion';

  @override
  String get prayerCompanionPreparation => 'Preparation reminder';

  @override
  String get prayerCompanionPreparationDisabled => 'Disabled';

  @override
  String prayerCompanionMinutesValue(String minutes) {
    return '$minutes minutes';
  }

  @override
  String get prayerCompanionCheckIn => 'Post-prayer check-in';

  @override
  String get prayerCompanionCheckInSub =>
      'A gentle reminder arrives 20 minutes after the prayer.';

  @override
  String get prayerCompanionFollowUp => 'Allow one follow-up reminder';

  @override
  String get prayerCompanionFollowUpSub =>
      'Sent once when you choose \"I will pray now\" or \"Remind me later\".';

  @override
  String get prayerCompanionLocalOnly =>
      'Your confirmations stay on this device only and are never uploaded.';

  @override
  String get prayerCompanionClear => 'Clear prayer confirmations';

  @override
  String get prayerCompanionClearSub =>
      'Deletes your saved confirmations on this device.';

  @override
  String get prayerCompanionClearConfirmTitle => 'Clear confirmations?';

  @override
  String get prayerCompanionClearConfirmBody =>
      'Do you want to clear the confirmations saved on this device?';

  @override
  String get prayerCompanionClearConfirmButton => 'Clear';

  @override
  String get prayerCompanionClearCancel => 'Cancel';

  @override
  String get prayerCompanionClearFailed =>
      'Could not clear confirmations. Please try again.';

  @override
  String get prayerCompanionCleared => 'Confirmations cleared.';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get notificationExactAlarmRequest => 'Enable exact alarms';

  @override
  String get notificationExactAlarmExplanation =>
      'Ensures prayer reminders and the adhan fire exactly on time';

  @override
  String get notificationExactAlarmGranted =>
      'Exact prayer-time alarms are enabled.';

  @override
  String get notificationExactAlarmDenied =>
      'Reminders still arrive approximately on time; you can grant exact alarms later in system settings.';

  @override
  String get notificationTestFailed =>
      'Could not send the notification. Check notification permission in device settings.';

  @override
  String get notificationQuietHours => 'Quiet hours';

  @override
  String get notificationQuietHoursSub =>
      'Move regular reminders outside the chosen period. Prayer times remain unchanged.';

  @override
  String get notificationQuietHoursStart => 'Starts';

  @override
  String get notificationQuietHoursEnd => 'Ends';

  @override
  String get notificationSmartReminder => 'Smart reminder';

  @override
  String get notificationSmartReminderSub =>
      'Uses your recent on-device opening times to choose a reminder time.';

  @override
  String memorizationHubReviewDueBadge(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText ayahs',
      one: '$countText ayah',
    );
    return '$_temp0 due for review';
  }

  @override
  String get memorizationHubReviewDueNone => 'No reviews due right now';

  @override
  String dailyPlanNextReviewInDays(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText days',
      one: '1 day',
      zero: 'today',
    );
    return 'Next review in $_temp0';
  }

  @override
  String get dailyPlanStrengthWeak => 'Weak memorization';

  @override
  String get dailyPlanStrengthLearning => 'Still settling';

  @override
  String get dailyPlanStrengthStrong => 'Solid memorization';

  @override
  String get memorizedPageAction => 'Memorize this page';

  @override
  String get memorizedPageSubtext =>
      'Start a memorization session for the current page\'s ayahs';

  @override
  String get memorizedPageUnavailable =>
      'Page memorization is available when all its ayahs belong to one surah.';

  @override
  String customPlanDirectionForward(String from, String to) {
    return 'Memorization direction: forward (from $from to $to)';
  }

  @override
  String customPlanDirectionBackward(String from, String to) {
    return 'Memorization direction: backward (from $from to $to)';
  }

  @override
  String get fieldRequired => 'This field is required';

  @override
  String fieldTooLong(String maxLength) {
    return 'Cannot exceed $maxLength characters';
  }

  @override
  String get progressDueReviewsLabel => 'Due reviews';

  @override
  String progressStreakDaysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String get progressNextMilestoneTitle => 'Your next milestone';

  @override
  String progressNextMilestoneRemaining(String remaining) {
    return '$remaining to go';
  }

  @override
  String get progressAllAchievementsUnlocked =>
      'Masha\'Allah! You\'ve unlocked every achievement';

  @override
  String progressDueReviewsNudge(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText ayahs are due for review',
      one: '1 ayah is due for review',
    );
    return '$_temp0';
  }

  @override
  String get progressStartReview => 'Start review';

  @override
  String progressActiveDays(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText active days',
      one: '1 active day',
      zero: 'No active days yet',
    );
    return '$_temp0';
  }

  @override
  String get progressXpToNextLevel => 'Toward next level';

  @override
  String get privacyEffectiveDate => 'Effective date: October 2, 2026';

  @override
  String get privacyIntro =>
      'This policy explains how Talia Quran handles your data on your device and through cloud services, and how you control permissions and request deletion.';

  @override
  String get privacyManualOptionAction =>
      'Open memorization to use manual self-grade';

  @override
  String get privacyControllerTitle => '1. Introduction and Data Controller';

  @override
  String get privacyControllerBody =>
      'Talia Quran is an app for reading, memorization, revision and Azkar. The developer and controller responsible for app data is Sayed Saad. This policy covers Talia, its account features and guardian linking. Privacy enquiries and requests: elsayed.saad2014@feps.edu.eg.';

  @override
  String get privacyDataTitle =>
      '2. Information We Collect and Where It Is Stored';

  @override
  String get privacyAccountData =>
      'Account: Registration processes your email and password through Supabase for authentication, verification and recovery, together with an account ID and session tokens. Profile details, such as a name or child nickname and age when supplied, personalize the experience, appear to a linked guardian and support certificates. Never send your password to support.';

  @override
  String get privacyProgressData =>
      'Progress and preferences: The app stores reading progress, bookmarks, memorization plans, reviews and ratings, sessions, XP, streaks, achievements, certificates and child/guardian settings. Operational data is stored on your device; supported cloud features synchronize associated account data when signed in and connected. Pending operations may upload automatically when connectivity returns. Some local features and preferences do not synchronize.';

  @override
  String get privacyTechnicalData =>
      'Technical data and support: Account and audio services receive ordinary connection information such as IP address, request time and technical data needed for service operation and security. The app logs technical errors locally. If you contact us, we process your email, message and information you choose to send to resolve your request. The current version does not include third-party advertising or behavioral analytics SDKs.';

  @override
  String get privacyPurposeTitle => '3. Purposes of Processing';

  @override
  String get privacyPurposeBody =>
      'We use data to operate accounts, synchronize progress, provide revision, reminders and certificates, enable guardian linking you choose, protect the service and respond to support. We do not sell your data or use progress or children’s data for targeted advertising. Permission requests are separate from this policy; you can refuse optional permissions and continue using features that do not require them.';

  @override
  String get privacyPermissionsTitle => '4. Device Permissions and Speech';

  @override
  String get privacyMicrophone =>
      'Microphone: Used when you start recitation assessment to recognize your reading. Recognition uses your operating system\'s built-in speech service; the platform provider may process audio under its own policies, and offline processing is not guaranteed. Talia does not retain raw audio and does not send it to Talia servers. An assessment result may be saved with progress. A manual self-grade option is available; revoke microphone and speech-recognition permissions in device settings.';

  @override
  String get privacyCamera =>
      'Camera: Used when you choose to scan a guardian-link QR code. The scanner processes camera frames to read the code; the app does not save or upload camera images. The pairing token is sent to the account service to validate and establish the link.';

  @override
  String get privacyNotifications =>
      'Notifications: Reminders for memorization, reading, Azkar and prayer times are scheduled locally. Disable them in the app or system settings. Reminder information may appear on the lock screen depending on your device settings.';

  @override
  String get privacyPhotos =>
      'Photos, files and sharing: Used when you choose to save, export or share a certificate or card. Files may contain the name and progress you choose to display. Copies saved outside the app or sent to another app are subject to your control and the recipient’s policy; deleting your account does not erase them.';

  @override
  String get privacyLocation =>
      'Prayer times: Calculated on your device using the city you select or coordinates you enter manually. These settings are stored locally. This version does not request GPS location or track your location in the background.';

  @override
  String get privacyChildrenTitle => '5. Children’s Privacy and Guardians';

  @override
  String get privacyChildrenBody =>
      'The app includes a children’s path that may process a child’s nickname, age, memorization progress, assessments, sessions and rewards. A guardian should supervise account use, synchronization, speech assessment and sharing, use a nickname instead of a full name and avoid providing unnecessary details. Local child profiles are not necessarily separate accounts.';

  @override
  String get privacyGuardianSharing =>
      'When you approve and complete guardian account linking, the linked guardian can view available child monitoring data through the cloud, including the name or nickname, age, progress, sessions and achievements, and manage rewards. Linking is not exclusively local. Unlink using the guardian tools and request review or deletion of child data through the privacy email. Unlinking cannot erase copies a recipient previously saved.';

  @override
  String get privacyChildrenSpeech =>
      'We do not serve targeted advertising to children. Speech assessment is optional; the operating system’s recognition provider may process audio away from the device. Guardians can choose manual assessment and revoke permissions. QR linking alone is not proof of legally required parental consent.';

  @override
  String get privacyProvidersTitle => '6. Who May Receive Data';

  @override
  String get privacyProvidersBody =>
      'Supabase processes authentication, account and cloud progress data for the app. Your device’s speech-recognition provider may process recitation audio. EveryAyah provides reciter recordings online and receives ordinary technical request data during streaming or downloads. Email services may process verification and support messages. Linked guardians and apps you select for sharing receive the data described above.';

  @override
  String get privacyProviderProtection =>
      'We limit processing to what the service needs and require processors to protect data consistently with this policy, store requirements and applicable law. Device platform services and apps you choose for sharing also have their own policies. We may disclose information necessary to comply with a binding legal request or protect rights and service security.';

  @override
  String get privacySecurityTitle => '7. Security and International Transfers';

  @override
  String get privacySecurityBody =>
      'Account connections use HTTPS. Cloud access depends on account identity and access rules that allow the specified sharing with linked guardians. Selected sensitive data, including guardian PIN protection and selected account data, uses secure storage; the authentication library persists a session on the device to keep you signed in. No security measure is absolute. Service providers may process data outside your country; transfers are handled subject to applicable safeguards and legal requirements.';

  @override
  String get privacyRetentionTitle => '8. Data Retention';

  @override
  String get privacyRetentionBody =>
      'Active account data and profile are retained while your account exists, until the data or account is deleted. Local data remains until you erase it or clear app data. Successful account deletion removes account data from operational databases. Provider backups or security logs may remain during their limited retention cycle and are not used to recreate the account. Your device platform may keep backups according to your backup settings; manage these in system settings. Support correspondence is retained as necessary to resolve requests and meet legal obligations. Contact us for the retention period applicable to your data; if a legal exception requires retention, we explain the categories, reason and duration in our response.';

  @override
  String get privacyDeletionTitle => '9. Account and Data Deletion';

  @override
  String get privacyDeletionBody =>
      'To delete your account, open Settings → Account → Delete account, read the warning and confirm. Internet access is required. This deletes your login account, profile and associated cloud data, including progress, plans, bookmarks, certificates, guardian links and associated rewards. It ends the session and clears account data on this device, including progress, dependent local profiles and pending operations. Deletion is permanent; signing out or unlinking is not a substitute. Success is shown after cleanup finishes; follow any retry instructions if completion is interrupted.';

  @override
  String get privacyDeletionLimits =>
      'Deleting a guardian account does not delete independent child or other guardian accounts; their links to the deleted account are removed. Certificates or cards exported outside the app, shared copies and local copies on other devices are not erased by this operation; clear app data on those devices as well. General device preferences, downloaded Quran content and separately identifiable guest data may remain.';

  @override
  String get privacyExternalDeletion =>
      'You can request deletion without installing the app: email elsayed.saad2014@feps.edu.eg from your account email with the subject “Talia Quran account deletion request” and ask to delete the account and associated data. We verify account ownership before acting and notify you of completion or any legally required retention. Do not send passwords or verification codes. Use the same email to request deletion of particular data while keeping your account.';

  @override
  String get privacyRightsTitle => '10. Your Choices and Rights';

  @override
  String get privacyRightsBody =>
      'Edit your profile in the app, revoke device permissions, disable reminders and unlink guardians. Depending on applicable law, you may request access, a copy, correction or erasure of data, restriction of processing, object to processing, withdraw consent or complain to the relevant authority. Contact us from your account email and describe your request; we may request limited identity verification. Withdrawal does not affect processing that occurred before it.';

  @override
  String get privacyChangesTitle => '11. Changes to This Policy';

  @override
  String get privacyChangesBody =>
      'We update the effective date when the policy changes and provide appropriate notice of material changes. If a new use of your data requires consent, we request it before that use begins. Review the policy when updating the app.';

  @override
  String get privacyContactTitle => '12. Contact Us';

  @override
  String get privacyContactBody =>
      'Developer: Sayed Saad\nApp: Talia Quran — تالية القرآن\nPrivacy, account deletion and children’s data: elsayed.saad2014@feps.edu.eg';

  @override
  String get accountDeletionRemoteConfirmedCleanupFailed =>
      'Your cloud account was deleted, but device cleanup is incomplete. Retry to finish cleanup.';

  @override
  String get accountDeletionSessionCleanupFailed =>
      'Your account was deleted, but removing the device session is incomplete. Retry.';

  @override
  String get accountDeletionProgressMarkerFailed =>
      'The deletion state could not be saved safely. Account deletion has not started; retry.';

  @override
  String get accountDeletionUnavailable =>
      'Account deletion is currently unavailable. Retry or contact the privacy email.';

  @override
  String get accountDeletionFailed =>
      'Account deletion could not be confirmed. Check your connection and retry; wait for the success message before assuming deletion is complete.';

  @override
  String get accountDeletionRetryTitle => 'Finish account deletion';

  @override
  String get accountDeletionRetryAction => 'Retry';

  @override
  String get sourcesLicensesTitle => 'Sources & licenses';

  @override
  String get sourcesLicensesSubtitle =>
      'Where the Quran text, audio and code come from';

  @override
  String get sourcesQuranTextTitle => 'Quran text';

  @override
  String get sourcesQuranTextBody =>
      'Uthmani script, Hafs narration, from the Tanzil Project via alquran.cloud.';

  @override
  String get sourcesMushafTitle => 'Mushaf pages';

  @override
  String get sourcesMushafBody =>
      'Mushaf page fonts (QCF) are rendered with the qcf_quran_plus package, MIT license.';

  @override
  String get sourcesRecitationTitle => 'Recitations';

  @override
  String get sourcesRecitationBody =>
      'Ayah recitations are streamed from EveryAyah.com.';

  @override
  String get sourcesAdhanTitle => 'Adhan';

  @override
  String get sourcesAdhanBody =>
      'The selectable muezzin recordings come from the Internet Archive and carry the Public Domain Mark 1.0.';

  @override
  String get sourcesKhatmDuaTitle => 'Khatm al-Quran dua';

  @override
  String get sourcesKhatmDuaBody =>
      'From the appendix of the King Fahd Complex Mushaf.';

  @override
  String get sourcesOpenSourceTitle => 'Open-source licenses';

  @override
  String get sourcesOpenSourceBody =>
      'Full licenses of the libraries used in the app.';

  @override
  String sourcesOpenLink(String site) {
    return 'Open $site';
  }

  @override
  String get authCloudUnavailable =>
      'Accounts aren\'t available in this version. You can keep using Talia as a guest.';

  @override
  String surahNamed(String name) {
    return 'Surah $name';
  }

  @override
  String get azkarFontSizeTitle => 'Azkar font size';

  @override
  String get hijriAdjustmentTitle => 'Hijri date';

  @override
  String get hijriAdjustmentSubtitle =>
      'Shift the Hijri date to match your country\'s announcement of the new month.';

  @override
  String hijriAdjustmentToday(String date) {
    return 'Today: $date';
  }

  @override
  String get guardianPinCreateReason =>
      'This is a guardian action. Create a 4-digit PIN to protect it; you will be asked for it next time.';

  @override
  String get childSetupPinOptionalHelp =>
      'Optional: create it now or the first time a guardian action needs it.';
}
