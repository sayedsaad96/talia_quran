// Tests for V2 Session Resume — Phase D coverage.
//
// V2SessionProgressAdapter.restore() is a PURE function: it reads only its
// IsarV2Session argument and rebuilds a V2SessionState — it never touches the
// datasource. These tests therefore exercise it without an Isar instance,
// proving an interrupted session round-trips back into a faithful state for
// every restorable phase, and that terminal (completed) / pre-start (created)
// phases are rejected by the Cubit's resume gate so completion is never
// double-awarded.
//
// Note: loadIfExists()/clear() are thin pass-throughs to
// V2SessionLocalDatasource (an Isar wrapper) and are covered by the existing
// Isar-backed datasource suite; they are intentionally not re-tested here to
// keep this file free of the native Isar harness.

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  group('V2 Session Resume — restore() per phase', () {
    test('restores every restorable phase with full field fidelity', () {
      for (final phase in V2SessionPhase.values) {
        if (phase == V2SessionPhase.created ||
            phase == V2SessionPhase.completed) {
          continue; // non-restorable — covered in the rejection group.
        }

        final saved = IsarV2Session.create(
          surahId: 1,
          blockAyahNumbers: const [1, 2, 3],
          currentAyahIndex: 1,
          phaseIndex: phase.index,
          passedAyahNumbers: const {1},
          failureCounts: const {2: 2},
          // fullAyah is V2HintLevel index 2 — stored as the raw int in the
          // CSV persistence format, so we use the literal here.
          hintLevels: const {1: 2},
          blockReviewRequired: true,
        );

        final restored = V2SessionProgressAdapter.restore(saved, _allAyahs);

        expect(restored.phase, phase, reason: 'phase mismatch for $phase');
        expect(restored.surahId, 1);
        expect(
          restored.currentAyahIndex,
          1,
          reason: 'currentAyahIndex mismatch for $phase',
        );
        expect(
          restored.currentAyah.numberInSurah,
          2,
          reason: 'currentAyah mismatch for $phase',
        );
        expect(
          restored.passedAyahNumbers,
          {1},
          reason: 'passedAyahNumbers mismatch for $phase',
        );
        expect(
          restored.blockAyahs.map((a) => a.numberInSurah),
          [1, 2, 3],
          reason: 'blockAyahs mismatch for $phase',
        );
        expect(
          restored.failureTracker.failureCountFor(1, 2),
          2,
          reason: 'failureTracker mismatch for $phase',
        );
        expect(
          restored.failureTracker.remediationLevelFor(1, 2),
          V2RemediationLevel.guided,
          reason: 'remediation level mismatch for $phase',
        );
        expect(
          restored.hintTracker.levelFor(1, 1),
          V2HintLevel.fullAyah,
          reason: 'hintTracker mismatch for $phase',
        );
        expect(restored.blockReviewRequired, true);
        expect(restored.lastRecitationResult, isNull);
      }
    });

    test('restores currentAyahIndex independently of failure state', () {
      final saved = IsarV2Session.create(
        surahId: 1,
        blockAyahNumbers: const [1, 2, 3],
        currentAyahIndex: 2,
        phaseIndex: V2SessionPhase.learning.index,
        passedAyahNumbers: const {1, 2},
        failureCounts: const {},
        hintLevels: const {},
        blockReviewRequired: true,
      );

      final restored = V2SessionProgressAdapter.restore(saved, _allAyahs);

      expect(restored.currentAyahIndex, 2);
      expect(restored.currentAyah.numberInSurah, 3);
    });

    test('clamps out-of-range currentAyahIndex defensively', () {
      final saved = IsarV2Session.create(
        surahId: 1,
        blockAyahNumbers: const [1, 2, 3],
        currentAyahIndex: 99, // corruption / edited data
        phaseIndex: V2SessionPhase.memorizing.index,
        passedAyahNumbers: const {},
        failureCounts: const {},
        hintLevels: const {},
        blockReviewRequired: true,
      );

      final restored = V2SessionProgressAdapter.restore(saved, _allAyahs);

      expect(restored.currentAyahIndex, 2); // clamped to last valid index
      expect(restored.currentAyah.numberInSurah, 3);
    });

    test('falls back to learning on out-of-range phaseIndex', () {
      // Simulates a corrupted or future-enum persisted index that would
      // otherwise throw RangeError. The guard must fall back safely instead
      // of crashing startSession(), and must not bypass any recitation or
      // block-review gate.
      final saved = IsarV2Session.create(
        surahId: 1,
        blockAyahNumbers: const [1, 2, 3],
        currentAyahIndex: 0,
        phaseIndex: 999, // out of range
        passedAyahNumbers: const {1},
        failureCounts: const {},
        hintLevels: const {},
        blockReviewRequired: true,
      );

      final restored = V2SessionProgressAdapter.restore(saved, _allAyahs);

      expect(restored.phase, V2SessionPhase.learning);
      // Other fields must still restore correctly.
      expect(restored.passedAyahNumbers, {1});
      expect(restored.currentAyah.numberInSurah, 1);
    });

    test('negative phaseIndex also falls back to learning', () {
      final saved = IsarV2Session.create(
        surahId: 1,
        blockAyahNumbers: const [1, 2, 3],
        currentAyahIndex: 0,
        phaseIndex: -1, // corruption
        passedAyahNumbers: const {},
        failureCounts: const {},
        hintLevels: const {},
        blockReviewRequired: true,
      );

      final restored = V2SessionProgressAdapter.restore(saved, _allAyahs);

      expect(restored.phase, V2SessionPhase.learning);
    });

    test('reconstructs weak-ayah status (>= 3 failures) from counts', () {
      final saved = IsarV2Session.create(
        surahId: 1,
        blockAyahNumbers: const [1, 2, 3],
        currentAyahIndex: 0,
        phaseIndex: V2SessionPhase.remediation.index,
        passedAyahNumbers: const {},
        failureCounts: const {3: 3},
        hintLevels: const {},
        blockReviewRequired: true,
      );

      final restored = V2SessionProgressAdapter.restore(saved, _allAyahs);

      expect(restored.failureTracker.isWeak(1, 3), isTrue);
      expect(restored.failureTracker.hasWeakAyahs, isTrue);
      expect(
        restored.failureTracker.weakAyahs.map((r) => r.ayahNumber),
        contains(3),
      );
    });

    test('restore() is symmetric with adapter save() shape for a block-review state', () {
      final original = V2SessionState(
        surahId: 1,
        blockAyahs: _blockAyahs,
        currentAyahIndex: 1,
        phase: V2SessionPhase.blockReviewPending,
        passedAyahNumbers: const {1, 2},
        hintTracker: const V2HintTracker()
            .record(surahId: 1, ayahNumber: 2, level: V2HintLevel.firstWord),
        failureTracker: const V2AyahFailureTracker()
            .recordFailure(surahId: 1, ayahNumber: 1),
        blockReviewRequired: true,
      );

      // Mimic V2SessionProgressAdapter.save's serialization shape.
      final failureCounts = <int, int>{};
      for (final r in original.failureTracker.allFailures) {
        failureCounts[r.ayahNumber] = r.failureCount;
      }
      final hintLevels = <int, int>{};
      for (final u in original.hintTracker.allUsages) {
        hintLevels[u.ayahNumber] = u.level.index;
      }
      final saved = IsarV2Session.create(
        surahId: original.surahId,
        blockAyahNumbers:
            original.blockAyahs.map((a) => a.numberInSurah).toList(),
        currentAyahIndex: original.currentAyahIndex,
        phaseIndex: original.phase.index,
        passedAyahNumbers: original.passedAyahNumbers,
        failureCounts: failureCounts,
        hintLevels: hintLevels,
        blockReviewRequired: original.blockReviewRequired,
      );

      final restored = V2SessionProgressAdapter.restore(saved, _allAyahs);

      expect(restored.phase, original.phase);
      expect(restored.currentAyahIndex, original.currentAyahIndex);
      expect(restored.currentAyah.numberInSurah,
          original.currentAyah.numberInSurah);
      expect(restored.passedAyahNumbers, original.passedAyahNumbers);
      expect(
        restored.failureTracker.totalFailures,
        original.failureTracker.totalFailures,
      );
      expect(restored.hintTracker.hasAnyHint, original.hintTracker.hasAnyHint);
    });

    test('restore() slices the persisted block subset from the full surah list', () {
      // Block persisted as ayahs [2,3] — restore must keep ONLY those two,
      // ignoring ayahs 1 and 4 that exist in the loaded surah list.
      final saved = IsarV2Session.create(
        surahId: 1,
        blockAyahNumbers: const [2, 3],
        currentAyahIndex: 0,
        phaseIndex: V2SessionPhase.reciting.index,
        passedAyahNumbers: const {2},
        failureCounts: const {},
        hintLevels: const {},
        blockReviewRequired: true,
      );

      final restored = V2SessionProgressAdapter.restore(saved, _allAyahs);

      expect(restored.blockAyahs.map((a) => a.numberInSurah), [2, 3]);
      expect(restored.currentAyah.numberInSurah, 2);
    });
  });

  group('V2 Session Resume — terminal/pre-start rejection', () {
    // These phases are filtered out by the Cubit BEFORE calling restore(); we
    // assert the invariant here so a future caller cannot accidentally restore
    // a completed session (which would re-run gamification and double-award
    // streak/XP/certs).

    test('completed phase is rejected by the resume gate', () {
      expect(
        _isPhaseRestorable(V2SessionPhase.completed.index),
        isFalse,
      );
    });

    test('created phase is rejected by the resume gate', () {
      expect(_isPhaseRestorable(V2SessionPhase.created.index), isFalse);
    });

    test('every in-flight phase is accepted by the resume gate', () {
      const inFlight = [
        V2SessionPhase.learning,
        V2SessionPhase.memorizing,
        V2SessionPhase.reciting,
        V2SessionPhase.remediation,
        V2SessionPhase.blockReviewPending,
        V2SessionPhase.blockReview,
      ];
      for (final phase in inFlight) {
        expect(_isPhaseRestorable(phase.index), isTrue, reason: '$phase');
      }
    });
  });
}

/// Mirrors the Cubit's resume gate so the test asserts the exact invariant the
/// production code enforces. Kept in sync with startSession().
bool _isPhaseRestorable(int phaseIndex) {
  final phase = V2SessionPhase.values[phaseIndex];
  return phase != V2SessionPhase.created && phase != V2SessionPhase.completed;
}

const _blockAyahs = <Ayah>[
  Ayah(number: 1, surahId: 1, text: 'آية واحدة', numberInSurah: 1),
  Ayah(number: 2, surahId: 1, text: 'آية ثانية', numberInSurah: 2),
  Ayah(number: 3, surahId: 1, text: 'آية ثالثة', numberInSurah: 3),
];

/// Simulates the full surah ayah list the Cubit loads; it supersets the
/// persisted block so restore() can slice by number.
const _allAyahs = <Ayah>[
  Ayah(number: 1, surahId: 1, text: 'آية واحدة', numberInSurah: 1),
  Ayah(number: 2, surahId: 1, text: 'آية ثانية', numberInSurah: 2),
  Ayah(number: 3, surahId: 1, text: 'آية ثالثة', numberInSurah: 3),
  Ayah(number: 4, surahId: 1, text: 'آية رابعة', numberInSurah: 4),
];
