import 'package:isar/isar.dart';

import '../../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../../features/memorization_plus/data/models/isar_review_evidence_event.dart';
import '../../../features/memorization_plus/data/models/isar_v2_session.dart';
import '../../../features/memorization_plus/data/models/memorization_models.dart';
import '../../../features/memorization_plus/domain/entities/memorization_entities.dart';
import '../../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../identity/record_owner_provider.dart';
import '../review_record_audience_scope.dart';
import '../review_record_identity.dart';
import 'hint_usage.dart';
import 'review_outcome_commit_support.dart';
import 'session_phase.dart';
import 'session_state.dart';

/// Result of an idempotent local review-outcome commit.
final class V2ReviewOutcomeCommitResult {
  const V2ReviewOutcomeCommitResult({
    required this.eventId,
    required this.sessionId,
    required this.alreadyCommitted,
  });

  final String eventId;
  final String sessionId;
  final bool alreadyCommitted;
}

/// The local durability boundary for an adult V2 recitation pass.
///
/// The transaction deliberately excludes the SharedPreferences daily-plan
/// cache and gamification stores: they have no shared transaction with Isar.
/// Instead, deterministic outbox rows request reconciliation/awarding later.
/// Never run those effects inline from the Cubit.
final class V2ReviewOutcomeCommitter {
  V2ReviewOutcomeCommitter({
    required Isar isar,
    required RecordOwnerProvider owner,
    required ScheduleNextReviewUsecase scheduler,
    DateTime Function()? now,
    String Function()? idGenerator,
  }) : _isar = isar,
       _owner = owner,
       _scheduler = scheduler,
       _now = now ?? (() => DateTime.now().toUtc()),
       _idGenerator = idGenerator ?? V2ReviewOutcomeCommitSupport.newOpaqueId,
       _effects = ReviewEffectOutboxWriter(isar);

  final Isar _isar;
  final RecordOwnerProvider _owner;
  final ScheduleNextReviewUsecase _scheduler;
  final DateTime Function() _now;
  final String Function() _idGenerator;
  final ReviewEffectOutboxWriter _effects;

