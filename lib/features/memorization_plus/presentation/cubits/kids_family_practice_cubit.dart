import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/kids_family_practice_step.dart';

enum KidsFamilyPracticePhase { idle, inProgress, finished }

class KidsFamilyPracticeState extends Equatable {
  const KidsFamilyPracticeState({
    this.phase = KidsFamilyPracticePhase.idle,
    this.stepIndex = 0,
  });

  final KidsFamilyPracticePhase phase;
  final int stepIndex;

  KidsFamilyPracticeStep? get step =>
      phase == KidsFamilyPracticePhase.inProgress
      ? KidsFamilyPracticeStep.ordered[stepIndex]
      : null;

  bool get isLastStep => stepIndex == KidsFamilyPracticeStep.ordered.length - 1;

  @override
  List<Object?> get props => [phase, stepIndex];
}

/// Walks a guardian and child through the family-practice steps. It is
/// deliberately self-contained: it has no link to the memorization session,
/// the review committer or the reward owner, so ending or abandoning it can
/// never change progress.
class KidsFamilyPracticeCubit extends Cubit<KidsFamilyPracticeState> {
  KidsFamilyPracticeCubit() : super(const KidsFamilyPracticeState());

  void begin() {
    if (state.phase == KidsFamilyPracticePhase.inProgress) return;
    emit(
      const KidsFamilyPracticeState(phase: KidsFamilyPracticePhase.inProgress),
    );
  }

  void advance() {
    if (state.phase != KidsFamilyPracticePhase.inProgress) return;
    if (state.isLastStep) {
      emit(
        const KidsFamilyPracticeState(phase: KidsFamilyPracticePhase.finished),
      );
      return;
    }
    emit(
      KidsFamilyPracticeState(
        phase: KidsFamilyPracticePhase.inProgress,
        stepIndex: state.stepIndex + 1,
      ),
    );
  }

  void cancel() {
    if (state.phase == KidsFamilyPracticePhase.idle) return;
    emit(const KidsFamilyPracticeState());
  }
}
