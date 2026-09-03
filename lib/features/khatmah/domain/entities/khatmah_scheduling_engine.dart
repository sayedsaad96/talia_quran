import 'dart:math';

class KhatmahSchedulingEngine {
  const KhatmahSchedulingEngine._();

  static const totalPages = 604;

  static int calculateDaysFromPages(int remainingPages, int pagesPerDay) {
    if (pagesPerDay <= 0) return remainingPages;
    return (remainingPages / pagesPerDay).ceil();
  }

  static int calculatePagesFromDays(int remainingPages, int targetDays) {
    if (targetDays <= 0) return remainingPages;
    return (remainingPages / targetDays).ceil();
  }

  static DateTime calculateEndDate(DateTime start, int days) {
    final local = start.toLocal();
    return DateTime(local.year, local.month, local.day + max(0, days - 1));
  }

  static DateTime localDate(DateTime instant) {
    final local = instant.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Calendar dates, not elapsed 24-hour periods (which vary at DST changes).
  static int elapsedCalendarDays(DateTime start, DateTime end) {
    final first = start.toLocal();
    final last = end.toLocal();
    return max(
      1,
      DateTime.utc(last.year, last.month, last.day)
              .difference(DateTime.utc(first.year, first.month, first.day))
              .inDays +
          1,
    );
  }

  static ({int startPage, int endPage}) todaysWird(
    int currentPage,
    int targetPagesPerDay,
  ) {
    final startPage = min(currentPage + 1, totalPages);
    final endPage = min(
      max(startPage, startPage + targetPagesPerDay - 1),
      totalPages,
    );
    return (startPage: startPage, endPage: endPage);
  }

  static DateTime recalculateAfterResume(
    int remainingPages,
    int pagesPerDay, [
    DateTime? fromDate,
  ]) {
    final days = calculateDaysFromPages(remainingPages, pagesPerDay);
    return calculateEndDate(fromDate ?? DateTime.now(), days);
  }
}