  /// Writes evidence, SM-2 projection, checkpoint, and outbox rows together.
  ///
  /// [taskId] must remain stable for a logical ayah task. Retrying a successful
  /// commit returns [V2ReviewOutcomeCommitResult.alreadyCommitted] without
  /// incrementing `totalReviews`, interval, or outbox effects.
  Future<V2ReviewOutcomeCommitResult> commitAutomaticPass({
    required V2SessionState previousState,
    required V2SessionState nextState,
    required String taskId,
    bool manuallyAssessed = false,
    double? similarityScore,
    String? eventId,
  }) async {
    final ownerId = _owner.currentOwnerId;
    const audience = ReviewRecordReadScope.adult;
    final sessionKey = IsarV2Session.keyFor(
      ownerId: ownerId,
      audience: MemorizationAudience.adult,
      surahId: nextState.surahId,
    );
    final now = _now().toUtc();
    final requestedEventId = eventId ?? 'event-${_idGenerator()}';

    return _isar.writeTxn(() async {
      final existingByEventId = await _isar.isarReviewEvidenceEvents
          .filter()
          .eventIdEqualTo(requestedEventId)
          .findFirst();
      if (existingByEventId != null) {
        _validateEventIdReuse(existingByEventId, ownerId, audience, taskId);
        return V2ReviewOutcomeCommitResult(
          eventId: existingByEventId.eventId,
          sessionId: existingByEventId.sessionId,
          alreadyCommitted: true,
        );
      }
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

      final currentAyah = previousState.currentAyah;
      final rating = manuallyAssessed
          ? null
          : V2ReviewOutcomeCommitSupport.ratingFor(
              previousState,
              currentAyah.numberInSurah,
            );
      final identity = ReviewRecordIdentity(
        ownerUserId: ownerId,
        audience: audience,
        surahId: previousState.surahId,
        ayahNumber: currentAyah.numberInSurah,
      );
      final existingProjection = await _isar.isarAyahReviewRecords
          .getByCompositeKey(identity.storageKey);
      final base =
          existingProjection?.toModel() ??
          AyahReviewRecordModel.initial(
            previousState.surahId,
            currentAyah.numberInSurah,
          ).copyWith(createdByMode: ReviewRecordCreatedByMode.v2Session);
      final scheduled = manuallyAssessed
          ? V2ReviewOutcomeCommitSupport.manualSchedule(base, now)
          : _scheduler
                .schedule(base, rating!, now)
                .copyWith(createdByMode: ReviewRecordCreatedByMode.v2Session);
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

      final event = IsarReviewEvidenceEvent()
        ..eventId = requestedEventId
        ..idempotencyKey = finalOutcomeKey
        ..sessionId = sessionId
        ..taskId = taskId
        ..ownerId = ownerId
        ..audience = audience.name
        ..surahId = previousState.surahId
        ..ayahNumber = currentAyah.numberInSurah
        ..eventTypeIndex = ReviewEvidenceEventType.finalOutcome.index
        ..assessmentIndex =
            (manuallyAssessed
                    ? ReviewEvidenceAssessment.manual
                    : ReviewEvidenceAssessment.automatic)
                .index
        ..outcomeIndex = ReviewEvidenceOutcome.passed.index
        ..ratingIndex = rating?.index
        ..similarityScore = manuallyAssessed ? null : similarityScore
        ..attemptCount =
            previousState.failureTracker.failureCountFor(
              previousState.surahId,
              currentAyah.numberInSurah,
            ) +
            1
        ..failureCount = previousState.failureTracker.failureCountFor(
          previousState.surahId,
          currentAyah.numberInSurah,
        )
        ..hintLevelIndex = previousState.hintTracker
            .levelFor(previousState.surahId, currentAyah.numberInSurah)
            .index
        ..occurredAt = now
        ..committedAt = now
        ..studyDayKey = V2ReviewOutcomeCommitSupport.studyDayKey(now);

      final checkpoint = V2ReviewOutcomeCommitSupport.checkpointFromState(
        nextState,
        ownerId: ownerId,
        sessionId: sessionId,
      )..id = existingSession?.id ?? Isar.autoIncrement;

      await _isar.isarReviewEvidenceEvents.put(event);
      await _isar.isarAyahReviewRecords.put(projection);
      await _isar.isarV2Sessions.put(checkpoint);
      await _effects.put(
        eventId: requestedEventId,
        ownerId: ownerId,
        audience: audience.name,
        effectType: 'dailyPlanReconciliation',
        receiptKey: 'daily-plan:$requestedEventId',
        createdAt: now,
      );
      await _effects.put(
        eventId: requestedEventId,
        ownerId: ownerId,
        audience: audience.name,
        effectType: 'sync',
        receiptKey: 'sync:$requestedEventId',
        createdAt: now,
      );
      if (nextState.phase == V2SessionPhase.completed) {
        await _effects.enqueueCompletionEffects(
          eventId: requestedEventId,
          ownerId: ownerId,
          audience: audience.name,
          sessionId: sessionId,
          activityDelta: nextState.totalAyahsInBlock,
          includeCertificate: !manuallyAssessed,
          createdAt: now,
        );
      }

      return V2ReviewOutcomeCommitResult(
        eventId: requestedEventId,
        sessionId: sessionId,
        alreadyCommitted: false,
      );
    });
  }

