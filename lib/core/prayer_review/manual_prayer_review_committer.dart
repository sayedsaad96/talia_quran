import 'package:isar_community/isar.dart';
import '../../features/home/domain/entities/activity_event.dart';
import '../../features/prayer_companion/domain/entities/prayer_companion.dart';
import '../services/activity_event_recorder.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/memorization_plus/data/models/isar_review_evidence_event.dart';
import '../../features/memorization_plus/data/models/memorization_models.dart';
import '../../features/memorization_plus/domain/entities/ayah_review_record.dart';
import '../../features/prayer_review/data/models/isar_prayer_review_receipt.dart';
import '../../features/prayer_review/data/models/isar_prayer_review_assignment.dart';
import '../../features/prayer_review/data/repositories/isar_prayer_review_repository.dart';
import '../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../features/prayer_review/domain/entities/prayer_review_authority.dart';
import '../../features/prayer_review/domain/entities/prayer_review_selection.dart';
import '../identity/account_data_barrier.dart';
import '../memorization/v2/self_grade.dart';
import '../memorization/v2/review_outcome_commit_support.dart';
import '../memorization/review_record_identity.dart';
import '../memorization/review_record_audience_scope.dart';
import '../memorization/review_record_filters.dart';
import '../progress/progress_events_bus.dart';
import '../progress/progress_changed_reason.dart';

final class ManualPrayerReviewResult {
  const ManualPrayerReviewResult({
    required this.receipt,
    required this.alreadyCommitted,
  });
  final PrayerReviewReceipt receipt;
  final bool alreadyCommitted;
}

final class ManualPrayerReviewCommitter {
  ManualPrayerReviewCommitter({
    required this._isar,
    required this._barrier,
    required this._scheduler,
    required this._isEnabled,
    required this._readAdultEligibility,
    DateTime Function()? now,
    ProgressEventsBus? progressEvents,
    ActivityEventRecorder? activityRecorder,
  }) : _now = now ?? DateTime.now,
       _events = progressEvents,
       _activity = activityRecorder;

  final Isar _isar;
  final AccountDataBarrier _barrier;
  final ScheduleNextReviewUsecase _scheduler;
  final bool Function() _isEnabled;
  final Future<bool> Function() _readAdultEligibility;
  final DateTime Function() _now;
  final ProgressEventsBus? _events;
  final ActivityEventRecorder? _activity;

  /// Local hour before which an Isha belongs to the previous civil day. Mirrors
  /// the tarawih night rule (kTarawihNightEndHour) without a core-to-UI import.
  static const int _ishaNightEndHour = 4;

  Future<ManualPrayerReviewResult> commit({
    required PrayerReviewSelection selection,
    required V2SelfGrade grade,
    required PrayerReviewAuthority authority,
  }) async {
    authority.check();
    PrayerReviewValidation.checkSelection(selection);
    if (!_isEnabled() || selection.ownerId != authority.ownerId) {
      throw StateError('Prayer review is unavailable');
    }
    final acceptedAt = _now().toUtc();
    final adult = await _readAdultEligibility();
    authority.check();
    if (!adult || !_isEnabled()) {
      throw StateError('Adult review is unavailable');
    }
    final result = await _barrier.run((lease) async {
      final currentAdult = await _readAdultEligibility();
      authority.check();
      if (!currentAdult || !_isEnabled()) {
        throw StateError('Adult review is unavailable');
      }
      return _isar.writeTxn(
        () => _commitTransaction(selection, grade, authority, acceptedAt),
      );
    }, authority: authority.lease);
    if (!result.alreadyCommitted) {
      _events?.notify(ProgressChangedReason.reviewRecord);
      await _recordActivity(selection, acceptedAt);
    }
    return result;
  }

  Future<void> _recordActivity(
    PrayerReviewSelection selection,
    DateTime at,
  ) async {
    final recorder = _activity;
    if (recorder == null) return;
    try {
      final key = PrayerReviewIdentity.receiptKey(
        ownerId: selection.ownerId,
        localDayKey: selection.localDayKey,
        surahId: selection.surahId,
        startAyah: selection.startAyah,
        endAyah: selection.endAyah,
      );
      await recorder.record(
        ActivityEvent(
          occurredAt: at,
          kind: ActivityEventKind.review,
          idempotencyKey: 'review|prayer|$key',
          surahId: selection.surahId,
          startAyah: selection.startAyah,
          endAyah: selection.endAyah,
        ),
      );
    } catch (_) {
      // Activity feed is decoration; the committed review must stay successful.
    }
  }

