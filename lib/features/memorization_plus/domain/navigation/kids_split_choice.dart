import '../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../../../../core/router/app_router.dart';
import '../entities/kids_journey_path_definition.dart';
import '../entities/memorization_entities.dart';
import 'kids_next_mission_resolver.dart';

/// Whether the child still has to pick how to memorize [surahId] (whole or in
/// stages, spec §4.4). Only the Quran journey asks, only before anything is
/// memorized in the surah, and only when the settings, logs and the surah's
/// size ([ayahCount] > 0) are known: a missing answer never blocks the child.
///
/// This is the single source of the rule; the journey page, the home mission
/// card and the completion "Next" all use it.
bool kidsSurahNeedsSplitChoice({
  required KidsJourneyPathDefinition path,
  required int surahId,
  required int ayahCount,
  required ParentSettings? settings,
  required List<KidsSessionLog>? logs,
}) {
  if (!path.isQuranJourney || settings == null || logs == null) return false;
  if (ayahCount <= 0) return false;
  final hasProgress = logs.any(
    (log) =>
        log.surahId == surahId &&
        KidsSessionLogsCloudMerge.isCanonicalRewardLog(log),
  );
  return !hasProgress &&
      !settings.kidsWholeSurahIds.contains(surahId) &&
      !settings.kidsHouseSizesBySurah.containsKey(surahId);
}

/// Whether opening [mission] must first ask the split question: only new
/// memorization starts a surah, so reviews always go straight to the session.
bool kidsMissionNeedsSplitChoice(
  KidsNextMission? mission, {
  required bool Function(int surahId) surahNeedsChoice,
}) =>
    mission != null &&
    mission.type == KidsMissionType.newMemorization &&
    surahNeedsChoice(mission.surahId);

/// Where opening [mission] leads: straight to the session, or to the journey
/// page of its surah, which asks the split question first.
String kidsMissionLocation(
  KidsNextMission mission, {
  bool needsSplitChoice = false,
}) => needsSplitChoice
    ? '${AppRoutes.memorizationPlusKidsJourney}?surahId=${mission.surahId}'
    : '${AppRoutes.memorizationPlusKids}?surahId=${mission.surahId}'
          '&ayahNumber=${mission.startAyah}&missionType=${mission.type.name}';

/// Surah size from its journey stages (the last stage's end ayah).
int kidsAyahCountFromStages(int surahId, List<KidsJourneyStage> stages) {
  var ayahCount = 0;
  for (final stage in stages) {
    if (stage.surahId == surahId && stage.endAyah > ayahCount) {
      ayahCount = stage.endAyah;
    }
  }
  return ayahCount;
}
