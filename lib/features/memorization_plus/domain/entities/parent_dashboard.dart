import 'package:equatable/equatable.dart';

import 'kids_journey_stage.dart';
import 'kids_progress.dart';
import 'kids_session_log.dart';

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
  });

  final String? pinHash;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int weeklyGoalSessions;
  final bool remoteLinkEnabled;

  /// Optional nickname for the local child on this device.
  final String? localChildNickname;

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
  }) => ParentSettings(
    pinHash: clearPin ? null : (pinHash ?? this.pinHash),
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    weeklyGoalSessions: weeklyGoalSessions ?? this.weeklyGoalSessions,
    remoteLinkEnabled: remoteLinkEnabled ?? this.remoteLinkEnabled,
    localChildNickname: localChildNickname ?? this.localChildNickname,
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
  });

  final KidsProgress progress;
  final List<KidsJourneyStage> stages;
  final List<KidsSessionLog> logs;
  final List<ParentReward> rewards;
  final ParentSettings settings;

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
  List<Object?> get props => [progress, stages, logs, rewards, settings];
}
