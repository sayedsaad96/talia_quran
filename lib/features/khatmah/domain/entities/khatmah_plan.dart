import 'package:equatable/equatable.dart';

import 'khatmah_dedication.dart';
import 'khatmah_scheduling_engine.dart';
import '../../../../core/utils/mushaf_juz_table.dart';

enum KhatmahStatus { active, paused, completed }

enum QuranReaderMode { free, khatmah }

/// How a day's wird is measured: a page count, or one juz a day (Ramadan).
enum KhatmahWirdUnit { pages, juz }

class KhatmahPlan extends Equatable {
  /// Stable storage value for a system-created plan without a recipient title.
  /// Presentation localizes this value at display time, so changing the app
  /// language never leaves the default title in the language of its creation.
  static const defaultTitle = 'Khatmah';

  /// Plan title derived from a dedication: the recipient's name, else the
  /// stable default that presentation localizes.
  static String titleFor(KhatmahDedication dedication) {
    final name = dedication.recipientName?.trim();
    return dedication.isDedicated && name != null && name.isNotEmpty
        ? name
        : defaultTitle;
  }

  KhatmahPlan({
    required this.id,
    required this.title,
    this.startPage = 1,
    Iterable<int>? completedPages,
    required this.targetPagesPerDay,
    required this.targetDays,
    required this.startDate,
    required this.expectedEndDate,
    this.status = KhatmahStatus.active,
    this.dedication = const KhatmahDedication(),
    this.lastReadDate,
    this.dailyTargetDate,
    this.dailyTargetStartPage,
    this.dailyTargetEndPage,
    this.pausedAt,
    this.authority,
    this.wirdUnit = KhatmahWirdUnit.pages,
  }) : completedPages = Set.unmodifiable(
         _normalizeCompletedPages(completedPages ?? const <int>{}),
       ),
       currentPage = _lastContiguousPage(
         _normalizeCompletedPages(completedPages ?? const <int>{}),
         startPage,
       );

  final String id;
  final String title;
  final int startPage;
  final int currentPage;
  final Set<int> completedPages;
  final int targetPagesPerDay;
  final int targetDays;
  final DateTime startDate;
  final DateTime expectedEndDate;
  final KhatmahStatus status;
  final KhatmahDedication dedication;
  final DateTime? lastReadDate;
  final DateTime? dailyTargetDate;
  final int? dailyTargetStartPage;
  final int? dailyTargetEndPage;
  final DateTime? pausedAt;
  final KhatmahWirdUnit wirdUnit;

  /// Runtime-only authority of the load; never serialized or shared.
  final Object? authority;

  int get completedPagesCount => completedPages.length;

  double get progressPercentage =>
      completedPagesCount / KhatmahSchedulingEngine.totalPages;

  int get remainingPages =>
      KhatmahSchedulingEngine.totalPages - completedPagesCount;

  /// First unread page in reading order: from [startPage] to 604, then
  /// wrapping to page 1 (a khatmah may begin anywhere in the mushaf).
  int get nextUnreadPage {
    for (final page in readingOrder(startPage)) {
      if (!completedPages.contains(page)) return page;
    }
    return KhatmahSchedulingEngine.totalPages + 1;
  }

  /// Every page once, starting at [startPage] and wrapping after page 604.
  static Iterable<int> readingOrder(int startPage) sync* {
    const total = KhatmahSchedulingEngine.totalPages;
    final first = startPage.clamp(1, total);
    for (var offset = 0; offset < total; offset++) {
      yield (first - 1 + offset) % total + 1;
    }
  }

  /// Position of [page] in the reading order that begins at [startPage].
  static int readingIndex(int page, int startPage) {
    const total = KhatmahSchedulingEngine.totalPages;
    final first = startPage.clamp(1, total);
    return (page - first + total) % total;
  }

  /// Pages from [nextUnreadPage] through [page] in reading order (wrapping
  /// after 604). Empty when [page] was already passed or is out of range.
  Iterable<int> pagesThrough(int page) sync* {
    const total = KhatmahSchedulingEngine.totalPages;
    final next = nextUnreadPage;
    if (next > total || page < 1 || page > total) return;
    final from = readingIndex(next, startPage);
    final to = readingIndex(page, startPage);
    if (to < from) return;
    final first = startPage.clamp(1, total);
    for (var index = from; index <= to; index++) {
      yield (first - 1 + index) % total + 1;
    }
  }

