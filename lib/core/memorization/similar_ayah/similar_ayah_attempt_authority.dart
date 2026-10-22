import '../../identity/account_data_barrier.dart';

/// Captured synchronously before recitation processing crosses any await.
final class SimilarAyahAttemptAuthority {
  const SimilarAyahAttemptAuthority({
    required this.ownerId,
    required this.lease,
  });

  final String ownerId;
  final AccountDataLease lease;

  void check() => lease.checkOwner(ownerId);
}
