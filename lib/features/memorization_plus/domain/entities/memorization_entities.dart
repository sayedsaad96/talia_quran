import 'package:equatable/equatable.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum MemorizationTrack { adults, kids }

enum PerformanceRating { excellent, average, weak }

// ─── AyahReviewRecord ─────────────────────────────────────────────────────────

/// Enhanced per-ayah progress record used exclusively by MemorizationPlus.
/// Lives alongside existing [AyahProgress] without replacing it.
class AyahReviewRecord extends Equatable {
  const AyahReviewRecord({
    required this.surahId,
    required this.ayahNumber,
    required this.strengthLevel,
    required this.intervalDays,
    required this.lastReviewedAt,
    required this.nextReviewDate,
    required this.totalReviews,
    required this.lastRating,
  });

  final int surahId;
  final int ayahNumber;

  /// 0 = new, 1–5 = weak→strong, 6+ = memorized
  final int strengthLevel;

  /// Current interval in days
  final int intervalDays;

  final DateTime lastReviewedAt;
  final DateTime nextReviewDate;
  final int totalReviews;
  final PerformanceRating? lastRating;

  bool get isDue => DateTime.now().isAfter(nextReviewDate);
  bool get isNew => totalReviews == 0;
  bool get isMemorized => strengthLevel >= 6;

  /// Near revision: reviewed within last 5 days
  bool get isNearRevision {
    if (isNew) return false;
    final diff = DateTime.now().difference(lastReviewedAt).inDays;
    return diff <= 5 && !isMemorized;
  }

  /// Far revision: reviewed more than 5 days ago
  bool get isFarRevision {
    if (isNew) return false;
    final diff = DateTime.now().difference(lastReviewedAt).inDays;
    return diff > 5 && !isMemorized;
  }

  String get key => '${surahId}_$ayahNumber';

  AyahReviewRecord copyWith({
    int? strengthLevel,
    int? intervalDays,
    DateTime? lastReviewedAt,
    DateTime? nextReviewDate,
    int? totalReviews,
    PerformanceRating? lastRating,
  }) => AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel ?? this.strengthLevel,
    intervalDays: intervalDays ?? this.intervalDays,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    totalReviews: totalReviews ?? this.totalReviews,
    lastRating: lastRating ?? this.lastRating,
  );

  @override
  List<Object?> get props => [
    surahId,
    ayahNumber,
    strengthLevel,
    intervalDays,
    nextReviewDate,
    totalReviews,
    lastRating,
  ];
}

// ─── DailyPlan ────────────────────────────────────────────────────────────────

class DailyPlanAyah extends Equatable {
  const DailyPlanAyah({
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
    required this.record,
  });

  final int surahId;
  final int ayahNumber;
  final String ayahText;
  final AyahReviewRecord? record;

  bool get isNew => record == null || record!.isNew;

  @override
  List<Object?> get props => [surahId, ayahNumber, ayahText];
}

class DailyPlan extends Equatable {
  const DailyPlan({
    required this.generatedAt,
    required this.surahId,
    required this.newAyahs,
    required this.nearRevision,
    required this.farRevision,
    required this.completedAyahNums,
  });

  final DateTime generatedAt;
  final int surahId;
  final List<DailyPlanAyah> newAyahs;
  final List<DailyPlanAyah> nearRevision;
  final List<DailyPlanAyah> farRevision;
  final List<int> completedAyahNums;

  int get totalItems =>
      newAyahs.length + nearRevision.length + farRevision.length;
  int get completedCount => completedAyahNums.length;
  double get progress => totalItems == 0 ? 0 : completedCount / totalItems;

  bool isCompleted(int ayahNumber) => completedAyahNums.contains(ayahNumber);

  DailyPlan withCompleted(int ayahNumber) {
    if (completedAyahNums.contains(ayahNumber)) return this;
    return DailyPlan(
      generatedAt: generatedAt,
      surahId: surahId,
      newAyahs: newAyahs,
      nearRevision: nearRevision,
      farRevision: farRevision,
      completedAyahNums: [...completedAyahNums, ayahNumber],
    );
  }

  @override
  List<Object?> get props => [
    generatedAt,
    surahId,
    newAyahs,
    nearRevision,
    farRevision,
    completedAyahNums,
  ];
}

