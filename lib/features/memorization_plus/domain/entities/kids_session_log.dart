import 'package:equatable/equatable.dart';

import 'ayah_review_record.dart';
import 'kids_session_policy.dart';

class KidsSessionLog extends Equatable {
  const KidsSessionLog({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.repeatsCompleted,
    required this.pointsEarned,
    required this.completedAt,
    this.syncedAt,
    this.missionType = KidsMissionType.newMemorization,
    this.ayahNumbers = const [],
    this.durationSeconds = 0,
    this.attemptCount = 1,
    this.hintCount = 0,
    this.masteryRating = PerformanceRating.excellent,
  }) : assert(durationSeconds >= 0),
       assert(attemptCount >= 1),
       assert(hintCount >= 0);

  final String id;
  final int surahId;
  final int ayahNumber;
  final int repeatsCompleted;
  final int pointsEarned;
  final DateTime completedAt;
  final DateTime? syncedAt;
  final KidsMissionType missionType;
  final List<int> ayahNumbers;
  final int durationSeconds;
  final int attemptCount;
  final int hintCount;
  final PerformanceRating masteryRating;

  bool get isSynced => syncedAt != null;

  KidsSessionLog copyWith({DateTime? syncedAt}) => KidsSessionLog(
    id: id,
    surahId: surahId,
    ayahNumber: ayahNumber,
    repeatsCompleted: repeatsCompleted,
    pointsEarned: pointsEarned,
    completedAt: completedAt,
    syncedAt: syncedAt ?? this.syncedAt,
    missionType: missionType,
    ayahNumbers: ayahNumbers,
    durationSeconds: durationSeconds,
    attemptCount: attemptCount,
    hintCount: hintCount,
    masteryRating: masteryRating,
  );

  @override
  List<Object?> get props => [
    id,
    surahId,
    ayahNumber,
    repeatsCompleted,
    pointsEarned,
    completedAt,
    syncedAt,
    missionType,
    ayahNumbers,
    durationSeconds,
    attemptCount,
    hintCount,
    masteryRating,
  ];
}
