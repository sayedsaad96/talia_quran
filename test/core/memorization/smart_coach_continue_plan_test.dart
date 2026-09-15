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
      final route = Uri.parse(recommendation!.route);
      expect(route.path, '/memorization-v2/session');
      expect(route.queryParameters['surahId'], '67');
      expect(route.queryParameters['startAyah'], '7');
      expect(route.queryParameters['intent'], 'memorize');
      expect(route.queryParameters['origin'], 'smartCoach');
    });

    test('routes continueDailyPlan to a cross-surah weak target', () {
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
              ayahText: 'new',
              record: null,
            ),
          ],
          weakRecovery: const [
            DailyPlanAyah(
              surahId: 36,
              ayahNumber: 3,
              ayahText: 'weak',
              record: null,
            ),
          ],
          nearRevision: const [
            DailyPlanAyah(
              surahId: 67,
              ayahNumber: 2,
              ayahText: 'completed',
              record: null,
            ),
          ],
          farRevision: const [],
          completedAyahNums: const [2],
        ),
      );

      final recommendation = engine.recommend(snapshot);

      expect(recommendation?.surahId, 36);
      expect(recommendation?.startAyah, 3);
      final route = Uri.parse(recommendation!.route);
      expect(route.queryParameters['surahId'], '36');
      expect(route.queryParameters['startAyah'], '3');
      expect(route.queryParameters['intent'], 'memorize');
      expect(route.queryParameters['origin'], 'smartCoach');
    });

    test('counts weak and retention ayahs in the remaining workload', () {
      final now = DateTime.utc(2026, 7, 9);
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: const [],
        cachedDailyPlan: DailyPlan(
          generatedAt: now,
          surahId: 67,
          newAyahs: const [],
          weakRecovery: const [
            DailyPlanAyah(
              surahId: 36,
              ayahNumber: 3,
              ayahText: 'weak',
              record: null,
            ),
          ],
          nearRevision: const [
            DailyPlanAyah(
              surahId: 67,
              ayahNumber: 2,
              ayahText: 'completed',
              record: null,
            ),
          ],
          farRevision: const [],
          retentionReview: const [
            DailyPlanAyah(
              surahId: 2,
              ayahNumber: 255,
              ayahText: 'retention',
              record: null,
            ),
          ],
          completedAyahNums: const [2],
        ),
      );

      final recommendation = engine.recommend(snapshot);

      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.continueDailyPlan,
      );
      expect(recommendation?.completedCount, 1);
      expect(recommendation?.totalCount, 3);
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
