import 'package:equatable/equatable.dart';

/// What a kids milestone counts.
enum KidsAchievementMetric { ayahs, surahs, pages, streak, stars }

/// Kids-only milestones. Names are stable storage keys: never rename one.
enum KidsAchievementId {
  firstAyah,
  ayahs10,
  ayahs50,
  ayahs100,
  firstSurah,
  surahs3,
  surahs10,
  firstPage,
  pages10,
  pages30,
  streak3,
  streak7,
  streak30,
  firstStar,
  stars10,
  stars50,
}

class KidsAchievementSpec {
  const KidsAchievementSpec(this.id, this.metric, this.target);

  final KidsAchievementId id;
  final KidsAchievementMetric metric;
  final int target;
}

/// The kids track's own numbers. Never fed from the adult learner.
class KidsAchievementInputs extends Equatable {
  const KidsAchievementInputs({
    this.memorizedAyahs = 0,
    this.memorizedSurahs = 0,
    this.readPages = 0,
    this.longestStreak = 0,
    this.stars = 0,
  });

  final int memorizedAyahs;

  /// Surahs the child holds a kids certificate for.
  final int memorizedSurahs;

  /// Distinct Mushaf pages the child confirmed reading.
  final int readPages;
  final int longestStreak;
  final int stars;

  int valueOf(KidsAchievementMetric metric) => switch (metric) {
    KidsAchievementMetric.ayahs => memorizedAyahs,
    KidsAchievementMetric.surahs => memorizedSurahs,
    KidsAchievementMetric.pages => readPages,
    KidsAchievementMetric.streak => longestStreak,
    KidsAchievementMetric.stars => stars,
  };

  @override
  List<Object?> get props => [
    memorizedAyahs,
    memorizedSurahs,
    readPages,
    longestStreak,
    stars,
  ];
}

class KidsAchievement extends Equatable {
  const KidsAchievement({
    required this.spec,
    required this.current,
    this.unlockedAt,
  });

  final KidsAchievementSpec spec;

  /// Progress toward [KidsAchievementSpec.target], capped at the target.
  final int current;
  final DateTime? unlockedAt;

  KidsAchievementId get id => spec.id;
  KidsAchievementMetric get metric => spec.metric;
  int get target => spec.target;
  bool get isUnlocked => unlockedAt != null;
  double get progress => isUnlocked ? 1 : current / target;

  @override
  List<Object?> get props => [spec.id, current, unlockedAt];
}

abstract final class KidsAchievementCatalog {
  static const specs = <KidsAchievementSpec>[
    KidsAchievementSpec(
      KidsAchievementId.firstAyah,
      KidsAchievementMetric.ayahs,
      1,
    ),
    KidsAchievementSpec(
      KidsAchievementId.ayahs10,
      KidsAchievementMetric.ayahs,
      10,
    ),
    KidsAchievementSpec(
      KidsAchievementId.ayahs50,
      KidsAchievementMetric.ayahs,
      50,
    ),
    KidsAchievementSpec(
      KidsAchievementId.ayahs100,
      KidsAchievementMetric.ayahs,
      100,
    ),
    KidsAchievementSpec(
      KidsAchievementId.firstSurah,
      KidsAchievementMetric.surahs,
      1,
    ),
    KidsAchievementSpec(
      KidsAchievementId.surahs3,
      KidsAchievementMetric.surahs,
      3,
    ),
    KidsAchievementSpec(
      KidsAchievementId.surahs10,
      KidsAchievementMetric.surahs,
      10,
    ),
    KidsAchievementSpec(
      KidsAchievementId.firstPage,
      KidsAchievementMetric.pages,
      1,
    ),
    KidsAchievementSpec(
      KidsAchievementId.pages10,
      KidsAchievementMetric.pages,
      10,
    ),
    KidsAchievementSpec(
      KidsAchievementId.pages30,
      KidsAchievementMetric.pages,
      30,
    ),
    KidsAchievementSpec(
      KidsAchievementId.streak3,
      KidsAchievementMetric.streak,
      3,
    ),
    KidsAchievementSpec(
      KidsAchievementId.streak7,
      KidsAchievementMetric.streak,
      7,
    ),
    KidsAchievementSpec(
      KidsAchievementId.streak30,
      KidsAchievementMetric.streak,
      30,
    ),
    KidsAchievementSpec(
      KidsAchievementId.firstStar,
      KidsAchievementMetric.stars,
      1,
    ),
    KidsAchievementSpec(
      KidsAchievementId.stars10,
      KidsAchievementMetric.stars,
      10,
    ),
    KidsAchievementSpec(
      KidsAchievementId.stars50,
      KidsAchievementMetric.stars,
      50,
    ),
  ];

  /// Evaluates every milestone. [unlocked] (id name → date) keeps earlier
  /// unlocks, so a milestone never re-locks when its data ages out; a target
  /// met for the first time unlocks at [now].
  static List<KidsAchievement> evaluate(
    KidsAchievementInputs inputs, {
    required DateTime now,
    Map<String, DateTime> unlocked = const {},
  }) => [
    for (final spec in specs)
      KidsAchievement(
        spec: spec,
        current: inputs.valueOf(spec.metric).clamp(0, spec.target),
        unlockedAt:
            unlocked[spec.id.name] ??
            (inputs.valueOf(spec.metric) >= spec.target ? now : null),
      ),
  ];
}
