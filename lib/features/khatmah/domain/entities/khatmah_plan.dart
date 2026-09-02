import 'package:equatable/equatable.dart';
import 'khatmah_dedication.dart';

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
  double get progressPercentage => completedPagesCount / 604;
  int get remainingPages => 604 - currentPage;

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
      pausedAt: pausedAt ?? this.pausedAt,
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
