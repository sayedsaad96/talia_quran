import 'dart:math';

import 'package:isar_community/isar.dart';

import '../../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../../features/memorization_plus/data/models/isar_review_evidence_event.dart';
import '../../../features/memorization_plus/data/models/isar_v2_session.dart';
import '../../../features/memorization_plus/data/models/memorization_models.dart';
import '../../../features/memorization_plus/domain/entities/memorization_entities.dart';
import '../../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../identity/record_owner_provider.dart';
import '../../identity/account_data_barrier.dart';
import '../similar_ayah/similar_ayah_attempt_authority.dart';
import '../similar_ayah/similar_ayah_confusion_detector.dart';
import '../../../features/memorization_plus/data/repositories/isar_confusion_pair_repository.dart';
import '../../progress/progress_changed_reason.dart';
import '../../progress/progress_events_bus.dart';
import '../review_record_audience_scope.dart';
import '../review_record_identity.dart';
import '../../../features/home/domain/entities/activity_event.dart';
import '../../services/activity_event_recorder.dart';
import 'hint_usage.dart';
import 'review_outcome_commit_support.dart';
import 'self_grade.dart';
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
    required this._owner,
    required this._scheduler,
    DateTime Function()? now,
    String Function()? idGenerator,
    this._activityRecorder,
    this._progressEvents,
    this._accountBarrier,
  }) : _isar = isar,
       _now = now ?? (() => DateTime.now().toUtc()),
       _idGenerator = idGenerator ?? V2ReviewOutcomeCommitSupport.newOpaqueId,
       _effects = ReviewEffectOutboxWriter(isar);

  final Isar _isar;
  final RecordOwnerProvider _owner;
  final ScheduleNextReviewUsecase _scheduler;
  final DateTime Function() _now;
  final String Function() _idGenerator;
  final ReviewEffectOutboxWriter _effects;
  final ActivityEventRecorder? _activityRecorder;
  final AccountDataBarrier? _accountBarrier;

  /// Per-ayah commits change progress before any completion effect runs, so
  /// read-side screens must hear about the review record directly.
  final ProgressEventsBus? _progressEvents;

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
    V2SelfGrade selfGrade = V2SelfGrade.mastered,
    double? similarityScore,
    String? eventId,
  }) async {
    final ownerId = _owner.currentOwnerId;
    const audience = ReviewRecordReadScope.adult;
    final sessionKey = IsarV2Session.keyFor(
      ownerId: ownerId,
      audience: MemorizationAudience.adult,
      surahId: nextState.surahId,
      review: nextState.isReview,
    );
    final now = _now().toUtc();
    final requestedEventId = eventId ?? 'event-${_idGenerator()}';

    final result = await _isar.writeTxn(() async {
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
          ? V2ReviewOutcomeCommitSupport.manualRatingFor(
              previousState,
              currentAyah.numberInSurah,
              selfGrade,
            )
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
      // Self-assessments are real reviews (they advance totalReviews so the
      // ayah leaves the new bucket) but their rating is capped above.
      final scheduled = _scheduler
          .schedule(base, rating, now)
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
        ..ratingIndex = rating.index
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
        launchContext: existingSession?.launchContext,
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
          isReview: nextState.isReview,
        );
      }

      return V2ReviewOutcomeCommitResult(
        eventId: requestedEventId,
        sessionId: sessionId,
        alreadyCommitted: false,
      );
    });
    if (!result.alreadyCommitted) {
      _progressEvents?.notify(ProgressChangedReason.reviewRecord);
    }
    await _recordSessionActivity(
      result: result,
      kind: ActivityEventKind.memorize,
      state: nextState,
    );
    return result;
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
      review: nextState.isReview,
    );
    final now = _now().toUtc();
    final requestedEventId = eventId ?? 'event-${_idGenerator()}';
    final result = await _isar.writeTxn(() async {
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
        launchContext: existingSession?.launchContext,
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
    await _recordSessionActivity(
      result: result,
      kind: ActivityEventKind.review,
      state: nextState,
    );
    return result;
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
    bool manuallyAssessed = false,
    double? similarityScore,
    String? eventId,
    SimilarAyahConfusionMatch? confusionMatch,
    SimilarAyahAttemptAuthority? attemptAuthority,
  }) async {
    const audience = ReviewRecordReadScope.adult;
    final ownerId = _owner.currentOwnerId;
    final sessionKey = IsarV2Session.keyFor(
      ownerId: ownerId,
      audience: MemorizationAudience.adult,
      surahId: previousState.surahId,
      review: previousState.isReview,
    );
    final now = _now().toUtc();
    final requestedEventId = eventId ?? 'event-${_idGenerator()}';
    var demotedRecord = false;

    _validateAuthority(attemptAuthority, ownerId);

    Future<V2ReviewOutcomeCommitResult> write(
      AccountDataLease? activeLease,
    ) => _isar.writeTxn(() async {
      _checkAuthority(ownerId, activeLease);
      final existingByEventId = await _isar.isarReviewEvidenceEvents
          .filter()
          .eventIdEqualTo(requestedEventId)
          .findFirst();
      _checkAuthority(ownerId, activeLease);
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
      _checkAuthority(ownerId, activeLease);
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
      _checkAuthority(ownerId, activeLease);
      if (existingEvent != null) {
        return V2ReviewOutcomeCommitResult(
          eventId: existingEvent.eventId,
          sessionId: sessionId,
          alreadyCommitted: true,
        );
      }

      if (confusionMatch != null) {
        _validateConfusionRequest(
          previousState: previousState,
          nextState: nextState,
          manuallyAssessed: manuallyAssessed,
          similarityScore: similarityScore,
          confusionMatch: confusionMatch,
          attemptAuthority: attemptAuthority,
          ownerId: ownerId,
        );
        final other = _parseAyahKey(confusionMatch.otherKey);
        try {
          await ConfusionPairTransactionWriter.record(
            _isar,
            ownerId: ownerId,
            lease: activeLease!,
            targetSurahId: nextState.surahId,
            targetAyahNumber: currentAyah.numberInSurah,
            otherSurahId: other.$1,
            otherAyahNumber: other.$2,
            occurredAt: now,
          );
        } on FormatException {
          // A corrupt stored pair loses only this attribution (the writer
          // validates before it writes). The failure itself must still
          // commit, or the learner is stuck retrying the same save.
        }
        _checkAuthority(ownerId, activeLease);
      }

      // A failed block review is real forgetting of an ayah that already
      // passed (and was scheduled) earlier in this block. Demote it once per
      // session so repeated block attempts do not stack lapses.
      final demote =
          previousState.phase == V2SessionPhase.blockReview &&
          await _isar.isarReviewEvidenceEvents
                  .filter()
                  .sessionIdEqualTo(sessionId)
                  .surahIdEqualTo(nextState.surahId)
                  .ayahNumberEqualTo(currentAyah.numberInSurah)
                  .eventTypeIndexEqualTo(ReviewEvidenceEventType.attempt.index)
                  .ratingIndexEqualTo(PerformanceRating.weak.index)
                  .findFirst() ==
              null;
      _checkAuthority(ownerId, activeLease);
      if (demote) {
        final identity = ReviewRecordIdentity(
          ownerUserId: ownerId,
          audience: audience,
          surahId: nextState.surahId,
          ayahNumber: currentAyah.numberInSurah,
        );
        final existing = await _isar.isarAyahReviewRecords.getByCompositeKey(
          identity.storageKey,
        );
        _checkAuthority(ownerId, activeLease);
        if (existing != null) {
          final demoted = _scheduler
              .schedule(existing.toModel(), PerformanceRating.weak, now)
              .copyWith(createdByMode: ReviewRecordCreatedByMode.v2Session);
          await _isar.isarAyahReviewRecords.put(
            IsarAyahReviewRecord.fromModel(
                AyahReviewRecordModel.fromEntity(demoted),
              )
              ..id = existing.id
              ..compositeKey = identity.storageKey
              ..ownerUserId = ownerId
              ..audience = audience.name
              ..cloudDirty = true
              ..lastSyncedAt = null,
          );
          _checkAuthority(ownerId, activeLease);
          demotedRecord = true;
        }
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
          ..assessmentIndex =
              (manuallyAssessed
                      ? ReviewEvidenceAssessment.manual
                      : ReviewEvidenceAssessment.automatic)
                  .index
          ..outcomeIndex = ReviewEvidenceOutcome.failed.index
          ..ratingIndex = demote ? PerformanceRating.weak.index : null
          ..similarityScore = manuallyAssessed ? null : similarityScore
          ..attemptCount = attemptNumber
          ..failureCount = recordedFailures
          ..hintLevelIndex = previousState.hintTracker
              .levelFor(nextState.surahId, currentAyah.numberInSurah)
              .index
          ..occurredAt = now
          ..committedAt = now
          ..studyDayKey = V2ReviewOutcomeCommitSupport.studyDayKey(now),
      );
      _checkAuthority(ownerId, activeLease);
      final checkpoint = V2ReviewOutcomeCommitSupport.checkpointFromState(
        nextState,
        ownerId: ownerId,
        sessionId: sessionId,
        launchContext: existingSession?.launchContext,
      )..id = existingSession?.id ?? Isar.autoIncrement;
      await _isar.isarV2Sessions.put(checkpoint);
      _checkAuthority(ownerId, activeLease);
      await _effects.put(
        eventId: requestedEventId,
        ownerId: ownerId,
        audience: audience.name,
        effectType: 'sync',
        receiptKey: 'sync:$requestedEventId',
        createdAt: now,
      );
      _checkAuthority(ownerId, activeLease);
      return V2ReviewOutcomeCommitResult(
        eventId: requestedEventId,
        sessionId: sessionId,
        alreadyCommitted: false,
      );
    });
    final result = await _runFailedWrite(
      write,
      attemptAuthority,
      confusionMatch != null,
    );
    if (demotedRecord) {
      _progressEvents?.notify(ProgressChangedReason.reviewRecord);
    }
    return result;
  }

  Future<void> _recordSessionActivity({
    required V2ReviewOutcomeCommitResult result,
    required ActivityEventKind kind,
    required V2SessionState state,
  }) async {
    if (result.alreadyCommitted) return;
    // Memorization shows on home as soon as an ayah passes, and its entry
    // grows with each passed ayah. A block review is logged once complete.
    final int? startAyah;
    final int? endAyah;
    if (kind == ActivityEventKind.memorize) {
      final passed = state.passedAyahNumbers;
      if (passed.isEmpty) return;
      startAyah = passed.reduce(min);
      endAyah = passed.reduce(max);
    } else {
      if (state.phase != V2SessionPhase.completed) return;
      final ayahs = state.blockAyahs;
      startAyah = ayahs.isEmpty ? null : ayahs.first.numberInSurah;
      endAyah = ayahs.isEmpty ? null : ayahs.last.numberInSurah;
    }
    await _activityRecorder?.record(
      ActivityEvent(
        occurredAt: _now(),
        kind: kind,
        idempotencyKey: '${kind.name}|${result.sessionId}|block',
        surahId: state.surahId,
        startAyah: startAyah,
        endAyah: endAyah,
      ),
      replace: kind == ActivityEventKind.memorize,
    );
  }

  Future<V2ReviewOutcomeCommitResult> _runFailedWrite(
    Future<V2ReviewOutcomeCommitResult> Function(AccountDataLease? lease) write,
    SimilarAyahAttemptAuthority? authority,
    bool hasConfusionMatch,
  ) {
    if (authority == null) {
      if (hasConfusionMatch) throw const FormatException('Missing authority');
      return write(null);
    }
    final barrier = _accountBarrier;
    if (barrier == null) {
      throw const FormatException('Missing account barrier');
    }
    return barrier.run(
      (lease) async {
        authority.check();
        return write(lease);
      },
      authority: authority.lease,
    );
  }

  void _validateConfusionRequest({
    required V2SessionState previousState,
    required V2SessionState nextState,
    required bool manuallyAssessed,
    required double? similarityScore,
    required SimilarAyahConfusionMatch? confusionMatch,
    required SimilarAyahAttemptAuthority? attemptAuthority,
    required String ownerId,
  }) {
    _validateAuthority(attemptAuthority, ownerId);
    if (confusionMatch == null) return;
    if (attemptAuthority == null || _accountBarrier == null || manuallyAssessed) {
      throw const FormatException('Invalid confusion attribution');
    }
    final current = nextState.currentAyah;
    final expected = '${nextState.surahId}:${current.numberInSurah}';
    final previousFailures = previousState.failureTracker.failureCountFor(
      nextState.surahId,
      current.numberInSurah,
    );
    final failures = nextState.failureTracker.failureCountFor(
      nextState.surahId,
      current.numberInSurah,
    );
    if (previousState.phase != V2SessionPhase.reciting ||
        failures <= previousFailures ||
        confusionMatch.targetKey != expected ||
        !_validScore(similarityScore) ||
        !_validScore(confusionMatch.originalScore) ||
        !_validScore(confusionMatch.candidateScore) ||
        similarityScore != confusionMatch.originalScore) {
      throw const FormatException('Invalid confusion attribution');
    }
    final other = _parseAyahKey(confusionMatch.otherKey);
    if (other.$1 == nextState.surahId && other.$2 == current.numberInSurah) {
      throw const FormatException('Invalid confusion attribution');
    }
  }

  static void _validateAuthority(
    SimilarAyahAttemptAuthority? authority,
    String ownerId,
  ) {
    if (authority == null) return;
    authority.check();
    if (authority.ownerId != ownerId) {
      throw const AccountDataUnavailableException();
    }
  }

  static bool _validScore(double? value) =>
      value != null && value.isFinite && value >= 0 && value <= 1;

  static (int, int) _parseAyahKey(String value) {
    final parts = value.split(':');
    if (parts.length != 2) throw const FormatException('Invalid ayah key');
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null || value != '$surah:$ayah') {
      throw const FormatException('Invalid ayah key');
    }
    ConfusionPairTransactionWriter.checkAyah(surah, ayah);
    return (surah, ayah);
  }

  static void _checkAuthority(String ownerId, AccountDataLease? lease) {
    if (lease != null) lease.checkOwner(ownerId);
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
