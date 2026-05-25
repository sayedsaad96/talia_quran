import '../../domain/entities/hifz_entities.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/usecases/memorization_plus_usecases.dart';

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
    final now = DateTime.now().toUtc();
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
    final currentInterval = nextReviewDate
        .toUtc()
        .difference(lastReviewDate.toUtc())
        .inDays
        .clamp(0, 180);
    final reviewRecord = AyahReviewRecord(
      surahId: surahId,
      ayahNumber: ayahNumber,
      strengthLevel: repetitions.clamp(0, 10),
      intervalDays: currentInterval,
      lastReviewedAt: lastReviewDate.toUtc(),
      nextReviewDate: nextReviewDate.toUtc(),
      totalReviews: repetitions,
      lastRating: repetitions == 0 ? null : PerformanceRating.excellent,
    );
    final updated = const ScheduleNextReviewUsecase().schedule(
      reviewRecord,
      PerformanceRating.excellent,
    );
    final nextStatus = updated.isMemorized
        ? AyahStatus.memorized
        : AyahStatus.review;

    return AyahProgressModel(
      surahId: surahId,
      ayahNumber: ayahNumber,
      status: nextStatus,
      repetitions: updated.totalReviews,
      nextReviewDate: updated.nextReviewDate,
      lastReviewDate: updated.lastReviewedAt,
    );
  }

  /// Soft Penalty: decrease repetitions by 1 (min 0) and reschedule for tomorrow.
  /// Unlike the old hard reset which wiped all progress, this preserves
  /// the user's memorization history while indicating they need to review.
  AyahProgressModel softPenalty() {
    // UTC: consistent with .initial() and streak/review date comparisons.
    final now = DateTime.now().toUtc();
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
