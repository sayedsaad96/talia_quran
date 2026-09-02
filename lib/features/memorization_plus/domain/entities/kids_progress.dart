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

  final int totalPoints;
  final int currentLevel;
  final int currentStreak;
  final int starsEarned;
  final int ayahsCompleted;
  final DateTime? lastSessionAt;

  /// Points needed to reach next level (exponential growth)
  int get pointsForNextLevel => currentLevel * 100;

  /// Points earned in current level
  int get pointsInCurrentLevel {
    int spent = 0;
    for (int i = 1; i < currentLevel; i++) {
      spent += i * 100;
    }
    return totalPoints - spent;
  }

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
    assert(stars >= 1 && stars <= 3);
    final newTotal = totalPoints + points;
    int level = currentLevel;
    int needed = level * 100;
    int spent = 0;
    for (int i = 1; i < level; i++) {
      spent += i * 100;
    }
    while (newTotal - spent >= needed) {
      spent += needed;
      level++;
      needed = level * 100;
    }

    final now = DateTime.now().toUtc();

    return KidsProgress(
      totalPoints: newTotal,
      currentLevel: level,
      currentStreak: currentStreak,
      starsEarned: starsEarned + stars,
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
