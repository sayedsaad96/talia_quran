import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/review_outcome_committer.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_evidence_event.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

bool _isarCoreInitialized = false;

Future<void> _initializeIsarCoreForTests() async {
  if (_isarCoreInitialized) return;
  if (Platform.isWindows) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final dllPath =
          '$localAppData\\Pub\\Cache\\hosted\\pub.dev\\isar_flutter_libs-3.1.0+1\\windows\\isar.dll';
      if (File(dllPath).existsSync()) {
        await Isar.initializeIsarCore(libraries: {Abi.current(): dllPath});
        _isarCoreInitialized = true;
        return;
      }
    }
  }
  await Isar.initializeIsarCore();
  _isarCoreInitialized = true;
}

void main() {
  group('V2ReviewOutcomeCommitter — real Isar transaction', () {
    late Directory tempDir;
    late Isar isar;
    late V2ReviewOutcomeCommitter committer;
    var generatedId = 0;

    setUp(() async {
      await _initializeIsarCoreForTests();
      tempDir = await Directory.systemTemp.createTemp('talia_review_outcome_');
      isar = await Isar.open(
        [
          IsarAyahReviewRecordSchema,
          IsarV2SessionSchema,
          IsarReviewEvidenceEventSchema,
          IsarReviewEffectOutboxSchema,
        ],
        directory: tempDir.path,
        name: 'review_outcome_${DateTime.now().microsecondsSinceEpoch}',
      );
      committer = V2ReviewOutcomeCommitter(
        isar: isar,
        owner: const FixedRecordOwnerProvider('owner-a'),
        scheduler: const ScheduleNextReviewUsecase(),
        now: () => DateTime.utc(2026, 9, 8, 12),
        idGenerator: () {
          generatedId += 1;
          return '00000000-0000-4000-8000-${generatedId.toString().padLeft(12, '0')}';
        },
      );
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test(
      'repeating one session/task writes one event and one SM-2 projection',
      () async {
        final result = await committer.commitAutomaticPass(
          previousState: _recitingState,
          nextState: _nextState,
          taskId: 'ayah-1',
        );
        final retry = await committer.commitAutomaticPass(
          previousState: _recitingState,
          nextState: _nextState,
          taskId: 'ayah-1',
        );

        expect(result.alreadyCommitted, isFalse);
        expect(retry.alreadyCommitted, isTrue);
        expect(await isar.isarReviewEvidenceEvents.count(), 1);
        expect(await isar.isarAyahReviewRecords.count(), 1);
        expect(
          (await isar.isarAyahReviewRecords.where().findFirst())?.totalReviews,
          1,
        );
        expect(await isar.isarReviewEffectOutboxs.count(), 2);
      },
    );

    test(
      'terminal pass stores a recoverable checkpoint and completion effect',
      () async {
        final terminal = _nextState.copyWith(phase: V2SessionPhase.completed);
        await committer.commitAutomaticPass(
          previousState: _recitingState,
          nextState: terminal,
          taskId: 'ayah-1',
        );

        final checkpoint = await isar.isarV2Sessions.where().findFirst();
        final effects = await isar.isarReviewEffectOutboxs.where().findAll();
        expect(checkpoint?.phaseIndex, V2SessionPhase.completed.index);
        expect(checkpoint?.sessionId, isNotEmpty);
        expect(
          effects.map((effect) => effect.effectType),
          contains('completion'),
        );
        expect(effects.every((effect) => effect.processedAt == null), isTrue);
      },
    );

    test(
      'self-assessment completes its task without promoting the SM-2 record',
      () async {
        await committer.commitAutomaticPass(
          previousState: _recitingState,
          nextState: _nextState,
          taskId: 'automatic-baseline',
        );
        final before = await isar.isarAyahReviewRecords.where().findFirst();

        await committer.commitAutomaticPass(
          previousState: _recitingState,
          nextState: _nextState.copyWith(phase: V2SessionPhase.completed),
          taskId: 'self-assessment',
          manuallyAssessed: true,
        );

        final after = await isar.isarAyahReviewRecords.where().findFirst();
        final events = await isar.isarReviewEvidenceEvents.where().findAll();
        final effects = await isar.isarReviewEffectOutboxs.where().findAll();
        final selfAssessment = events.singleWhere(
          (event) =>
              event.assessmentIndex == ReviewEvidenceAssessment.manual.index,
        );

        expect(after?.strengthLevel, before?.strengthLevel);
        expect(after?.intervalDays, before?.intervalDays);
        expect(after?.totalReviews, before?.totalReviews);
        expect(after?.lastRatingIndex, before?.lastRatingIndex);
        expect(after?.nextReviewDate.toUtc(), DateTime.utc(2026, 9, 9, 12));
        expect(selfAssessment.ratingIndex, isNull);
        expect(
          effects.any((effect) => effect.effectType == 'certificate'),
          isFalse,
        );
      },
    );

    test(
      'a failed automatic attempt remains evidence when the retry passes',
      () async {
        final failureTracker = V2AyahFailureTracker.empty.recordFailure(
          surahId: 1,
          ayahNumber: 1,
        );
        final failed = _recitingState.copyWith(
          phase: V2SessionPhase.remediation,
          failureTracker: failureTracker,
        );
        final retry = _recitingState.copyWith(failureTracker: failureTracker);
        final passed = _nextState.copyWith(failureTracker: failureTracker);

        final firstFailure = await committer.commitFailedAutomaticAttempt(
          previousState: _recitingState,
          nextState: failed,
          taskId: 'ayah-1',
        );
        final duplicateFailure = await committer.commitFailedAutomaticAttempt(
          previousState: _recitingState,
          nextState: failed,
          taskId: 'ayah-1',
        );
        await committer.commitAutomaticPass(
          previousState: retry,
          nextState: passed,
          taskId: 'ayah-1',
        );

        final events = await isar.isarReviewEvidenceEvents.where().findAll();
        final projection = await isar.isarAyahReviewRecords.where().findFirst();
        expect(firstFailure.alreadyCommitted, isFalse);
        expect(duplicateFailure.alreadyCommitted, isTrue);
        expect(events, hasLength(2));
        expect(
          events.where(
            (event) => event.outcomeIndex == ReviewEvidenceOutcome.failed.index,
          ),
          hasLength(1),
        );
        expect(projection?.totalReviews, 1);
        expect(projection?.lastRatingIndex, PerformanceRating.average.index);
      },
    );

    test(
      'block-review failure records the ayah selected for remediation',
      () async {
        final failedAyah = _recitingState.copyWith(
          phase: V2SessionPhase.remediation,
          currentAyahIndex: 1,
          failureTracker: V2AyahFailureTracker.empty.recordFailure(
            surahId: 1,
            ayahNumber: 2,
          ),
        );

        await committer.commitFailedAutomaticAttempt(
          previousState: _recitingState.copyWith(
            phase: V2SessionPhase.blockReview,
          ),
          nextState: failedAyah,
          taskId: 'block-review:1',
        );

        final event = await isar.isarReviewEvidenceEvents.where().findFirst();
        expect(event?.ayahNumber, 2);
        expect(event?.surahId, 1);
      },
    );

    test('malformed legacy payload falls back without skipping an ayah', () {
      final malformed =
          IsarV2Session.create(
              surahId: 1,
              blockAyahNumbers: const [1, 2],
              currentAyahIndex: 99,
              phaseIndex: V2SessionPhase.blockReview.index,
              passedAyahNumbers: const {1, 2},
              failureCounts: const {},
              hintLevels: const {},
              blockReviewRequired: true,
            )
            ..blockAyahNumbersCsv = '1,not-an-ayah'
            ..passedAyahNumbersCsv = '2,not-an-ayah'
            ..hintLevelsCsv = '2:999';

      final restored = V2SessionProgressAdapter.restore(malformed, _ayahs);

      expect(restored.phase, V2SessionPhase.learning);
      expect(restored.currentAyah.numberInSurah, 1);
      expect(restored.passedAyahNumbers, isEmpty);
    });

    test('event schema exposes no speech text or audio fields', () {
      final persisted = IsarReviewEvidenceEventSchema.properties.keys;
      expect(
        persisted.where(
          (name) => RegExp(
            r'(audio|recording|recognized|spoken|speech|text)',
            caseSensitive: false,
          ).hasMatch(name),
        ),
        isEmpty,
      );
    });
  });
}

const _ayahs = <Ayah>[
  Ayah(number: 1, surahId: 1, numberInSurah: 1, text: 'أ', page: 1),
  Ayah(number: 2, surahId: 1, numberInSurah: 2, text: 'ب', page: 1),
];

const _recitingState = V2SessionState(
  surahId: 1,
  blockAyahs: _ayahs,
  currentAyahIndex: 0,
  phase: V2SessionPhase.reciting,
  passedAyahNumbers: {},
  hintTracker: V2HintTracker.empty,
  failureTracker: V2AyahFailureTracker.empty,
  blockReviewRequired: false,
);

const _nextState = V2SessionState(
  surahId: 1,
  blockAyahs: _ayahs,
  currentAyahIndex: 1,
  phase: V2SessionPhase.learning,
  passedAyahNumbers: {1},
  hintTracker: V2HintTracker.empty,
  failureTracker: V2AyahFailureTracker.empty,
  blockReviewRequired: false,
);
