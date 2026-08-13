/// Decides whether a cloud custom plan should replace local state.
///
/// A clean plan may have been saved locally after its last cloud push. In that
/// case, only a strictly newer cloud row can replace it.
class CustomPlanCloudMerge {
  const CustomPlanCloudMerge._();

  static bool shouldApplyRemote({
    required bool localDirty,
    required DateTime? localUpdatedAt,
    required DateTime remoteUpdatedAt,
  }) {
    if (localDirty) return false;
    if (localUpdatedAt == null) return true;
    return remoteUpdatedAt.toUtc().isAfter(localUpdatedAt.toUtc());
  }
}
