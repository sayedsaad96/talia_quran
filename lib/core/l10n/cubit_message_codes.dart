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

  /// K15 — daily session-limit gate. Carries the total allowed session count
  /// after the code: '@kids/daily_limit|4'.
  static const kidsDailySessionLimitPrefix = '@kids/daily_limit|';

  // Guardian linking and parent rewards (family dashboard, child linking).
  static const guardianSignInRequired = '@guardian/sign_in_required';
  static const guardianCloudUnavailable = '@guardian/cloud_unavailable';
  static const guardianOnlyForChildren = '@guardian/only_for_children';
  static const guardianAlreadyLinked = '@guardian/already_linked';
  static const guardianParentModeAdultsOnly =
      '@guardian/parent_mode_adults_only';
  static const guardianLinkCodeInvalid = '@guardian/link_code_invalid';
  static const guardianChildHasGuardian = '@guardian/child_has_guardian';
  static const guardianSameAccount = '@guardian/same_account';
  static const parentRewardTitleRequired = '@guardian/reward_title_required';
  static const parentRewardLimitReached = '@guardian/reward_limit_reached';
  static const childNicknameInvalid = '@guardian/child_nickname_invalid';
  static const childAgeInvalid = '@guardian/child_age_invalid';
  static const guardianChildNotLinked = '@guardian/child_not_linked';
  static const childIdentityUpdateUnavailable =
      '@guardian/child_identity_update_unavailable';

  // Generic data-layer failures (emitted by core Failure types).
  static const errorCache = '@error/cache';
  static const errorNetwork = '@error/network';
  static const errorServer = '@error/server';
  static const errorNotFound = '@error/not_found';
  static const errorParse = '@error/parse';
  static const errorUnknown = '@error/unknown';
  static const kidsHomeMissionInvalidTitle =
      'kids_home_mission_invalid_title';

  // Account deletion is a multi-step remote/local transaction. These codes
  // deliberately conceal backend and storage details from the UI.
  static const accountDeletionFailed = '@auth/account_deletion_failed';
  static const accountDeletionCleanupFailed =
      '@auth/account_deletion_cleanup_failed';
  static const accountDeletionSessionCleanupFailed =
      '@auth/account_deletion_session_cleanup_failed';
  static const accountDeletionMarkerFailed =
      '@auth/account_deletion_marker_failed';
  static const accountDeletionUnavailable =
      '@auth/account_deletion_unavailable';
}
