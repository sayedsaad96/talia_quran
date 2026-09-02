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
    return start.add(Duration(days: days));
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
