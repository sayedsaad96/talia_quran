import 'package:equatable/equatable.dart';
import 'khatmah_dedication.dart';
import 'khatmah_scheduling_engine.dart';

enum KhatmahStatus { active, paused, completed }
enum QuranReaderMode { free, khatmah }

class KhatmahPlan extends Equatable {
  const KhatmahPlan({
    required this.id,
    required this.title,
    this.startPage = 1,
    this.currentPage = 0,
    required this.targetPagesPerDay,
    required this.targetDays,
    required this.startDate,
    required this.expectedEndDate,
    this.status = KhatmahStatus.active,
    this.dedication = const KhatmahDedication(),
    this.lastReadDate,
    this.pausedAt,
  });

  final String id;
  final String title;
  final int startPage;
  final int currentPage;
  final int targetPagesPerDay;
  final int targetDays;
  final DateTime startDate;
  final DateTime expectedEndDate;
  final KhatmahStatus status;
  final KhatmahDedication dedication;
  final DateTime? lastReadDate;
  final DateTime? pausedAt;

  int get completedPagesCount =>
      currentPage < startPage ? 0 : currentPage - startPage + 1;
  double get progressPercentage =>
      completedPagesCount / KhatmahSchedulingEngine.totalPages;
  int get remainingPages => KhatmahSchedulingEngine.totalPages - currentPage;

  KhatmahPlan copyWith({
    String? id,
    String? title,
    int? startPage,
    int? currentPage,
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

  @override
  List<Object?> get props => [
        id,
        title,
        startPage,
        currentPage,
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
