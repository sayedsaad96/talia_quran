/// Defines how canonical Mushaf page numbers are arranged in a reader.
///
/// The canonical page number always remains the identifier used for Quran
/// data, audio, reading receipts, and deep links. This policy only maps that
/// identifier to a visual [PageView] index.
enum QuranPageOrderPolicy {
  /// Pages advance in canonical order: 1, 2, ..., 604.
  canonical,

  /// Starts with Al-Fatihah, then presents the remaining Mushaf pages in
  /// reading direction: 1, 604, 603, ..., 2.
  kidsFatihahFirstReverse;

  /// Returns the canonical Mushaf page displayed at [index].
  int canonicalPageForIndex(int index, {int pageCount = 604}) {
    _validateIndex(index, pageCount);
    return switch (this) {
      QuranPageOrderPolicy.canonical => index + 1,
      QuranPageOrderPolicy.kidsFatihahFirstReverse =>
        index == 0 ? 1 : pageCount - index + 1,
    };
  }

  /// Returns the visual [PageView] index for canonical Mushaf [pageNumber].
  int indexForCanonicalPage(int pageNumber, {int pageCount = 604}) {
    _validatePage(pageNumber, pageCount);
    return switch (this) {
      QuranPageOrderPolicy.canonical => pageNumber - 1,
      QuranPageOrderPolicy.kidsFatihahFirstReverse =>
        pageNumber == 1 ? 0 : pageCount - pageNumber + 1,
    };
  }

  static void _validateIndex(int index, int pageCount) {
    if (pageCount < 1 || index < 0 || index >= pageCount) {
      throw RangeError.range(index, 0, pageCount - 1, 'index');
    }
  }

  static void _validatePage(int pageNumber, int pageCount) {
    if (pageCount < 1 || pageNumber < 1 || pageNumber > pageCount) {
      throw RangeError.range(pageNumber, 1, pageCount, 'pageNumber');
    }
  }
}