// ─── KidsProgress ─────────────────────────────────────────────────────────────

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

  KidsProgress addPoints(int points) {
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
    return KidsProgress(
      totalPoints: newTotal,
      currentLevel: level,
      currentStreak: currentStreak + 1,
      starsEarned: starsEarned + _starsForRating(),
      ayahsCompleted: ayahsCompleted + 1,
      lastSessionAt: DateTime.now(),
    );
  }

  int _starsForRating() => 1; // base, can be extended

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

// ─── CustomMemorizationPlan ───────────────────────────────────────────────────

/// Difficulty level affects the spaced repetition multiplier.
enum MemorizationDifficulty { easy, moderate, challenging }

/// A user-defined memorization plan with all scheduling parameters.
class CustomMemorizationPlan extends Equatable {
  const CustomMemorizationPlan({
    required this.name,
    required this.startSurahId,
    required this.endSurahId,
    required this.newAyahsPerDay,
    required this.availableDaysPerWeek,
    required this.sessionMinutes,
    required this.difficulty,
    required this.enableNearRevision,
    required this.enableFarRevision,
    required this.nearRevisionCount,
    required this.farRevisionCount,
    required this.startAyah,
    required this.createdAt,
    this.isActive = true,
  });

  /// User-given plan name, e.g. "خطتي لحفظ جزء عمّ"
  final String name;

  /// Surah range (inclusive)
  final int startSurahId;
  final int endSurahId;

  /// Starting ayah inside [startSurahId] (1-based)
  final int startAyah;

  /// How many new ayahs to introduce each session
  final int newAyahsPerDay;

  /// How many days per week the user can dedicate
  final int availableDaysPerWeek;

  /// Ideal session duration in minutes
  final int sessionMinutes;

  /// Affects review interval multiplier
  final MemorizationDifficulty difficulty;

  /// Whether to include near-revision and far-revision sections
  final bool enableNearRevision;
  final bool enableFarRevision;

  /// Max ayahs to include in each revision section
  final int nearRevisionCount;
  final int farRevisionCount;

  final DateTime createdAt;
  final bool isActive;

  /// Estimated days to finish (rough)
  int get estimatedDays {
    int totalAyahs = 0;
    // Rough estimate — will be refined at plan generation time
    // Using a simple heuristic: average surah ≈ 20 ayahs
    for (int s = startSurahId; s <= endSurahId; s++) {
      totalAyahs += 20; // placeholder average
    }
    if (newAyahsPerDay == 0) return 0;
    final sessionsNeeded = (totalAyahs / newAyahsPerDay).ceil();
    return (sessionsNeeded / (availableDaysPerWeek / 7.0)).ceil();
  }

  CustomMemorizationPlan copyWith({
    String? name,
    int? startSurahId,
    int? endSurahId,
    int? newAyahsPerDay,
    int? availableDaysPerWeek,
    int? sessionMinutes,
    MemorizationDifficulty? difficulty,
    bool? enableNearRevision,
    bool? enableFarRevision,
    int? nearRevisionCount,
    int? farRevisionCount,
    int? startAyah,
    DateTime? createdAt,
    bool? isActive,
  }) => CustomMemorizationPlan(
    name: name ?? this.name,
    startSurahId: startSurahId ?? this.startSurahId,
    endSurahId: endSurahId ?? this.endSurahId,
    newAyahsPerDay: newAyahsPerDay ?? this.newAyahsPerDay,
    availableDaysPerWeek: availableDaysPerWeek ?? this.availableDaysPerWeek,
    sessionMinutes: sessionMinutes ?? this.sessionMinutes,
    difficulty: difficulty ?? this.difficulty,
    enableNearRevision: enableNearRevision ?? this.enableNearRevision,
    enableFarRevision: enableFarRevision ?? this.enableFarRevision,
    nearRevisionCount: nearRevisionCount ?? this.nearRevisionCount,
    farRevisionCount: farRevisionCount ?? this.farRevisionCount,
    startAyah: startAyah ?? this.startAyah,
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
  );

  @override
  List<Object?> get props => [
    name,
    startSurahId,
    endSurahId,
    newAyahsPerDay,
    availableDaysPerWeek,
    sessionMinutes,
    difficulty,
    enableNearRevision,
    enableFarRevision,
    nearRevisionCount,
    farRevisionCount,
    startAyah,
    createdAt,
    isActive,
  ];
}
