/// Helper for Hizb and Juz calculations based on the standard
/// 604-page Madinah Mushaf (King Fahd Complex) layout.
abstract class MushafHizbHelper {
  MushafHizbHelper._();

  // ─── Juz Start Pages (Madinah Mushaf) ───────────────────────────────────────
  // Each entry is the first page of the corresponding Juz (1-indexed).
  static const List<int> juzStartPages = [
    1,   22,  42,  62,  82,  102, 121, 142, 162, 182, // Juz  1–10
    201, 222, 242, 262, 282, 302, 322, 342, 362, 382, // Juz 11–20
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582, // Juz 21–30
  ];

  // ─── Ordinal Juz Names (Arabic) ──────────────────────────────────────────────
  static const List<String> juzNames = [
    'الأوَّل',   'الثَّاني',   'الثَّالث',   'الرَّابع',   'الخَامس',
    'السَّادس',  'السَّابع',   'الثَّامن',   'التَّاسع',   'العَاشر',
    'الحَادي عشر','الثَّاني عشر','الثَّالث عشر','الرَّابع عشر','الخَامس عشر',
    'السَّادس عشر','السَّابع عشر','الثَّامن عشر','التَّاسع عشر','العِشرون',
    'الحَادي والعشرون','الثَّاني والعشرون','الثَّالث والعشرون',
    'الرَّابع والعشرون','الخَامس والعشرون','السَّادس والعشرون',
    'السَّابع والعشرون','الثَّامن والعشرون','التَّاسع والعشرون','الثَّلاثون',
  ];

  // ─── API ─────────────────────────────────────────────────────────────────────

  /// Returns the Juz number (1-30) for a given Mushaf page (1-604).
  static int getJuz(int pageNumber) {
    final page = pageNumber.clamp(1, 604);
    for (int i = 28; i >= 0; i--) {
      if (page >= juzStartPages[i]) return i + 1;
    }
    return 1;
  }

  /// Returns the Hizb number (1-60) for a given Mushaf page (1-604).
  ///
  /// Each Juz contains 2 Hizbs. The midpoint of a Juz separates Hizb n from n+1.
  static int getHizb(int pageNumber) {
    final page = pageNumber.clamp(1, 604);
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
    return number
        .toString()
        .split('')
        .map((c) => digits[int.parse(c)])
        .join();
  }
}
