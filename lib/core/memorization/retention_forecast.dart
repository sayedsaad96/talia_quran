import 'dart:math' as math;

import '../../features/memorization_plus/domain/entities/ayah_review_record.dart';
import '../../features/quran/domain/entities/quran_entities.dart';
import 'review_passage_picker.dart';

/// A read-only review passage predicted to weaken before the selected horizon.
final class ForecastPassage {
  const ForecastPassage({
    required this.surahId,
    required this.startAyah,
    required this.endAyah,
    required this.weakensBy,
  });

  final int surahId;
  final int startAyah;
  final int endAyah;
  final DateTime weakensBy;
}

/// Returns the FSRS retrievability at [at].
///
/// A non-positive stability has no FSRS prediction, so [double.nan] marks the
/// value for callers that must use the scheduler fallback instead.
double retrievabilityAt(
  AyahReviewRecord record,
  DateTime at, {
  int? elapsedDaysOverride,
}) {
  if (record.stability <= 0 || !record.stability.isFinite) return double.nan;
  final elapsedDays =
      elapsedDaysOverride?.toDouble() ??
      at.toUtc().difference(record.lastReviewedAt.toUtc()).inMicroseconds /
          Duration.microsecondsPerDay;
  return math.exp(-elapsedDays / math.max(record.stability, 1));
}

/// Finds reviewed adult ayahs which will fall below 80% recall in [horizon].
///
/// [ayahsBySurah] is canonical Quran metadata from the repository. Invalid or
/// incomplete metadata is deliberately skipped: forecast grouping must never
/// invent ayah or page relationships.
List<ForecastPassage> weakeningSoon(
  List<AyahReviewRecord> adultRecords,
  DateTime now, {
  Duration horizon = const Duration(days: 7),
  required Map<int, List<Ayah>> ayahsBySurah,
}) {
  if (horizon.isNegative) {
    throw ArgumentError.value(horizon, 'horizon', 'must not be negative');
  }
  final candidates = _forecastCandidates(adultRecords, now, horizon);
  final passages = <ForecastPassage>[];
  for (final entry in _groupCandidatesBySurah(candidates).entries) {
    passages.addAll(_passagesForSurah(entry, ayahsBySurah));
  }
  passages.sort(_comparePassages);
  return passages.take(3).toList(growable: false);
}

List<_ForecastCandidate> _forecastCandidates(
  List<AyahReviewRecord> records,
  DateTime now,
  Duration horizon,
) {
  final horizonAt = now.add(horizon);
  final candidates = <_ForecastCandidate>[];
  for (final record in records) {
    if (record.totalReviews <= 0 || !record.nextReviewDate.isAfter(now)) {
      continue;
    }
    final stability = record.stability;
    if (!stability.isFinite) continue;
    if (stability > 0) {
      final atHorizon = retrievabilityAt(record, horizonAt);
      if (!(atHorizon < .8)) continue;
      final weakensAt = record.lastReviewedAt.toUtc().add(
        Duration(
          microseconds:
              (-math.log(.8) *
                      math.max(stability, 1) *
                      Duration.microsecondsPerDay)
                  .round(),
        ),
      );
      candidates.add(
        _ForecastCandidate(record, weakensAt.isAfter(now) ? weakensAt : now),
      );
    } else if (!record.nextReviewDate.isAfter(horizonAt)) {
      candidates.add(_ForecastCandidate(record, record.nextReviewDate));
    }
  }
  return candidates;
}

Map<int, List<_ForecastCandidate>> _groupCandidatesBySurah(
  List<_ForecastCandidate> candidates,
) {
  final bySurah = <int, List<_ForecastCandidate>>{};
  for (final candidate in candidates) {
    bySurah.putIfAbsent(candidate.record.surahId, () => []).add(candidate);
  }
  return bySurah;
}

List<ForecastPassage> _passagesForSurah(
  MapEntry<int, List<_ForecastCandidate>> entry,
  Map<int, List<Ayah>> ayahsBySurah,
) {
  final canonical = _validatedCanonicalAyahs(entry.key, ayahsBySurah);
  if (canonical.isEmpty) return const [];
  final known = {for (final ayah in canonical) ayah.numberInSurah};
  final remaining = <int, _ForecastCandidate>{
    for (final candidate in entry.value)
      if (known.contains(candidate.record.ayahNumber))
        candidate.record.ayahNumber: candidate,
  };
  final passages = <ForecastPassage>[];
  while (remaining.isNotEmpty) {
    final start = remaining.keys.reduce((a, b) => a < b ? a : b);
    final picked = ReviewPassagePicker.pick(
      surahAyahs: canonical,
      startAyah: start,
      dueAyahNumbers: remaining.keys.toSet(),
    );
    if (picked.isEmpty) {
      remaining.remove(start);
      continue;
    }
    passages.add(_passageFromPicked(entry.key, picked, remaining));
    for (final ayah in picked) {
      remaining.remove(ayah.numberInSurah);
    }
  }
  return passages;
}

ForecastPassage _passageFromPicked(
  int surahId,
  List<Ayah> picked,
  Map<int, _ForecastCandidate> candidates,
) {
  final weakensBy = picked
      .map((ayah) => candidates[ayah.numberInSurah]!.weakensBy)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  return ForecastPassage(
    surahId: surahId,
    startAyah: picked.first.numberInSurah,
    endAyah: picked.last.numberInSurah,
    weakensBy: weakensBy,
  );
}

int _comparePassages(ForecastPassage a, ForecastPassage b) {
  final byTime = a.weakensBy.compareTo(b.weakensBy);
  if (byTime != 0) return byTime;
  final bySurah = a.surahId.compareTo(b.surahId);
  return bySurah != 0 ? bySurah : a.startAyah.compareTo(b.startAyah);
}

List<Ayah> _validatedCanonicalAyahs(
  int surahId,
  Map<int, List<Ayah>> ayahsBySurah,
) {
  final ayahs = ayahsBySurah[surahId];
  if (ayahs == null || ayahs.isEmpty) return const [];
  final sorted = [...ayahs]
    ..sort((a, b) => a.numberInSurah.compareTo(b.numberInSurah));
  var expected = 1;
  for (final ayah in sorted) {
    if (ayah.surahId != surahId ||
        ayah.numberInSurah != expected ||
        ayah.page == null ||
        ayah.page! <= 0) {
      return const [];
    }
    expected++;
  }
  return sorted;
}

final class _ForecastCandidate {
  const _ForecastCandidate(this.record, this.weakensBy);

  final AyahReviewRecord record;
  final DateTime weakensBy;
}
