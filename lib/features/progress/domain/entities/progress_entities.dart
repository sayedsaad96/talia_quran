import 'package:equatable/equatable.dart';

class OverallProgress extends Equatable {
  const OverallProgress({
    required this.memorizedAyahs,
    required this.totalAyahs,
    required this.memorizedSurahs,
    required this.totalSurahs,
    required this.memorizedJuz,
    required this.totalJuz,
    required this.readAyahs,
    required this.readSurahs,
    required this.readJuz,
    required this.streakDays,
    required this.lastActiveDate,
    required this.achievements,
    required this.readPagesCount,
    required this.totalQuranPages,
    required this.learningAyahs,
    required this.reviewAyahs,
    // Two-tier memorization vocabulary (Phase 1):
    // - memorizedAyahs = strengthLevel >= 6 (truly memorized)
    // - startedAyahs   = totalReviews > 0 (started; superset of memorized)
    this.startedAyahs = 0,
    // Cumulative review repetitions performed across all counted ayahs.
    this.reviewedAyahsTotal = 0,
    // Number of ayahs currently overdue for review.
    this.overdueReviews = 0,
    this.lastReviewedAt,
    this.lastMemorizedSurahId,
    this.lastMemorizedAyahNumber,
    this.kidsPoints = 0,
    this.kidsStars = 0,
  });

  final int memorizedAyahs;
  final int startedAyahs;
  final int reviewedAyahsTotal;
  final int overdueReviews;
  final DateTime? lastReviewedAt;
  final int? lastMemorizedSurahId;
  final int? lastMemorizedAyahNumber;
  final int totalAyahs;
  final int memorizedSurahs;
  final int totalSurahs;
  final int memorizedJuz;
  final int totalJuz;

  // Reading-only stats
  final int readAyahs;
  final int readSurahs;
  final int readJuz;

  // In-progress stats
  final int learningAyahs;
  final int reviewAyahs;

  final int kidsPoints;
  final int kidsStars;

  final int streakDays;
  final DateTime? lastActiveDate;
  final List<Achievement> achievements;
  final int readPagesCount;
  final int totalQuranPages;

  double get quranPercentage => totalQuranPages == 0
      ? 0
      : (readPagesCount / totalQuranPages).clamp(0.0, 1.0);

  double get surahPercentage =>
      totalSurahs == 0 ? 0 : (memorizedSurahs / totalSurahs).clamp(0.0, 1.0);

  double get memorizedAyahsPercentage =>
      totalAyahs == 0 ? 0 : (memorizedAyahs / totalAyahs).clamp(0.0, 1.0);

  double get startedAyahsPercentage =>
      totalAyahs == 0 ? 0 : (startedAyahs / totalAyahs).clamp(0.0, 1.0);

  /// Share of started ayahs that reached full memorization.
  double get retentionRate =>
      startedAyahs == 0 ? 0 : (memorizedAyahs / startedAyahs).clamp(0.0, 1.0);

  double get memorizedJuzPercentage =>
      totalJuz == 0 ? 0 : (memorizedJuz / totalJuz).clamp(0.0, 1.0);

  int get unlockedAchievements =>
      achievements.where((a) => a.isUnlocked).length;

  @override
  List<Object?> get props => [
    memorizedAyahs,
    startedAyahs,
    reviewedAyahsTotal,
    overdueReviews,
    overdueReviews,
    lastReviewedAt,
    lastMemorizedSurahId,
    lastMemorizedAyahNumber,
    memorizedSurahs,
    memorizedJuz,
    readAyahs,
    readSurahs,
    readJuz,
    streakDays,
    achievements,
    readPagesCount,
    learningAyahs,
    reviewAyahs,
    kidsPoints,
    kidsStars,
  ];
}

enum AchievementCategory { reading, memorization, streak, milestone }

class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.isUnlocked,
    required this.category,
    this.currentValue = 0,
    this.targetValue = 1,
  });

  final String id;
  final String titleKey;
  final String descriptionKey;
  final String icon;
  final bool isUnlocked;
  final AchievementCategory category;
  final int currentValue;
  final int targetValue;

  double get progressPercent =>
      targetValue == 0 ? 0 : (currentValue / targetValue).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [id, isUnlocked, currentValue];
}
