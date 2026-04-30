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
    return '🏆 Alhamdulillah, I\'ve achieved \"$title\" 🌟\n📖 $description\n\n📱 Achieved via the amazing \"Talia Quran\" app!\n✨ Don\'t miss out on the rewards, download the app now and join me on this blessed journey 💚';
  }

  @override
  String shareAchievementWithName(
    Object description,
    Object name,
    Object title,
  ) {
    return '🏆 Alhamdulillah, $name achieved \"$title\" 🌟\n📖 $description\n\n📱 Achieved via the amazing \"Talia Quran\" app!\n✨ Don\'t miss out on the rewards, download the app now and join us on this blessed journey 💚';
  }

  @override
  String get shareProgress => 'Share Progress';

  @override
  String shareProgressText(Object ayahs, Object pages, Object streak) {
    return '📊 Alhamdulillah, here is my progress on the \"Talia Quran\" app 🌟:\n📖 $pages pages read\n🧠 $ayahs ayahs memorized\n🔥 $streak days of consistent streak\n\n✨ Download \"Talia Quran\" now and start your blessed journey 💚';
  }

  @override
  String shareProgressWithName(
    Object ayahs,
    Object name,
    Object pages,
    Object streak,
  ) {
    return '📊 Alhamdulillah, here is $name\'s progress on the \"Talia Quran\" app 🌟:\n📖 $pages pages read\n🧠 $ayahs ayahs memorized\n🔥 $streak days of consistent streak\n\n✨ Download \"Talia Quran\" now and start your blessed journey 💚';
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
}
