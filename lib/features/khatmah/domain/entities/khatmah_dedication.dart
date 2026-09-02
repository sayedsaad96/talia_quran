import 'package:equatable/equatable.dart';

enum DedicationCondition { alive, deceased, sick }

class KhatmahDedication extends Equatable {
  const KhatmahDedication({
    this.isDedicated = false,
    this.recipientName,
    this.relationship,
    this.condition,
    this.customNote,
  });

  final bool isDedicated;
  final String? recipientName;
  final String? relationship;
  final DedicationCondition? condition;
  final String? customNote;

  static const none = KhatmahDedication();

  @override
  List<Object?> get props =>
      [isDedicated, recipientName, relationship, condition, customNote];
}
