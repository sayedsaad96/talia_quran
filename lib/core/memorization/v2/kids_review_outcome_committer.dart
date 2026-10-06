import 'dart:async';

import 'package:isar_community/isar.dart';

import '../../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../../features/memorization_plus/data/models/isar_review_evidence_event.dart';
import '../../../features/memorization_plus/data/models/isar_v2_session.dart';
import '../../../features/memorization_plus/data/models/memorization_models.dart';
import '../../../features/memorization_plus/domain/entities/memorization_entities.dart';
import '../../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../identity/record_owner_provider.dart';
import '../../sync/cloud_sync_queue.dart';
import '../../utils/talia_logger.dart';
import '../review_record_audience_scope.dart';
import '../review_record_identity.dart';
import 'review_outcome_commit_support.dart';
import 'review_outcome_committer.dart';
import 'session_state.dart';

/// The idempotent local durability boundary for a kids recitation pass.
///
/// Twin of [V2ReviewOutcomeCommitter.commitAutomaticPass]: evidence, the SM-2
/// projection and the session checkpoint are written in ONE Isar transaction
/// keyed by `sessionId|taskId|final`, so a retried completion never schedules
/// the ayah's spaced-repetition review a second time. Unlike the adult path it
/// writes no outbox rows: kids rewards and plan effects are handled by
/// `awardKidsPoints`, not by the adult effect processor. Evidence upload is
/// independent of this class; it depends on the `reviewEvidenceTransport` flag
/// and on `ReviewEvidenceLocalDatasource.ensureSyncEffects` backfilling sync
/// receipts for every event of the owner (no audience filter).
final class KidsReviewOutcomeCommitter {
  KidsReviewOutcomeCommitter({
    required Isar isar,
    required RecordOwnerProvider owner,
    required ScheduleNextReviewUsecase scheduler,
    CloudSyncQueue? cloudSyncQueue,
    DateTime Function()? now,
    String Function()? idGenerator,
  }) : _isar = isar,
       _owner = owner,
       _scheduler = scheduler,
       _cloudSyncQueue = cloudSyncQueue,
       _now = now ?? (() => DateTime.now().toUtc()),
       _idGenerator = idGenerator ?? V2ReviewOutcomeCommitSupport.newOpaqueId;

  final Isar _isar;
  final RecordOwnerProvider _owner;
  final ScheduleNextReviewUsecase _scheduler;
  final CloudSyncQueue? _cloudSyncQueue;
  final DateTime Function() _now;
  final String Function() _idGenerator;

