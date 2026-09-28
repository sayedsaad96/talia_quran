// lib/core/memorization/v2/session_state.dart

import 'package:equatable/equatable.dart';

import '../../../features/quran/domain/entities/quran_entities.dart';
import 'session_phase.dart';
import 'hint_usage.dart';
import 'ayah_failure_tracker.dart';
import 'recitation_evaluator.dart';

/// Immutable domain state for a single V2 memorization session.
///
/// This is a pure domain object — no Flutter imports, no Cubit dependency.
/// The Cubit wraps this and converts it to UI states.
final class V2SessionState extends Equatable {
  const V2SessionState({
    required this.surahId,
    required this.blockAyahs,
    required this.currentAyahIndex,
    required this.phase,
    required this.passedAyahNumbers,
    required this.hintTracker,
    required this.failureTracker,
    required this.blockReviewRequired,
    this.isReview = false,
    this.lastRecitationResult,
    this.nearMissCount = 0,
  });

  /// Creates the initial session state for a new block.
  factory V2SessionState.initial({
    required int surahId,
    required List<Ayah> blockAyahs,
    required bool blockReviewRequired,
    bool isReview = false,
  }) {
    return V2SessionState(
      surahId: surahId,
      blockAyahs: blockAyahs,
      currentAyahIndex: 0,
      phase: V2SessionPhase.created,
      passedAyahNumbers: const {},
      hintTracker: V2HintTracker.empty,
      failureTracker: V2AyahFailureTracker.empty,
      blockReviewRequired: blockReviewRequired,
      isReview: isReview,
    );
  }

  final int surahId;

  /// All ayahs in this block (e.g., ayahs 1–5 of a surah).
  final List<Ayah> blockAyahs;

  /// Index within [blockAyahs] — points to the current ayah being worked on.
  final int currentAyahIndex;

  /// Current phase in the V2 state machine.
  final V2SessionPhase phase;

  /// Ayah numbers that have individually passed recitation.
  final Set<int> passedAyahNumbers;

  /// Hint usage tracker for this session.
  final V2HintTracker hintTracker;

  /// Failure tracker for this session.
  final V2AyahFailureTracker failureTracker;

  /// Whether block review is required (false for children < 8 per §14.3).
  final bool blockReviewRequired;

  /// True for an active-recall review session: starts straight at reciting,
  /// offers no learning/hint stages, and completes without block review.
  /// Derived from the persisted launch intent on resume — never user-set.
  final bool isReview;

  /// Result of the most recent recitation evaluation.
  final V2RecitationResult? lastRecitationResult;

  /// Near misses (retry verdicts) on the current ayah. Transient: not part
  /// of the resume checkpoint, so a resumed session starts a fresh allowance.
  final int nearMissCount;

  // ── Computed Properties ──────────────────────────────────

  Ayah get currentAyah => blockAyahs[currentAyahIndex];

  int get totalAyahsInBlock => blockAyahs.length;

  bool get allAyahsPassed => passedAyahNumbers.length >= blockAyahs.length;

  bool get isLastAyah => currentAyahIndex >= blockAyahs.length - 1;

  bool get isComplete => phase == V2SessionPhase.completed;

  double get blockProgress =>
      blockAyahs.isEmpty ? 0 : passedAyahNumbers.length / blockAyahs.length;

  // ── Mutation Helpers ─────────────────────────────────────

  V2SessionState copyWith({
    V2SessionPhase? phase,
    int? currentAyahIndex,
    Set<int>? passedAyahNumbers,
    V2HintTracker? hintTracker,
    V2AyahFailureTracker? failureTracker,
    V2RecitationResult? lastRecitationResult,
    bool clearLastResult = false,
    int? nearMissCount,
  }) {
    return V2SessionState(
      surahId: surahId,
      blockAyahs: blockAyahs,
      currentAyahIndex: currentAyahIndex ?? this.currentAyahIndex,
      phase: phase ?? this.phase,
      passedAyahNumbers: passedAyahNumbers ?? this.passedAyahNumbers,
      hintTracker: hintTracker ?? this.hintTracker,
      failureTracker: failureTracker ?? this.failureTracker,
      blockReviewRequired: blockReviewRequired,
      isReview: isReview,
      lastRecitationResult: clearLastResult
          ? null
          : (lastRecitationResult ?? this.lastRecitationResult),
      nearMissCount: nearMissCount ?? this.nearMissCount,
    );
  }

  @override
  List<Object?> get props => [
    surahId,
    blockAyahs,
    currentAyahIndex,
    phase,
    passedAyahNumbers,
    hintTracker,
    failureTracker,
    blockReviewRequired,
    isReview,
    lastRecitationResult,
    nearMissCount,
  ];
}
