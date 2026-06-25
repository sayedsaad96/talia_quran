// lib/core/memorization/v2/session_phase.dart

/// Official V2 session phase state machine.
/// Matches Product Rules §11 verbatim.
enum V2SessionPhase {
  created,
  learning,
  memorizing,
  reciting,
  remediation,
  blockReviewPending,
  blockReview,
  completed,
}

extension V2SessionPhaseX on V2SessionPhase {
  /// Whether STT recording should be active.
  bool get requiresSTT =>
      this == V2SessionPhase.reciting || this == V2SessionPhase.blockReview;

  /// Whether the ayah text must be hidden from user.
  bool get textHidden =>
      this == V2SessionPhase.reciting || this == V2SessionPhase.blockReview;

  /// Whether the hint system is available (Product Rules §5: memorizing ONLY).
  bool get hintsAllowed => this == V2SessionPhase.memorizing;

  /// Whether this is a terminal phase.
  bool get isTerminal => this == V2SessionPhase.completed;

  /// Human-readable label for logging.
  String get debugLabel => switch (this) {
    V2SessionPhase.created => 'CREATED',
    V2SessionPhase.learning => 'LEARNING',
    V2SessionPhase.memorizing => 'MEMORIZING',
    V2SessionPhase.reciting => 'RECITING',
    V2SessionPhase.remediation => 'REMEDIATION',
    V2SessionPhase.blockReviewPending => 'BLOCK_REVIEW_PENDING',
    V2SessionPhase.blockReview => 'BLOCK_REVIEW',
    V2SessionPhase.completed => 'COMPLETED',
  };
}
