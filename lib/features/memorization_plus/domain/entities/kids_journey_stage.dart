import 'package:equatable/equatable.dart';

enum KidsJourneyStageStatus { locked, current, completed, needsReview }

class KidsJourneyStage extends Equatable {
  const KidsJourneyStage({
    required this.stageNumber,
    required this.surahId,
    required this.startAyah,
    required this.endAyah,
    required this.completedAyahs,
    required this.status,
  });

  final int stageNumber;
  final int surahId;
  final int startAyah;
  final int endAyah;
  final List<int> completedAyahs;
  final KidsJourneyStageStatus status;

  int get totalAyahs => endAyah - startAyah + 1;
  int get completedCount => completedAyahs.length;
  double get progress => totalAyahs <= 0 ? 0 : completedCount / totalAyahs;
  bool get isUnlocked => status != KidsJourneyStageStatus.locked;

  /// The next ayah to start memorizing. If all ayahs are completed,
  /// returns [startAyah] to allow reviewing from the beginning.
  int get nextAyahToStart => completedAyahs.length >= totalAyahs
      ? startAyah
      : startAyah + completedAyahs.length;

  @override
  List<Object?> get props => [
    stageNumber,
    surahId,
    startAyah,
    endAyah,
    completedAyahs,
    status,
  ];
}
