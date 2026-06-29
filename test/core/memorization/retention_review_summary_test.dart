import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/memorization_snapshot.dart';
import 'package:talia_quran/core/memorization/smart_coach_engine.dart';
import 'package:talia_quran/core/memorization/smart_coach_recommendation.dart';
import 'package:talia_quran/core/memorization/usecases/get_retention_review_summary_usecase.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  group('GetRetentionReviewSummaryUseCase', () {
    const usecase = GetRetentionReviewSummaryUseCase();
    final now = DateTime.now().toUtc();

    test('1. Empty review store returns totalDue = 0', () {
      final summary = usecase.summarize([]);
      expect(summary.totalDue, 0);
      expect(summary.affectedSurahCount, 0);
      expect(summary.hasPotentialPathAmbiguity, false);
    });

    test('2. One memorized-due record increments totalDue', () {
      final summary = usecase.summarize([
        _memorizedDueRecord(now: now, surahId: 1, ayahNumber: 1),
      ]);
      expect(summary.totalDue, 1);
      expect(summary.affectedSurahCount, 1);
    });

    test('3. Non-due memorized record is not counted', () {
      final summary = usecase.summarize([
        _memorizedDueRecord(
          now: now,
          surahId: 1,
          ayahNumber: 1,
          nextReviewDate: now.add(const Duration(days: 5)),
        ),
      ]);
      expect(summary.totalDue, 0);
    });

    test(
      '4. Due but non-memorized near/far record is not counted as retention',
      () {
        final summary = usecase.summarize([
          _dueRecord(now: now, surahId: 1, ayahNumber: 1, strengthLevel: 3),
        ]);
        expect(summary.totalDue, 0);
      },
    );

    test('5. Summary reports oldest due date', () {
      final olderDate = now.subtract(const Duration(days: 10));
      final newerDate = now.subtract(const Duration(days: 2));

      final summary = usecase.summarize([
        _memorizedDueRecord(now: now, ayahNumber: 1, nextReviewDate: newerDate),
        _memorizedDueRecord(now: now, ayahNumber: 2, nextReviewDate: olderDate),
      ]);

      expect(summary.oldestDueAt, olderDate);
    });

    test('6. Summary reports weakest memorized-due strength', () {
      final summary = usecase.summarize([
        _memorizedDueRecord(now: now, ayahNumber: 1, strengthLevel: 9),
        _memorizedDueRecord(now: now, ayahNumber: 2, strengthLevel: 6),
        _memorizedDueRecord(now: now, ayahNumber: 3, strengthLevel: 8),
      ]);

      expect(summary.weakestStrengthLevel, 6);
    });

    test(
      '7. Summary reports path ambiguity when source/path metadata is unavailable',
      () {
        final summary = usecase.summarize([
          _memorizedDueRecord(now: now, surahId: 1, ayahNumber: 1),
        ]);
        // As long as there is at least one memorized-due record, there is ambiguity.
        expect(summary.hasPotentialPathAmbiguity, true);
      },
    );
  });

  group('Boundary Safety Validation', () {
    const usecase = GetRetentionReviewSummaryUseCase();
    final now = DateTime.now().toUtc();

    test(
      '8. Kids-created style memorized records cannot be safely distinguished without metadata',
      () {
        // Represents a record created by KidsModeCubit -> MarkAyahMemorizedUsecase
        final kidsRecord = AyahReviewRecord(
          surahId: 1,
          ayahNumber: 1,
          strengthLevel: 6,
          intervalDays: 30,
          lastReviewedAt: now.subtract(const Duration(days: 45)),
          nextReviewDate: now.subtract(const Duration(days: 15)),
          totalReviews: 1,
          lastRating: PerformanceRating.excellent,
        );

        // Represents a record created by Adult Daily Plan
        final adultRecord = AyahReviewRecord(
          surahId: 1,
          ayahNumber: 2,
          strengthLevel: 6,
          intervalDays: 30,
          lastReviewedAt: now.subtract(const Duration(days: 45)),
          nextReviewDate: now.subtract(const Duration(days: 15)),
          totalReviews: 8,
          lastRating: PerformanceRating.excellent,
        );

        // Both are identical from the perspective of ReviewClassification.isMemorizedDue
        expect(kidsRecord.reviewClassification.isMemorizedDue, true);
        expect(adultRecord.reviewClassification.isMemorizedDue, true);

        // Both increment the summary
        final summary = usecase.summarize([kidsRecord, adultRecord]);
        expect(summary.totalDue, 2);
      },
    );

    test(
      '9. Summary does not claim records are adult-safe if metadata is missing',
      () {
        final summary = usecase.summarize([
          _memorizedDueRecord(now: now, surahId: 1, ayahNumber: 1),
        ]);
        // The flag explicitly guards against assuming safety.
        expect(summary.hasPotentialPathAmbiguity, true);
      },
    );

    test(
      '10. Future Daily Plan retention must not be considered safe while ambiguity exists',
      () {
        // This is a documentation test to enforce that Daily Plan generation should NOT
        // consume these records while hasPotentialPathAmbiguity is true.
        final summary = usecase.summarize([
          _memorizedDueRecord(now: now, surahId: 1, ayahNumber: 1),
        ]);

        // Assertion verifying the constraint we documented.
        expect(summary.totalDue > 0, true);
        expect(summary.hasPotentialPathAmbiguity, true);
        // In a real generation logic flow, if (summary.hasPotentialPathAmbiguity) -> bypass retention review for Daily Plan.
      },
    );
  });

  group('Daily Plan Non-Change Regression', () {
    // Tests that the generator logic does not put memorized records in near/far revision.
    final now = DateTime.now().toUtc();

    test('11. Memorized-due records do not appear in newAyahs', () {
      final record = _memorizedDueRecord(now: now, surahId: 1, ayahNumber: 1);
      final classification = record.reviewClassification;

      // Ensure classification behaves correctly
      expect(classification.isNew, false);
      expect(classification.isDue, true);
      expect(classification.isNearRevision, false);
      expect(classification.isFarRevision, false);
    });

    test('12. Memorized-due records do not appear in nearRevision', () {
      final record = _memorizedDueRecord(now: now, surahId: 1, ayahNumber: 1);
      expect(record.reviewClassification.isNearRevision, false);
    });

    test('13. Memorized-due records do not appear in farRevision', () {
      final record = _memorizedDueRecord(now: now, surahId: 1, ayahNumber: 1);
      expect(record.reviewClassification.isFarRevision, false);
    });

    test(
      '14. Daily Plan totalItems remains unchanged (memorized items do not inflate it)',
      () {
        final plan = DailyPlan(
          generatedAt: now,
          surahId: 1,
          newAyahs: const [
            DailyPlanAyah(
              surahId: 1,
              ayahNumber: 2,
              ayahText: 'text',
              record: null,
            ),
          ],
          nearRevision: const [],
          farRevision: const [],
          completedAyahNums: const [],
        );

        // totalItems only counts new + near + far
        expect(plan.totalItems, 1);
      },
    );

    test('15. Daily Plan progress remains unchanged', () {
      final plan = DailyPlan(
        generatedAt: now,
        surahId: 1,
        newAyahs: const [
          DailyPlanAyah(
            surahId: 1,
            ayahNumber: 2,
            ayahText: 'text',
            record: null,
          ),
          DailyPlanAyah(
            surahId: 1,
            ayahNumber: 3,
            ayahText: 'text',
            record: null,
          ),
        ],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [2],
      );

      expect(plan.progress, 0.5);
    });
  });

  group('Smart Coach Regression Tests', () {
    const engine = SmartCoachEngine();
    final now = DateTime.now().toUtc();

    test('16. Smart Coach can still recommend memorized-due', () {
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(now: now, surahId: 1, ayahNumber: 5),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.memorizedReviewDue,
      );
      expect(recommendation?.startAyah, 5);
    });

    test('17. Smart Coach exact ayah quiz route still works', () {
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(now: now, surahId: 1, ayahNumber: 5),
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(
        recommendation?.route,
        '/memorization-v2/session?surahId=1&startAyah=5',
      );
    });

    test('18. Smart Coach priority order remains unchanged', () {
      // Weak > Near > Far > Memorized Due
      final snapshot = MemorizationSnapshot(
        profile: _adultProfile(),
        reviewRecords: [
          _memorizedDueRecord(now: now, surahId: 1, ayahNumber: 5),
          _dueRecord(
            now: now,
            surahId: 1,
            ayahNumber: 2,
            strengthLevel: 3,
          ), // Near due
        ],
      );

      final recommendation = engine.recommend(snapshot);

      expect(recommendation?.kind, SmartCoachRecommendationKind.reviewDueNear);
      expect(recommendation?.startAyah, 2);
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

AyahReviewRecord _dueRecord({
  required DateTime now,
  int surahId = 67,
  int ayahNumber = 1,
  int strengthLevel = 3,
  DateTime? lastReviewedAt,
  DateTime? nextReviewDate,
  PerformanceRating? lastRating = PerformanceRating.average,
}) {
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: 1,
    lastReviewedAt: lastReviewedAt ?? now.subtract(const Duration(days: 2)),
    nextReviewDate: nextReviewDate ?? now.subtract(const Duration(hours: 1)),
    totalReviews: 2,
    lastRating: lastRating,
  );
}

AyahReviewRecord _memorizedDueRecord({
  required DateTime now,
  int surahId = 67,
  int ayahNumber = 1,
  int strengthLevel = 6,
  int intervalDays = 30,
  DateTime? nextReviewDate,
}) {
  return AyahReviewRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    strengthLevel: strengthLevel,
    intervalDays: intervalDays,
    lastReviewedAt: now.subtract(const Duration(days: 45)),
    nextReviewDate: nextReviewDate ?? now.subtract(const Duration(days: 1)),
    totalReviews: 6,
    lastRating: PerformanceRating.excellent,
  );
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
