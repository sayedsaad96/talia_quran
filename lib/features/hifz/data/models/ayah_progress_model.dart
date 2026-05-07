import '../../domain/entities/hifz_entities.dart';
import '../../../../core/constants/app_constants.dart';

class AyahProgressModel extends AyahProgress {
  const AyahProgressModel({
    required super.surahId,
    required super.ayahNumber,
    required super.status,
    required super.repetitions,
    required super.nextReviewDate,
    required super.lastReviewDate,
  });

  factory AyahProgressModel.fromJson(Map<String, dynamic> json) {
    return AyahProgressModel(
      surahId: json['surahId'] as int,
      ayahNumber: json['ayahNumber'] as int,
      status: AyahStatus.values[json['status'] as int],
      repetitions: json['repetitions'] as int,
      nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
      lastReviewDate: DateTime.parse(json['lastReviewDate'] as String),
    );
  }

  factory AyahProgressModel.initial(int surahId, int ayahNumber) {
    final now = DateTime.now();
    return AyahProgressModel(
      surahId: surahId,
      ayahNumber: ayahNumber,
      status: AyahStatus.notStarted,
      repetitions: 0,
      nextReviewDate: now,
      lastReviewDate: now,
    );
  }

  Map<String, dynamic> toJson() => {
    'surahId': surahId,
    'ayahNumber': ayahNumber,
    'status': status.index,
    'repetitions': repetitions,
    'nextReviewDate': nextReviewDate.toIso8601String(),
    'lastReviewDate': lastReviewDate.toIso8601String(),
  };

  AyahProgressModel advanceWithSpacedRepetition() {
    final now = DateTime.now();
    final rep = repetitions + 1;
    final intervalIndex = rep - 1;
    final intervalDays =
        intervalIndex < AppConstants.spacedRepetitionIntervals.length
        ? AppConstants.spacedRepetitionIntervals[intervalIndex]
        : AppConstants.spacedRepetitionIntervals.last;
    final nextStatus = rep >= 5 ? AyahStatus.memorized : AyahStatus.review;

    return AyahProgressModel(
      surahId: surahId,
      ayahNumber: ayahNumber,
      status: nextStatus,
      repetitions: rep,
      nextReviewDate: now.add(Duration(days: intervalDays)),
      lastReviewDate: now,
    );
  }

  /// Soft Penalty: decrease repetitions by 1 (min 0) and reschedule for tomorrow.
  /// Unlike the old hard reset which wiped all progress, this preserves
  /// the user's memorization history while indicating they need to review.
  AyahProgressModel softPenalty() {
    final now = DateTime.now();
    final newRep = (repetitions - 1).clamp(0, repetitions);
    final newStatus = newRep == 0 ? AyahStatus.learning : AyahStatus.review;

    return AyahProgressModel(
      surahId: surahId,
      ayahNumber: ayahNumber,
      status: newStatus,
      repetitions: newRep,
      nextReviewDate: now.add(const Duration(days: 1)),
      lastReviewDate: now,
    );
  }
}
