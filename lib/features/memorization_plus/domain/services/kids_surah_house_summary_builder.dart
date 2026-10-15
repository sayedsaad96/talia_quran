import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../../../core/memorization/kids_progress_cloud_merge.dart';
import '../../../../core/memorization/review_record_filters.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../entities/kids_journey_path_definition.dart';
import '../entities/memorization_entities.dart';
import 'kids_due_review_policy.dart';
import 'kids_house_review_policy.dart';

enum KidsSurahHouseStatus { notStarted, inProgress, needsReview, completed }

/// One surah house on the Quran journey map.
final class KidsSurahHouse extends Equatable {
  const KidsSurahHouse({
    required this.surahId,
    required this.ayahCount,
    required this.juz,
    required this.status,
    required this.completedCount,
  });

  final int surahId;
  final int ayahCount;
  final int juz;
  final KidsSurahHouseStatus status;
  final int completedCount;

  double get progress => ayahCount <= 0 ? 0 : completedCount / ayahCount;

  @override
  List<Object?> get props => [surahId, ayahCount, juz, status, completedCount];
}

/// Builds one [KidsSurahHouse] per surah of [path], in path order.
///
/// Mirrors the per-surah rules of `getKidsJourney` (the journey page is the
/// source of truth): completion comes from canonical reward logs by
/// `log.ayahNumber` only (`kidsMemorizedSurahIds` also adds `log.ayahNumbers`;
/// that set is for region unlocking, not house status), a finished stage is
/// `needsReview` on a pending house review or a due kids record inside that
/// stage, and the stage size follows the whole-set precedence rule.
///
/// [kidsRecords] must already be kids records (`ReviewRecordFilters
/// .isKidsSource`); the caller filters. Surahs missing from [surahs] are
/// skipped.
List<KidsSurahHouse> buildKidsSurahHouses({
  required KidsJourneyPathDefinition path,
  required List<Surah> surahs,
  required List<KidsSessionLog> logs,
  required List<AyahReviewRecord> kidsRecords,
  required Map<int, int> frozenSizes,
  required Set<int> wholeSurahIds,
  required int defaultStageSize,
  required DateTime now,
}) {
  final surahById = {for (final s in surahs) s.id: s};
  final completedBySurah = <int, Set<int>>{};
  final logsBySurah = <int, List<KidsSessionLog>>{};
  for (final log in logs) {
    logsBySurah.putIfAbsent(log.surahId, () => []).add(log);
    if (KidsSessionLogsCloudMerge.isCanonicalRewardLog(log)) {
      completedBySurah.putIfAbsent(log.surahId, () => {}).add(log.ayahNumber);
    }
  }
  final recordsBySurah = <int, Map<int, AyahReviewRecord>>{};
  for (final record in kidsRecords) {
    if (!ReviewRecordFilters.isKidsSource(record)) continue;
    recordsBySurah.putIfAbsent(record.surahId, () => {})[record.ayahNumber] =
        record;
  }

  final houses = <KidsSurahHouse>[];
  for (final id in path.surahIds) {
    final surah = surahById[id];
    if (surah == null || surah.ayahCount < 1) continue;
    final total = surah.ayahCount;
    final completed = (completedBySurah[id] ?? const <int>{})
        .where((a) => a >= 1 && a <= total)
        .toSet();
    final surahLogs = logsBySurah[id] ?? const <KidsSessionLog>[];
    final records = recordsBySurah[id] ?? const <int, AyahReviewRecord>{};

    final stageSize = _stageSize(
      surah: surah,
      frozenSizes: frozenSizes,
      wholeSurahIds: wholeSurahIds,
      defaultStageSize: defaultStageSize,
    );
    var needsReview = false;
    for (var start = 1; start <= total && !needsReview; start += stageSize) {
      final end = min(start + stageSize - 1, total);
      final range = [for (var a = start; a <= end; a++) a];
      if (!range.every(completed.contains)) continue;
      if (KidsHouseReviewPolicy.pendingAyahs(surahLogs, id, range).isNotEmpty) {
        needsReview = true;
      } else {
        needsReview = range.any((a) {
          final record = records[a];
          return record != null && KidsDueReviewPolicy.isDue(record, now);
        });
      }
    }

    final status = needsReview
        ? KidsSurahHouseStatus.needsReview
        : completed.length == total
        ? KidsSurahHouseStatus.completed
        : completed.isNotEmpty
        ? KidsSurahHouseStatus.inProgress
        : KidsSurahHouseStatus.notStarted;
    houses.add(
      KidsSurahHouse(
        surahId: id,
        ayahCount: total,
        juz: surah.juz,
        status: status,
        completedCount: completed.length,
      ),
    );
  }
  return houses;
}

int _stageSize({
  required Surah surah,
  required Map<int, int> frozenSizes,
  required Set<int> wholeSurahIds,
  required int defaultStageSize,
}) {
  if (wholeSurahIds.contains(surah.id) &&
      surah.ayahCount <= kKidsWholeSurahMaxAyahsLimit) {
    return surah.ayahCount;
  }
  final size =
      sanitizeKidsAyahsPerHouse(frozenSizes[surah.id]) ??
      sanitizeKidsAyahsPerHouse(defaultStageSize) ??
      1;
  return max(1, size);
}

/// The house the map opens on: the surah of the most recent canonical reward
/// log if it is not completed; otherwise the next non-completed house after
/// it in path order (falling back to the first non-completed house, then the
/// first house); with no such logs, the first house of the path.
int currentKidsSurahHouse(
  List<KidsSurahHouse> houses,
  List<KidsSessionLog> logs,
) {
  if (houses.isEmpty) return KidsJourneyPath.surahIds.first;
  final inPath = {for (final h in houses) h.surahId};
  KidsSessionLog? last;
  for (final log in logs) {
    if (!KidsSessionLogsCloudMerge.isCanonicalRewardLog(log) ||
        !inPath.contains(log.surahId)) {
      continue;
    }
    if (last == null || log.completedAt.isAfter(last.completedAt)) last = log;
  }
  if (last == null) return houses.first.surahId;
  final index = houses.indexWhere((h) => h.surahId == last!.surahId);
  if (houses[index].status != KidsSurahHouseStatus.completed) {
    return houses[index].surahId;
  }
  for (var i = index + 1; i < houses.length; i++) {
    if (houses[i].status != KidsSurahHouseStatus.completed) {
      return houses[i].surahId;
    }
  }
  for (final h in houses) {
    if (h.status != KidsSurahHouseStatus.completed) return h.surahId;
  }
  return houses.first.surahId;
}
