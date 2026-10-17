import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';
import 'package:talia_quran/core/memorization/v2/kids_review_outcome_committer.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_streak_store.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_evidence_event.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

import '../../../../helpers/isar_test_core.dart';

/// Item 20 — guardian-assessed recitation feeds the existing kids commit
/// path (`commitPass(manuallyAssessed: true)`), never new engine logic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepository repository;
  late _CountingRecorder recorder;
  late Isar isar;
  late Directory tempDir;
  const owner = FixedRecordOwnerProvider('owner-a');
  final cubits = <KidsModeCubit>[];

  KidsModeCubit build() {
    final cubit = KidsModeCubit(
      GetKidsProgressUsecase(repository),
      GetKidsJourneyUsecase(repository),
      AwardKidsPointsUsecase(repository),
      _FakeAchievementService(),
      _UnusedQuranRepository(),
      V2SessionEngine(),
      V2SessionReviewAdapter(
        repository: repository,
        scheduler: const ScheduleNextReviewUsecase(),
      ),
      _FakeStreakService(),
      recorder,
      null,
      (pin) async => pin == '1234',
      null,
      null,
      null,
      null,
      KidsReviewOutcomeCommitter(
        isar: isar,
        owner: owner,
        scheduler: const ScheduleNextReviewUsecase(),
      ),
    );
    cubits.add(cubit);
    return cubit;
  }

  Future<IsarAyahReviewRecord?> recordFor(ReviewRecordReadScope audience) =>
      isar.isarAyahReviewRecords.getByCompositeKey(
        ReviewRecordIdentity(
          ownerUserId: 'owner-a',
          audience: audience,
          surahId: 114,
          ayahNumber: 1,
        ).storageKey,
      );

  /// Loads a fresh ayah and completes the required listens.
  Future<KidsModeCubit> loadedAfterListens() async {
    final cubit = build();
    await cubit.load(114, 1, 'ayah text');
    cubit.debugSetLoopCount(cubit.maxLoops);
    return cubit;
  }

  setUp(() async {
    repository = _FakeRepository();
    recorder = _CountingRecorder();
    await initializeIsarCoreForTests();
    tempDir = await Directory.systemTemp.createTemp('talia_kids_guardian_');
    isar = await Isar.open(
      [
        IsarAyahReviewRecordSchema,
        IsarV2SessionSchema,
        IsarReviewEvidenceEventSchema,
        IsarReviewEffectOutboxSchema,
      ],
      directory: tempDir.path,
      name: 'kids_guardian_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    for (final cubit in cubits) {
      await cubit.close();
    }
    cubits.clear();
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('a wrong or cancelled PIN enters no mode and saves nothing', () async {
    final cubit = await loadedAfterListens();

    final started = await startKidsGuardianRecitation(cubit, () async => false);

    expect(started, isFalse);
    expect((cubit.state as KidsModeLoaded).isGuardianAssessing, isFalse);
    expect(
      await cubit.submitGuardianAssessment(PerformanceRating.excellent),
      isFalse,
    );
    expect(repository.awardCalls, 0);
    expect(await isar.isarReviewEvidenceEvents.count(), 0);
  });

  test('a verified guardian opens the mode with the ayah hidden', () async {
    final cubit = await loadedAfterListens();

    expect(await startKidsGuardianRecitation(cubit, () async => true), isTrue);

    final state = cubit.state as KidsModeLoaded;
    expect(state.isGuardianAssessing, isTrue);
    // Recall from memory: the page shows the hidden-ayah card.
    expect(state.sessionState.phase, V2SessionPhase.memorizing);
    expect(state.isRecallingFromMemory, isTrue);
  });

  test('the mode waits for the required listens', () async {
    final cubit = build();
    await cubit.load(114, 1, 'ayah text');

    expect(await cubit.enterGuardianRecitation(), isFalse);
    expect((cubit.state as KidsModeLoaded).isGuardianAssessing, isFalse);
  });

  test('«excellent» saves once, manually assessed, as excellent', () async {
    final cubit = await loadedAfterListens();
    await cubit.enterGuardianRecitation();

    expect(
      await cubit.submitGuardianAssessment(PerformanceRating.excellent),
      isTrue,
    );

    final state = cubit.state as KidsModeLoaded;
    expect(state.isCompleted, isTrue);
    final events = await isar.isarReviewEvidenceEvents.where().findAll();
    expect(events, hasLength(1));
    expect(
      events.single.assessmentIndex,
      ReviewEvidenceAssessment.manual.index,
    );
    expect(events.single.ratingIndex, PerformanceRating.excellent.index);
    expect(repository.awardCalls, 1);
    expect(repository.lastMasteryRating, PerformanceRating.excellent);
    expect(repository.markCalls, 0, reason: 'the kids committer is used');
  });

  test('«needs review» saves as average', () async {
    final cubit = await loadedAfterListens();
    await cubit.enterGuardianRecitation();

    await cubit.submitGuardianAssessment(PerformanceRating.average);

    final events = await isar.isarReviewEvidenceEvents.where().findAll();
    expect(events.single.ratingIndex, PerformanceRating.average.index);
    expect(repository.lastMasteryRating, PerformanceRating.average);
  });

  test('only excellent or average are accepted', () async {
    final cubit = await loadedAfterListens();
    await cubit.enterGuardianRecitation();

    expect(
      await cubit.submitGuardianAssessment(PerformanceRating.weak),
      isFalse,
    );
    expect(repository.awardCalls, 0);
    expect(await isar.isarReviewEvidenceEvents.count(), 0);
  });

  test('«let us retry» saves nothing and keeps the mode', () async {
    final cubit = await loadedAfterListens();
    await cubit.enterGuardianRecitation();

    cubit.retryGuardianRecitation();

    final state = cubit.state as KidsModeLoaded;
    expect(state.isGuardianAssessing, isTrue);
    expect(state.isCompleted, isFalse);
    expect(repository.awardCalls, 0);
    expect(await isar.isarReviewEvidenceEvents.count(), 0);
  });

  test('a double tap saves once', () async {
    final cubit = await loadedAfterListens();
    await cubit.enterGuardianRecitation();

    await Future.wait([
      cubit.submitGuardianAssessment(PerformanceRating.excellent),
      cubit.submitGuardianAssessment(PerformanceRating.excellent),
    ]);
    await cubit.submitGuardianAssessment(PerformanceRating.average);

    expect(repository.awardCalls, 1);
    expect(await isar.isarReviewEvidenceEvents.count(), 1);
    expect((await recordFor(ReviewRecordReadScope.kids))!.totalReviews, 1);
  });

  test('the microphone never starts in the mode', () async {
    final cubit = await loadedAfterListens();
    await cubit.enterGuardianRecitation();

    await cubit.startRecording();

    expect(recorder.captureCalls, 0);
    expect((cubit.state as KidsModeLoaded).isRecording, isFalse);
  });

  test('the saved record is a kids record, never an adult one', () async {
    final cubit = await loadedAfterListens();
    await cubit.enterGuardianRecitation();

    await cubit.submitGuardianAssessment(PerformanceRating.excellent);

    final kids = await recordFor(ReviewRecordReadScope.kids);
    expect(kids, isNotNull);
    expect(kids!.audience, ReviewRecordReadScope.kids.name);
    expect(kids.createdByModeIndex, ReviewRecordCreatedByMode.kidsMode.index);
    expect(await recordFor(ReviewRecordReadScope.adult), isNull);
    final event =
        (await isar.isarReviewEvidenceEvents.where().findAll()).single;
    expect(event.audience, ReviewRecordReadScope.kids.name);
  });

  test('a guardian grade earns the manual-path reward, no bonus', () async {
    final cubit = await loadedAfterListens();
    await cubit.enterGuardianRecitation();

    await cubit.submitGuardianAssessment(PerformanceRating.excellent);

    // Same award inputs as the existing manual completion: the hint count
    // stays 1, so the first-try excellence bonus is never granted.
    expect(repository.lastHintCount, 1);
    expect(repository.lastMissionType, KidsMissionType.newMemorization);
  });
}

class _FakeRepository implements MemorizationPlusRepository {
  int awardCalls = 0;
  int markCalls = 0;
  PerformanceRating? lastMasteryRating;
  int? lastHintCount;
  KidsMissionType? lastMissionType;

  @override
  Future<Either<Failure, KidsProgress>> getKidsProgress() async =>
      const Right(KidsProgress.initial());

  @override
  Future<Either<Failure, List<KidsJourneyStage>>> getKidsJourney({
    required int surahId,
  }) async => const Right([
    KidsJourneyStage(
      stageNumber: 1,
      surahId: 114,
      startAyah: 1,
      endAyah: 6,
      completedAyahs: [],
      status: KidsJourneyStageStatus.current,
    ),
  ]);

  @override
  Future<Either<Failure, KidsCompletionResult>> awardKidsPoints({
    bool completionAuthorized = false,
    String? sessionId,
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    KidsMissionType missionType = KidsMissionType.newMemorization,
    List<int> ayahNumbers = const [],
    int durationSeconds = 0,
    int attemptCount = 1,
    int hintCount = 0,
    PerformanceRating masteryRating = PerformanceRating.excellent,
  }) async {
    awardCalls++;
    lastMasteryRating = masteryRating;
    lastHintCount = hintCount;
    lastMissionType = missionType;
    // Let a concurrent second tap reach the cubit while this one is pending.
    await Future<void>.delayed(Duration.zero);
    return const Right(
      KidsCompletionResult(
        progress: KidsProgress.initial(),
        pointsEarned: 10,
        starsEarned: 1,
        alreadyCompleted: false,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> saveReviewRecord(
    AyahReviewRecord record,
  ) async {
    markCalls++;
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAchievementService implements AchievementService {
  @override
  Future<List<CertificateAward>> checkAndUnlockCertificates({
    required bool isKids,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedQuranRepository implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakService implements KidsStreakStore {
  @override
  Future<void> recordActivity({int activityDelta = 1}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountingRecorder implements KidsRecitationRecorder {
  int captureCalls = 0;

  @override
  Future<KidsRecitationCaptureResult> capture({
    Completer<KidsRecitationCaptureResult>? externalCompleter,
  }) async {
    captureCalls++;
    return const KidsRecitationCaptureResult.captured(words: 'ayah text');
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