  /// Same local day, or Isha of the previous civil day before 04:00 local.
  bool _occurrenceOpen(PrayerReviewSelection selection, DateTime now) {
    if (selection.localDayKey == V2ReviewOutcomeCommitSupport.studyDayKey(now)) {
      return true;
    }
    if (selection.prayerKey != PrayerKey.isha) return false;
    final local = now.toLocal();
    if (local.hour >= _ishaNightEndHour) return false;
    final previous = DateTime(local.year, local.month, local.day - 1);
    return selection.localDayKey ==
        V2ReviewOutcomeCommitSupport.studyDayKey(previous);
  }

  Future<ManualPrayerReviewResult> _commitTransaction(
    PrayerReviewSelection selection,
    V2SelfGrade grade,
    PrayerReviewAuthority authority,
    DateTime now,
  ) async {
    authority.check();
    if (!_isEnabled()) throw StateError('Prayer review is unavailable');
    final key = PrayerReviewIdentity.receiptKey(
      ownerId: authority.ownerId,
      localDayKey: selection.localDayKey,
      surahId: selection.surahId,
      startAyah: selection.startAyah,
      endAyah: selection.endAyah,
    );
    final existing = await _isar.isarPrayerReviewReceipts
        .filter()
        .ownerIdEqualTo(authority.ownerId)
        .receiptKeyEqualTo(key)
        .findFirst();
    authority.check();
    if (existing != null) {
      return ManualPrayerReviewResult(
        receipt: IsarPrayerReviewRepository.receiptFromRow(existing),
        alreadyCommitted: true,
      );
    }
    if (!_occurrenceOpen(selection, now)) {
      throw StateError('Prayer review occurrence has expired');
    }
    await _checkFrozenSelection(selection, authority);
    return _writePassage(selection, grade, authority, now, key);
  }

  Future<void> _checkFrozenSelection(
    PrayerReviewSelection proposed,
    PrayerReviewAuthority authority,
  ) async {
    final row = await _isar.isarPrayerReviewAssignments
        .filter()
        .ownerIdEqualTo(authority.ownerId)
        .occurrenceKeyEqualTo(proposed.occurrenceKey)
        .findFirst();
    authority.check();
    if (row == null ||
        IsarPrayerReviewRepository.selectionFromRow(
              row,
            ).copyWith(promptConsumed: false) !=
            proposed.copyWith(promptConsumed: false)) {
      throw StateError('Prayer review selection is not the frozen assignment');
    }
  }

  Future<ManualPrayerReviewResult> _writePassage(
    PrayerReviewSelection selection,
    V2SelfGrade grade,
    PrayerReviewAuthority authority,
    DateTime now,
    String key,
  ) async {
    final ids = <String>[];
    for (var ayah = selection.startAyah; ayah <= selection.endAyah; ayah++) {
      final eventId = 'prayer-review:$key:$ayah';
      await _writeAyah(selection, grade, authority, now, ayah, eventId);
      authority.check();
      ids.add(eventId);
    }
    final receipt = PrayerReviewReceipt(
      ownerId: authority.ownerId,
      localDayKey: selection.localDayKey,
      surahId: selection.surahId,
      startAyah: selection.startAyah,
      endAyah: selection.endAyah,
      gradeIndex: grade.index,
      committedAt: now,
      eventIds: ids,
    );
    final saved = await PrayerReviewReceiptTransactionWriter.record(
      _isar,
      authority: authority,
      proposed: receipt,
    );
    authority.check();
    return ManualPrayerReviewResult(
      receipt: saved.receipt,
      alreadyCommitted: saved.alreadyCommitted,
    );
  }

