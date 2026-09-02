import 'package:equatable/equatable.dart';

import 'khatmah_dedication.dart';
import 'khatmah_scheduling_engine.dart';

enum KhatmahStatus { active, paused, completed }

enum QuranReaderMode { free, khatmah }

class KhatmahPlan extends Equatable {
  KhatmahPlan({
    required this.id,
    required this.title,
    this.startPage = 1,
    int currentPage = 0,
    Iterable<int>? completedPages,
    required this.targetPagesPerDay,
    required this.targetDays,
    required this.startDate,
    required this.expectedEndDate,
    this.status = KhatmahStatus.active,
    this.dedication = const KhatmahDedication(),
    this.lastReadDate,
    this.pausedAt,
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
  final DateTime? pausedAt;

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
    DateTime? pausedAt,
    bool clearPausedAt = false,
  }) {
    return KhatmahPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      startPage: startPage ?? this.startPage,
      currentPage: currentPage ?? this.currentPage,
      completedPages: completedPages ?? this.completedPages,
      targetPagesPerDay: targetPagesPerDay ?? this.targetPagesPerDay,
      targetDays: targetDays ?? this.targetDays,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      status: status ?? this.status,
      dedication: dedication ?? this.dedication,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
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
    pausedAt,
  ];
}
