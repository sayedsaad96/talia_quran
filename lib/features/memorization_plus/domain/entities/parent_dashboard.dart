import 'package:equatable/equatable.dart';

import 'ayah_review_record.dart';
import 'kids_home_mission.dart';
import 'kids_journey_stage.dart';
import 'kids_progress.dart';
import 'kids_session_log.dart';
import 'kids_session_policy.dart';

enum ParentRewardStatus { locked, unlocked, claimed }

class ParentSettings extends Equatable {
  const ParentSettings({
    this.pinHash,
    this.reminderEnabled = true,
    this.reminderHour = 18,
    this.reminderMinute = 30,
    this.weeklyGoalSessions = 5,
    this.remoteLinkEnabled = false,
    this.localChildNickname,
    this.guidanceAudioEnabled,
    this.sessionGoalMinutes,
    this.startingSurahId = KidsJourneyPath.firstSurahId,
    this.kidsHifzV2Enabled = false,
    this.kidsReduceMotion = false,
    this.maxDailySuggestions = 3,
    this.homeMissionsEnabled = true,
    this.policyVersion = 0,
  });

  final String? pinHash;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int weeklyGoalSessions;
  final bool remoteLinkEnabled;

  /// Optional nickname for the local child on this device.
  final String? localChildNickname;

  /// Null keeps the age-band default; an explicit value is a parent override.
  final bool? guidanceAudioEnabled;
  final int? sessionGoalMinutes;
  final int startingSurahId;
  final bool kidsHifzV2Enabled;

  /// Guardian policy: calm the kids world (no ambient motion).
  final bool kidsReduceMotion;

  /// Guardian policy: daily suggestions shown to the child (1..3).
  final int maxDailySuggestions;

  /// Guardian policy: whether home missions appear for the child.
  final bool homeMissionsEnabled;

  /// Compare-and-swap version of the child policy (0 = never synced).
  final int policyVersion;

  bool get hasPin => pinHash != null && pinHash!.isNotEmpty;

  ParentSettings copyWith({
    String? pinHash,
    bool clearPin = false,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    int? weeklyGoalSessions,
    bool? remoteLinkEnabled,
    String? localChildNickname,
    bool? guidanceAudioEnabled,
    int? sessionGoalMinutes,
    bool clearSessionGoalMinutes = false,
    int? startingSurahId,
    bool? kidsHifzV2Enabled,
    bool? kidsReduceMotion,
    int? maxDailySuggestions,
    bool? homeMissionsEnabled,
    int? policyVersion,
  }) => ParentSettings(
    pinHash: clearPin ? null : (pinHash ?? this.pinHash),
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    weeklyGoalSessions: weeklyGoalSessions ?? this.weeklyGoalSessions,
    remoteLinkEnabled: remoteLinkEnabled ?? this.remoteLinkEnabled,
    localChildNickname: localChildNickname ?? this.localChildNickname,
    guidanceAudioEnabled: guidanceAudioEnabled ?? this.guidanceAudioEnabled,
    sessionGoalMinutes: clearSessionGoalMinutes
        ? null
        : (sessionGoalMinutes ?? this.sessionGoalMinutes),
    startingSurahId: startingSurahId ?? this.startingSurahId,
    kidsHifzV2Enabled: kidsHifzV2Enabled ?? this.kidsHifzV2Enabled,
    kidsReduceMotion: kidsReduceMotion ?? this.kidsReduceMotion,
    maxDailySuggestions: maxDailySuggestions ?? this.maxDailySuggestions,
    homeMissionsEnabled: homeMissionsEnabled ?? this.homeMissionsEnabled,
    policyVersion: policyVersion ?? this.policyVersion,
  );

  @override
  List<Object?> get props => [
    pinHash,
    reminderEnabled,
    reminderHour,
    reminderMinute,
    weeklyGoalSessions,
    remoteLinkEnabled,
    localChildNickname,
    guidanceAudioEnabled,
    sessionGoalMinutes,
    startingSurahId,
    kidsHifzV2Enabled,
    kidsReduceMotion,
    maxDailySuggestions,
    homeMissionsEnabled,
    policyVersion,
  ];
}

class ParentReward extends Equatable {
  const ParentReward({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.unlockedAt,
    this.claimedAt,
  });

  final String id;
  final String title;
  final ParentRewardStatus status;
  final DateTime createdAt;
  final DateTime? unlockedAt;
  final DateTime? claimedAt;

  ParentReward copyWith({
    String? title,
    ParentRewardStatus? status,
    DateTime? unlockedAt,
    DateTime? claimedAt,
  }) => ParentReward(
    id: id,
    title: title ?? this.title,
    status: status ?? this.status,
    createdAt: createdAt,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    claimedAt: claimedAt ?? this.claimedAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    status,
    createdAt,
    unlockedAt,
    claimedAt,
  ];
}

class ParentDashboard extends Equatable {
  const ParentDashboard({
    required this.progress,
    required this.stages,
    required this.logs,
    required this.rewards,
    required this.settings,
    this.homeMissions = const [],
  });

  final KidsProgress progress;
  final List<KidsJourneyStage> stages;
  final List<KidsSessionLog> logs;
  final List<ParentReward> rewards;
  final ParentSettings settings;

  /// Missions the guardian assigned to this device's child.
  final List<KidsHomeMission> homeMissions;

  int get commitmentDays => logs
      .map((log) {
        final local = log.completedAt.toLocal();
        return '${local.year}-${local.month}-${local.day}';
      })
      .toSet()
      .length;

  int get dueReviewCount => stages
      .where((stage) => stage.status == KidsJourneyStageStatus.needsReview)
      .fold(0, (sum, stage) => sum + stage.totalAyahs);

  int get ayahsNeedingSupport {
    final latestByAyah = <String, KidsSessionLog>{};
    for (final log in logs) {
      final key = '${log.surahId}:${log.ayahNumber}';
      final existing = latestByAyah[key];
      if (existing == null || log.completedAt.isAfter(existing.completedAt)) {
        latestByAyah[key] = log;
      }
    }
    return latestByAyah.values
        .where((log) => log.masteryRating == PerformanceRating.weak)
        .length;
  }

  int get averageSessionDurationSeconds {
    final measured = logs.where((log) => log.durationSeconds > 0).toList();
    if (measured.isEmpty) return 0;
    final total = measured.fold<int>(
      0,
      (sum, log) => sum + log.durationSeconds,
    );
    return (total / measured.length).round();
  }

  int get totalHintUses => logs.fold(0, (sum, log) => sum + log.hintCount);

  int get weeklyCompletedSessions {
    final now = DateTime.now().toUtc();
    final weekStart = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return logs
        .where((log) => !log.completedAt.toUtc().isBefore(weekStart))
        .length;
  }

  @override
  List<Object?> get props => [
    progress,
    stages,
    logs,
    rewards,
    settings,
    homeMissions,
  ];
}
