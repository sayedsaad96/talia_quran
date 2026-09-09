import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/streak_risk_evaluator.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  const evaluator = StreakRiskEvaluator(riskHour: 20);

  test('is at risk after the threshold with no activity today', () {
    final risk = evaluator.evaluate(
      StreakEntity(
        currentStreak: 4,
        longestStreak: 10,
        lastActivityDate: DateTime(2026, 9, 7),
        freezesAvailable: 2,
      ),
      now: DateTime(2026, 9, 8, 21),
    );
    expect(risk.isAtRisk, isTrue);
    expect(risk.freezesAvailable, 2);
  });

  test('is not at risk when activity happened today', () {
    final risk = evaluator.evaluate(
      StreakEntity(
        currentStreak: 4,
        longestStreak: 10,
        lastActivityDate: DateTime(2026, 9, 8, 8),
        freezesAvailable: 1,
      ),
      now: DateTime(2026, 9, 8, 21),
    );
    expect(risk.isAtRisk, isFalse);
  });
}
