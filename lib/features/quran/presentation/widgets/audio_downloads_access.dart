import '../../../../core/di/injection.dart';
import '../../../../core/experience/experience_feature_flags.dart';
import '../../../../core/experience/feature_preferences.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';

/// Whether the audio-download entry points may be shown.
Future<bool> audioDownloadsAvailable() =>
    adultExperienceAvailable(ExperienceFeature.audioDownloads);

/// Whether the user still wants [feature] (rollout AND preference). UI must
/// not read `ExperienceFlags` directly for these features; the plain-flags
/// fallback only covers callers that run before the preference layer is
/// registered (early startup, legacy tests).
bool experienceFeatureVisible(ExperienceFeature feature) {
  try {
    if (getIt.isRegistered<FeaturePreferences>()) {
      return getIt<FeaturePreferences>().isVisible(feature);
    }
    return getIt.isRegistered<ExperienceFlags>() &&
        getIt<ExperienceFlags>().isEnabled(feature);
  } catch (_) {
    return false;
  }
}

/// Whether the entry points of an adult-only [feature] may be shown: the
/// feature is visible and the profile is not a child. Their routes are
/// adult-only (`MemorizationRouteGuard.adultOnlyRedirect`), so a child
/// profile must not see a control that would bounce them away.
Future<bool> adultExperienceAvailable(ExperienceFeature feature) async {
  if (!experienceFeatureVisible(feature)) return false;
  if (!getIt.isRegistered<MemorizationPathResolver>()) return true;
  try {
    final profile = await getIt<MemorizationPathResolver>().currentProfile();
    return profile?.isChild != true;
  } catch (_) {
    return true;
  }
}
