import 'quran_entities.dart';

/// Presentation-ready metadata for one Juz (1-30), derived from real Quran
/// data instead of hardcoded display strings.
///
/// The page boundaries are the standard Madinah Mushaf page numbers (the same
/// source previously hardcoded inside `JuzGridView`). The surah range is
/// computed from the loaded [Surah] list: a surah overlaps a juz when its
/// page span `[startPage, endPage]` intersects the juz page span, where a
/// surah's end page is the next surah's start page minus one (604 for the
/// last surah).
class JuzSummary {
  const JuzSummary({
    required this.juzNumber,
    required this.startPage,
    required this.endPage,
    required this.surahs,
  });

  final int juzNumber;
  final int startPage;
  final int endPage;
  final List<Surah> surahs;

  bool get hasRange => surahs.isNotEmpty;
  Surah get firstSurah => surahs.first;
  Surah get lastSurah => surahs.last;
  bool get isSingleSurah =>
      surahs.length == 1 || firstSurah.id == lastSurah.id;
}

/// Builds [JuzSummary] lists outside widget rebuild paths so both the Quran
/// list Juz tab and the reader Quick Navigation sheet can share them.
abstract class JuzSummaries {
  /// Standard Madinah Mushaf Juz start pages (1-indexed, 30 entries).
  static const List<int> startPages = [
    1,
    22,
    42,
    62,
    82,
    102,
    121,
    142,
    162,
    182,
    201,
    222,
    242,
    262,
    282,
    302,
    322,
    342,
    362,
    382,
    402,
    422,
    442,
    462,
    482,
    502,
    522,
    542,
    562,
    582,
  ];

  static const int totalPages = 604;
  static const int totalJuz = 30;

  static List<JuzSummary> fromSurahs(List<Surah> surahs) {
    if (surahs.isEmpty) return const [];
    final sorted = [...surahs]..sort((a, b) => a.id.compareTo(b.id));

    // Surah page spans derived from consecutive start pages.
    final spans = <int, ({int start, int end})>{};
    for (var i = 0; i < sorted.length; i++) {
      final start = sorted[i].page;
      final end = i + 1 < sorted.length
          ? sorted[i + 1].page - 1
          : totalPages;
      spans[sorted[i].id] = (start: start, end: end);
    }

    final summaries = <JuzSummary>[];
    for (var juz = 1; juz <= totalJuz; juz++) {
      final juzStart = startPages[juz - 1];
      final juzEnd = juz < totalJuz ? startPages[juz] - 1 : totalPages;
      final overlapping = sorted.where((surah) {
        final span = spans[surah.id]!;
        return span.start <= juzEnd && span.end >= juzStart;
      }).toList();
      summaries.add(
        JuzSummary(
          juzNumber: juz,
          startPage: juzStart,
          endPage: juzEnd,
          surahs: overlapping,
        ),
      );
    }
    return summaries;
  }
}
