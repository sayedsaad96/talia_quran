import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/kids_review_outcome_committer.dart';
import 'package:talia_quran/core/memorization/v2/review_outcome_commit_support.dart';
import 'package:talia_quran/core/memorization/v2/review_outcome_committer.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_evidence_event.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import '../../../helpers/isar_test_core.dart';


Future<void> _initializeIsarCoreForTests() => initializeIsarCoreForTests();

const _taskId = '114:3:newMemorization';

void main() {
  group('KidsReviewOutcomeCommitter — real Isar transaction', () {
    late Directory tempDir;
    late Isar isar;
    late KidsReviewOutcomeCommitter committer;
    var generatedId = 0;

    String nextId() {
      generatedId += 1;
      return '00000000-0000-4000-8000-${generatedId.toString().padLeft(12, '0')}';
    }

    KidsReviewOutcomeCommitter buildCommitter(String ownerId) =>
        KidsReviewOutcomeCommitter(
          isar: isar,
          owner: FixedRecordOwnerProvider(ownerId),
          scheduler: const ScheduleNextReviewUsecase(),
          now: () => DateTime.utc(2026, 10, 2, 12),
          idGenerator: nextId,
        );

    Future<IsarAyahReviewRecord?> recordFor(String ownerId) {
      final identity = ReviewRecordIdentity(
        ownerUserId: ownerId,
        audience: ReviewRecordReadScope.kids,
        surahId: 114,
        ayahNumber: 3,
      );
      return isar.isarAyahReviewRecords.getByCompositeKey(identity.storageKey);
    }

    Future<V2ReviewOutcomeCommitResult> commit(
      KidsReviewOutcomeCommitter c,
      V2SessionState s,
    ) => c.commitPass(
      sessionState: s,
      taskId: _taskId,
      rating: PerformanceRating.excellent,
      manuallyAssessed: false,
      similarityScore: 0.97,
    );

    setUp(() async {
      await _initializeIsarCoreForTests();
      tempDir = await Directory.systemTemp.createTemp('talia_kids_outcome_');
      isar = await Isar.open(
        [
          IsarAyahReviewRecordSchema,
          IsarV2SessionSchema,
          IsarReviewEvidenceEventSchema,
          IsarReviewEffectOutboxSchema,
        ],
        directory: tempDir.path,
        name: 'kids_outcome_${DateTime.now().microsecondsSinceEpoch}',
      );
      committer = buildCommitter('owner-a');
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test(
      'first pass schedules once and checkpoints the kids session',
      () async {
        final result = await commit(committer, _state());

        expect(result.alreadyCommitted, isFalse);
        final record = await recordFor('owner-a');
        expect(record?.totalReviews, 1);
        expect(
          record?.createdByModeIndex,
          ReviewRecordCreatedByMode.kidsMode.index,
        );
        expect(record?.audience, 'kids');
        expect(record?.cloudDirty, isTrue);

        final events = await isar.isarReviewEvidenceEvents.where().findAll();
        expect(events, hasLength(1));
        expect(events.single.audience, 'kids');
        expect(
          events.single.idempotencyKey,
          '${result.sessionId}|114:3:newMemorization|final',
        );

        final checkpoint = await isar.isarV2Sessions
            .filter()
            .sessionKeyEqualTo(
              IsarV2Session.keyFor(
                ownerId: 'owner-a',
                audience: MemorizationAudience.kids,
                surahId: 114,
              ),
            )
            .findFirst();
        expect(checkpoint?.sessionId, result.sessionId);
        expect(await isar.isarReviewEffectOutboxs.count(), 0);
      },
    );

    test('retrying the same session and task changes nothing', () async {
      final first = await commit(committer, _state());
      final retry = await commit(committer, _state());

      expect(first.alreadyCommitted, isFalse);
      expect(retry.alreadyCommitted, isTrue);
      expect(retry.sessionId, first.sessionId);
      expect((await recordFor('owner-a'))?.totalReviews, 1);
      expect(await isar.isarReviewEvidenceEvents.count(), 1);
    });

    test('a new session for the same ayah counts again', () async {
      await commit(committer, _state());
      await isar.writeTxn(() => isar.isarV2Sessions.clear());
      final second = await commit(committer, _state());

      expect(second.alreadyCommitted, isFalse);
      expect((await recordFor('owner-a'))?.totalReviews, 2);
    });

    test('review missions use the review session key', () async {
      final result = await commit(committer, _state(isReview: true));

      final checkpoint = await isar.isarV2Sessions
          .filter()
          .sessionKeyEqualTo(
            IsarV2Session.keyFor(
              ownerId: 'owner-a',
              audience: MemorizationAudience.kids,
              surahId: 114,
              review: true,
            ),
          )
          .findFirst();
      expect(checkpoint?.sessionId, result.sessionId);
    });

    test('owner isolation', () async {
      await commit(committer, _state());
      final other = await commit(buildCommitter('owner-b'), _state());

      expect(other.alreadyCommitted, isFalse);
      expect((await recordFor('owner-a'))?.totalReviews, 1);
      expect((await recordFor('owner-b'))?.totalReviews, 1);
    });

    test('adult checkpoint default unchanged', () {
      final adult = V2ReviewOutcomeCommitSupport.checkpointFromState(
        _state(),
        ownerId: 'o',
        sessionId: 's',
        launchContext: null,
      );
      final kids = V2ReviewOutcomeCommitSupport.checkpointFromState(
        _state(),
        ownerId: 'o',
        sessionId: 's',
        launchContext: null,
        audience: MemorizationAudience.kids,
      );
      expect(adult.audienceIndex, MemorizationAudience.adult.index);
      expect(kids.audienceIndex, MemorizationAudience.kids.index);
    });
  });
}

const _ayahs = <Ayah>[
  Ayah(number: 6230, surahId: 114, numberInSurah: 1, text: 'أ', page: 604),
  Ayah(number: 6231, surahId: 114, numberInSurah: 2, text: 'ب', page: 604),
  Ayah(number: 6232, surahId: 114, numberInSurah: 3, text: 'ج', page: 604),
];

V2SessionState _state({bool isReview = false}) => V2SessionState(
  surahId: 114,
  blockAyahs: _ayahs,
  currentAyahIndex: 2,
  phase: V2SessionPhase.reciting,
  passedAyahNumbers: const {},
  hintTracker: V2HintTracker.empty,
  failureTracker: V2AyahFailureTracker.empty,
  blockReviewRequired: false,
  isReview: isReview,
);
