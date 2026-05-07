import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

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
}
