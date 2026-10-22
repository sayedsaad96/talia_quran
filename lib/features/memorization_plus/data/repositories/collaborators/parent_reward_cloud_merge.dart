import '../../../domain/entities/parent_dashboard.dart';
import '../../models/memorization_models.dart';

/// Identity-safe cache merge for a complete, authorized cloud snapshot.
///
/// A server snapshot is authoritative only for cloud rows belonging to the
/// requested child. Local and unresolved legacy rows are deliberately kept.
class ParentRewardCloudMerge {
  const ParentRewardCloudMerge._();

  static List<ParentRewardModel> completeSnapshot({
    required List<ParentRewardModel> current,
    required List<ParentRewardModel> cloudSnapshot,
    required String ownerId,
  }) {
    final preserved = current.where((reward) {
      return reward.origin != ParentRewardOrigin.cloud ||
          reward.ownerId != ownerId;
    });
    final scopedSnapshot = cloudSnapshot.where((reward) {
      return reward.origin == ParentRewardOrigin.cloud &&
          reward.ownerId == ownerId;
    });
    return [...preserved, ...scopedSnapshot];
  }

  static List<ParentRewardModel> mergeAcknowledged({
    required List<ParentRewardModel> current,
    required Iterable<ParentReward> acknowledged,
  }) {
    final next = [...current];
    for (final reward in acknowledged) {
      if (reward.origin != ParentRewardOrigin.cloud) continue;
      final index = next.indexWhere(
        (existing) => existing.storageIdentity == reward.storageIdentity,
      );
      final model = ParentRewardModel.fromEntity(reward);
      if (index == -1) {
        next.add(model);
      } else {
        next[index] = model;
      }
    }
    return next;
  }
}
