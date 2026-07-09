import 'package:equatable/equatable.dart';

import '../../../../core/memorization/review_due_evaluator.dart';

enum AyahStatus { notStarted, learning, review, memorized }

class AyahProgress extends Equatable {
  const AyahProgress({
    required this.surahId,
    required this.ayahNumber,
    required this.status,
    required this.repetitions,
    required this.nextReviewDate,
    required this.lastReviewDate,
  });

  final int surahId;
  final int ayahNumber;
  final AyahStatus status;
  final int repetitions;
  final DateTime nextReviewDate;
  final DateTime lastReviewDate;

  bool get isDue => const ReviewDueEvaluator().isDue(
    now: DateTime.now().toUtc(),
    scheduledAt: nextReviewDate,
    policy: ReviewDuePolicy.afterScheduledTime,
  );

  AyahProgress copyWith({
    AyahStatus? status,
    int? repetitions,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
  }) => AyahProgress(
    surahId: surahId,
    ayahNumber: ayahNumber,
    status: status ?? this.status,
    repetitions: repetitions ?? this.repetitions,
    nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    lastReviewDate: lastReviewDate ?? this.lastReviewDate,
  );

  String get key => '${surahId}_$ayahNumber';

  @override
  List<Object?> get props => [surahId, ayahNumber, status, repetitions];
}

class SurahHifzProgress extends Equatable {
  const SurahHifzProgress({
    required this.surahId,
    required this.totalAyahs,
    required this.memorizedCount,
    required this.reviewCount,
    required this.learningCount,
  });

  final int surahId;
  final int totalAyahs;
  final int memorizedCount;
  final int reviewCount;
  final int learningCount;

  double get percentage => totalAyahs == 0 ? 0 : memorizedCount / totalAyahs;

  bool get isComplete => memorizedCount == totalAyahs;

  @override
  List<Object?> get props => [
    surahId,
    totalAyahs,
    memorizedCount,
    reviewCount,
    learningCount,
  ];
}
