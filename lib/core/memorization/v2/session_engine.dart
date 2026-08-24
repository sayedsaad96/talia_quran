// lib/core/memorization/v2/session_engine.dart
//
// Pure domain class — no Flutter imports, no Cubit, no BuildContext.
// Implements the V2 phase state machine (Product Rules §11).
//
// Usage: MemorizationSessionCubit wraps this and drives UI.

import 'session_phase.dart';
import 'session_state.dart';
import 'hint_usage.dart';
import 'recitation_evaluator.dart';

/// Pure domain session engine for Memorization V2.
///
/// All methods are synchronous and return a new [V2SessionState].
/// Side effects (persistence, services) are handled by the Cubit via callbacks.
final class V2SessionEngine {
  V2SessionEngine({V2RecitationEvaluator? evaluator})
    : _evaluator = evaluator ?? const V2RecitationEvaluator();

  final V2RecitationEvaluator _evaluator;

  // ── Phase Transitions ────────────────────────────────────

  /// Transitions from [created] → [learning].
  V2SessionState startLearning(V2SessionState state) {
    if (state.phase != V2SessionPhase.created) return state;
    return state.copyWith(phase: V2SessionPhase.learning);
  }

  /// Transitions from [learning] → [memorizing].
  V2SessionState startMemorizing(V2SessionState state) {
    if (state.phase != V2SessionPhase.learning) return state;
    return state.copyWith(phase: V2SessionPhase.memorizing);
  }

  /// Transitions from [memorizing] or [remediation] → [reciting].
  V2SessionState startReciting(V2SessionState state) {
    if (state.phase != V2SessionPhase.memorizing &&
        state.phase != V2SessionPhase.remediation) {
      return state;
    }
    return state.copyWith(
      phase: V2SessionPhase.reciting,
      clearLastResult: true,
    );
  }

  /// Transitions from [blockReviewPending] → [blockReview].
  V2SessionState startBlockReview(V2SessionState state) {
    if (state.phase != V2SessionPhase.blockReviewPending) return state;
    return state.copyWith(
      phase: V2SessionPhase.blockReview,
      clearLastResult: true,
    );
  }

  /// Records a hint usage during [memorizing].
  /// Returns unchanged state if called outside memorizing phase.
  V2SessionState useHint(V2SessionState state, V2HintLevel level) {
    if (!state.phase.hintsAllowed) return state; // silent guard
    return state.copyWith(
      hintTracker: state.hintTracker.record(
        surahId: state.surahId,
        ayahNumber: state.currentAyah.numberInSurah,
        level: level,
      ),
    );
  }

  /// Evaluates a recitation attempt.
  ///
  /// On pass  → marks ayah passed, advances to next or blockReviewPending.
  /// On fail  → increments failure counter, transitions to remediation.
  /// No-attempt → returns state unchanged (STT returned empty).
  V2SessionState evaluateRecitation(V2SessionState state, String spokenText) {
    if (state.phase != V2SessionPhase.reciting) return state;

    final result = _evaluator.evaluate(
      targetText: state.currentAyah.text,
      spokenText: spokenText,
    );

    // No-attempt: STT returned empty — don't penalize.
    if (result.isNoAttempt) {
      return state.copyWith(phase: V2SessionPhase.reciting);
    }

    final stateWithResult = state.copyWith(lastRecitationResult: result);

    if (result.passed) {
      return _handlePass(stateWithResult);
    } else {
      return _handleFail(stateWithResult);
    }
  }

