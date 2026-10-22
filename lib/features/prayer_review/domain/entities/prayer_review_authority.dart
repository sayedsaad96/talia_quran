import '../../../../core/identity/account_data_barrier.dart';

/// Original account authority captured before prayer-review input crosses an
/// asynchronous boundary.
final class PrayerReviewAuthority {
  const PrayerReviewAuthority({required this.ownerId, required this.lease});

  final String ownerId;
  final AccountDataLease lease;

  void check() => lease.checkOwner(ownerId);
}
