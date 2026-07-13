import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
import 'progress_metrics.dart';
import 'review_classification.dart';
import 'review_record_filters.dart';

/// The single, pure calculator for all progress numbers.
///
/// Every consumer (ProgressRepository, AchievementService, Parent Dashboard,
/// Home) MUST derive its figures from this service instead of computing them
/// locally. This guarantees that a given user state produces identical numbers
/// on every screen.
///
/// The service is deliberately pure: it performs no IO and takes an explicit
/// [now], so it is fully deterministic and unit-testable. All time-dependent
/// classification (due/overdue) uses the injected [now] rather than the
/// record's own `DateTime.now()`-based getters.
class ProgressMetricsService {
  const ProgressMetricsService();

  static const _classifier = ReviewClassifier();

  /// Computes a complete [ProgressMetrics] snapshot for one [audience].
  ///
  /// Inputs are primitive/aggregate structures shaped by the caller from its
  /// data sources:
  /// - [records]        : all review records (any source); filtered internally
  ///                      by [audience].
  /// - [surahAyahCounts]: surahId → total ayah count (for full-surah checks).
  /// - [ayahKeysByJuz]  : juz → set of `"surah_ayah"` keys belonging to it.
  /// - [readPagesCount] / [readAyahKeys] / [readSurahIds]: reading progress
  ///   already resolved from confirmed pages.
  ProgressMetrics calculate({
    required List<AyahReviewRecord> records,
    required DateTime now,
    ProgressAudience audience = ProgressAudience.adult,
    Map<int, int> surahAyahCounts = const {},
    Map<int, Set<String>> ayahKeysByJuz = const {},
    int totalAyahs = 0,
    int totalSurahs = 0,
    int totalJuz = 0,
    int readPagesCount = 0,
    int totalQuranPages = 0,
    Set<String> readAyahKeys = const {},
    Set<int> readSurahIds = const {},
    int streakDays = 0,
  }) {
    final counted = records.where(_sourcePredicate(audience)).toList();

    final memorizedKeys = <String>{};
    final memorizedBySurah = <int, Set<int>>{};
    var startedAyahs = 0;
    var learningAyahs = 0;
    var totalReviewEvents = 0;
    var dueReviews = 0;
    var overdueReviews = 0;
    DateTime? lastReviewedAt;
    int? lastMemorizedSurahId;
    int? lastMemorizedAyahNumber;
    DateTime? lastMemorizedAt;

    final startOfToday = DateTime.utc(now.year, now.month, now.day);

    for (final record in counted) {
      totalReviewEvents += record.totalReviews;

      final started = ReviewRecordFilters.isStarted(record);
      if (!started) continue;
      startedAyahs++;

      if (ReviewRecordFilters.isMemorized(record)) {
        memorizedKeys.add(record.key);
        memorizedBySurah
            .putIfAbsent(record.surahId, () => <int>{})
            .add(record.ayahNumber);

        if (lastMemorizedAt == null ||
            record.lastReviewedAt.isAfter(lastMemorizedAt)) {
          lastMemorizedAt = record.lastReviewedAt;
          lastMemorizedSurahId = record.surahId;
          lastMemorizedAyahNumber = record.ayahNumber;
        }
      } else {
        learningAyahs++;
      }

      if (lastReviewedAt == null ||
          record.lastReviewedAt.isAfter(lastReviewedAt)) {
        lastReviewedAt = record.lastReviewedAt;
      }

      if (_isDue(record, now)) {
        dueReviews++;
        if (record.nextReviewDate.toUtc().isBefore(startOfToday)) {
          overdueReviews++;
        }
      }
    }

    final memorizedSurahs = memorizedBySurah.entries.where((entry) {
      final total = surahAyahCounts[entry.key];
      return total != null && total > 0 && entry.value.length >= total;
    }).length;

    var memorizedJuz = 0;
    for (final juzKeys in ayahKeysByJuz.values) {
      if (juzKeys.isNotEmpty && juzKeys.every(memorizedKeys.contains)) {
        memorizedJuz++;
      }
    }

    final readJuz = (readPagesCount / 20).floor().clamp(
      0,
      totalJuz == 0 ? 30 : totalJuz,
    );

    return ProgressMetrics(
      audience: audience,
      startedAyahs: startedAyahs,
      memorizedAyahs: memorizedKeys.length,
      learningAyahs: learningAyahs,
      totalReviewEvents: totalReviewEvents,
      memorizedSurahs: memorizedSurahs,
      memorizedJuz: memorizedJuz,
      dueReviews: dueReviews,
      overdueReviews: overdueReviews,
      totalAyahs: totalAyahs,
      totalSurahs: totalSurahs,
      totalJuz: totalJuz,
      readPagesCount: readPagesCount,
      totalQuranPages: totalQuranPages,
      readAyahs: readAyahKeys.length,
      readSurahs: readSurahIds.length,
      readJuz: readJuz,
      streakDays: streakDays,
      memorizedKeys: memorizedKeys,
      lastReviewedAt: lastReviewedAt,
      lastMemorizedSurahId: lastMemorizedSurahId,
      lastMemorizedAyahNumber: lastMemorizedAyahNumber,
    );
  }

  bool Function(AyahReviewRecord) _sourcePredicate(ProgressAudience audience) {
    return switch (audience) {
      ProgressAudience.adult => ReviewRecordFilters.isAdultProductionCount,
      ProgressAudience.kids => ReviewRecordFilters.isKidsSource,
    };
  }

  bool _isDue(AyahReviewRecord record, DateTime now) {
    if (!ReviewRecordFilters.isStarted(record)) return false;
    return _classifier
        .classify(
          ReviewClassificationInput(
            now: now,
            lastReviewedAt: record.lastReviewedAt,
            nextReviewDate: record.nextReviewDate,
            strengthLevel: record.strengthLevel,
            totalReviews: record.totalReviews,
          ),
        )
        .isDue;
  }
}
