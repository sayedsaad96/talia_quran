import '../../features/memorization_plus/domain/entities/ayah_review_record.dart';

/// "لمحة مراجعة" (Micro-Review) — the daily surprise-recall pick.
///
/// Deliberately DIFFERENT from the Smart Coach / Journey hero: those surface
/// what is DUE. This picker surfaces one quiet ayah from the user's older
/// memorization for a 30-second active-recall moment — preferably an ayah
/// whose scheduled review is still ahead, chosen deterministically so the
/// same ayah stays for the whole day.
class MicroReviewPicker {
  const MicroReviewPicker();

  /// Returns the picked record, or null when the user has no memorized ayahs.
  AyahReviewRecord? pick({
    required List<AyahReviewRecord> records,
    required DateTime now,
  }) {
    final eligible =
        records.where((record) => record.strengthLevel >= 1).toList()
          ..sort(_oldestReviewedFirst);
    if (eligible.isEmpty) return null;

    // Prefer upcoming (not-yet-due) ayahs; fall back to any memorized ayah.
    final upcoming =
        eligible.where((r) => r.nextReviewDate.isAfter(now)).toList();
    final candidates = upcoming.isEmpty ? eligible : upcoming;

    // Rotate within the three oldest candidates so the pick changes daily
    // without feeling random between rebuilds.
    final daySeed = now.year * 372 + now.month * 31 + now.day;
    final window = candidates.length < 3 ? candidates.length : 3;
    return candidates[daySeed % window];
  }

  static int _oldestReviewedFirst(AyahReviewRecord a, AyahReviewRecord b) =>
      a.lastReviewedAt.compareTo(b.lastReviewedAt);
}
