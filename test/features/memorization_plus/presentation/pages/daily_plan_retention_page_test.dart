import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

/// Mirrors Daily Plan retention visibility without coupling to private widgets.
Widget retentionSectionLabel(BuildContext context, DailyPlan plan) {
  if (!plan.hasRetentionReview) {
    return const SizedBox.shrink();
  }
  final l10n = AppLocalizations.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l10n.dailyPlanRetentionReview),
      Text(l10n.dailyPlanRetentionReviewHint),
    ],
  );
}

/// Mirrors the required-only progress display (P0 hotfix).
Widget requiredProgressLabel(BuildContext context, DailyPlan plan) {
  return Text('${plan.requiredCompletedCount}/${plan.totalItems}');
}

/// Mirrors the completion celebration gate (P0 hotfix).
bool wouldFireCelebration(DailyPlan plan, {int? lastEvaluatedAyah}) {
  return plan.isRequiredPlanCompleted && lastEvaluatedAyah != null;
}

void main() {
  const retentionAyah = DailyPlanAyah(
    surahId: 67,
    ayahNumber: 5,
    ayahText: 'retention text',
    record: null,
  );

  const requiredAyah = DailyPlanAyah(
    surahId: 67,
    ayahNumber: 1,
    ayahText: 'new',
    record: null,
  );

  DailyPlan planWithRetention({List<int> completed = const []}) => DailyPlan(
    generatedAt: DateTime.utc(2026, 6, 10),
    surahId: 67,
    newAyahs: const [requiredAyah],
    nearRevision: const [],
    farRevision: const [],
    completedAyahNums: completed,
    retentionReview: const [retentionAyah],
  );

  DailyPlan planWithoutRetention({List<int> completed = const []}) => DailyPlan(
    generatedAt: DateTime.utc(2026, 6, 10),
    surahId: 67,
    newAyahs: const [requiredAyah],
    nearRevision: const [],
    farRevision: const [],
    completedAyahNums: completed,
  );

  DailyPlan retentionOnlyPlan({List<int> completed = const []}) => DailyPlan(
    generatedAt: DateTime.utc(2026, 6, 10),
    surahId: 67,
    newAyahs: const [],
    nearRevision: const [],
    farRevision: const [],
    completedAyahNums: completed,
    retentionReview: const [retentionAyah],
  );

  Future<void> pumpLocalized(
    WidgetTester tester, {
    required Locale locale,
    required DailyPlan plan,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              body: Column(
                children: [
                  retentionSectionLabel(context, plan),
                  requiredProgressLabel(context, plan),
                  Text(l10n.dailyPlanNewAyahs),
                  Text(l10n.dailyPlanNearRevision),
                  Text(l10n.dailyPlanFarRevision),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // ── P0 hotfix: UI / celebration entity-level tests ───────────────────────────

  group('P0-1 hotfix: celebration gate and progress display', () {
    // Test 7
    test(
      'completing retention ayah first does NOT trigger celebration gate',
      () {
        // Only retention ayah (#5) completed.
        final plan = planWithRetention(completed: [5]);
        expect(
          wouldFireCelebration(plan, lastEvaluatedAyah: 5),
          isFalse,
          reason: 'Retention-only completion must not fire celebration',
        );
      },
    );

    // Test 8
    testWidgets(
      'completing retention ayah first does NOT show required progress as 100%',
      (tester) async {
        // Only retention ayah (#5) completed — required ayah (#1) still pending.
        final plan = planWithRetention(completed: [5]);
        await pumpLocalized(tester, locale: const Locale('en'), plan: plan);
        // requiredProgressLabel shows 'requiredCompletedCount / totalItems'
        expect(find.text('0/1'), findsOneWidget);
        expect(find.text('1/1'), findsNothing);
      },
    );

    // Test 9
    test('completing required ayah triggers celebration gate', () {
      // Required ayah (#1) completed.
      final plan = planWithRetention(completed: [1]);
      expect(
        wouldFireCelebration(plan, lastEvaluatedAyah: 1),
        isTrue,
        reason: 'Completing all required ayahs must fire celebration',
      );
    });

    // Test 10 — plan with retention remains optional
    test(
      'required+retention plan: retention stays optional after required done',
      () {
        final plan = planWithRetention(completed: [1]);
        expect(plan.isRequiredPlanCompleted, isTrue);
        // Retention is still optional — not required
        expect(plan.optionalRetentionCount, 1);
        expect(
          plan.requiredAyahs.map((a) => a.ayahNumber),
          isNot(contains(5)),
          reason: 'Retention ayah must not appear in requiredAyahs',
        );
      },
    );
  });

  // ── Regression tests ────────────────────────────────────────────────────────

  group('Daily Plan retention UI labels (regression)', () {
    testWidgets('shows Retention Review section when retention items exist', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        locale: const Locale('en'),
        plan: planWithRetention(),
      );
      expect(find.text('Retention Review'), findsOneWidget);
      expect(
        find.text('Optional review for ayahs you have already memorized.'),
        findsOneWidget,
      );
    });

    testWidgets('hides Retention Review section when empty', (tester) async {
      await pumpLocalized(
        tester,
        locale: const Locale('en'),
        plan: planWithoutRetention(),
      );
      expect(find.text('Retention Review'), findsNothing);
    });

    testWidgets('required progress ignores retention count', (tester) async {
      await pumpLocalized(
        tester,
        locale: const Locale('en'),
        plan: planWithRetention(),
      );
      expect(find.text('0/1'), findsOneWidget);
    });

    testWidgets('AR label appears correctly', (tester) async {
      await pumpLocalized(
        tester,
        locale: const Locale('ar'),
        plan: planWithRetention(),
      );
      expect(find.text('مراجعة تثبيت'), findsOneWidget);
      expect(
        find.text('مراجعة اختيارية لتثبيت الآيات التي حفظتها بالفعل.'),
        findsOneWidget,
      );
    });

    testWidgets('EN label appears correctly', (tester) async {
      await pumpLocalized(
        tester,
        locale: const Locale('en'),
        plan: planWithRetention(),
      );
      expect(find.text('Retention Review'), findsOneWidget);
    });

    testWidgets('existing Daily Plan section labels still render', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        locale: const Locale('en'),
        plan: planWithRetention(),
      );
      expect(find.text('New ayahs to memorize'), findsOneWidget);
      expect(find.text('Near review (last 5 days)'), findsOneWidget);
      expect(find.text('Far review'), findsOneWidget);
    });
  });

  group('Daily Plan completion behavior (regression)', () {
    // Test 11 — retention still shows checked when completed
    test('retention still registers as checked via isCompleted', () {
      final plan = planWithRetention(completed: [5]);
      expect(plan.isCompleted(5), isTrue);
      expect(plan.completedRetentionCount, 1);
    });

    // Test 12 — required sections still show checked state
    test('required ayah shows as completed via isCompleted', () {
      final plan = planWithRetention(completed: [1]);
      expect(plan.isCompleted(1), isTrue);
    });

    test('completion celebration threshold (entity) ignores retention', () {
      // This was the original failing scenario: retention done, required not.
      final plan = planWithRetention(completed: [5]);
      // Old (buggy): completedCount >= totalItems == 1/1 == true (WRONG)
      // New (fixed): isRequiredPlanCompleted == false
      expect(plan.isRequiredPlanCompleted, isFalse);
      expect(plan.hasRetentionReview, isTrue);
      expect(plan.optionalRetentionCount, 1);
    });

    test('progress ignores retention (required-only)', () {
      final plan = planWithRetention();
      expect(plan.requiredProgress, 0.0);
      expect(plan.totalItems, 1);
    });

    // Test — retention-only day
    test('retention-only day: progress==0 and not completed', () {
      final plan = retentionOnlyPlan(completed: [5]);
      expect(plan.totalItems, 0);
      expect(plan.requiredProgress, 0.0);
      expect(plan.isRequiredPlanCompleted, isFalse);
    });
  });
}
