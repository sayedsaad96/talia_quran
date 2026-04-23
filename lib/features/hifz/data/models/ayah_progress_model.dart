import '../../domain/entities/hifz_entities.dart';

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
    const intervals = [1, 3, 7, 14, 30, 90];
    final rep = repetitions + 1;
    final intervalDays = rep < intervals.length ? intervals[rep] : 90;
    final nextStatus = rep >= 5 ? AyahStatus.memorized : AyahStatus.review;

    return AyahProgressModel(
      surahId: surahId,
      ayahNumber: ayahNumber,
      status: nextStatus,
      repetitions: rep,
      nextReviewDate: DateTime.now().add(Duration(days: intervalDays)),
      lastReviewDate: DateTime.now(),
    );
  }
}
