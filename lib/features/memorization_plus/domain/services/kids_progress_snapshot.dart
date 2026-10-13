import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../../core/constants/surah_names.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../../home/domain/entities/activity_event.dart';
import '../../../streak/domain/entities/streak_entity.dart';
import '../entities/kids_progress.dart';
import '../entities/kids_session_log.dart';
import '../entities/remote_child_summary.dart';
import 'kids_achievements.dart';
import 'kids_daily_missions.dart';
import 'kids_effort_achievement_inputs.dart';

/// Everything the kids "تقدّمي" page shows, from the kids track only. The
/// guardian's view of a child reads the same shape.
class KidsProgressSnapshot extends Equatable {
  const KidsProgressSnapshot({
    required this.level,
    required this.levelProgress,
    required this.points,
    required this.stars,
    required this.currentStreak,
    required this.longestStreak,
    required this.memorizedAyahs,
    required this.weekPages,
    required this.achievements,
    required this.certificates,
    required this.recentActivity,
  });

  final int level;

  /// Progress toward the next level, 0..1.
  final double levelProgress;
  final int points;
  final int stars;
  final int currentStreak;
  final int longestStreak;
  final int memorizedAyahs;

  /// Distinct Mushaf pages confirmed in the last 7 days. Null when unknown
  /// (a linked child whose device has not published reading yet).
  final int? weekPages;
  final List<KidsAchievement> achievements;

  /// Newest first.
  final List<CertificateAward> certificates;
  final List<ActivityEvent> recentActivity;

  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;

  @override
  List<Object?> get props => [
    level,
    levelProgress,
    points,
    stars,
    currentStreak,
    longestStreak,
    memorizedAyahs,
    weekPages,
    achievements,
    certificates,
    recentActivity,
  ];
}

/// Builds a [KidsProgressSnapshot] from the kids-only local stores.
class KidsProgressSnapshotLoader {
  KidsProgressSnapshotLoader({
    required Future<KidsProgress> Function() progress,
    required Future<StreakEntity> Function() streak,
    required Future<Set<int>> Function(String dayKey) pagesOn,
    required Future<Set<int>> Function() allPages,
    required List<CertificateAward> Function() certificates,
    required Future<List<ActivityEvent>> Function() recentActivity,
    required Future<List<KidsAchievement>> Function(KidsAchievementInputs)
    achievements,
    Future<List<KidsSessionLog>> Function()? sessionLogs,
    bool Function()? effortEnabled,
    String Function()? currentOwner,
    int Function()? familyPractices,
    bool Function()? familyPracticeEnabled,
    DateTime Function()? clock,
  }) : _sessionLogs = sessionLogs,
       _effortEnabled = effortEnabled,
       _currentOwner = currentOwner,
       _familyPractices = familyPractices,
       _familyPracticeEnabled = familyPracticeEnabled,
       _progress = progress,
       _streak = streak,
       _pagesOn = pagesOn,
       _allPages = allPages,
       _certificates = certificates,
       _recentActivity = recentActivity,
       _achievements = achievements,
       _clock = clock ?? DateTime.now;

  static const int recentLimit = 5;

  final Future<KidsProgress> Function() _progress;
  final Future<StreakEntity> Function() _streak;
  final Future<Set<int>> Function(String dayKey) _pagesOn;
  final Future<Set<int>> Function() _allPages;
  final List<CertificateAward> Function() _certificates;
  final Future<List<ActivityEvent>> Function() _recentActivity;
  final Future<List<KidsAchievement>> Function(KidsAchievementInputs)
  _achievements;
  final DateTime Function() _clock;

  /// Source of the child's saved session logs and the feature switch for the
  /// effort milestones. Without both, those milestones are not evaluated.
  final Future<List<KidsSessionLog>> Function()? _sessionLogs;
  final bool Function()? _effortEnabled;

  /// The record owner. When set, a load whose owner changed while it was
  /// reading is abandoned before it stores any milestone, so one account's
  /// numbers are never written under the next account.
  final String Function()? _currentOwner;

  /// Count of guardian-confirmed family practices (T4); none when null.
  final int Function()? _familyPractices;
  final bool Function()? _familyPracticeEnabled;

  Future<KidsEffortAchievementInputs?> _effortInputs() async {
    final logs = _sessionLogs;
    if (logs == null || !(_effortEnabled?.call() ?? false)) return null;
    try {
      final inputs = buildKidsEffortInputs(await logs());
      var practices = 0;
      try {
        practices = _familyPractices?.call() ?? 0;
      } catch (_) {
        practices = 0;
      }
      var available = false;
      try {
        available = _familyPracticeEnabled?.call() ?? false;
      } catch (_) {
        available = false;
      }
      return inputs.withFamilyPractices(practices, available: available);
    } catch (_) {
      // Unreadable logs never unlock (or re-lock) a milestone.
      return null;
    }
  }

