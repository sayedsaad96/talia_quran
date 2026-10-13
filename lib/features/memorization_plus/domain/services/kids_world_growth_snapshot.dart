import 'package:equatable/equatable.dart';

import 'kids_achievements.dart';

/// Saved evidence the world may reflect. Each source is optional, so the
/// world never depends on every enrichment feature being switched on.
class KidsWorldGrowthEvidence {
  const KidsWorldGrowthEvidence({this.unlockedAchievements = const {}});

  /// Milestone ids already stored for the child (id name → first date).
  final Map<String, DateTime> unlockedAchievements;
}

/// Purely decorative growth: plants on the hills for reached milestones and
/// blossoms for effort milestones. It opens nothing, unlocks no surah and
/// never changes the journey; it only mirrors milestones already saved.
class KidsWorldGrowthSnapshot extends Equatable {
  const KidsWorldGrowthSnapshot({this.plants = 0, this.blossoms = 0});

  static const none = KidsWorldGrowthSnapshot();
  static const maxPlants = 12;

  final int plants;
  final int blossoms;

  bool get isEmpty => plants == 0 && blossoms == 0;

  @override
  List<Object?> get props => [plants, blossoms];
}

/// Pure: ids this build does not know are ignored, and since milestones never
/// re-lock, the same evidence always grows the same world.
KidsWorldGrowthSnapshot buildKidsWorldGrowthSnapshot(
  KidsWorldGrowthEvidence evidence,
) {
  final unlocked = evidence.unlockedAchievements.keys.toSet();
  final plants = KidsAchievementCatalog.specs
      .where((spec) => unlocked.contains(spec.id.name))
      .length;
  final blossoms = KidsAchievementCatalog.effortSpecs
      .where((spec) => unlocked.contains(spec.id.name))
      .length;
  return KidsWorldGrowthSnapshot(
    plants: plants.clamp(0, KidsWorldGrowthSnapshot.maxPlants),
    blossoms: blossoms,
  );
}