  bool get isComplete =>
      completedPagesCount == KhatmahSchedulingEngine.totalPages;

  /// Without an anchor, legacy coverage cannot identify earlier daily activity.
  ({int startPage, int endPage}) dailyTargetFor(DateTime date) {
    final start = dailyTargetStartPage;
    final end = dailyTargetEndPage;
    if (dailyTargetDate != null &&
        KhatmahSchedulingEngine.localDate(dailyTargetDate!) ==
            KhatmahSchedulingEngine.localDate(date) &&
        start != null &&
        end != null &&
        start >= 1 &&
        end >= start &&
        end <= KhatmahSchedulingEngine.totalPages) {
      return (startPage: start, endPage: end);
    }
    if (wirdUnit == KhatmahWirdUnit.juz) {
      final first = nextUnreadPage.clamp(1, KhatmahSchedulingEngine.totalPages);
      return (
        startPage: first,
        endPage: MushafJuzTable.range(MushafJuzTable.juzOf(first)).end,
      );
    }
    return KhatmahSchedulingEngine.todaysWird(
      nextUnreadPage - 1,
      targetPagesPerDay,
    );
  }

  int dailyCompletedPages(DateTime date) {
    final target = dailyTargetFor(date);
    return completedPages
        .where((page) => page >= target.startPage && page <= target.endPage)
        .length;
  }

  bool isDailyTargetComplete(DateTime date) {
    final target = dailyTargetFor(date);
    return dailyCompletedPages(date) == target.endPage - target.startPage + 1;
  }

  /// Pages the learner is behind the planned finish date at the current
  /// daily pace; 0 when on schedule. Counts [today] and the end date.
  int pagesBehind(DateTime today) {
    final start = KhatmahSchedulingEngine.localDate(today);
    final end = KhatmahSchedulingEngine.localDate(expectedEndDate);
    final daysLeft = end.isBefore(start)
        ? 0
        : KhatmahSchedulingEngine.elapsedCalendarDays(start, end);
    final capacity = _capacityPages(daysLeft);
    final behind = remainingPages - capacity;
    return behind > 0 ? behind : 0;
  }

  /// Juz (1–30) that still hold an unread page.
  int get remainingJuzCount => {
    for (var page = 1; page <= KhatmahSchedulingEngine.totalPages; page++)
      if (!completedPages.contains(page)) MushafJuzTable.juzOf(page),
  }.length;

  /// Wird days needed for the remaining pages at the plan's pace.
  int get remainingWirdDays => wirdUnit == KhatmahWirdUnit.juz
      ? remainingJuzCount
      : KhatmahSchedulingEngine.calculateDaysFromPages(
          remainingPages,
          targetPagesPerDay,
        );

  /// Pages the plan covers in [days] wird days from the next unread page.
  int _capacityPages(int days) {
    if (wirdUnit == KhatmahWirdUnit.pages) return days * targetPagesPerDay;
    final unreadByJuz = <int, int>{};
    for (final page in readingOrder(startPage)) {
      if (completedPages.contains(page)) continue;
      final juz = MushafJuzTable.juzOf(page);
      unreadByJuz[juz] = (unreadByJuz[juz] ?? 0) + 1;
    }
    return unreadByJuz.values.take(days).fold(0, (sum, pages) => sum + pages);
  }

  /// Finish date if the learner keeps the plan's pace from the next wird day.
  DateTime projectedEndDate(DateTime today) {
    final first = KhatmahSchedulingEngine.localDate(today);
    final start = isDailyTargetComplete(today)
        ? DateTime(first.year, first.month, first.day + 1)
        : first;
    return KhatmahSchedulingEngine.calculateEndDate(start, remainingWirdDays);
  }

  /// Whole days the projection beats the planned finish date; 0 otherwise.
  int daysAhead(DateTime today) {
    final planned = KhatmahSchedulingEngine.localDate(expectedEndDate);
    final projected = projectedEndDate(today);
    final diff = DateTime.utc(planned.year, planned.month, planned.day)
        .difference(
          DateTime.utc(projected.year, projected.month, projected.day),
        )
        .inDays;
    return diff > 0 ? diff : 0;
  }

