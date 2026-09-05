import 'package:equatable/equatable.dart';

import 'khatmah_dedication.dart';
import 'khatmah_scheduling_engine.dart';

enum KhatmahStatus { active, paused, completed }

enum QuranReaderMode { free, khatmah }

class KhatmahPlan extends Equatable {
  /// Stable storage value for a system-created plan without a recipient title.
  /// Presentation localizes this value at display time, so changing the app
  /// language never leaves the default title in the language of its creation.
  static const defaultTitle = 'Khatmah';

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
  }) : completedPages = Set.unmodifiable(
         _normalizeCompletedPages(completedPages ?? const <int>{}),
       ),
       currentPage = _highestContiguousPage(
         _normalizeCompletedPages(completedPages ?? const <int>{}),
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

  /// Runtime-only authority of the load; never serialized or shared.
  final Object? authority;

  int get completedPagesCount => completedPages.length;

  double get progressPercentage =>
      completedPagesCount / KhatmahSchedulingEngine.totalPages;

  int get remainingPages =>
      KhatmahSchedulingEngine.totalPages - completedPagesCount;

  int get nextUnreadPage {
    for (var page = 1; page <= KhatmahSchedulingEngine.totalPages; page++) {
      if (!completedPages.contains(page)) return page;
    }
    return KhatmahSchedulingEngine.totalPages + 1;
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
    final nextPage = nextUnreadPage;
    if (pageNumber < nextPage) return this;

    return copyWith(
      completedPages: {
        ...completedPages,
        for (var page = nextPage; page <= pageNumber; page++) page,
      },
    );
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

  static int _highestContiguousPage(Set<int> pages) {
    var current = 0;
    while (pages.contains(current + 1)) {
      current++;
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
  ];
}
