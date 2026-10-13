import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_family_practice_step.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_family_practice_cubit.dart';

void main() {
  test('starts idle with no step', () {
    final cubit = KidsFamilyPracticeCubit();

    expect(cubit.state.phase, KidsFamilyPracticePhase.idle);
    expect(cubit.state.step, isNull);
    cubit.close();
  });

  test('begin shows the first step; a second begin keeps the position', () {
    final cubit = KidsFamilyPracticeCubit()..begin();
    expect(cubit.state.step, KidsFamilyPracticeStep.listenTogether);

    cubit.advance();
    cubit.begin();

    expect(cubit.state.step, KidsFamilyPracticeStep.grownUpRecites);
    cubit.close();
  });

  test('advancing through every step finishes the practice', () {
    final cubit = KidsFamilyPracticeCubit()..begin();
    final seen = <KidsFamilyPracticeStep>[];

    while (cubit.state.phase == KidsFamilyPracticePhase.inProgress) {
      seen.add(cubit.state.step!);
      cubit.advance();
    }

    expect(seen, KidsFamilyPracticeStep.ordered);
    expect(cubit.state.phase, KidsFamilyPracticePhase.finished);
    expect(cubit.state.step, isNull);
    cubit.close();
  });

  test('advance does nothing before begin or after finishing', () {
    final cubit = KidsFamilyPracticeCubit()..advance();
    expect(cubit.state.phase, KidsFamilyPracticePhase.idle);

    cubit.begin();
    for (var i = 0; i < KidsFamilyPracticeStep.ordered.length; i++) {
      cubit.advance();
    }
    final finished = cubit.state;
    cubit.advance();

    expect(cubit.state, finished);
    cubit.close();
  });

  test('cancel returns to idle from any step and can be repeated', () {
    final cubit = KidsFamilyPracticeCubit()
      ..begin()
      ..advance()
      ..cancel();

    expect(cubit.state.phase, KidsFamilyPracticePhase.idle);
    expect(cubit.state.stepIndex, 0);

    cubit.cancel();
    expect(cubit.state.phase, KidsFamilyPracticePhase.idle);

    cubit.begin();
    expect(cubit.state.step, KidsFamilyPracticeStep.listenTogether);
    cubit.close();
  });

  test('the last step is flagged so the button can read Done', () {
    final cubit = KidsFamilyPracticeCubit()..begin();
    for (var i = 0; i < KidsFamilyPracticeStep.ordered.length - 1; i++) {
      expect(cubit.state.isLastStep, isFalse);
      cubit.advance();
    }

    expect(cubit.state.isLastStep, isTrue);
    expect(cubit.state.step, KidsFamilyPracticeStep.praiseEffort);
    cubit.close();
  });
}
