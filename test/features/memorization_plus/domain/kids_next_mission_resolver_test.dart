import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';

void main() {
  group('KidsNextMissionResolver', () {
    test('due kids review takes priority over new memorization', () {
      final now = DateTime.utc(2026, 9, 1);
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [1],
            status: KidsJourneyStageStatus.current,
          ),
        ],
        resumableMission: const KidsNextMission(
          type: KidsMissionType.resume,
          surahId: 113,
          ayahNumbers: [2],
        ),
        reviewRecords: [
          AyahReviewRecord(
            surahId: 114,
            ayahNumber: 1,
            strengthLevel: 1,
            intervalDays: 1,
            lastReviewedAt: DateTime.utc(2026, 8, 30),
            nextReviewDate: DateTime.utc(2026, 8, 31),
            totalReviews: 1,
            lastRating: PerformanceRating.average,
            createdByMode: ReviewRecordCreatedByMode.kidsMode,
          ),
        ],
        now: now,
      );

      expect(mission?.type, KidsMissionType.dueReview);
      expect(mission?.surahId, 114);
      expect(mission?.ayahNumbers, const [1]);
    });

    test('starts the next short surah after completing the current one', () {
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 6,
            completedAyahs: [1, 2, 3, 4, 5, 6],
            status: KidsJourneyStageStatus.completed,
          ),
        ],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
      );

      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.surahId, 113);
      expect(mission?.ayahNumbers, const [1]);
    });

    test('does not move beyond the configured Juz Amma boundary', () {
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 78,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 78,
            startAyah: 1,
            endAyah: 40,
            completedAyahs: [1],
            status: KidsJourneyStageStatus.completed,
          ),
        ],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
      );

      expect(mission, isNull);
    });
    test('resumes an interrupted session before linked or new work', () {
      const resume = KidsNextMission(
        type: KidsMissionType.resume,
        surahId: 113,
        ayahNumbers: [3],
      );

      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 3,
            completedAyahs: [1, 2, 3],
            status: KidsJourneyStageStatus.needsReview,
          ),
        ],
        resumableMission: resume,
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
      );

      expect(mission, resume);
    });
  });
}
