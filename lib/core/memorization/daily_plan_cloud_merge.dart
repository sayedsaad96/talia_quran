import '../../features/memorization_plus/domain/entities/daily_plan.dart';

/// Decides whether a cloud daily plan should replace the local cache.
///
/// Dirty local plans always win until they are pushed — pull-before-push must
/// not discard offline completions or regenerations.
class DailyPlanCloudMerge {
  const DailyPlanCloudMerge._();

  /// Returns true when the remote plan should be applied locally.
  static bool shouldApplyRemote({
    required bool localDirty,
    required DateTime? localGeneratedAt,
    required DateTime remoteGeneratedAt,
  }) {
    if (localDirty) return false;
    if (localGeneratedAt == null) return true;
    return remoteGeneratedAt.toUtc().isAfter(localGeneratedAt.toUtc());
  }

  /// When both devices changed the same study day's plan, keep the local
  /// plan's items and add the other device's completions (union) instead of
  /// letting either side silently overwrite the other. Returns null when the
  /// plans belong to different local study days.
  static DailyPlan? mergeSameDay({
    required DailyPlan local,
    required DailyPlan remote,
  }) {
    if (!_sameLocalDay(local.generatedAt, remote.generatedAt)) return null;
    var merged = local;
    for (final ayahNumber in remote.completedAyahNums) {
      merged = merged.withCompleted(ayahNumber, ayahSurahId: remote.surahId);
    }
    for (final key in remote.completedAyahKeys) {
      final parts = key.split(':');
      final surahId = parts.length == 2 ? int.tryParse(parts[0]) : null;
      final ayahNumber = parts.length == 2 ? int.tryParse(parts[1]) : null;
      if (surahId == null || ayahNumber == null) continue;
      merged = merged.withCompleted(ayahNumber, ayahSurahId: surahId);
    }
    return merged;
  }

  static bool _sameLocalDay(DateTime a, DateTime b) {
    final left = a.toLocal();
    final right = b.toLocal();
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
