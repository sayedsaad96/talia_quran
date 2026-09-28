import '../entities/memorization_entities.dart';

/// The single definition of "this kids review record is due", shared by the
/// mission resolver, the active-surah lookup, and the journey's `needsReview`
/// stage status so they can never drift apart (N6).
///
/// A record is due once its SM-2 date arrives. A weak rating comes back
/// earlier than its date, but never on the same local day it was recorded
/// (N5): a guardian-assisted or struggling pass is revisited tomorrow instead
/// of replacing the child's celebration with the same ayah again.
final class KidsDueReviewPolicy {
  const KidsDueReviewPolicy._();

  static bool isDue(AyahReviewRecord record, DateTime now) {
    if (!record.nextReviewDate.toUtc().isAfter(now.toUtc())) return true;
    if (record.lastRating != PerformanceRating.weak) return false;
    final local = now.toLocal();
    final startOfToday = DateTime(local.year, local.month, local.day);
    return record.lastReviewedAt.isBefore(startOfToday);
  }
}
