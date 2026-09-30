import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
import 'review_record_filters.dart';

/// How much of a surah the adult learner has memorized (N17), for the
/// status badge in the surah list.
enum SurahMemorizationStatus {
  /// Some ayahs recited and reviewed, not all memorized yet.
  inProgress,

  /// Every ayah of the surah is memorized (strength 6+).
  memorized;

  /// Statuses by surah id. Surahs the learner never started are absent;
  /// never-reviewed and non-adult records do not count.
  static Map<int, SurahMemorizationStatus> fromRecords(
    Iterable<AyahReviewRecord> records, {
    required Map<int, int> ayahCounts,
  }) {
    final started = <int>{};
    final memorized = <int, Set<int>>{};
    for (final record in records) {
      if (!ReviewRecordFilters.isAdultCompatible(record)) continue;
      if (record.totalReviews == 0) continue;
      started.add(record.surahId);
      if (record.isMemorized) {
        (memorized[record.surahId] ??= <int>{}).add(record.ayahNumber);
      }
    }
    return {
      for (final surahId in started)
        surahId:
            (memorized[surahId]?.length ?? 0) >=
                (ayahCounts[surahId] ?? 1 << 30)
            ? SurahMemorizationStatus.memorized
            : SurahMemorizationStatus.inProgress,
    };
  }
}
