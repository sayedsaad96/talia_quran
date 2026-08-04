import '../constants/app_constants.dart';
import 'quran_reciter.dart';

/// Centralized audio URL builder for consistent Quran audio across the app.
class QuranAudioService {
  /// Builds a URL for a specific ayah audio file.
  ///
  /// If [reciter] is provided, uses that reciter's base URL.
  /// Otherwise defaults to [AppConstants.audioBaseUrl].
  static String buildUrl(int surahId, int ayahNumber, {QuranReciter? reciter}) {
    final s = surahId.toString().padLeft(3, '0');
    final a = ayahNumber.toString().padLeft(3, '0');
    final baseUrl = reciter?.baseUrl ?? AppConstants.audioBaseUrl;
    return '$baseUrl$s$a.mp3';
  }

  const QuranAudioService._();
}