  /// Commits one kids ayah pass. [rating] is the caller's mastery decision;
  /// [taskId] must stay stable for a logical ayah task so retries dedupe.
  Future<V2ReviewOutcomeCommitResult> commitPass({
    required V2SessionState sessionState,
    required String taskId,
    required PerformanceRating rating,
    required bool manuallyAssessed,
    double? similarityScore,
  }) async {
    final ownerId = _owner.currentOwnerId;
    const audience = ReviewRecordReadScope.kids;
    final sessionKey = IsarV2Session.keyFor(
      ownerId: ownerId,
      audience: MemorizationAudience.kids,
      surahId: sessionState.surahId,
      review: sessionState.isReview,
    );
    final now = _now().toUtc();
    final eventId = 'event-${_idGenerator()}';

    final result = await _isar.writeTxn(() async {
      final existingSession = await _isar.isarV2Sessions
          .filter()
          .sessionKeyEqualTo(sessionKey)
          .findFirst();
      final sessionId =
          V2ReviewOutcomeCommitSupport.nonEmpty(existingSession?.sessionId) ??
          'session-${_idGenerator()}';
      final finalOutcomeKey = '$sessionId|$taskId|final';
      final existingEvent = await _isar.isarReviewEvidenceEvents
          .filter()
          .idempotencyKeyEqualTo(finalOutcomeKey)
          .findFirst();
      if (existingEvent != null) {
        return V2ReviewOutcomeCommitResult(
          eventId: existingEvent.eventId,
          sessionId: sessionId,
          alreadyCommitted: true,
        );
      }

      final currentAyah = sessionState.currentAyah;
      final identity = ReviewRecordIdentity(
        ownerUserId: ownerId,
        audience: audience,
        surahId: sessionState.surahId,
        ayahNumber: currentAyah.numberInSurah,
      );
      final existingProjection = await _isar.isarAyahReviewRecords
          .getByCompositeKey(identity.storageKey);
      final base =
          existingProjection?.toModel() ??
          AyahReviewRecordModel.initial(
            sessionState.surahId,
            currentAyah.numberInSurah,
          ).copyWith(createdByMode: ReviewRecordCreatedByMode.kidsMode);
      final scheduled = _scheduler
          .schedule(base, rating, now)
          .copyWith(createdByMode: ReviewRecordCreatedByMode.kidsMode);
      final projection =
          IsarAyahReviewRecord.fromModel(
              AyahReviewRecordModel.fromEntity(scheduled),
            )
            ..id = existingProjection?.id ?? Isar.autoIncrement
            ..compositeKey = identity.storageKey
            ..ownerUserId = ownerId
            ..audience = audience.name
            ..cloudDirty = true
            ..lastSyncedAt = null;

      final failureCount = sessionState.failureTracker.failureCountFor(
        sessionState.surahId,
        currentAyah.numberInSurah,
      );
      final event = IsarReviewEvidenceEvent()
        ..eventId = eventId
        ..idempotencyKey = finalOutcomeKey
        ..sessionId = sessionId
        ..taskId = taskId
        ..ownerId = ownerId
        ..audience = audience.name
        ..surahId = sessionState.surahId
        ..ayahNumber = currentAyah.numberInSurah
        ..eventTypeIndex = ReviewEvidenceEventType.finalOutcome.index
        ..assessmentIndex =
            (manuallyAssessed
                    ? ReviewEvidenceAssessment.manual
                    : ReviewEvidenceAssessment.automatic)
                .index
        ..outcomeIndex = ReviewEvidenceOutcome.passed.index
        ..ratingIndex = rating.index
        ..similarityScore = manuallyAssessed ? null : similarityScore
        ..attemptCount = failureCount + 1
        ..failureCount = failureCount
        ..hintLevelIndex = sessionState.hintTracker
            .levelFor(sessionState.surahId, currentAyah.numberInSurah)
            .index
        ..occurredAt = now
        ..committedAt = now
        ..studyDayKey = V2ReviewOutcomeCommitSupport.studyDayKey(now);

      // The checkpoint stores the pre-pass state, so a retry resumes at the
      // recitation step instead of re-running earlier phases.
      final checkpoint = V2ReviewOutcomeCommitSupport.checkpointFromState(
        sessionState,
        ownerId: ownerId,
        sessionId: sessionId,
        launchContext: existingSession?.launchContext,
        audience: MemorizationAudience.kids,
      )..id = existingSession?.id ?? Isar.autoIncrement;

      await _isar.isarReviewEvidenceEvents.put(event);
      await _isar.isarAyahReviewRecords.put(projection);
      await _isar.isarV2Sessions.put(checkpoint);

      return V2ReviewOutcomeCommitResult(
        eventId: eventId,
        sessionId: sessionId,
        alreadyCommitted: false,
      );
    });

    final queue = _cloudSyncQueue;
    if (!result.alreadyCommitted && queue != null) {
      // Same push `saveReviewRecord` triggers; never allowed to fail the commit.
      try {
        unawaited(
          queue.enqueue(CloudSyncQueueKind.productionPush).catchError((
            Object error,
            StackTrace stack,
          ) {
            TaliaLogger.w('Kids review push enqueue failed', error, stack);
          }),
        );
      } catch (error, stack) {
        // enqueue threw synchronously before returning a future.
        TaliaLogger.w('Kids review push enqueue failed', error, stack);
      }
    }
    return result;
  }
}
