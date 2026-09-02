import 'khatmah_dedication_model.dart';
import '../../domain/entities/khatmah_plan.dart';

class KhatmahPlanModel {
  KhatmahPlanModel({
    required this.id,
    required this.title,
    this.startPage = 1,
    this.currentPage = 0,
    Iterable<int>? completedPages,
    required this.targetPagesPerDay,
    required this.targetDays,
    required this.startDate,
    required this.expectedEndDate,
    this.status = 'active',
    required this.dedication,
    this.lastReadDate,
    this.pausedAt,
  }) : completedPages = Set.unmodifiable(
         _normalizeCompletedPages(
           completedPages ?? _legacyCompletedPages(currentPage),
         ),
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
  final String status;
  final KhatmahDedicationModel dedication;
  final DateTime? lastReadDate;
  final DateTime? pausedAt;

  factory KhatmahPlanModel.fromJson(Map<String, dynamic> json) {
    final rawCompletedPages = json['completedPages'];
    final currentPage = json['currentPage'] as int? ?? 0;
    return KhatmahPlanModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startPage: json['startPage'] as int? ?? 1,
      currentPage: currentPage,
      completedPages: rawCompletedPages is List
          ? rawCompletedPages.whereType<int>()
          : _legacyCompletedPages(currentPage),
      targetPagesPerDay: json['targetPagesPerDay'] as int,
      targetDays: json['targetDays'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      expectedEndDate: DateTime.parse(json['expectedEndDate'] as String),
      status: json['status'] as String? ?? 'active',
      dedication: KhatmahDedicationModel.fromJson(
        json['dedication'] as Map<String, dynamic>? ?? {},
      ),
      lastReadDate: json['lastReadDate'] != null
          ? DateTime.parse(json['lastReadDate'] as String)
          : null,
      pausedAt: json['pausedAt'] != null
          ? DateTime.parse(json['pausedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startPage': startPage,
    'currentPage': currentPage,
    'completedPages': completedPages.toList()..sort(),
    'targetPagesPerDay': targetPagesPerDay,
    'targetDays': targetDays,
    'startDate': startDate.toIso8601String(),
    'expectedEndDate': expectedEndDate.toIso8601String(),
    'status': status,
    'dedication': dedication.toJson(),
    'lastReadDate': lastReadDate?.toIso8601String(),
    'pausedAt': pausedAt?.toIso8601String(),
  };

  factory KhatmahPlanModel.fromEntity(KhatmahPlan entity) {
    return KhatmahPlanModel(
      id: entity.id,
      title: entity.title,
      startPage: entity.startPage,
      currentPage: entity.currentPage,
      completedPages: entity.completedPages,
      targetPagesPerDay: entity.targetPagesPerDay,
      targetDays: entity.targetDays,
      startDate: entity.startDate,
      expectedEndDate: entity.expectedEndDate,
      status: entity.status.name,
      dedication: KhatmahDedicationModel.fromEntity(entity.dedication),
      lastReadDate: entity.lastReadDate,
      pausedAt: entity.pausedAt,
    );
  }

  KhatmahPlan toEntity() => KhatmahPlan(
    id: id,
    title: title,
    startPage: startPage,
    currentPage: currentPage,
    completedPages: completedPages,
    targetPagesPerDay: targetPagesPerDay,
    targetDays: targetDays,
    startDate: startDate,
    expectedEndDate: expectedEndDate,
    status: KhatmahStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => KhatmahStatus.active,
    ),
    dedication: dedication.toEntity(),
    lastReadDate: lastReadDate,
    pausedAt: pausedAt,
  );

  static Set<int> _legacyCompletedPages(int currentPage) {
    return {
      for (var page = 1; page <= currentPage && page <= 604; page++) page,
    };
  }

  static Set<int> _normalizeCompletedPages(Iterable<int> pages) {
    return {
      for (final page in pages)
        if (page >= 1 && page <= 604) page,
    };
  }
}
