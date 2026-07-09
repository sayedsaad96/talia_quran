import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/memorization_snapshot.dart';
import 'package:talia_quran/core/memorization/smart_coach_engine.dart';
import 'package:talia_quran/core/memorization/smart_coach_recommendation.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  group('smart coach continue plan', () {
    const engine = SmartCoachEngine();

    test('routes continueDailyPlan to first pending cached-plan ayah', () {
      final now = DateTime.utc(2026, 7, 9);
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: const [],
        cachedDailyPlan: DailyPlan(
          generatedAt: now,
          surahId: 67,
          newAyahs: const [
            DailyPlanAyah(
              surahId: 67,
              ayahNumber: 7,
              ayahText: 'text',
              record: null,
            ),
            DailyPlanAyah(
              surahId: 67,
              ayahNumber: 8,
              ayahText: 'text',
              record: null,
            ),
          ],
          nearRevision: const [
            DailyPlanAyah(
              surahId: 67,
              ayahNumber: 1,
              ayahText: 'text',
              record: null,
            ),
          ],
          farRevision: const [],
          completedAyahNums: const [1, 2, 3, 4, 5, 6],
        ),
      );

      final recommendation = engine.recommend(snapshot);

      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.continueDailyPlan,
      );
      expect(recommendation?.startAyah, 7);
      expect(
        recommendation?.route,
        '/memorization-v2/session?surahId=67&startAyah=7',
      );
    });
  });
}

MemorizationProfile _adultProfile() => MemorizationProfile(
  schemaVersion: 1,
  selectedPath: MemorizationPath.adult,
  guardianLinkStatus: GuardianLinkStatus.none,
  guardianOnboardingStatus: GuardianOnboardingStatus.completed,
  isParentGuardian: false,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);
