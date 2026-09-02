import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';

void main() {
  group('DailyPlan', () {
    test('withCompleted does not duplicate completed ayah numbers', () {
      final plan = DailyPlan(
        generatedAt: DateTime(2026, 5, 5),
        surahId: 1,
        newAyahs: const [
          DailyPlanAyah(
            surahId: 1,
            ayahNumber: 1,
            ayahText: 'بسم الله الرحمن الرحيم',
            record: null,
          ),
        ],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [],
      );

      final completedOnce = plan.withCompleted(1);
      final completedTwice = completedOnce.withCompleted(1);

      expect(completedTwice.completedAyahNums, [1]);
      expect(completedTwice.completedCount, 1);
      expect(completedTwice.progress, 1);
    });
  });

  group('parent dashboard learning metrics', () {
    test('summarizes support signals without speech content', () {
      final dashboard = ParentDashboard(
        progress: const KidsProgress.initial(),
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
        logs: [
          KidsSessionLog(
            id: 'one',
            surahId: 114,
            ayahNumber: 1,
            repeatsCompleted: 1,
            pointsEarned: 10,
            completedAt: DateTime.utc(2026, 8, 31),
            durationSeconds: 60,
            hintCount: 2,
            masteryRating: PerformanceRating.weak,
          ),
          KidsSessionLog(
            id: 'two',
            surahId: 114,
            ayahNumber: 1,
            repeatsCompleted: 1,
            pointsEarned: 0,
            completedAt: DateTime.utc(2026, 9, 1),
            durationSeconds: 120,
            hintCount: 1,
            masteryRating: PerformanceRating.average,
          ),
        ],
        rewards: const [],
        settings: const ParentSettings(),
      );

      expect(dashboard.commitmentDays, 2);
      expect(dashboard.dueReviewCount, 3);
      expect(dashboard.ayahsNeedingSupport, 0);
      expect(dashboard.averageSessionDurationSeconds, 90);
      expect(dashboard.totalHintUses, 3);
    });
  });

  group('kids settings persistence', () {
    test('preserves child nickname through JSON round trip', () {
      final json = ParentSettingsModel.fromEntity(
        const ParentSettings(localChildNickname: 'مريم'),
      ).toJson();

      expect(ParentSettingsModel.fromJson(json).localChildNickname, 'مريم');
    });

    test('preserves guidance, session goal, and starting surah', () {
      final json = ParentSettingsModel.fromEntity(
        const ParentSettings(
          guidanceAudioEnabled: false,
          sessionGoalMinutes: 6,
          startingSurahId: 112,
          kidsHifzV2Enabled: true,
        ),
      ).toJson();
      final restored = ParentSettingsModel.fromJson(json);

      expect(restored.guidanceAudioEnabled, isFalse);
      expect(restored.sessionGoalMinutes, 6);
      expect(restored.startingSurahId, 112);
      expect(restored.kidsHifzV2Enabled, isTrue);
    });

    test('old settings remain readable with safe journey defaults', () {
      final restored = ParentSettingsModel.fromJson(const {});

      expect(restored.guidanceAudioEnabled, isNull);
      expect(restored.sessionGoalMinutes, isNull);
      expect(restored.startingSurahId, 114);
      expect(restored.kidsHifzV2Enabled, isFalse);
    });
    test('kids session log stores learning metrics without speech content', () {
      final log = KidsSessionLogModel(
        id: 'mission-1',
        surahId: 114,
        ayahNumber: 2,
        repeatsCompleted: 1,
        pointsEarned: 10,
        completedAt: DateTime.utc(2026, 9, 1),
        missionType: KidsMissionType.dueReview,
        ayahNumbers: const [1, 2],
        durationSeconds: 245,
        attemptCount: 3,
        hintCount: 1,
        masteryRating: PerformanceRating.average,
      );

      final json = log.toJson();
      final restored = KidsSessionLogModel.fromJson(json);

      expect(restored.missionType, KidsMissionType.dueReview);
      expect(restored.ayahNumbers, [1, 2]);
      expect(restored.durationSeconds, 245);
      expect(restored.attemptCount, 3);
      expect(restored.hintCount, 1);
      expect(restored.masteryRating, PerformanceRating.average);
      expect(json.keys, isNot(contains('recognizedText')));
      expect(json.keys, isNot(contains('audioPath')));
    });

    test('old kids logs receive safe metric defaults', () {
      final restored = KidsSessionLogModel.fromJson({
        'id': 'legacy',
        'surahId': 114,
        'ayahNumber': 1,
        'repeatsCompleted': 3,
        'pointsEarned': 14,
        'completedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      });

      expect(restored.missionType, KidsMissionType.newMemorization);
      expect(restored.ayahNumbers, [1]);
      expect(restored.durationSeconds, 0);
      expect(restored.attemptCount, 1);
      expect(restored.hintCount, 0);
    });
    test('preserves child age through profile JSON round trip', () {
      final now = DateTime.utc(2026, 9, 1);
      final profile = MemorizationProfile(
        schemaVersion: 1,
        selectedPath: MemorizationPath.child,
        guardianLinkStatus: GuardianLinkStatus.none,
        guardianOnboardingStatus: GuardianOnboardingStatus.completed,
        isParentGuardian: false,
        createdAt: now,
        updatedAt: now,
        childAge: 6,
      );

      final json = MemorizationProfileModel.fromEntity(profile).toJson();
      expect(MemorizationProfileModel.fromJson(json).childAge, 6);
    });
  });
}
