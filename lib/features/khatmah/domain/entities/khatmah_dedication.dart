import 'package:equatable/equatable.dart';

enum DedicationCondition { alive, deceased, sick }

enum DedicationGender { male, female }

class KhatmahDedication extends Equatable {
  const KhatmahDedication({
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
  final DedicationCondition? condition;
  final String? customNote;
  final DedicationGender? recipientGender;

  static const none = KhatmahDedication();

  /// Explicit gender, else one implied by an explicit relationship. Never
  /// inferred from the recipient's name.
  DedicationGender? get effectiveGender =>
      recipientGender ?? genderForRelationship(relationship);

  static DedicationGender? genderForRelationship(String? relationship) =>
      switch (relationship) {
        'الأم' || 'والدة' || 'Mother' => DedicationGender.female,
        'الأب' || 'والد' || 'Father' => DedicationGender.male,
        _ => null,
      };

  @override
  List<Object?> get props => [
    isDedicated,
    recipientName,
    relationship,
    condition,
    customNote,
    recipientGender,
  ];
}
