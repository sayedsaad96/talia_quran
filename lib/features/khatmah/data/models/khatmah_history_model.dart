import 'khatmah_dedication_model.dart';
import '../../domain/entities/khatmah_history_entry.dart';

class KhatmahHistoryModel {
  KhatmahHistoryModel({
    required this.id,
    required this.khatmahNumber,
    required this.title,
    required this.startDate,
    required this.completedDate,
    required this.totalDays,
    this.dedication,
    this.certificateId,
  });

  final String id;
  final int khatmahNumber;
  final String title;
  final DateTime startDate;
  final DateTime completedDate;
  final int totalDays;
  final KhatmahDedicationModel? dedication;
  final String? certificateId;

  factory KhatmahHistoryModel.fromJson(Map<String, dynamic> json) {
    return KhatmahHistoryModel(
      id: json['id'] as String,
      khatmahNumber: json['khatmahNumber'] as int,
      title: json['title'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      completedDate: DateTime.parse(json['completedDate'] as String),
      totalDays: json['totalDays'] as int,
      dedication: json['dedication'] != null
          ? KhatmahDedicationModel.fromJson(
              json['dedication'] as Map<String, dynamic>)
          : null,
      certificateId: json['certificateId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'khatmahNumber': khatmahNumber,
        'title': title,
        'startDate': startDate.toIso8601String(),
        'completedDate': completedDate.toIso8601String(),
        'totalDays': totalDays,
        'dedication': dedication?.toJson(),
        'certificateId': certificateId,
      };

  KhatmahHistoryEntry toEntity() => KhatmahHistoryEntry(
        id: id,
        khatmahNumber: khatmahNumber,
        title: title,
        startDate: startDate,
        completedDate: completedDate,
        totalDays: totalDays,
        dedication: dedication?.toEntity(),
        certificateId: certificateId,
      );

  factory KhatmahHistoryModel.fromEntity(KhatmahHistoryEntry entity) {
    return KhatmahHistoryModel(
      id: entity.id,
      khatmahNumber: entity.khatmahNumber,
      title: entity.title,
      startDate: entity.startDate,
      completedDate: entity.completedDate,
      totalDays: entity.totalDays,
      dedication: entity.dedication != null
          ? KhatmahDedicationModel.fromEntity(entity.dedication!)
          : null,
      certificateId: entity.certificateId,
    );
  }
}
