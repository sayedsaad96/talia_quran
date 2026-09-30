/// Juz page boundaries of the 604-page Madinah mushaf. Pure Dart so domain
/// rules can use it without Flutter.
abstract final class MushafJuzTable {
  /// First page of each juz (1-indexed by juz).
  // dart format off
  static const List<int> startPages = [
    1, 22, 42, 62, 82, 102, 121, 142, 162, 182, // Juz  1–10
    201, 222, 242, 262, 282, 302, 322, 342, 362, 382, // Juz 11–20
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582, // Juz 21–30
  ];
  // dart format on

  /// Juz (1-30) containing [page] (1-604).
  static int juzOf(int page) {
    final clamped = page.clamp(1, 604);
    for (var i = startPages.length - 1; i >= 0; i--) {
      if (clamped >= startPages[i]) return i + 1;
    }
    return 1;
  }

  /// First and last page of [juz] (1-30).
  static ({int start, int end}) range(int juz) {
    final index = juz.clamp(1, 30) - 1;
    final end = index == startPages.length - 1
        ? 604
        : startPages[index + 1] - 1;
    return (start: startPages[index], end: end);
  }
}
