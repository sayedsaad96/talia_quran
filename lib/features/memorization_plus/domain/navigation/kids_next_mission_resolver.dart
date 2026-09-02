import 'package:equatable/equatable.dart';

import '../entities/memorization_entities.dart';

/// The single actionable task shown on the kids home screen.
final class KidsNextMission extends Equatable {
  const KidsNextMission({
    required this.type,
    required this.surahId,
    required this.ayahNumbers,
  });

  final KidsMissionType type;
  final int surahId;
  final List<int> ayahNumbers;

  int get startAyah => ayahNumbers.first;

  @override
  List<Object?> get props => [type, surahId, ayahNumbers];
}

/// Resolves one distraction-free kids mission using the product priority:
/// due review, resumed session, linked review, current memorization, then the next short surah.
final class KidsNextMissionResolver {
  const KidsNextMissionResolver({this.lastJuzAmmaSurahId = 78});

  final int lastJuzAmmaSurahId;

  KidsNextMission? resolve({
    required int activeSurahId,
    required List<KidsJourneyStage> stages,
    KidsNextMission? resumableMission,
    required List<AyahReviewRecord> reviewRecords,
    required DateTime now,
  }) {
    final dueReviews =
        reviewRecords
            .where(
              (record) =>
                  record.createdByMode == ReviewRecordCreatedByMode.kidsMode &&
                  (record.lastRating == PerformanceRating.weak ||
                      !record.nextReviewDate.toUtc().isAfter(now.toUtc())),
            )
            .toList()
          ..sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
    if (dueReviews.isNotEmpty) {
      final record = dueReviews.first;
      return KidsNextMission(
        type: KidsMissionType.dueReview,
        surahId: record.surahId,
        ayahNumbers: [record.ayahNumber],
      );
    }
    if (resumableMission != null) return resumableMission;

    for (final stage in stages) {
      if (stage.status != KidsJourneyStageStatus.needsReview) continue;
      return KidsNextMission(
        type: KidsMissionType.linkedReview,
        surahId: stage.surahId,
        ayahNumbers: _completedOrRange(stage),
      );
    }

    for (final stage in stages) {
      if (stage.status != KidsJourneyStageStatus.current) continue;
      return KidsNextMission(
        type: KidsMissionType.newMemorization,
        surahId: stage.surahId,
        ayahNumbers: [_firstIncompleteAyah(stage)],
      );
    }

    if (activeSurahId > lastJuzAmmaSurahId && stages.isNotEmpty) {
      return KidsNextMission(
        type: KidsMissionType.newMemorization,
        surahId: activeSurahId - 1,
        ayahNumbers: const [1],
      );
    }

    return null;
  }

  static int _firstIncompleteAyah(KidsJourneyStage stage) {
    final completed = stage.completedAyahs.toSet();
    for (var ayah = stage.startAyah; ayah <= stage.endAyah; ayah++) {
      if (!completed.contains(ayah)) return ayah;
    }
    return stage.startAyah;
  }

  static List<int> _completedOrRange(KidsJourneyStage stage) {
    if (stage.completedAyahs.isNotEmpty) {
      final ayahs = stage.completedAyahs.toSet().toList()..sort();
      return ayahs;
    }
    return List<int>.generate(
      stage.totalAyahs,
      (index) => stage.startAyah + index,
    );
  }
}