  /// Evaluates a block review recitation.
  ///
  /// On pass  → transitions to [completed].
  /// On fail  → identifies weak ayahs, loops back for targeted remediation.
  V2SessionState evaluateBlockReview(V2SessionState state, String spokenText) {
    if (state.phase != V2SessionPhase.blockReview) return state;

    // Build expected text: all ayahs in block joined.
    final fullText = state.blockAyahs.map((a) => a.text).join(' ');
    final result = _evaluator.evaluate(
      targetText: fullText,
      spokenText: spokenText,
    );

    if (result.isNoAttempt) {
      return state.copyWith(phase: V2SessionPhase.blockReview);
    }

    if (result.passed) {
      return state.copyWith(
        phase: V2SessionPhase.completed,
        lastRecitationResult: result,
      );
    }

    // On block review fail: identify a concrete ayah for targeted remediation.
    // A failed block review must never be promoted to completion.
    final weakAyahNumber = _findFirstRemediationAyah(state);

    final weakIndex = state.blockAyahs.indexWhere(
      (a) => a.numberInSurah == weakAyahNumber,
    );
    final remediationIndex = weakIndex >= 0
        ? weakIndex
        : state.currentAyahIndex;
    final remediationAyah = state.blockAyahs[remediationIndex];
    final newTracker = state.failureTracker.recordFailure(
      surahId: state.surahId,
      ayahNumber: remediationAyah.numberInSurah,
    );

    return state.copyWith(
      phase: V2SessionPhase.remediation,
      currentAyahIndex: remediationIndex,
      failureTracker: newTracker,
      lastRecitationResult: result,
    );
  }

  /// Completes remediation and returns to memorizing for retry.
  V2SessionState completeRemediation(V2SessionState state) {
    if (state.phase != V2SessionPhase.remediation) return state;
    return state.copyWith(
      phase: V2SessionPhase.memorizing,
      clearLastResult: true,
    );
  }

  // ── Manual / self-grade route (V1-M8) ────────────────────

  /// Records a self-graded pass for the current ayah.
  ///
  /// Used when STT or the network is unavailable. The learner explicitly
  /// confirms they recited the ayah from memory; no automatic score is
  /// fabricated and review scheduling behaves exactly like a normal pass.
  V2SessionState submitManualRecall(V2SessionState state) {
    if (state.phase != V2SessionPhase.reciting) return state;
    return _handlePass(
      state.copyWith(lastRecitationResult: _manualPassResult()),
    );
  }

  /// Records a self-graded pass for the whole block review.
  V2SessionState submitManualBlockReview(V2SessionState state) {
    if (state.phase != V2SessionPhase.blockReview) return state;
    return state.copyWith(
      phase: V2SessionPhase.completed,
      lastRecitationResult: _manualPassResult(),
    );
  }

  static V2RecitationResult _manualPassResult() =>
      const V2RecitationResult(
        passed: true,
        similarityScore: 1.0,
        normalizedTarget: '',
        normalizedSpoken: '',
      );

  // ── Private Helpers ──────────────────────────────────────

  V2SessionState _handlePass(V2SessionState state) {
    final ayahNumber = state.currentAyah.numberInSurah;
    final newPassed = {...state.passedAyahNumbers, ayahNumber};
    final allPassed = newPassed.length >= state.blockAyahs.length;

    if (allPassed) {
      // All ayahs individually passed — determine next phase.
      final nextPhase = state.blockReviewRequired
          ? V2SessionPhase.blockReviewPending
          : V2SessionPhase.completed;

      return state.copyWith(phase: nextPhase, passedAyahNumbers: newPassed);
    }

    // Advance to next un-passed ayah.
    final nextIndex = _nextUnpassedIndex(state, newPassed);
    return state.copyWith(
      phase: V2SessionPhase.learning, // restart cycle for next ayah
      currentAyahIndex: nextIndex,
      passedAyahNumbers: newPassed,
      clearLastResult: true,
    );
  }

  V2SessionState _handleFail(V2SessionState state) {
    final ayahNumber = state.currentAyah.numberInSurah;
    final newTracker = state.failureTracker.recordFailure(
      surahId: state.surahId,
      ayahNumber: ayahNumber,
    );

    return state.copyWith(
      phase: V2SessionPhase.remediation,
      failureTracker: newTracker,
    );
  }

  int _nextUnpassedIndex(V2SessionState state, Set<int> passed) {
    for (int i = 0; i < state.blockAyahs.length; i++) {
      if (!passed.contains(state.blockAyahs[i].numberInSurah)) return i;
    }
    return state.currentAyahIndex;
  }

  int _findFirstRemediationAyah(V2SessionState state) {
    for (final record in state.failureTracker.weakAyahs) {
      return record.ayahNumber;
    }
    // If no explicitly weak ayahs, return first un-passed.
    for (final ayah in state.blockAyahs) {
      if (!state.passedAyahNumbers.contains(ayah.numberInSurah)) {
        return ayah.numberInSurah;
      }
    }
    return state.blockAyahs.first.numberInSurah;
  }
}
