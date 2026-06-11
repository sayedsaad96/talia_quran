import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  const requiredAyah = DailyPlanAyah(
    surahId: 67,
    ayahNumber: 1,
    ayahText: 'required text',
    record: null,
  );

  const retentionAyah = DailyPlanAyah(
    surahId: 67,
    ayahNumber: 2,
    ayahText: 'retention text',
    record: null,
  );

  // Plan with 1 required ayah (#1) and 1 optional retention ayah (#2).
  DailyPlan mixedPlan({List<int> completed = const []}) => DailyPlan(
    generatedAt: DateTime.utc(2026, 6, 10),
    surahId: 67,
    newAyahs: const [requiredAyah],
    nearRevision: const [],
    farRevision: const [],
    completedAyahNums: completed,
    retentionReview: const [retentionAyah],
  );

  // Plan with no retention.
  DailyPlan plainPlan({List<int> completed = const []}) => DailyPlan(
    generatedAt: DateTime.utc(2026, 6, 10),
    surahId: 67,
    newAyahs: const [requiredAyah],
    nearRevision: const [],
    farRevision: const [],
    completedAyahNums: completed,
  );

  // Retention-only day: all ayahs are memorized — no required workload.
  DailyPlan retentionOnlyPlan({List<int> completed = const []}) => DailyPlan(
    generatedAt: DateTime.utc(2026, 6, 10),
    surahId: 67,
    newAyahs: const [],
    nearRevision: const [],
    farRevision: const [],
    completedAyahNums: completed,
    retentionReview: const [retentionAyah],
  );

  // ── P0 hotfix: required-only progress entity tests ──────────────────────────

  group('P0-1 hotfix: required progress must exclude retention', () {
    // Test 1
    test('requiredCompletedCount ignores completed retention ayah', () {
      // Only retention ayah (#2) is completed — required ayah (#1) is not.
      final plan = mixedPlan(completed: [2]);
      expect(plan.requiredCompletedCount, 0);
    });

    // Test 2
    test('requiredProgress ignores completed retention ayah', () {
      final plan = mixedPlan(completed: [2]);
      expect(plan.requiredProgress, 0.0);
    });

    // Test 3
    test(
      'isRequiredPlanCompleted is false when only retention is completed',
      () {
        final plan = mixedPlan(completed: [2]);
        expect(plan.isRequiredPlanCompleted, isFalse);
      },
    );

    // Test 4
    test(
      'isRequiredPlanCompleted is true when all required ayahs are done',
      () {
        final plan = mixedPlan(completed: [1]);
        expect(plan.isRequiredPlanCompleted, isTrue);
      },
    );

    // Test 5
    test(
      'retention-only day: totalItems==0, requiredProgress==0, isRequiredPlanCompleted==false',
      () {
        final plan = retentionOnlyPlan(completed: [2]);
        expect(plan.totalItems, 0);
        expect(plan.requiredProgress, 0.0);
        expect(plan.isRequiredPlanCompleted, isFalse);
        expect(plan.hasRetentionReview, isTrue);
      },
    );

    // Test 6
    test('plan without retention behaves exactly as before', () {
      final empty = plainPlan();
      expect(empty.requiredCompletedCount, 0);
      expect(empty.requiredProgress, 0.0);
      expect(empty.isRequiredPlanCompleted, isFalse);

      final done = plainPlan(completed: [1]);
      expect(done.requiredCompletedCount, 1);
      expect(done.requiredProgress, 1.0);
      expect(done.isRequiredPlanCompleted, isTrue);
    });

    test(
      'completing required ayah AND retention does not double-count required',
      () {
        final plan = mixedPlan(completed: [1, 2]);
        expect(plan.requiredCompletedCount, 1);
        expect(plan.requiredProgress, 1.0);
        expect(plan.isRequiredPlanCompleted, isTrue);
      },
    );
  });

  // ── Existing regression tests (must still pass) ──────────────────────────────

  group('DailyPlan retention entity (regression)', () {
    const legacyAyah = DailyPlanAyah(
      surahId: 67,
      ayahNumber: 1,
      ayahText: 'text',
      record: null,
    );

    DailyPlan basePlan({List<DailyPlanAyah> retention = const []}) => DailyPlan(
      generatedAt: DateTime.utc(2026, 6, 10),
      surahId: 67,
      newAyahs: [legacyAyah],
      nearRevision: const [],
      farRevision: const [],
      completedAyahNums: const [],
      retentionReview: retention,
    );

    test('retentionReview defaults to empty', () {
      final plan = DailyPlan(
        generatedAt: DateTime.utc(2026),
        surahId: 1,
        newAyahs: const [],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [],
      );
      expect(plan.retentionReview, isEmpty);
      expect(plan.hasRetentionReview, isFalse);
    });

    test('totalItems excludes retention', () {
      final plan = basePlan(
        retention: const [
          DailyPlanAyah(
            surahId: 67,
            ayahNumber: 2,
            ayahText: 't',
            record: null,
          ),
        ],
      );
      expect(plan.totalItems, 1);
      expect(plan.optionalRetentionCount, 1);
    });

    test('progress excludes retention (required-only)', () {
      final plan = basePlan().withCompleted(1);
      // progress now delegates to requiredProgress
      expect(plan.progress, 1.0);
      expect(plan.completedRetentionCount, 0);
    });

    test('withCompleted preserves retentionReview', () {
      final plan = basePlan(retention: [legacyAyah]);
      final updated = plan.withCompleted(1);
      expect(updated.retentionReview, hasLength(1));
    });

    test('completedRetentionCount tracks optional completions', () {
      // legacyAyah (#1) is both required and retention in this legacy test
      final plan = basePlan(retention: [legacyAyah]).withCompleted(1);
      expect(plan.completedRetentionCount, 1);
      expect(plan.completedCount, 1);
      expect(plan.totalItems, 1);
    });
  });

  // ── Cache round-trip tests ───────────────────────────────────────────────────

  group('DailyPlanModel cache (regression)', () {
    const cacheAyah = DailyPlanAyah(
      surahId: 67,
      ayahNumber: 1,
      ayahText: 'text',
      record: null,
    );

    test('round-trips retentionReview in JSON', () {
      final model = DailyPlanModel(
        generatedAt: DateTime.utc(2026, 6, 10),
        surahId: 67,
        newAyahs: const [cacheAyah],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [],
        retentionReview: const [
          DailyPlanAyah(
            surahId: 67,
            ayahNumber: 3,
            ayahText: 'retention',
            record: null,
          ),
        ],
      );

      final decoded = DailyPlanModel.fromJson(model.toJson());
      expect(decoded.retentionReview, hasLength(1));
      expect(decoded.retentionReview.first.ayahNumber, 3);
    });

    test('old JSON without retentionReview deserializes to empty list', () {
      final legacy = {
        'generatedAt': '2026-06-10T00:00:00.000Z',
        'surahId': 67,
        'newAyahs': [
          {'surahId': 67, 'ayahNumber': 1, 'ayahText': 'text'},
        ],
        'nearRevision': <dynamic>[],
        'farRevision': <dynamic>[],
        'completedAyahNums': <int>[],
      };

      final decoded = DailyPlanModel.fromJson(legacy);
      expect(decoded.retentionReview, isEmpty);
      expect(decoded.newAyahs, hasLength(1));
    });
  });
}
