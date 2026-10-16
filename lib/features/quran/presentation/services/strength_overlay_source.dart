import '../../../../core/memorization/strength_band.dart';
import '../../../memorization_plus/domain/entities/ayah_review_record.dart';

/// Returns the ayah ranges (inclusive) that a Mushaf page contains.
typedef PageAyahRanges =
    List<({int surah, int start, int end})> Function(int page);

/// Pure per-page strength lookup for the reader overlay. Holds no Flutter or
/// qcf dependency; the page-range provider is injected.
class StrengthOverlaySource {
  StrengthOverlaySource({required PageAyahRanges pageRanges})
    : _pageRanges = pageRanges;

  final PageAyahRanges _pageRanges;
  final Map<String, AyahReviewRecord> _records = {};
  final Map<int, Map<({int surah, int ayah}), StrengthBand>> _pageCache = {};

  static String _key(int surah, int ayah) => '$surah:$ayah';

  void setRecords(Iterable<AyahReviewRecord> adultRecords) {
    _records
      ..clear()
      ..addEntries(
        adultRecords.map((r) => MapEntry(_key(r.surahId, r.ayahNumber), r)),
      );
    _pageCache.clear();
  }

  void clear() {
    _records.clear();
    _pageCache.clear();
  }

  /// Bands for the ayahs of [page]; ayahs with band none are omitted.
  /// Cached per page until [setRecords] or [clear]; [now] only matters for the
  /// first computation after a reset.
  Map<({int surah, int ayah}), StrengthBand> bandsForPage(
    int page,
    DateTime now,
  ) {
    final cached = _pageCache[page];
    if (cached != null) return cached;
    final result = <({int surah, int ayah}), StrengthBand>{};
    if (_records.isNotEmpty) {
      for (final range in _pageRanges(page)) {
        for (var a = range.start; a <= range.end; a++) {
          final band = strengthBandFor(_records[_key(range.surah, a)], now);
          if (band != StrengthBand.none) {
            result[(surah: range.surah, ayah: a)] = band;
          }
        }
      }
    }
    return _pageCache[page] = result;
  }
}
