import '../../../../core/memorization/strength_band.dart';
import '../../../memorization_plus/domain/entities/ayah_review_record.dart';

/// Returns the ayah ranges (inclusive) that a Mushaf page contains.
typedef PageAyahRanges =
    List<({int surah, int start, int end})> Function(int page);

/// Pure per-page strength lookup for the reader overlay. Holds no Flutter or
/// qcf dependency; the page-range provider is injected.
class StrengthOverlaySource {
  StrengthOverlaySource({required this._pageRanges});

  final PageAyahRanges _pageRanges;
  final Map<String, AyahReviewRecord> _records = {};
  final Map<int, Map<({int surah, int ayah}), StrengthBand>> _pageCache = {};

  /// When each cached page may change on its own: the earliest upcoming
  /// review date on it, capped at the next local midnight.
  final Map<int, DateTime> _validUntil = {};

  static String _key(int surah, int ayah) => '$surah:$ayah';

  void setRecords(Iterable<AyahReviewRecord> adultRecords) {
    _records
      ..clear()
      ..addEntries(
        adultRecords.map((r) => MapEntry(_key(r.surahId, r.ayahNumber), r)),
      );
    _pageCache.clear();
    _validUntil.clear();
  }

  void clear() {
    _records.clear();
    _pageCache.clear();
    _validUntil.clear();
  }

  /// Bands for the ayahs of [page]; ayahs with band none are omitted.
  /// Cached per page until [setRecords] or [clear], or until an ayah on the
  /// page may have become due (a reader left open past a due time).
  Map<({int surah, int ayah}), StrengthBand> bandsForPage(
    int page,
    DateTime now,
  ) {
    final cached = _pageCache[page];
    final until = _validUntil[page];
    if (cached != null && until != null && now.isBefore(until)) return cached;
    final result = <({int surah, int ayah}), StrengthBand>{};
    var validUntil = DateTime(now.year, now.month, now.day + 1);
    if (_records.isNotEmpty) {
      for (final range in _pageRanges(page)) {
        for (var a = range.start; a <= range.end; a++) {
          final record = _records[_key(range.surah, a)];
          final band = strengthBandFor(record, now);
          if (band != StrengthBand.none) {
            result[(surah: range.surah, ayah: a)] = band;
          }
          final next = record?.nextReviewDate;
          if (next != null && next.isAfter(now) && next.isBefore(validUntil)) {
            validUntil = next;
          }
        }
      }
    }
    _validUntil[page] = validUntil;
    return _pageCache[page] = result;
  }
}
