import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'quran_audio_service.dart';

/// Intelligent audio caching service for Quran audio files.
///
/// Wraps [flutter_cache_manager] to provide offline-capable audio playback.
/// Audio files are cached for 30 days and up to 500 files (~50MB).
class AudioCacheService {
  AudioCacheService._();
  static final AudioCacheService instance = AudioCacheService._();

  static final _cacheManager = CacheManager(
    Config(
      'quran_audio_cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
    ),
  );

  /// Returns a local file path for the given ayah audio.
  ///
  /// If the audio is already cached, returns the cached path immediately.
  /// Otherwise, downloads and caches the file first.
  Future<String> getAudioPath(int surahId, int ayahNumber) async {
    final url = QuranAudioService.buildUrl(surahId, ayahNumber);
    final fileInfo = await _cacheManager.getFileFromCache(url);
    if (fileInfo != null) {
      return fileInfo.file.path;
    }
    final file = await _cacheManager.getSingleFile(url);
    return file.path;
  }

  /// Returns a URL or cached file path suitable for audio player.
  ///
  /// Tries cache first for instant playback, falls back to network URL.
  Future<String> getAudioSource(int surahId, int ayahNumber) async {
    final url = QuranAudioService.buildUrl(surahId, ayahNumber);
    final fileInfo = await _cacheManager.getFileFromCache(url);
    if (fileInfo != null) {
      return fileInfo.file.path;
    }
    // Return the URL — the player will stream it, and we cache in background
    unawaited(_cacheManager.getSingleFile(url));
    return url;
  }

  /// Pre-downloads audio files for an upcoming session.
  ///
  /// This runs in the background so the user doesn't wait.
  Future<void> prefetchSession({
    required int surahId,
    required List<int> ayahNumbers,
  }) async {
    for (final ayahNumber in ayahNumbers) {
      final url = QuranAudioService.buildUrl(surahId, ayahNumber);
      unawaited(_cacheManager.getSingleFile(url));
    }
  }

  /// Clears the entire audio cache.
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }
}