  /// Pages read out of the pages in [juz].
  ({int read, int total}) juzProgress(int juz) {
    final range = MushafJuzTable.range(juz);
    var read = 0;
    for (var page = range.start; page <= range.end; page++) {
      if (completedPages.contains(page)) read++;
    }
    return (read: read, total: range.end - range.start + 1);
  }

  /// First unread page of [juz]; its first page when fully read.
  int firstUnreadPageInJuz(int juz) {
    final range = MushafJuzTable.range(juz);
    for (var page = range.start; page <= range.end; page++) {
      if (!completedPages.contains(page)) return page;
    }
    return range.start;
  }

  KhatmahPlan anchorDailyTarget(DateTime date) {
    final target = dailyTargetFor(date);
    return copyWith(
      dailyTargetDate: KhatmahSchedulingEngine.localDate(date),
      dailyTargetStartPage: target.startPage,
      dailyTargetEndPage: target.endPage,
    );
  }

  int actualElapsedDays(DateTime completedAt) =>
      KhatmahSchedulingEngine.elapsedCalendarDays(startDate, completedAt);

  KhatmahPlan recordPage(int pageNumber) {
    return copyWith(completedPages: {...completedPages, pageNumber});
  }

  KhatmahPlan recordThroughPage(int pageNumber) {
    final pages = pagesThrough(pageNumber).toList();
    if (pages.isEmpty) return this;
    return copyWith(completedPages: {...completedPages, ...pages});
  }

  KhatmahPlan copyWith({
    String? id,
    String? title,
    int? startPage,
    int? currentPage,
    Iterable<int>? completedPages,
    int? targetPagesPerDay,
    int? targetDays,
    DateTime? startDate,
    DateTime? expectedEndDate,
    KhatmahStatus? status,
    KhatmahDedication? dedication,
    DateTime? lastReadDate,
    DateTime? dailyTargetDate,
    int? dailyTargetStartPage,
    int? dailyTargetEndPage,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    Object? authority,
    KhatmahWirdUnit? wirdUnit,
  }) {
    return KhatmahPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      startPage: startPage ?? this.startPage,
      completedPages: completedPages ?? this.completedPages,
      targetPagesPerDay: targetPagesPerDay ?? this.targetPagesPerDay,
      targetDays: targetDays ?? this.targetDays,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      status: status ?? this.status,
      dedication: dedication ?? this.dedication,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      dailyTargetDate: dailyTargetDate ?? this.dailyTargetDate,
      dailyTargetStartPage: dailyTargetStartPage ?? this.dailyTargetStartPage,
      dailyTargetEndPage: dailyTargetEndPage ?? this.dailyTargetEndPage,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
      authority: authority ?? this.authority,
      wirdUnit: wirdUnit ?? this.wirdUnit,
    );
  }

  KhatmahPlan pause({DateTime? at}) {
    return copyWith(
      status: KhatmahStatus.paused,
      pausedAt: at ?? DateTime.now(),
    );
  }

  KhatmahPlan resume({DateTime? fromDate}) {
    final newExpectedEndDate = KhatmahSchedulingEngine.recalculateAfterResume(
      remainingPages,
      targetPagesPerDay,
      fromDate,
    );
    return copyWith(
      status: KhatmahStatus.active,
      expectedEndDate: newExpectedEndDate,
      clearPausedAt: true,
    );
  }

  static Set<int> _normalizeCompletedPages(Iterable<int> pages) {
    return {
      for (final page in pages)
        if (page >= 1 && page <= KhatmahSchedulingEngine.totalPages) page,
    };
  }

  /// Last page of the unbroken run read from [startPage] in reading order;
  /// 0 when the start page itself is unread.
  static int _lastContiguousPage(Set<int> pages, int startPage) {
    var current = 0;
    for (final page in readingOrder(startPage)) {
      if (!pages.contains(page)) break;
      current = page;
    }
    return current;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    startPage,
    currentPage,
    completedPages,
    targetPagesPerDay,
    targetDays,
    startDate,
    expectedEndDate,
    status,
    dedication,
    lastReadDate,
    dailyTargetDate,
    dailyTargetStartPage,
    dailyTargetEndPage,
    pausedAt,
    wirdUnit,
  ];
}
