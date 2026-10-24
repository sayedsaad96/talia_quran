import '../../../../core/di/injection.dart';
import '../../../../core/experience/experience_feature_flags.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';

/// Whether the audio-download entry points may be shown.
Future<bool> audioDownloadsAvailable() =>
    adultExperienceAvailable(ExperienceFeature.audioDownloads);

/// Whether the entry points of an adult-only [feature] may be shown: its flag
/// is on and the profile is not a child. Their routes are adult-only
/// (`MemorizationRouteGuard.adultOnlyRedirect`), so a child profile must not
/// see a control that would bounce them away.
Future<bool> adultExperienceAvailable(ExperienceFeature feature) async {
  if (!getIt.isRegistered<ExperienceFlags>() ||
      !getIt<ExperienceFlags>().isEnabled(feature)) {
    return false;
  }
  if (!getIt.isRegistered<MemorizationPathResolver>()) return true;
  try {
    final profile = await getIt<MemorizationPathResolver>().currentProfile();
    return profile?.isChild != true;
  } catch (_) {
    return true;
  }
}
