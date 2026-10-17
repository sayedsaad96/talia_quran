import 'package:equatable/equatable.dart';

import '../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../entities/ayah_review_record.dart';
import '../entities/kids_session_log.dart';
import 'kids_adventure_regions.dart';
import 'kids_weekly_coaching.dart';

/// One ayah that needs a little more support this month.
typedef KidsReportAyah = ({int surahId, int ayahNumber});

/// What a guardian can say about the child's last 30 local days.
final class KidsMonthlyReport extends Equatable {
  const KidsMonthlyReport({
    required this.periodStart,
    required this.periodEnd,
    this.sessions = 0,
    this.activeDays = 0,
    this.newAyahs = 0,
    this.reviews = 0,
    this.sessionsWithHints = 0,
    this.completedSurahIds = const [],
    this.needsSupport = const [],
  });

  /// First and last local calendar day of the window (inclusive, date only).
  final DateTime periodStart;
  final DateTime periodEnd;

  final int sessions;
  final int activeDays;

  /// Distinct ayahs covered by new-memorization sessions in the period.
  final int newAyahs;
  final int reviews;
  final int sessionsWithHints;

  /// Surahs that became fully covered inside the period, in surah order.
  final List<int> completedSurahIds;

  /// Ayahs with at least two failures or weak ratings, newest failure first,
  /// at most [maxNeedsSupport].
  final List<KidsReportAyah> needsSupport;

  static const int maxNeedsSupport = 10;

  bool get isEmpty => sessions == 0;

  @override
  List<Object?> get props => [
    periodStart,
    periodEnd,
    sessions,
    activeDays,
    newAyahs,
    reviews,
    sessionsWithHints,
    completedSurahIds,
    needsSupport,
  ];
}

DateTime _localDay(DateTime value) {
  final at = value.toLocal();
  return DateTime(at.year, at.month, at.day);
}

Iterable<int> _ayahsOf(KidsSessionLog log) => {
  log.ayahNumber,
  ...log.ayahNumbers,
};

/// Pure summary of the last 30 local calendar days, today included.
///
/// Sessions, reviews and hints use the same definitions as the weekly
/// summary (`kidsLogIsReview`, `kidsLogUsedHint`, `kidsLogIsNewMemorization`).
///
/// A surah is "completed in the period" when the canonical reward log that
/// first made its coverage whole (1..count) falls inside the period. A surah
/// completed earlier and merely revisited does not count again.
///
/// An ayah "needs support" when, over the logs of the period, its failures
/// add up to at least two. Each log adds its extra attempts
/// (`attemptCount - 1`) plus one if it was rated weak.
KidsMonthlyReport buildKidsMonthlyReport({
  required List<KidsSessionLog> logs,
  required Map<int, int> ayahCountBySurah,
  required DateTime now,
}) {
  final local = now.toLocal();
  final periodEnd = DateTime(local.year, local.month, local.day);
  final periodStart = DateTime(local.year, local.month, local.day - 29);

  final byId = <String, KidsSessionLog>{};
  for (final log in logs) {
    byId.putIfAbsent(log.id, () => log);
  }
  final unique = byId.values.toList();

  bool inPeriod(DateTime at) {
    final day = _localDay(at);
    return !day.isBefore(periodStart) && !day.isAfter(periodEnd);
  }

  final month = unique.where((l) => inPeriod(l.completedAt)).toList();
  final days = {for (final l in month) _localDay(l.completedAt)};

  final newAyahs = <KidsReportAyah>{
    for (final l in month.where(kidsLogIsNewMemorization))
      for (final a in _ayahsOf(l)) (surahId: l.surahId, ayahNumber: a),
  };

  // Completion moment of each fully covered surah.
  final memorized = kidsMemorizedSurahIds(unique, ayahCountBySurah);
  final canonical =
      unique.where(KidsSessionLogsCloudMerge.isCanonicalRewardLog).toList()
        ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  final covered = <int, Set<int>>{};
  final completedAt = <int, DateTime>{};
  for (final log in canonical) {
    if (!memorized.contains(log.surahId) ||
        completedAt.containsKey(log.surahId)) {
      continue;
    }
    final set = covered.putIfAbsent(log.surahId, () => <int>{})
      ..addAll(_ayahsOf(log));
    final count = ayahCountBySurah[log.surahId]!;
    if (List.generate(count, (i) => i + 1).every(set.contains)) {
      completedAt[log.surahId] = log.completedAt;
    }
  }
  final completed =
      completedAt.entries
          .where((e) => inPeriod(e.value))
          .map((e) => e.key)
          .toList()
        ..sort();

  final failures = <KidsReportAyah, int>{};
  final lastFailure = <KidsReportAyah, DateTime>{};
  for (final log in month) {
    final count =
        (log.attemptCount - 1) +
        (log.masteryRating == PerformanceRating.weak ? 1 : 0);
    if (count <= 0) continue;
    for (final a in _ayahsOf(log)) {
      final key = (surahId: log.surahId, ayahNumber: a);
      failures[key] = (failures[key] ?? 0) + count;
      final prev = lastFailure[key];
      if (prev == null || log.completedAt.isAfter(prev)) {
        lastFailure[key] = log.completedAt;
      }
    }
  }
  final needs =
      failures.entries.where((e) => e.value >= 2).map((e) => e.key).toList()
        ..sort((a, b) {
          final byTime = lastFailure[b]!.compareTo(lastFailure[a]!);
          if (byTime != 0) return byTime;
          final bySurah = a.surahId.compareTo(b.surahId);
          return bySurah != 0 ? bySurah : a.ayahNumber.compareTo(b.ayahNumber);
        });

  return KidsMonthlyReport(
    periodStart: periodStart,
    periodEnd: periodEnd,
    sessions: month.length,
    activeDays: days.length,
    newAyahs: newAyahs.length,
    reviews: month.where(kidsLogIsReview).length,
    sessionsWithHints: month.where(kidsLogUsedHint).length,
    completedSurahIds: completed,
    needsSupport: needs.take(KidsMonthlyReport.maxNeedsSupport).toList(),
  );
}
