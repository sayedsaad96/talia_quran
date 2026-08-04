import 'package:equatable/equatable.dart';

import 'parent_dashboard.dart';
import 'remote_child_summary.dart';

// ─── FamilyChildEntry ─────────────────────────────────────────────────────────

/// Represents a single child entry in the Family Dashboard.
/// Can be either a local child (same device) or a remote child (linked via QR).
class FamilyChildEntry extends Equatable {
  const FamilyChildEntry({
    required this.childUserId,
    required this.displayName,
    this.avatarEmoji,
    required this.isLocal,
    this.localData,
    this.remoteSummary,
  });

  final String childUserId;
  final String displayName;

  /// Optional emoji avatar chosen by parent. Defaults shown in UI.
  final String? avatarEmoji;

  /// True when this child uses the same physical device as the parent.
  final bool isLocal;

  /// Non-null for local children — data read from Isar / SharedPrefs.
  final ParentDashboard? localData;

  /// Non-null for remote children — data read from Supabase.
  final RemoteChildSummary? remoteSummary;

  /// Points earned today (all sessions since UTC midnight).
  int get todayPoints {
    final today = DateTime.now().toUtc();
    final todayStart = DateTime.utc(today.year, today.month, today.day);
    if (isLocal) {
      return localData?.logs
              .where((l) => !l.completedAt.toUtc().isBefore(todayStart))
              .fold<int>(0, (s, l) => s + l.pointsEarned) ??
          0;
    }
    return remoteSummary?.logs
            .where((l) => !l.completedAt.toUtc().isBefore(todayStart))
            .fold<int>(0, (s, l) => s + l.pointsEarned) ??
        0;
  }

  /// Sessions completed today.
  int get todaySessions {
    final today = DateTime.now().toUtc();
    final todayStart = DateTime.utc(today.year, today.month, today.day);
    if (isLocal) {
      return localData?.logs
              .where((l) => !l.completedAt.toUtc().isBefore(todayStart))
              .length ??
          0;
    }
    return remoteSummary?.logs
            .where((l) => !l.completedAt.toUtc().isBefore(todayStart))
            .length ??
        0;
  }

  /// Current streak (days in a row).
  int get currentStreak =>
      isLocal
          ? (localData?.progress.currentStreak ?? 0)
          : (remoteSummary?.progress.currentStreak ?? 0);

  /// Current level.
  int get currentLevel =>
      isLocal
          ? (localData?.progress.currentLevel ?? 1)
          : (remoteSummary?.progress.currentLevel ?? 1);

  /// Stars earned.
  int get starsEarned =>
      isLocal
          ? (localData?.progress.starsEarned ?? 0)
          : (remoteSummary?.progress.starsEarned ?? 0);

  /// Level progress ratio [0.0, 1.0].
  double get levelProgress =>
      isLocal
          ? (localData?.progress.levelProgress ?? 0.0)
          : (remoteSummary?.progress.levelProgress ?? 0.0);

  /// Whether the child had any activity today.
  bool get isActiveToday => todaySessions > 0;

  @override
  List<Object?> get props =>
      [childUserId, displayName, isLocal, localData, remoteSummary];
}

// ─── FamilyDashboard ──────────────────────────────────────────────────────────

/// Unified family view: all children linked to a parent, plus parent settings.
class FamilyDashboard extends Equatable {
  const FamilyDashboard({
    required this.children,
    required this.settings,
  });

  final List<FamilyChildEntry> children;
  final ParentSettings settings;

  bool get hasAnyChild => children.isNotEmpty;

  /// Count of children who had at least one session today.
  int get totalActiveToday =>
      children.where((c) => c.isActiveToday).length;

  /// Sum of all points earned today across all children.
  int get totalPointsToday =>
      children.fold<int>(0, (sum, c) => sum + c.todayPoints);

  @override
  List<Object?> get props => [children, settings];
}
