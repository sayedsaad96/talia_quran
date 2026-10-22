import 'package:equatable/equatable.dart';

/// An adult learner's directed, local-only similar-ayah aggregate.
class ConfusionPair extends Equatable {
  const ConfusionPair({
    required this.targetSurahId,
    required this.targetAyahNumber,
    required this.otherSurahId,
    required this.otherAyahNumber,
    required this.count,
    required this.firstAt,
    required this.lastAt,
  });

  final int targetSurahId;
  final int targetAyahNumber;
  final int otherSurahId;
  final int otherAyahNumber;
  final int count;
  final DateTime firstAt;
  final DateTime lastAt;

  @override
  List<Object?> get props => [
    targetSurahId,
    targetAyahNumber,
    otherSurahId,
    otherAyahNumber,
    count,
    firstAt,
    lastAt,
  ];
}
