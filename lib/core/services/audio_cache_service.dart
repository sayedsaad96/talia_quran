import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'quran_audio_service.dart';
import 'quran_reciter.dart';

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
  Future<String> getAudioPath(int surahId, int ayahNumber, {QuranReciter? reciter}) async {
    final url = QuranAudioService.buildUrl(surahId, ayahNumber, reciter: reciter);
    final fileInfo = await _cacheManager.getFileFromCache(url);
    if (fileInfo != null) {
      return fileInfo.file.path;
    }
    final file = await _cacheManager.getSingleFile(url);
    return file.path;
  }

  /// Returns a URL or cached file path suitable for audio player.
  Future<String> getAudioSource(int surahId, int ayahNumber, {QuranReciter? reciter}) async {
    final url = QuranAudioService.buildUrl(surahId, ayahNumber, reciter: reciter);
    final fileInfo = await _cacheManager.getFileFromCache(url);
    if (fileInfo != null) {
      return fileInfo.file.path;
    }
    // Return the URL — the player will stream it, and we cache in background
    unawaited(_cacheManager.getSingleFile(url));
    return url;
  }

  /// Pre-downloads audio files for an upcoming session.
  Future<void> prefetchSession({
    required int surahId,
    required List<int> ayahNumbers,
    QuranReciter? reciter,
  }) async {
    const int batchSize = 5;
    for (int i = 0; i < ayahNumbers.length; i += batchSize) {
      final end = (i + batchSize < ayahNumbers.length)
          ? i + batchSize
          : ayahNumbers.length;
      final batch = ayahNumbers.sublist(i, end);

      // Process batch concurrently
      await Future.wait(
        batch.map((ayahNumber) async {
          final url = QuranAudioService.buildUrl(surahId, ayahNumber, reciter: reciter);
          try {
            await _cacheManager.getSingleFile(url);
          } catch (_) {
            // Ignore individual download failures during prefetch
          }
        }),
      );
    }
  }

  /// Plays an audio source on the given [player], correctly handling both
  /// network URLs and cached local file paths.
  static Future<void> playFromSource(AudioPlayer player, String source) async {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      await player.setUrl(source);
    } else {
      await player.setFilePath(source);
    }
    await player.play();
  }

  /// Clears the entire audio cache.
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }
}
