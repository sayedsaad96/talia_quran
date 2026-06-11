/// Central review due-date semantics.
///
/// Existing app behavior intentionally has two policies:
/// - Memorization Plus is due at the scheduled instant or later.
/// - Legacy Hifz is due only after the scheduled instant.
///
/// Future review logic should depend on this helper instead of calling
/// [DateTime.isBefore] or [DateTime.isAfter] directly.
enum ReviewDuePolicy { onOrAfterScheduledTime, afterScheduledTime }

class ReviewDueEvaluator {
  const ReviewDueEvaluator();

  bool isDue({
    required DateTime now,
    required DateTime scheduledAt,
    required ReviewDuePolicy policy,
  }) {
    final utcNow = now.toUtc();
    final utcScheduledAt = scheduledAt.toUtc();
    return switch (policy) {
      ReviewDuePolicy.onOrAfterScheduledTime => !utcNow.isBefore(
        utcScheduledAt,
      ),
      ReviewDuePolicy.afterScheduledTime => utcNow.isAfter(utcScheduledAt),
    };
  }
}
