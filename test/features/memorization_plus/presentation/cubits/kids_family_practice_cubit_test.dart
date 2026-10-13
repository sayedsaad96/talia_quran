import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_family_practice_receipt.dart';
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

  group('guardian confirmation', () {
    KidsFamilyPracticeCubit finished({
      required KidsFamilyPracticeRecorder recorder,
    }) {
      final cubit = KidsFamilyPracticeCubit(
        surahId: 114,
        ayahNumber: 2,
        recorder: recorder,
        clock: () => DateTime.utc(2026, 10, 13, 9),
      )..begin();
      for (var i = 0; i < KidsFamilyPracticeStep.ordered.length; i++) {
        cubit.advance();
      }
      return cubit;
    }

    test('only a finished practice can be confirmed', () async {
      final saved = <KidsFamilyPracticeReceipt>[];
      final cubit = KidsFamilyPracticeCubit(
        surahId: 114,
        ayahNumber: 2,
        recorder: (r) async {
          saved.add(r);
          return true;
        },
      )..begin();

      await cubit.confirm();

      expect(saved, isEmpty);
      expect(cubit.state.confirmation, KidsFamilyPracticeConfirmation.none);
      await cubit.close();
    });

    test('a confirmation records one receipt for this ayah', () async {
      final saved = <KidsFamilyPracticeReceipt>[];
      final cubit = finished(
        recorder: (r) async {
          saved.add(r);
          return true;
        },
      );

      await cubit.confirm();
      await cubit.confirm();

      expect(saved, hasLength(1));
      expect(saved.single.surahId, 114);
      expect(saved.single.ayahNumber, 2);
      expect(cubit.state.confirmation, KidsFamilyPracticeConfirmation.saved);
      await cubit.close();
    });

    test('a failed save can retry with the same receipt id', () async {
      final ids = <String>[];
      var accept = false;
      final cubit = finished(
        recorder: (r) async {
          ids.add(r.id);
          return accept;
        },
      );

      await cubit.confirm();
      expect(cubit.state.confirmation, KidsFamilyPracticeConfirmation.failed);
      accept = true;
      await cubit.confirm();

      expect(cubit.state.confirmation, KidsFamilyPracticeConfirmation.saved);
      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(1));
      await cubit.close();
    });

    test('a throwing recorder is a failure, not a crash', () async {
      final cubit = finished(recorder: (_) async => throw StateError('io'));

      await cubit.confirm();

      expect(cubit.state.confirmation, KidsFamilyPracticeConfirmation.failed);
      await cubit.close();
    });

    test('without a recorder nothing can be confirmed', () async {
      final cubit = KidsFamilyPracticeCubit()..begin();
      expect(cubit.canConfirm, isFalse);
      await cubit.close();
    });
  });
}
