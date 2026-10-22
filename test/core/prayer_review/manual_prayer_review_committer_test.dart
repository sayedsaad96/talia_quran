import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';
import 'package:talia_quran/core/memorization/v2/self_grade.dart';
import 'package:talia_quran/core/prayer_review/manual_prayer_review_committer.dart';
import 'package:talia_quran/core/services/activity_event_recorder.dart';
import 'package:talia_quran/core/storage/app_isar.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import 'package:talia_quran/features/home/domain/repositories/activity_feed_repository.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_evidence_event.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_review/data/models/isar_prayer_review_receipt.dart';
import 'package:talia_quran/features/prayer_review/data/models/isar_prayer_review_assignment.dart';
import 'package:talia_quran/features/prayer_review/data/repositories/isar_prayer_review_repository.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_authority.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';

import '../../helpers/isar_test_core.dart';

void main() {
  late Directory directory;
  late Isar isar;
  late AccountDataBarrier barrier;
  late PrayerReviewAuthority authority;
  late ManualPrayerReviewCommitter committer;
  var adult = true;
  final now = DateTime.utc(2026, 10, 20, 12);
  final day =
      '${now.toLocal().year}-'
      '${now.toLocal().month.toString().padLeft(2, '0')}-'
      '${now.toLocal().day.toString().padLeft(2, '0')}';

  PrayerReviewSelection selection({PrayerKey prayer = PrayerKey.dhuhr}) =>
      PrayerReviewSelection(
        ownerId: 'owner',
        localDayKey: day,
        prayerKey: prayer,
        scheduledAt: now,
        selectedAt: now.subtract(const Duration(hours: 1)),
        surahId: 2,
        startAyah: 1,
        endAyah: 3,
      );

  setUpAll(initializeIsarCoreForTests);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    barrier = AccountDataBarrier.forPreferences(prefs)
      ..owner = const FixedRecordOwnerProvider('owner');
    authority = PrayerReviewAuthority(
      ownerId: 'owner',
      lease: barrier.capture(),
    );
    adult = true;
    directory = await Directory(
      '.superpowers/tmp',
    ).createTemp('manual_prayer_');
    isar = await Isar.open(
      appIsarSchemas,
      directory: directory.path,
      name: 'manual_${DateTime.now().microsecondsSinceEpoch}',
    );
    committer = ManualPrayerReviewCommitter(
      isar: isar,
      barrier: barrier,
      scheduler: const ScheduleNextReviewUsecase(),
      isEnabled: () => true,
      readAdultEligibility: () async => adult,
      now: () => now,
    );
    await isar.writeTxn(() async {
      for (final prayer in [PrayerKey.dhuhr, PrayerKey.asr]) {
        await isar.isarPrayerReviewAssignments.put(
          IsarPrayerReviewRepository.assignmentFrom(selection(prayer: prayer)),
        );
      }
      for (var ayah = 1; ayah <= 3; ayah++) {
        final identity = ReviewRecordIdentity(
          ownerUserId: 'owner',
          audience: ReviewRecordReadScope.adult,
          surahId: 2,
          ayahNumber: ayah,
        );
        await isar.isarAyahReviewRecords.put(
          IsarAyahReviewRecord.fromModel(
              AyahReviewRecordModel.fromEntity(
                AyahReviewRecordModel.initial(2, ayah).copyWith(
                  strengthLevel: 6,
                  totalReviews: 2,
                  createdByMode: ReviewRecordCreatedByMode.v2Session,
                ),
              ),
            )
            ..compositeKey = identity.storageKey
            ..ownerUserId = 'owner'
            ..audience = 'adult',
        );
      }
    });
  });
  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    expect(
      directory.absolute.path.startsWith(
        Directory('.superpowers/tmp').absolute.path,
      ),
      isTrue,
    );
    await directory.delete(recursive: true);
  });

  for (final grade in V2SelfGrade.values) {
    test(
      '$grade writes one manual result per ayah without session effects',
      () async {
        final result = await committer.commit(
          selection: selection(),
          grade: grade,
          authority: authority,
        );
        expect(result.alreadyCommitted, isFalse);
        expect(await isar.isarV2Sessions.count(), 0);
        final evidence = await isar.isarReviewEvidenceEvents.where().findAll();
        expect(evidence, hasLength(3));
        // The server's logical key (session, task, type, attempt) has no ayah
        // number: each ayah's event must be distinct under it, or the server
        // rejects every ayah after the first.
        expect(
          evidence
              .map(
                (e) =>
                    '${e.sessionId}|${e.taskId}|${e.eventTypeIndex}|'
                    '${e.attemptCount}',
              )
              .toSet(),
          hasLength(3),
        );
        for (final event in evidence) {
          expect(event.assessmentIndex, ReviewEvidenceAssessment.manual.index);
          expect(event.similarityScore, isNull);
          expect(event.failureCount, 0);
          expect(event.attemptCount, 1);
          expect(
            event.outcomeIndex,
            (grade == V2SelfGrade.forgot
                    ? ReviewEvidenceOutcome.failed
                    : ReviewEvidenceOutcome.passed)
                .index,
          );
        }
        final effects = await isar.isarReviewEffectOutboxs.where().findAll();
        expect(effects.where((e) => e.effectType == 'sync'), hasLength(3));
        expect(
          effects.where((e) => e.effectType == 'dailyPlanReconciliation'),
          hasLength(grade == V2SelfGrade.forgot ? 0 : 3),
        );
        expect(
          effects.every(
            (e) => {'sync', 'dailyPlanReconciliation'}.contains(e.effectType),
          ),
          isTrue,
        );
        expect(await isar.isarPrayerReviewReceipts.count(), 1);
        expect(
          (await isar.isarAyahReviewRecords.where().findAll()).map(
            (r) => r.totalReviews,
          ),
          everyElement(3),
        );
      },
    );
  }

  test(
    'concurrent different-prayer and grade retries preserve first decision',
    () async {
      final results = await Future.wait([
        committer.commit(
          selection: selection(),
          grade: V2SelfGrade.mastered,
          authority: authority,
        ),
        committer.commit(
          selection: selection(prayer: PrayerKey.asr),
          grade: V2SelfGrade.forgot,
          authority: authority,
        ),
      ]);
      expect(results.where((r) => r.alreadyCommitted), hasLength(1));
      expect(results.first.receipt.eventIds, results.last.receipt.eventIds);
      expect(await isar.isarReviewEvidenceEvents.count(), 3);
      expect(
        (await isar.isarAyahReviewRecords.where().findAll()).map(
          (r) => r.totalReviews,
        ),
        everyElement(3),
      );
    },
  );

  test('child and stale authority cannot write any review', () async {
    adult = false;
    await expectLater(
      committer.commit(
        selection: selection(),
        grade: V2SelfGrade.mastered,
        authority: authority,
      ),
      throwsStateError,
    );
    adult = true;
    barrier.invalidate();
    await expectLater(
      committer.commit(
        selection: selection(),
        grade: V2SelfGrade.mastered,
        authority: authority,
      ),
      throwsA(isA<AccountDataUnavailableException>()),
    );
    expect(await isar.isarReviewEvidenceEvents.count(), 0);
    expect(await isar.isarPrayerReviewReceipts.count(), 0);
  });

  test('a profile changed while queued cannot commit adult reviews', () async {
    final release = Completer<void>();
    final started = Completer<void>();
    final held = barrier.run((_) async {
      started.complete();
      await release.future;
    });
    await started.future;
    final saving = committer.commit(
      selection: selection(),
      grade: V2SelfGrade.mastered,
      authority: authority,
    );
    await Future<void>.delayed(Duration.zero);
    adult = false;
    release.complete();
    await held;
    await expectLater(saving, throwsStateError);
    expect(await isar.isarReviewEvidenceEvents.count(), 0);
    expect(await isar.isarPrayerReviewReceipts.count(), 0);
  });

  test('missing projection rolls back earlier ayahs and all effects', () async {
    await isar.writeTxn(() async {
      await isar.isarAyahReviewRecords
          .filter()
          .ayahNumberEqualTo(3)
          .deleteAll();
    });
    await expectLater(
      committer.commit(
        selection: selection(),
        grade: V2SelfGrade.mastered,
        authority: authority,
      ),
      throwsStateError,
    );
    expect(await isar.isarReviewEvidenceEvents.count(), 0);
    expect(await isar.isarReviewEffectOutboxs.count(), 0);
    expect(await isar.isarPrayerReviewReceipts.count(), 0);
    expect(
      (await isar.isarAyahReviewRecords.where().findAll()).map(
        (r) => r.totalReviews,
      ),
      everyElement(2),
    );
  });

  test('an existing live checkpoint is byte-for-byte unchanged', () async {
    await isar.writeTxn(() async {
      await isar.isarV2Sessions.put(
        IsarV2Session()
          ..sessionKey = 'live'
          ..sessionId = 'live-id'
          ..ownerId = 'owner'
          ..surahId = 2
          ..blockAyahNumbersCsv = '1,2,3'
          ..currentAyahIndex = 1
          ..phaseIndex = 2
          ..passedAyahNumbersCsv = '1'
          ..failureCountsCsv = '2:2'
          ..hintLevelsCsv = '2:1'
          ..blockReviewRequired = true
          ..savedAt = now,
      );
    });
    final before = await isar.isarV2Sessions.where().exportJson();
    await committer.commit(
      selection: selection(),
      grade: V2SelfGrade.forgot,
      authority: authority,
    );
    expect(await isar.isarV2Sessions.where().exportJson(), before);
  });

  test('unsaved or altered frozen selection cannot be committed', () async {
    final altered = PrayerReviewSelection(
      ownerId: 'owner',
      localDayKey: day,
      prayerKey: PrayerKey.dhuhr,
      scheduledAt: now,
      selectedAt: now,
      surahId: 2,
      startAyah: 1,
      endAyah: 2,
    );
    await expectLater(
      committer.commit(
        selection: altered,
        grade: V2SelfGrade.mastered,
        authority: authority,
      ),
      throwsStateError,
    );
    expect(await isar.isarReviewEvidenceEvents.count(), 0);
  });

  group('activity parity', () {
    test('a new commit records one review activity; a replay adds none', () async {
      final repo = _FeedRepo();
      final withActivity = ManualPrayerReviewCommitter(
        isar: isar,
        barrier: barrier,
        scheduler: const ScheduleNextReviewUsecase(),
        isEnabled: () => true,
        readAdultEligibility: () async => true,
        now: () => now,
        activityRecorder: ActivityEventRecorder(repo),
      );
      await withActivity.commit(
        selection: selection(),
        grade: V2SelfGrade.mastered,
        authority: authority,
      );
      await withActivity.commit(
        selection: selection(),
        grade: V2SelfGrade.mastered,
        authority: authority,
      );
      expect(repo.events, hasLength(1));
      final event = repo.events.single;
      expect(event.kind, ActivityEventKind.review);
      expect(event.idempotencyKey, startsWith('review|prayer|'));
      expect(
        [event.surahId, event.startAyah, event.endAyah],
        [2, 1, 3],
      );
    });

    test('a failing recorder never fails the commit', () async {
      final failing = ManualPrayerReviewCommitter(
        isar: isar,
        barrier: barrier,
        scheduler: const ScheduleNextReviewUsecase(),
        isEnabled: () => true,
        readAdultEligibility: () async => true,
        now: () => now,
        activityRecorder: ActivityEventRecorder(_FeedRepo(fail: true)),
      );
      final result = await failing.commit(
        selection: selection(),
        grade: V2SelfGrade.mastered,
        authority: authority,
      );
      expect(result.alreadyCommitted, isFalse);
    });
  });

  group('Isha after midnight', () {
    Future<ManualPrayerReviewResult> commitAt(
      DateTime localNow,
      PrayerKey prayer,
    ) async {
      final sel = PrayerReviewSelection(
        ownerId: 'owner',
        localDayKey: '2026-10-20',
        prayerKey: prayer,
        scheduledAt: DateTime(2026, 10, 20, 20).toUtc(),
        selectedAt: DateTime(2026, 10, 20, 18).toUtc(),
        surahId: 2,
        startAyah: 1,
        endAyah: 3,
      );
      await isar.writeTxn(
        () => isar.isarPrayerReviewAssignments.put(
          IsarPrayerReviewRepository.assignmentFrom(sel),
        ),
      );
      return ManualPrayerReviewCommitter(
        isar: isar,
        barrier: barrier,
        scheduler: const ScheduleNextReviewUsecase(),
        isEnabled: () => true,
        readAdultEligibility: () async => true,
        now: () => localNow.toUtc(),
      ).commit(selection: sel, grade: V2SelfGrade.mastered, authority: authority);
    }

    test('yesterday Isha can be graded before 04:00', () async {
      final result = await commitAt(DateTime(2026, 10, 21, 1, 30), PrayerKey.isha);
      expect(result.alreadyCommitted, isFalse);
    });

    test('yesterday Isha expires from 04:00', () async {
      await expectLater(
        commitAt(DateTime(2026, 10, 21, 4), PrayerKey.isha),
        throwsStateError,
      );
    });

    test('other prayers keep the same-day rule after midnight', () async {
      await expectLater(
        commitAt(DateTime(2026, 10, 21, 1, 30), PrayerKey.maghrib),
        throwsStateError,
      );
    });
  });

  test('existing evidence without a receipt is not rescheduled or rejected', () async {
    final key = PrayerReviewIdentity.receiptKey(
      ownerId: 'owner',
      localDayKey: day,
      surahId: 2,
      startAyah: 1,
      endAyah: 3,
    );
    await isar.writeTxn(
      () => isar.isarReviewEvidenceEvents.put(
        IsarReviewEvidenceEvent()
          ..eventId = 'prayer-review:$key:1'
          ..idempotencyKey = 'prayer-review:$key:1:final'
          ..sessionId = 'prayer-review:$key'
          ..taskId = 'old'
          ..ownerId = 'owner'
          ..audience = 'adult'
          ..surahId = 2
          ..ayahNumber = 1
          ..eventTypeIndex = ReviewEvidenceEventType.finalOutcome.index
          ..assessmentIndex = ReviewEvidenceAssessment.manual.index
          ..outcomeIndex = ReviewEvidenceOutcome.passed.index
          ..ratingIndex = 0
          ..attemptCount = 1
          ..failureCount = 0
          ..hintLevelIndex = 0
          ..occurredAt = now
          ..committedAt = now
          ..studyDayKey = day,
      ),
    );
    final result = await committer.commit(
      selection: selection(),
      grade: V2SelfGrade.mastered,
      authority: authority,
    );
    expect(result.alreadyCommitted, isFalse);
    expect(await isar.isarPrayerReviewReceipts.count(), 1);
    expect(await isar.isarReviewEvidenceEvents.count(), 3);
    final totals = {
      for (final r in await isar.isarAyahReviewRecords.where().findAll())
        r.ayahNumber: r.totalReviews,
    };
    expect(totals, {1: 2, 2: 3, 3: 3});
  });
}

class _FeedRepo extends Fake implements ActivityFeedRepository {
  _FeedRepo({this.fail = false});
  final bool fail;
  final events = <ActivityEvent>[];
  @override
  Future<void> append(ActivityEvent event, {bool replace = false}) async {
    if (fail) throw StateError('feed down');
    events.add(event);
  }
}
