/// Stable message codes emitted from cubits/repositories and resolved in UI.
abstract final class CubitMessageCodes {
  static const hifzAudioPlaybackFailed = '@hifz/audio_playback_failed';
  static const hifzReviewSaveFailed = '@hifz/review_save_failed';
  static const hifzMemorizationSaveFailed = '@hifz/memorization_save_failed';
  static const hifzSurahLockedPrefix = '@hifz/surah_locked|';

  static const kidsAudioPlaybackFailed = '@kids/audio_playback_failed';

  static const quizSurahNotFound = '@quiz/surah_not_found';
  static const quizAyahsOutsidePlan = '@quiz/ayahs_outside_plan';
  static const quizNoMemorizedAyahs = '@quiz/no_memorized_ayahs';
  static const quizUnexpectedErrorPrefix = '@quiz/unexpected|';
}
