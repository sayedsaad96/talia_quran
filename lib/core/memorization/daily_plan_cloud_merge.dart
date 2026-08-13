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
}