import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/kids_family_practice_receipt.dart';
import '../../domain/entities/kids_family_practice_step.dart';

enum KidsFamilyPracticePhase { idle, inProgress, finished }

/// The guardian's confirmation of a finished practice.
enum KidsFamilyPracticeConfirmation { none, saving, saved, failed }

class KidsFamilyPracticeState extends Equatable {
  const KidsFamilyPracticeState({
    this.phase = KidsFamilyPracticePhase.idle,
    this.stepIndex = 0,
    this.confirmation = KidsFamilyPracticeConfirmation.none,
  });

  final KidsFamilyPracticePhase phase;
  final int stepIndex;
  final KidsFamilyPracticeConfirmation confirmation;

  KidsFamilyPracticeStep? get step =>
      phase == KidsFamilyPracticePhase.inProgress
      ? KidsFamilyPracticeStep.ordered[stepIndex]
      : null;

  bool get isLastStep => stepIndex == KidsFamilyPracticeStep.ordered.length - 1;

  @override
  List<Object?> get props => [phase, stepIndex, confirmation];
}

typedef KidsFamilyPracticeRecorder =
    Future<bool> Function(KidsFamilyPracticeReceipt receipt);

/// Walks a guardian and child through the family-practice steps. It has no
/// link to the memorization session, the review committer or the reward
/// owner, so ending or abandoning it can never change progress. A finished
/// practice may be confirmed by the guardian into a separate receipt store.
class KidsFamilyPracticeCubit extends Cubit<KidsFamilyPracticeState> {
  KidsFamilyPracticeCubit({
    this.surahId = 0,
    this.ayahNumber = 0,
    KidsFamilyPracticeRecorder? recorder,
    DateTime Function()? clock,
  }) : _recorder = recorder,
       _clock = clock ?? DateTime.now,
       super(const KidsFamilyPracticeState());

  final int surahId;
  final int ayahNumber;
  final KidsFamilyPracticeRecorder? _recorder;
  final DateTime Function() _clock;

  /// Fixed for this practice, so a retried confirmation is recorded once.
  String? _receiptId;

  /// Whether a finished practice can be confirmed at all on this screen.
  bool get canConfirm => _recorder != null && surahId > 0 && ayahNumber > 0;

  void begin() {
    if (state.phase == KidsFamilyPracticePhase.inProgress) return;
    _receiptId = null;
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

  /// Records the receipt after the caller verified the guardian (PIN). Only
  /// a finished practice can be confirmed, once; a failed save may retry
  /// with the same receipt id.
  Future<void> confirm() async {
    final recorder = _recorder;
    if (recorder == null || !canConfirm) return;
    if (state.phase != KidsFamilyPracticePhase.finished) return;
    if (state.confirmation == KidsFamilyPracticeConfirmation.saving ||
        state.confirmation == KidsFamilyPracticeConfirmation.saved) {
      return;
    }
    final now = _clock().toUtc();
    final id = _receiptId ??=
        'fp_${now.microsecondsSinceEpoch}_${surahId}_$ayahNumber';
    emit(_finished(KidsFamilyPracticeConfirmation.saving));
    var saved = false;
    try {
      saved = await recorder(
        KidsFamilyPracticeReceipt(
          id: id,
          surahId: surahId,
          ayahNumber: ayahNumber,
          confirmedAt: now,
        ),
      );
    } catch (_) {
      saved = false;
    }
    if (isClosed) return;
    emit(
      _finished(
        saved
            ? KidsFamilyPracticeConfirmation.saved
            : KidsFamilyPracticeConfirmation.failed,
      ),
    );
  }

  KidsFamilyPracticeState _finished(KidsFamilyPracticeConfirmation c) =>
      KidsFamilyPracticeState(
        phase: KidsFamilyPracticePhase.finished,
        confirmation: c,
      );
}
