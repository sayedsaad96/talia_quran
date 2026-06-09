abstract class AppConstants {
  // Quran
  static const int totalSurahs = 114;
  static const int totalAyahs = 6236;
  static const int totalJuz = 30;

  // Hifz spaced repetition intervals (days)
  static const List<int> spacedRepetitionIntervals = [1, 3, 7, 14, 30, 90];

  // Storage keys
  static const String kHifzProgress = 'hifz_progress';
  static const String kHifzCheckpointProgress = 'hifz_checkpoint_progress';
  static const String kHifzPathMode = 'hifz_path_mode';
  static const String kReadPages = 'read_pages';

  // Audio base URL (EveryAyah CDN)
  static const String audioBaseUrl =
      'https://everyayah.com/data/Alafasy_128kbps/';

  // Hifz evaluation
  static const double kSimilarityThreshold = 0.85;

  // ARCH-001 FIX: Was pointing to 'quran_simple.json' (non-existent). Actual file is 'quran.json'.
  static const String quranDataAsset = 'assets/data/quran.json';
  static const String azkarDataAsset = 'assets/data/azkar.json';

  // Font sizes
  static const double fontSizeSmall = 18.0;
  static const double fontSizeMedium = 22.0;
  static const double fontSizeLarge = 26.0;
  static const double fontSizeXLarge = 30.0;

  // App Links
  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.sayed.talia_quran';
}
