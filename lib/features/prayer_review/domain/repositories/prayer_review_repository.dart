import '../entities/prayer_review_selection.dart';
import '../entities/prayer_review_authority.dart';

abstract interface class PrayerReviewRepository {
  Future<PrayerReviewSelection?> readAssignment({
    required String localDayKey,
    required String occurrenceKey,
  });

  /// Every frozen assignment of the current owner for one local day.
  Future<List<PrayerReviewSelection>> readAssignmentsForDay(
    String localDayKey,
  );

  Future<List<PrayerReviewReceipt>> readReceipts(String localDayKey);

  /// Returns the already stored assignment if a concurrent caller won first.
  Future<PrayerReviewSelection> saveAssignmentIfAbsent(
    PrayerReviewSelection selection,
    PrayerReviewAuthority authority,
  );

  /// Claims a saved prompt once; null means absent or already consumed.
  Future<PrayerReviewSelection?> consumePrompt(
    String occurrenceKey,
    PrayerReviewAuthority authority,
  );
}
