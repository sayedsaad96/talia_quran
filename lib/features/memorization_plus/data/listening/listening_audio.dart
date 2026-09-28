import 'package:just_audio/just_audio.dart';

import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/utils/talia_logger.dart';

/// Audio seam for Listening Review so the cubit can be unit-tested.
abstract interface class ListeningAudio {
  Future<bool> isCached(ListeningAyahRef ref);

  /// Plays the ayah once. Completes when playback ends; returns false when
  /// the ayah could not be played (e.g. offline and not cached).
  Future<bool> play(ListeningAyahRef ref);

  Future<void> stop();

  Future<void> dispose();
}

class JustAudioListeningAudio implements ListeningAudio {
  JustAudioListeningAudio(this._cache, [AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioCacheService _cache;
  final AudioPlayer _player;

  @override
  Future<bool> isCached(ListeningAyahRef ref) async =>
      await _cache.getCachedFilePath(ref.surahId, ref.ayahNumber) != null;

  @override
  Future<bool> play(ListeningAyahRef ref) async {
    try {
      final source = await _cache.getAudioSource(ref.surahId, ref.ayahNumber);
      // just_audio's play() completes when playback stops or completes.
      await AudioCacheService.playFromSource(_player, source);
      await _player.pause();
      return true;
    } catch (e, stack) {
      TaliaLogger.w('Listening review: ayah audio unavailable', e, stack);
      return false;
    }
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
