/// The exact local mutations accepted by a cloud operation.
class SyncAcknowledgement {
  const SyncAcknowledgement({
    required this.mutationVersions,
    this.serverRevision,
  });

  final Map<String, int> mutationVersions;
  final int? serverRevision;
}

/// A compare-and-swap rejection that preserves both device copies for an
/// explicit user or product-level resolution step.
class SyncConflict<T> {
  const SyncConflict({
    required this.local,
    required this.cloud,
    required this.cloudRevision,
  });

  final T? local;
  final T? cloud;
  final int cloudRevision;
}

/// The only permitted resolution for a compare-and-swap plan conflict.
/// Neither value is silently overwritten during synchronization.
enum SyncConflictResolution { keepLocal, acceptCloud }

/// Outcome of an explicit dead-letter recovery request.
class DeadLetterRecoveryResult {
  const DeadLetterRecoveryResult({
    required this.kind,
    required this.rearmed,
  });

  final String kind;
  final bool rearmed;
}
