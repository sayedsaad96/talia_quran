import 'khatmah_dedication_model.dart';
import '../../domain/entities/khatmah_plan.dart';

class KhatmahPlanModel {
  KhatmahPlanModel({
    required this.id,
    required this.title,
    this.startPage = 1,
    this.currentPage = 0,
    required this.targetPagesPerDay,
    required this.targetDays,
    required this.startDate,
    required this.expectedEndDate,
    this.status = 'active',
    required this.dedication,
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
  final String status;
  final KhatmahDedicationModel dedication;
  final DateTime? lastReadDate;
  final DateTime? pausedAt;

  factory KhatmahPlanModel.fromJson(Map<String, dynamic> json) {
    return KhatmahPlanModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startPage: json['startPage'] as int? ?? 1,
      currentPage: json['currentPage'] as int? ?? 0,
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
}
