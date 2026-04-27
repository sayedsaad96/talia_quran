import '../constants/app_constants.dart';

/// Centralized audio URL builder for consistent Quran audio across the app.
/// All features (SurahDetail, HifzSession, KidsMode, QuranReader) should use
/// this service instead of building URLs manually.
class QuranAudioService {
  /// Builds a URL for a specific ayah audio file.
  ///
  /// [surahId] and [ayahNumber] are used to construct the file path
  /// in the format: `SSSAAA.mp3` (e.g., `002255.mp3` for Al-Baqarah:255).
  static String buildUrl(int surahId, int ayahNumber) {
    final s = surahId.toString().padLeft(3, '0');
    final a = ayahNumber.toString().padLeft(3, '0');
    return '${AppConstants.audioBaseUrl}$s$a.mp3';
  }

  const QuranAudioService._();
}