  /// Persists a completed block-review checkpoint and its completion evidence.
  /// Block review has no single ayah SRS projection to update; individual ayah
  /// passes were committed earlier. It still needs an atomic terminal record.
  Future<V2ReviewOutcomeCommitResult> commitBlockReviewCompletion({
    required V2SessionState previousState,
    required V2SessionState nextState,
    required String taskId,
    bool manuallyAssessed = false,
    double? similarityScore,
    String? eventId,
  }) async {
    if (nextState.phase != V2SessionPhase.completed) {
      throw ArgumentError.value(
        nextState.phase,
        'nextState',
        'must be completed',
      );
    }
    final ownerId = _owner.currentOwnerId;
    const audience = ReviewRecordReadScope.adult;
    final sessionKey = IsarV2Session.keyFor(
      ownerId: ownerId,
      audience: MemorizationAudience.adult,
      surahId: nextState.surahId,
    );
    final now = _now().toUtc();
    final requestedEventId = eventId ?? 'event-${_idGenerator()}';
    return _isar.writeTxn(() async {
      final existingByEventId = await _isar.isarReviewEvidenceEvents
          .filter()
          .eventIdEqualTo(requestedEventId)
          .findFirst();
      if (existingByEventId != null) {
        _validateEventIdReuse(existingByEventId, ownerId, audience, taskId);
        return V2ReviewOutcomeCommitResult(
          eventId: existingByEventId.eventId,
          sessionId: existingByEventId.sessionId,
          alreadyCommitted: true,
        );
      }
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
      final currentAyah = previousState.currentAyah;
      await _isar.isarReviewEvidenceEvents.put(
        IsarReviewEvidenceEvent()
          ..eventId = requestedEventId
          ..idempotencyKey = finalOutcomeKey
          ..sessionId = sessionId
          ..taskId = taskId
          ..ownerId = ownerId
          ..audience = audience.name
          ..surahId = previousState.surahId
          ..ayahNumber = currentAyah.numberInSurah
          ..eventTypeIndex = ReviewEvidenceEventType.finalOutcome.index
          ..assessmentIndex =
              (manuallyAssessed
                      ? ReviewEvidenceAssessment.manual
                      : ReviewEvidenceAssessment.automatic)
                  .index
          ..outcomeIndex = ReviewEvidenceOutcome.passed.index
          ..similarityScore = manuallyAssessed ? null : similarityScore
          ..attemptCount = 1
          ..failureCount = previousState.failureTracker.totalFailures
          ..hintLevelIndex = V2HintLevel.none.index
          ..occurredAt = now
          ..committedAt = now
          ..studyDayKey = V2ReviewOutcomeCommitSupport.studyDayKey(now),
      );
      final checkpoint = V2ReviewOutcomeCommitSupport.checkpointFromState(
        nextState,
        ownerId: ownerId,
        sessionId: sessionId,
      )..id = existingSession?.id ?? Isar.autoIncrement;
      await _isar.isarV2Sessions.put(checkpoint);
      await _effects.put(
        eventId: requestedEventId,
        ownerId: ownerId,
        audience: audience.name,
        effectType: 'sync',
        receiptKey: 'sync:$requestedEventId',
        createdAt: now,
      );
      await _effects.enqueueCompletionEffects(
        eventId: requestedEventId,
        ownerId: ownerId,
        audience: audience.name,
        sessionId: sessionId,
        activityDelta: nextState.totalAyahsInBlock,
        includeCertificate: !manuallyAssessed,
        createdAt: now,
      );
      return V2ReviewOutcomeCommitResult(
        eventId: requestedEventId,
        sessionId: sessionId,
        alreadyCommitted: false,
      );
    });
  }

