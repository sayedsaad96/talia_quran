import '../../domain/entities/khatmah_dedication.dart';

class KhatmahDedicationModel {
  KhatmahDedicationModel({
    this.isDedicated = false,
    this.recipientName,
    this.relationship,
    this.condition,
    this.customNote,
    this.recipientGender,
  });

  final bool isDedicated;
  final String? recipientName;
  final String? relationship;
  final String? condition;
  final String? customNote;
  final String? recipientGender;

  factory KhatmahDedicationModel.fromJson(Map<String, dynamic> json) {
    return KhatmahDedicationModel(
      isDedicated: json['isDedicated'] as bool? ?? false,
      recipientName: json['recipientName'] as String?,
      relationship: json['relationship'] as String?,
      condition: json['condition'] as String?,
      customNote: json['customNote'] as String?,
      recipientGender: json['recipientGender'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'isDedicated': isDedicated,
    'recipientName': recipientName,
    'relationship': relationship,
    'condition': condition,
    'customNote': customNote,
    'recipientGender': recipientGender,
  };

  factory KhatmahDedicationModel.fromEntity(KhatmahDedication entity) {
    return KhatmahDedicationModel(
      isDedicated: entity.isDedicated,
      recipientName: entity.recipientName,
      relationship: entity.relationship,
      condition: entity.condition?.name,
      customNote: entity.customNote,
      recipientGender: entity.recipientGender?.name,
    );
  }

  KhatmahDedication toEntity() => KhatmahDedication(
    isDedicated: isDedicated,
    recipientName: recipientName,
    relationship: relationship,
    condition: condition != null
        ? DedicationCondition.values.firstWhere(
            (e) => e.name == condition,
            orElse: () => DedicationCondition.alive,
          )
        : null,
    customNote: customNote,
    recipientGender: DedicationGender.values
        .where((gender) => gender.name == recipientGender)
        .firstOrNull,
  );
}