  Future<void> _writeAyah(
    PrayerReviewSelection selection,
    V2SelfGrade grade,
    PrayerReviewAuthority authority,
    DateTime now,
    int ayah,
    String eventId,
  ) async {
    // Evidence without a receipt means this ayah's SRS and effects already
    // committed: re-scheduling would double-count and the unique index on
    // eventId/idempotencyKey would reject the put.
    final prior = await _isar.isarReviewEvidenceEvents.getByIdempotencyKey(
      '$eventId:final',
    );
    authority.check();
    if (prior != null) return;
    final identity = ReviewRecordIdentity(
      ownerUserId: authority.ownerId,
      audience: ReviewRecordReadScope.adult,
      surahId: selection.surahId,
      ayahNumber: ayah,
    );
    final current = await _isar.isarAyahReviewRecords.getByCompositeKey(
      identity.storageKey,
    );
    authority.check();
    if (current == null ||
        current.ownerUserId != authority.ownerId ||
        current.audience != 'adult' ||
        current.surahId != selection.surahId ||
        current.ayahNumber != ayah ||
        current.totalReviews < 1 ||
        !ReviewRecordFilters.isAdultCompatible(current.toModel())) {
      throw StateError('Prayer review requires an existing adult review');
    }
    final rating = V2ReviewOutcomeCommitSupport.manualGradeRating(grade);
    final scheduled = _scheduler.schedule(current.toModel(), rating, now);
    final projection =
        IsarAyahReviewRecord.fromModel(
            AyahReviewRecordModel.fromEntity(scheduled),
          )
          ..id = current.id
          ..compositeKey = identity.storageKey
          ..ownerUserId = authority.ownerId
          ..audience = 'adult'
          ..cloudDirty = true
          ..lastSyncedAt = null;
    await _isar.isarAyahReviewRecords.put(projection);
    authority.check();
    await _isar.isarReviewEvidenceEvents.put(
      _evidence(selection, grade, now, ayah, eventId, rating),
    );
    authority.check();
    await _writeEffects(eventId, authority.ownerId, grade, now);
    authority.check();
  }

  IsarReviewEvidenceEvent _evidence(
    PrayerReviewSelection selection,
    V2SelfGrade grade,
    DateTime now,
    int ayah,
    String eventId,
    PerformanceRating rating,
  ) {
    final receiptKey = PrayerReviewIdentity.receiptKey(
      ownerId: selection.ownerId,
      localDayKey: selection.localDayKey,
      surahId: selection.surahId,
      startAyah: selection.startAyah,
      endAyah: selection.endAyah,
    );
    return IsarReviewEvidenceEvent()
      ..eventId = eventId
      ..idempotencyKey = '$eventId:final'
      ..sessionId = 'prayer-review:$receiptKey'
      // One logical event per ayah: the server's ayah_review_events unique
      // key (user, session, task, type, attempt) carries no ayah number, so a
      // shared task id would make it reject every ayah after the first.
      ..taskId =
          'prayer|${selection.localDayKey}|${selection.prayerKey.name}|'
          '${selection.surahId}:${selection.startAyah}-${selection.endAyah}|'
          '$ayah'
      ..ownerId = selection.ownerId
      ..audience = 'adult'
      ..surahId = selection.surahId
      ..ayahNumber = ayah
      ..eventTypeIndex = ReviewEvidenceEventType.finalOutcome.index
      ..assessmentIndex = ReviewEvidenceAssessment.manual.index
      ..outcomeIndex =
          (grade == V2SelfGrade.forgot
                  ? ReviewEvidenceOutcome.failed
                  : ReviewEvidenceOutcome.passed)
              .index
      ..ratingIndex = rating.index
      ..similarityScore = null
      ..attemptCount = 1
      ..failureCount = 0
      ..hintLevelIndex = 0
      ..occurredAt = now
      ..committedAt = now
      ..studyDayKey = selection.localDayKey;
  }

  Future<void> _writeEffects(
    String eventId,
    String owner,
    V2SelfGrade grade,
    DateTime now,
  ) async {
    final writer = ReviewEffectOutboxWriter(_isar);
    for (final kind in [
      'sync',
      if (grade != V2SelfGrade.forgot) 'dailyPlanReconciliation',
    ]) {
      await writer.put(
        eventId: eventId,
        ownerId: owner,
        audience: 'adult',
        effectType: kind,
        receiptKey: '$kind:$eventId',
        createdAt: now,
      );
    }
  }
}
