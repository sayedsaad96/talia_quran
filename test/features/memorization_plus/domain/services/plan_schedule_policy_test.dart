import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/plan_schedule_policy.dart';

void main() {
  CustomMemorizationPlan plan({
    int daysPerWeek = 7,
    int minutes = 60,
    int newPerDay = 5,
    MemorizationDifficulty difficulty = MemorizationDifficulty.moderate,
  }) => CustomMemorizationPlan(
    name: 'p',
    startSurahId: 67,
    endSurahId: 114,
    newAyahsPerDay: newPerDay,
    availableDaysPerWeek: daysPerWeek,
    sessionMinutes: minutes,
    difficulty: difficulty,
    enableNearRevision: true,
    enableFarRevision: true,
    nearRevisionCount: 5,
    farRevisionCount: 3,
    startAyah: 1,
    createdAt: DateTime.utc(2026, 9, 1),
  );

  // A full week, Friday 2026-09-25 through Thursday 2026-10-01.
  final week = [for (var d = 0; d < 7; d++) DateTime(2026, 9, 25 + d)];

  group('study days (M-U4)', () {
    test('N days per week yields exactly N study days, spread evenly', () {
      for (var n = 1; n <= 7; n++) {
        final studyDays = week
            .where(
              (day) => PlanSchedulePolicy.isStudyDay(plan(daysPerWeek: n), day),
            )
            .length;
        expect(studyDays, n, reason: '$n days/week');
      }
    });

    test('six days a week rests on Friday', () {
      final friday = DateTime(2026, 9, 25);
      expect(
        PlanSchedulePolicy.isStudyDay(plan(daysPerWeek: 6), friday),
        isFalse,
      );
    });

    test('a rest day serves reviews only: no new ayahs', () {
      final friday = DateTime(2026, 9, 25);
      expect(
        PlanSchedulePolicy.newAyahBudget(
          plan(daysPerWeek: 6),
          reviewItemCount: 0,
          today: friday,
        ),
        0,
      );
    });
  });

  group('session time caps new ayahs (M-U4)', () {
    final saturday = DateTime(2026, 9, 26);

    test('ample time keeps the configured new ayahs', () {
      expect(
        PlanSchedulePolicy.newAyahBudget(
          plan(minutes: 60, newPerDay: 5),
          reviewItemCount: 4,
          today: saturday,
        ),
        5,
      );
    });

    test('short sessions reduce new ayahs to fit after required reviews', () {
      // 20 min - 8 reviews x 1.5 = 8 min → 2 new ayahs at 4 min each.
      expect(
        PlanSchedulePolicy.newAyahBudget(
          plan(minutes: 20, newPerDay: 5),
          reviewItemCount: 8,
          today: saturday,
        ),
        2,
      );
    });

    test('a study day always keeps at least one new ayah', () {
      expect(
        PlanSchedulePolicy.newAyahBudget(
          plan(minutes: 10, newPerDay: 5),
          reviewItemCount: 20,
          today: saturday,
        ),
        1,
      );
    });
  });

  group('difficulty sets the pace (M-U4)', () {
    test(
      'block size: easy 3, moderate 5, challenging 7, capped by daily new',
      () {
        expect(
          PlanSchedulePolicy.blockSize(
            plan(difficulty: MemorizationDifficulty.easy, newPerDay: 10),
          ),
          3,
        );
        expect(PlanSchedulePolicy.blockSize(plan(newPerDay: 10)), 5);
        expect(
          PlanSchedulePolicy.blockSize(
            plan(difficulty: MemorizationDifficulty.challenging, newPerDay: 10),
          ),
          7,
        );
        expect(
          PlanSchedulePolicy.blockSize(
            plan(difficulty: MemorizationDifficulty.challenging, newPerDay: 4),
          ),
          4,
        );
      },
    );

    test('challenging raises the recitation pass threshold slightly', () {
      expect(
        PlanSchedulePolicy.passThreshold(MemorizationDifficulty.challenging),
        greaterThan(
          PlanSchedulePolicy.passThreshold(MemorizationDifficulty.moderate),
        ),
      );
      expect(
        PlanSchedulePolicy.passThreshold(MemorizationDifficulty.easy),
        PlanSchedulePolicy.passThreshold(MemorizationDifficulty.moderate),
      );
    });
  });
}
