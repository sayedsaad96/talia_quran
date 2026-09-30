import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;

import 'mushaf_juz_table.dart';

/// Helper for Hizb and Juz calculations based on the standard
/// 604-page Madinah Mushaf (King Fahd Complex) layout.
abstract class MushafHizbHelper {
  MushafHizbHelper._();

  // ─── Juz Start Pages (Madinah Mushaf) ───────────────────────────────────────
  // Each entry is the first page of the corresponding Juz (1-indexed).
  static const List<int> juzStartPages = MushafJuzTable.startPages;

  // ─── Ordinal Juz Names (Arabic) ──────────────────────────────────────────────
  static const List<String> juzNames = [
    'الأوَّل',
    'الثَّاني',
    'الثَّالث',
    'الرَّابع',
    'الخَامس',
    'السَّادس',
    'السَّابع',
    'الثَّامن',
    'التَّاسع',
    'العَاشر',
    'الحَادي عشر',
    'الثَّاني عشر',
    'الثَّالث عشر',
    'الرَّابع عشر',
    'الخَامس عشر',
    'السَّادس عشر',
    'السَّابع عشر',
    'الثَّامن عشر',
    'التَّاسع عشر',
    'العِشرون',
    'الحَادي والعشرون',
    'الثَّاني والعشرون',
    'الثَّالث والعشرون',
    'الرَّابع والعشرون',
    'الخَامس والعشرون',
    'السَّادس والعشرون',
    'السَّابع والعشرون',
    'الثَّامن والعشرون',
    'التَّاسع والعشرون',
    'الثَّلاثون',
  ];

  // ─── API ─────────────────────────────────────────────────────────────────────

  /// Authentic hizb start pages (1-indexed) resolved lazily from the qcf
  /// package's quarter data — the same source the mushaf header text uses.
  /// Null until resolved; an empty list marks "resolution failed" so the
  /// page-midpoint approximation remains as a fallback.
  static List<int>? _hizbStartPages;

  /// Returns the Juz number (1-30) for a given Mushaf page (1-604).
  static int getJuz(int pageNumber) => MushafJuzTable.juzOf(pageNumber);

  /// First and last Madinah-mushaf page of [juz] (1-30).
  static ({int start, int end}) juzPageRange(int juz) =>
      MushafJuzTable.range(juz);

  /// Returns the Hizb number (1-60) for a given Mushaf page (1-604).
  ///
  /// Hizb boundaries are fixed ayah positions, not page midpoints. The
  /// authentic start pages come from the qcf package quarter table; the
  /// old midpoint approximation is kept only as a fallback if that data
  /// cannot be resolved.
  static int getHizb(int pageNumber) {
    final page = pageNumber.clamp(1, 604);
    final starts = _resolveHizbStartPages();
    if (starts.isNotEmpty) {
      for (int i = starts.length - 1; i >= 0; i--) {
        if (page >= starts[i]) return i + 1;
      }
      return 1;
    }
    return _hizbByMidpoint(page);
  }

  static List<int> _resolveHizbStartPages() {
    final cached = _hizbStartPages;
    if (cached != null) return cached;
    return _hizbStartPages = _computeHizbStartPages();
  }

  static List<int> _computeHizbStartPages() {
    try {
      final quarters = qcf.quarters;
      // Quarters are ordered 1..240 and every hizb starts at its first
      // quarter (indices 0, 4, 8, ...).
      final starts = <int>[];
      for (var i = 0; i + 3 < quarters.length; i += 4) {
        final quarter = quarters[i];
        final page = qcf.getPageNumber(
          quarter['surah'] as int,
          quarter['ayah'] as int,
        );
        if (page >= 1 && page <= 604) starts.add(page);
      }
      // Sanity: the Madani mushaf has exactly 60 hizbs starting at page 1.
      if (starts.length == 60 && starts.first == 1) return starts;
    } catch (_) {}
    return const [];
  }

  static int _hizbByMidpoint(int page) {
    final juz = getJuz(page);
    final juzStart = juzStartPages[juz - 1];
    final juzEnd = juz < 30 ? juzStartPages[juz] - 1 : 604;
    final midpoint = juzStart + (juzEnd - juzStart) ~/ 2;
    return page <= midpoint ? (juz * 2 - 1) : (juz * 2);
  }

  /// Returns the Arabic ordinal name for a Juz number (1-30).
  static String getJuzName(int juz) {
    final idx = juz.clamp(1, 30) - 1;
    return juzNames[idx];
  }

  /// Converts an integer to Eastern Arabic numerals (٠١٢٣٤٥٦٧٨٩).
  static String toArabicNumber(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((c) => digits[int.parse(c)]).join();
  }
}
