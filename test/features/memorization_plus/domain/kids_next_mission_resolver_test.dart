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

    test('stage with completion gaps skips to the first incomplete ayah', () {
      // K4: with ayahs 1 and 3 done, the count-based rule returned ayah 3 —
      // an already-memorized ayah. The gap-aware entity rule returns ayah 2.
      final mission = const KidsNextMissionResolver().resolve(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [1, 3],
            status: KidsJourneyStageStatus.current,
          ),
        ],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 1),
      );

      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.surahId, 114);
      expect(mission?.ayahNumbers, const [2]);
    });

    test('nextAyahToStart skips gaps and wraps to the start when complete', () {
      // K4 single source of truth lives on the entity itself.
      const gapped = KidsJourneyStage(
        stageNumber: 1,
        surahId: 114,
        startAyah: 1,
        endAyah: 5,
        completedAyahs: [1, 3],
        status: KidsJourneyStageStatus.current,
      );
      expect(gapped.nextAyahToStart, 2);

      const complete = KidsJourneyStage(
        stageNumber: 1,
        surahId: 114,
        startAyah: 1,
        endAyah: 2,
        completedAyahs: [1, 2],
        status: KidsJourneyStageStatus.completed,
      );
      expect(complete.nextAyahToStart, 1);
    });

    test('resolveSkippingAyah keeps a due review ahead after completion', () {
      // K5: completing one ayah must not bury a due SRS review — the same
      // pipeline reruns with the ayah presumed completed.
      final mission = const KidsNextMissionResolver().resolveSkippingAyah(
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
        reviewRecords: [_dueReviewRecord(surahId: 113, ayahNumber: 4)],
        now: DateTime.utc(2026, 9, 24),
        justCompletedSurahId: 114,
        justCompletedAyah: 1,
      );

      expect(mission?.type, KidsMissionType.dueReview);
      expect(mission?.surahId, 113);
      expect(mission?.startAyah, 4);
    });

    test('resolveSkippingAyah advances past the just-completed ayah', () {
      final mission = const KidsNextMissionResolver().resolveSkippingAyah(
        activeSurahId: 114,
        stages: const [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [1, 2],
            status: KidsJourneyStageStatus.current,
          ),
        ],
        reviewRecords: const [],
        now: DateTime.utc(2026, 9, 24),
        justCompletedSurahId: 114,
        justCompletedAyah: 2,
      );

      expect(mission?.type, KidsMissionType.newMemorization);
      expect(mission?.ayahNumbers, const [3]);
    });

    test('resolveSkippingAyah advances to the next surah on stage completion', () {
      final mission = const KidsNextMissionResolver().resolveSkippingAyah(
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
        now: DateTime.utc(2026, 9, 24),
        justCompletedSurahId: 114,
        justCompletedAyah: 6,
      );

      expect(mission?.surahId, 113);
      expect(mission?.startAyah, 1);
    });
  });
}

AyahReviewRecord _dueReviewRecord({
  required int surahId,
  required int ayahNumber,
}) =>
    AyahReviewRecord(
      surahId: surahId,
      ayahNumber: ayahNumber,
      strengthLevel: 5,
      intervalDays: 1,
      lastReviewedAt: DateTime.utc(2026, 8, 30),
      nextReviewDate: DateTime.utc(2026, 9, 1),
      totalReviews: 2,
      lastRating: PerformanceRating.excellent,
      createdByMode: ReviewRecordCreatedByMode.kidsMode,
    );
