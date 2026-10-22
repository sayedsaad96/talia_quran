import '../constants/surah_names.dart';
import '../memorization/retention_forecast.dart';
import '../memorization/review_record_filters.dart';
import '../../features/memorization_plus/domain/entities/ayah_review_record.dart';
import '../../features/quran/domain/entities/quran_entities.dart';

/// An ID-only, same-surah passage selected for an optional prayer review.
///
/// It intentionally carries no Quran text, owner, prayer, or persistence
/// metadata. A later application-layer selection freezes those concerns.
final class PrayerReviewPassage {
  const PrayerReviewPassage({
    required this.surahId,
    required this.startAyah,
    required this.endAyah,
  }) : assert(surahId > 0),
       assert(startAyah > 0),
       assert(endAyah >= startAyah);

  final int surahId;
  final int startAyah;
  final int endAyah;

  @override
  bool operator ==(Object other) {
    return other is PrayerReviewPassage &&
        other.surahId == surahId &&
        other.startAyah == startAyah &&
        other.endAyah == endAyah;
  }

  @override
  int get hashCode => Object.hash(surahId, startAyah, endAyah);
}

/// Pure, deterministic selector for a standalone adult prayer-review passage.
///
/// The caller supplies canonical [Ayah] metadata. Invalid references,
/// duplicate IDs, or incomplete canonical data return `null` rather than
/// attempting to infer an ayah relationship.
abstract final class PrayerReviewPicker {
  static const validLengths = {3, 7, 15};

  static PrayerReviewPassage? pick({
    required List<AyahReviewRecord> records,
    required Iterable<Ayah> canonicalAyahs,
    required DateTime now,
    required int maxAyahs,
    Set<PrayerReviewPassage> excludedPassages = const {},
  }) {
    if (!validLengths.contains(maxAyahs)) {
      return null;
    }
    final canonical = _canonicalById(canonicalAyahs);
    if (canonical == null || !_recordsAreValid(records, canonical)) {
      return null;
    }
    final candidates = _eligible(records, now)..sort(_compareCandidates);
    for (final candidate in candidates) {
      final passage = _extend(
        candidate.record,
        candidates,
        canonical,
        maxAyahs,
      );
      if (passage != null && !excludedPassages.contains(passage)) {
        return passage;
      }
    }
    return null;
  }

  static Map<_AyahId, Ayah>? _canonicalById(Iterable<Ayah> ayahs) {
    final result = <_AyahId, Ayah>{};
    final globalNumbers = <int>{};
    for (final ayah in ayahs) {
      final id = _AyahId(ayah.surahId, ayah.numberInSurah);
      if (!_isCanonicalId(id) ||
          ayah.number <= 0 ||
          !globalNumbers.add(ayah.number) ||
          result.containsKey(id)) {
        return null;
      }
      result[id] = ayah;
    }
    return result;
  }

  static bool _recordsAreValid(
    List<AyahReviewRecord> records,
    Map<_AyahId, Ayah> canonical,
  ) {
    final seen = <_AyahId>{};
    for (final record in records) {
      final id = _AyahId(record.surahId, record.ayahNumber);
      if (!_isCanonicalId(id) || !seen.add(id) || !canonical.containsKey(id)) {
        return false;
      }
    }
    return true;
  }

  static bool _isCanonicalId(_AyahId id) {
    return id.surahId > 0 &&
        id.ayahNumber > 0 &&
        id.ayahNumber <= SurahNames.ayahCount(id.surahId);
  }

  static List<_Candidate> _eligible(
    List<AyahReviewRecord> records,
    DateTime now,
  ) {
    return [
      for (final record in records)
        if (ReviewRecordFilters.isAdultCompatible(record) &&
            record.classifyAt(now).isMemorized)
          _Candidate(record, retrievabilityAt(record, now)),
    ];
  }

  static int _compareCandidates(_Candidate a, _Candidate b) {
    final due = a.record.nextReviewDate.compareTo(b.record.nextReviewDate);
    if (due != 0) {
      return due;
    }
    final retrievability = _compareRetrievability(a, b);
    if (retrievability != 0) {
      return retrievability;
    }
    final reviewed = a.record.lastReviewedAt.compareTo(b.record.lastReviewedAt);
    if (reviewed != 0) {
      return reviewed;
    }
    final surah = a.record.surahId.compareTo(b.record.surahId);
    return surah != 0
        ? surah
        : a.record.ayahNumber.compareTo(b.record.ayahNumber);
  }

  static int _compareRetrievability(_Candidate a, _Candidate b) {
    final aKnown = a.retrievability.isFinite;
    final bKnown = b.retrievability.isFinite;
    if (aKnown && bKnown) {
      return a.retrievability.compareTo(b.retrievability);
    }
    if (aKnown != bKnown) {
      return aKnown ? -1 : 1;
    }
    return 0;
  }

  static PrayerReviewPassage? _extend(
    AyahReviewRecord start,
    List<_Candidate> candidates,
    Map<_AyahId, Ayah> canonical,
    int maxAyahs,
  ) {
    final eligible = {for (final candidate in candidates) candidate.id};
    final first = _AyahId(start.surahId, start.ayahNumber);
    if (!eligible.contains(first) || !canonical.containsKey(first)) {
      return null;
    }
    var end = first.ayahNumber;
    while (end - first.ayahNumber + 1 < maxAyahs) {
      final next = _AyahId(first.surahId, end + 1);
      if (!eligible.contains(next) || !canonical.containsKey(next)) {
        break;
      }
      end++;
    }
    return PrayerReviewPassage(
      surahId: first.surahId,
      startAyah: first.ayahNumber,
      endAyah: end,
    );
  }
}

final class _Candidate {
  const _Candidate(this.record, this.retrievability);

  final AyahReviewRecord record;
  final double retrievability;

  _AyahId get id => _AyahId(record.surahId, record.ayahNumber);
}

final class _AyahId {
  const _AyahId(this.surahId, this.ayahNumber);

  final int surahId;
  final int ayahNumber;

  @override
  bool operator ==(Object other) {
    return other is _AyahId &&
        other.surahId == surahId &&
        other.ayahNumber == ayahNumber;
  }

  @override
  int get hashCode => Object.hash(surahId, ayahNumber);
}