  /// Persists one failed automatic recitation attempt and its next checkpoint.
  ///
  /// A failure is evidence even when the learner succeeds later in the same
  /// session. The monotonically increasing failure count supplies the stable
  /// idempotency suffix, so an app kill after the transaction but before the
  /// UI transition cannot duplicate the same attempt on retry.
  Future<V2ReviewOutcomeCommitResult> commitFailedAutomaticAttempt({
    required V2SessionState previousState,
    required V2SessionState nextState,
    required String taskId,
    double? similarityScore,
    String? eventId,
  }) async {
    const audience = ReviewRecordReadScope.adult;
    final ownerId = _owner.currentOwnerId;
    final sessionKey = IsarV2Session.keyFor(
      ownerId: ownerId,
      audience: MemorizationAudience.adult,
      surahId: previousState.surahId,
    );
    final now = _now().toUtc();
    final requestedEventId = eventId ?? 'event-${_idGenerator()}';

    return _isar.writeTxn(() async {
      final existingByEventId = await _isar.isarReviewEvidenceEvents
          .filter()
          .eventIdEqualTo(requestedEventId)
          .findFirst();
      if (existingByEventId != null) {
        _validateEventIdReuse(existingByEventId, ownerId, audience, taskId);
        return V2ReviewOutcomeCommitResult(
          eventId: existingByEventId.eventId,
          sessionId: existingByEventId.sessionId,
          alreadyCommitted: true,
        );
      }
      final existingSession = await _isar.isarV2Sessions
          .filter()
          .sessionKeyEqualTo(sessionKey)
          .findFirst();
      final sessionId =
          V2ReviewOutcomeCommitSupport.nonEmpty(existingSession?.sessionId) ??
          'session-${_idGenerator()}';
      // A failed block review may select a different ayah for remediation.
      // Store the affected ayah rather than whichever ayah was active before
      // the block began.
      final currentAyah = nextState.currentAyah;
      final recordedFailures = nextState.failureTracker.failureCountFor(
        nextState.surahId,
        currentAyah.numberInSurah,
      );
      // The engine increments this value for a real failed recitation. The
      // fallback prevents a malformed engine output from using an empty key
      // while remaining idempotent for that exact checkpoint.
      final attemptNumber = recordedFailures > 0 ? recordedFailures : 1;
      final attemptKey = '$sessionId|$taskId|attempt:$attemptNumber';
      final existingEvent = await _isar.isarReviewEvidenceEvents
          .filter()
          .idempotencyKeyEqualTo(attemptKey)
          .findFirst();
      if (existingEvent != null) {
        return V2ReviewOutcomeCommitResult(
          eventId: existingEvent.eventId,
          sessionId: sessionId,
          alreadyCommitted: true,
        );
      }

      await _isar.isarReviewEvidenceEvents.put(
        IsarReviewEvidenceEvent()
          ..eventId = requestedEventId
          ..idempotencyKey = attemptKey
          ..sessionId = sessionId
          ..taskId = taskId
          ..ownerId = ownerId
          ..audience = audience.name
          ..surahId = nextState.surahId
          ..ayahNumber = currentAyah.numberInSurah
          ..eventTypeIndex = ReviewEvidenceEventType.attempt.index
          ..assessmentIndex = ReviewEvidenceAssessment.automatic.index
          ..outcomeIndex = ReviewEvidenceOutcome.failed.index
          ..similarityScore = similarityScore
          ..attemptCount = attemptNumber
          ..failureCount = recordedFailures
          ..hintLevelIndex = previousState.hintTracker
              .levelFor(nextState.surahId, currentAyah.numberInSurah)
              .index
          ..occurredAt = now
          ..committedAt = now
          ..studyDayKey = V2ReviewOutcomeCommitSupport.studyDayKey(now),
      );
      final checkpoint = V2ReviewOutcomeCommitSupport.checkpointFromState(
        nextState,
        ownerId: ownerId,
        sessionId: sessionId,
      )..id = existingSession?.id ?? Isar.autoIncrement;
      await _isar.isarV2Sessions.put(checkpoint);
      await _effects.put(
        eventId: requestedEventId,
        ownerId: ownerId,
        audience: audience.name,
        effectType: 'sync',
        receiptKey: 'sync:$requestedEventId',
        createdAt: now,
      );
      return V2ReviewOutcomeCommitResult(
        eventId: requestedEventId,
        sessionId: sessionId,
        alreadyCommitted: false,
      );
    });
  }

  void _validateEventIdReuse(
    IsarReviewEvidenceEvent event,
    String ownerId,
    ReviewRecordReadScope audience,
    String taskId,
  ) {
    if (event.ownerId == ownerId &&
        event.audience == audience.name &&
        event.taskId == taskId) {
      return;
    }
    throw StateError('review_event_id_reused_for_different_task');
  }
}
