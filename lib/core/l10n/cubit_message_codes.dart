/// Stable message codes emitted from cubits/repositories and resolved in UI.
abstract final class CubitMessageCodes {
  static const hifzAudioPlaybackFailed = '@hifz/audio_playback_failed';
  static const hifzReviewSaveFailed = '@hifz/review_save_failed';
  static const hifzMemorizationSaveFailed = '@hifz/memorization_save_failed';
  static const hifzSurahLockedPrefix = '@hifz/surah_locked|';
  static const v2SurahLoadFailed = '@v2/surah_load_failed';
  static const v2NoAyahsInRange = '@v2/no_ayahs_in_range';

  static const kidsAudioPlaybackFailed = '@kids/audio_playback_failed';
  static const kidsMicPermissionDenied = '@kids/mic_permission_denied';
  static const kidsRecordingUnavailable = '@kids/recording_unavailable';
  static const kidsRecordingNotCaptured = '@kids/recording_not_captured';
  static const kidsRecitationMismatch = '@kids/recitation_mismatch';
  static const kidsJourneyStageLocked = '@kids/journey_stage_locked';
  static const kidsAyahAlreadyCompleted = '@kids/ayah_already_completed';
}
