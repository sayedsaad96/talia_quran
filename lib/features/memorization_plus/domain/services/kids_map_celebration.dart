import '../entities/memorization_entities.dart';
import 'kids_surah_house_summary_builder.dart';

/// K37 — the houses to light up when the map opens: those completed since
/// the child's last visit to it. The first visit ([seenCompleted] null)
/// celebrates nothing, so an existing journey never bursts into glow.
Set<int> kidsHousesToCelebrate({
  required Set<int>? seenCompleted,
  required List<KidsJourneyStage> stages,
}) {
  if (seenCompleted == null) return const {};
  return kidsCompletedHouses(stages).difference(seenCompleted);
}

/// Stage numbers of the houses the child has finished (a house awaiting
/// review is still finished).
Set<int> kidsCompletedHouses(List<KidsJourneyStage> stages) => {
  for (final stage in stages)
    if (stage.status == KidsJourneyStageStatus.completed ||
        stage.status == KidsJourneyStageStatus.needsReview)
      stage.stageNumber,
};

/// Surah ids of the houses the child has finished on the whole-Quran
/// journey map (a surah awaiting review is still finished).
Set<int> kidsCompletedSurahs(List<KidsSurahHouse> houses) => {
  for (final house in houses)
    if (house.status == KidsSurahHouseStatus.completed ||
        house.status == KidsSurahHouseStatus.needsReview)
      house.surahId,
};

/// The surahs to light up when the whole-Quran journey map opens: those
/// completed since the child's last visit to it. The first visit
/// ([seenCompleted] null) celebrates nothing, so an existing journey never
/// bursts into glow.
Set<int> kidsSurahsToCelebrate({
  required Set<int>? seenCompleted,
  required List<KidsSurahHouse> houses,
}) {
  if (seenCompleted == null) return const {};
  return kidsCompletedSurahs(houses).difference(seenCompleted);
}