  Future<KidsProgressSnapshot> load() async {
    final owner = _currentOwner?.call();
    final now = _clock();
    final progress = await _progress();
    final streak = await _streak();
    final weekPages = <int>{
      for (var i = 0; i < 7; i++)
        ...await _pagesOn(kidsDayKey(now.subtract(Duration(days: i)))),
    };
    final allPages = await _allPages();
    final certificates = [..._certificates()]
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    final longestStreak = max(streak.longestStreak, streak.currentStreak);
    final effort = await _effortInputs();
    if (_currentOwner != null && _currentOwner() != owner) {
      throw StateError('Kids data owner changed while loading progress');
    }
    final achievements = await _achievements(
      KidsAchievementInputs(
        memorizedAyahs: progress.ayahsCompleted,
        memorizedSurahs: certificates
            .where((c) => c.type == CertificateType.surah)
            .length,
        readPages: allPages.length,
        longestStreak: longestStreak,
        stars: progress.starsEarned,
        effort: effort,
      ),
    );
    final recent = await _recentActivity();
    return KidsProgressSnapshot(
      level: progress.currentLevel,
      levelProgress: progress.levelProgress.clamp(0, 1).toDouble(),
      points: progress.totalPoints,
      stars: progress.starsEarned,
      currentStreak: streak.currentStreak,
      longestStreak: longestStreak,
      memorizedAyahs: progress.ayahsCompleted,
      weekPages: weekPages.length,
      achievements: achievements,
      certificates: certificates,
      recentActivity: recent.take(recentLimit).toList(),
    );
  }
}

/// The guardian's view of a linked child on another device, built from the
/// family dashboard: kids progress from `kids_progress_cloud`, certificates
/// from `certificate_awards_cloud`, and milestones, weekly reading and recent
/// activity from the child's published activity snapshot.
KidsProgressSnapshot remoteKidsProgressSnapshot(
  RemoteChildSummary summary, {
  required DateTime now,
  bool includeEffort = false,
}) {
  final progress = summary.progress;
  final activity = summary.activity;
  final certificates = [
    for (final remote
        in summary.production?.certificates ?? const <RemoteCertificateAward>[])
      _withSurahNames(
        CertificateAward.fromCloudRow({
          'cert_id': remote.certId,
          'title_ar': remote.titleAr,
          'cert_type': remote.certType,
          'earned_at': remote.earnedAt.toIso8601String(),
        }),
      ),
  ]..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
  final longestStreak = max(
    activity?.longestStreak ?? 0,
    progress.currentStreak,
  );
  return KidsProgressSnapshot(
    level: progress.currentLevel,
    levelProgress: progress.levelProgress.clamp(0, 1).toDouble(),
    points: progress.totalPoints,
    stars: progress.starsEarned,
    currentStreak: progress.currentStreak,
    longestStreak: longestStreak,
    memorizedAyahs: progress.ayahsCompleted,
    weekPages: activity?.weekReadPagesCount,
    achievements: [
      ...KidsAchievementCatalog.evaluate(
        KidsAchievementInputs(
          memorizedAyahs: progress.ayahsCompleted,
          memorizedSurahs: certificates
              .where((c) => c.type == CertificateType.surah)
              .length,
          readPages: activity?.readPagesCount ?? 0,
          longestStreak: longestStreak,
          stars: progress.starsEarned,
        ),
        now: now,
        unlocked: activity?.achievements ?? const {},
      ),
      // The child's logs are not on this device, so effort milestones appear
      // only once the child device reports them; never as a locked row with
      // an invented progress.
      if (includeEffort)
        for (final spec in KidsAchievementCatalog.effortSpecs)
          if (activity?.achievements[spec.id.name] case final at?)
            KidsAchievement(spec: spec, current: spec.target, unlockedAt: at),
    ],
    certificates: certificates,
    recentActivity: (activity?.events ?? const <ActivityEvent>[])
        .take(KidsProgressSnapshotLoader.recentLimit)
        .toList(),
  );
}

/// Cloud rows carry the surah only in the certificate id; the certificate
/// page shows its name.
CertificateAward _withSurahNames(CertificateAward award) {
  final surahId = award.surahId;
  if (surahId == null) return award;
  return CertificateAward(
    id: award.id,
    titleAr: award.titleAr,
    type: award.type,
    earnedAt: award.earnedAt,
    juzNumber: award.juzNumber,
    surahId: surahId,
    surahNameAr: SurahNames.nameAr(surahId),
    surahNameEn: SurahNames.nameEn(surahId),
    titleEn: award.titleEn,
    dedication: award.dedication,
  );
}
