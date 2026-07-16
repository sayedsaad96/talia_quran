import '../../features/memorization_plus/domain/entities/memorization_entities.dart';

/// Version / review-time merge for local ↔ cloud [AyahReviewRecord] rows.
///
/// Takes the complete later review event — never field-wise GREATEST — so a
/// legitimate weak rating can reduce mastery in synced state.
class ReviewRecordCloudMerge {
  ReviewRecordCloudMerge._();

  /// Merges [local] with [remote]. When [local] is null, returns [remote].
  static AyahReviewRecord merge({
    AyahReviewRecord? local,
    required AyahReviewRecord remote,
  }) {
    if (local == null) return remote;

    if (_isRemoteNewer(local: local, remote: remote)) {
      return remote.copyWith(
        createdByMode: _mergeMode(local.createdByMode, remote.createdByMode),
      );
    }
    return local.copyWith(
      createdByMode: _mergeMode(local.createdByMode, remote.createdByMode),
    );
  }

  static bool _isRemoteNewer({
    required AyahReviewRecord local,
    required AyahReviewRecord remote,
  }) {
    if (remote.lastReviewedAt.isAfter(local.lastReviewedAt)) return true;
    if (local.lastReviewedAt.isAfter(remote.lastReviewedAt)) return false;
    // Same review time: prefer remote (server is source of truth on pull).
    return true;
  }

  static ReviewRecordCreatedByMode _mergeMode(
    ReviewRecordCreatedByMode local,
    ReviewRecordCreatedByMode remote,
  ) {
    if (_isProductionMode(local) && !_isProductionMode(remote)) return local;
    if (_isProductionMode(remote) && !_isProductionMode(local)) return remote;
    return remote;
  }

  static bool _isProductionMode(ReviewRecordCreatedByMode mode) {
    return switch (mode) {
      ReviewRecordCreatedByMode.v2Session ||
      ReviewRecordCreatedByMode.kidsMode ||
      ReviewRecordCreatedByMode.hifz => true,
      _ => false,
    };
  }
}
