import 'package:equatable/equatable.dart';

// ─── KidsProgress ─────────────────────────────────────────────────────────────
//
// Gamification aggregate for the Kids path (points, level, stars, session timing).
//
// **Streak** — [currentStreak] is *not* owned here. It is hydrated at read time
// from [StreakService] (Isar `streakIsars`). Kids sessions call
// [StreakService.recordActivity] in [KidsModeCubit]; never increment streak in
// [addPoints].
//
// **Memorization** — cumulative ayah counts for certificates and parent
// metrics come from Isar review records tagged `kidsMode`
// ([ReviewRecordFilters.isKidsSource]). Journey stage visuals come from
// [KidsSessionLog] entries in SharedPreferences.

class KidsProgress extends Equatable {
  const KidsProgress({
    required this.totalPoints,
    required this.currentLevel,
    required this.currentStreak,
    required this.starsEarned,
    required this.ayahsCompleted,
    required this.lastSessionAt,
  });

  const KidsProgress.initial()
    : totalPoints = 0,
      currentLevel = 1,
      currentStreak = 0,
      starsEarned = 0,
      ayahsCompleted = 0,
      lastSessionAt = null;

  /// Points required to complete level step [level] (i.e. to move from
  /// [level] to [level] + 1).
  ///
  /// The first step is deliberately cheap (50 points ≈ 5 sessions) so a
  /// young child levels up within their first week — the strongest early
  /// motivator — while later steps keep the linear [level] * 100 growth.
  static int pointsForLevelStep(int level) => level <= 1 ? 50 : level * 100;

  /// Total points required to reach [level] from zero.
  static int cumulativePointsForLevel(int level) {
    var total = 0;
    for (var step = 1; step < level; step++) {
      total += pointsForLevelStep(step);
    }
    return total;
  }

  final int totalPoints;
  final int currentLevel;
  final int currentStreak;
  final int starsEarned;
  final int ayahsCompleted;
  final DateTime? lastSessionAt;

  /// Points needed to reach the next level.
  int get pointsForNextLevel => pointsForLevelStep(currentLevel);

  /// Points earned in the current level.
  int get pointsInCurrentLevel =>
      totalPoints - cumulativePointsForLevel(currentLevel);

  double get levelProgress => pointsInCurrentLevel / pointsForNextLevel;

  int get starsForLevel => switch (currentLevel) {
    <= 3 => 1,
    <= 7 => 2,
    _ => 3,
  };

  KidsProgress copyWith({
    int? totalPoints,
    int? currentLevel,
    int? currentStreak,
    int? starsEarned,
    int? ayahsCompleted,
    DateTime? lastSessionAt,
  }) {
    return KidsProgress(
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      starsEarned: starsEarned ?? this.starsEarned,
      ayahsCompleted: ayahsCompleted ?? this.ayahsCompleted,
      lastSessionAt: lastSessionAt ?? this.lastSessionAt,
    );
  }

  KidsProgress addPoints(int points, {int stars = 1}) {
    final clampedStars = stars.clamp(0, 3);
    final newTotal = totalPoints + points;
    // Levels are pure thresholds over the cumulative points; the shared
    // curve in [pointsForLevelStep] keeps entity and projection consistent.
    int level = currentLevel;
    while (newTotal >= cumulativePointsForLevel(level + 1)) {
      level++;
    }

    final now = DateTime.now().toUtc();

    return KidsProgress(
      totalPoints: newTotal,
      currentLevel: level,
      currentStreak: currentStreak,
      starsEarned: starsEarned + clampedStars,
      ayahsCompleted: ayahsCompleted + 1,
      lastSessionAt: now,
    );
  }

  KidsProgress withStar() => KidsProgress(
    totalPoints: totalPoints,
    currentLevel: currentLevel,
    currentStreak: currentStreak,
    starsEarned: starsEarned + 1,
    ayahsCompleted: ayahsCompleted,
    lastSessionAt: lastSessionAt,
  );

  @override
  List<Object?> get props => [
    totalPoints,
    currentLevel,
    currentStreak,
    starsEarned,
    ayahsCompleted,
  ];
}

class KidsCompletionResult extends Equatable {
  const KidsCompletionResult({
    required this.progress,
    required this.pointsEarned,
    required this.starsEarned,
    required this.alreadyCompleted,
  });

  final KidsProgress progress;
  final int pointsEarned;
  final int starsEarned;
  final bool alreadyCompleted;

  @override
  List<Object?> get props => [
    progress,
    pointsEarned,
    starsEarned,
    alreadyCompleted,
  ];
}
