import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:isar_community/isar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';

import 'package:talia_quran/core/memorization/learning_launch_context.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';
import 'package:talia_quran/core/memorization/v2/review_outcome_committer.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/features/adult_journey/adult_journey_feature_flags.dart';
import 'package:talia_quran/features/adult_journey/application/adult_journey_launch_resolver.dart';
import 'package:talia_quran/features/adult_journey/application/adult_journey_usecases.dart';
import 'package:talia_quran/features/adult_journey/data/adult_journey_repository_impl.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_context.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/daily_review_task.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_cubit.dart';

import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/v2_session_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_confusion_pair.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_effect_outbox.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_review_evidence_event.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart';

import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

import '../features/memorization_plus/presentation/cubits/memorization_session_cubit_test.mocks.dart';
import '../helpers/isar_test_core.dart';

const _owner = FixedRecordOwnerProvider('owner-a');
const _route =
    '/memorization-v2/session?surahId=1&startAyah=1&blockSize=1&intent=review';
const _action = UnifiedJourneyAction(
  route: _route,
  priority: UnifiedJourneyPriority.p3ReviewBacklog,
  source: 'test',
  actionType: UnifiedJourneyActionType.reviewBacklog,
  intent: JourneyIntent.review,
);

/// Integrates the real daily-task decision, launch resolver, V2 engine and Isar
/// outcome transaction. Device audio/speech and corpus loading are test
/// boundaries; ayah text comes from the bundled Quran corpus. UI/Android acceptance is separate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Isar isar;
  late SharedPreferences prefs;
  late AccountDataBarrier barrier;
  late AdultJourneyRepositoryImpl preferences;
  late AdultJourneyCubit journey;
  late MemorizationSessionCubit session;

  late StreamController<PlayerState> playerStates;
  late DateTime now;

  var omitOutbox = false;

  Future<AdultJourneyContext> freshContext() async {
    final record = await isar.isarAyahReviewRecords.where().findFirst();
    final due = record != null && !record.nextReviewDate.isAfter(now);
    return AdultJourneyContext(
      ownerId: _owner.currentOwnerId,
      isAdult: true,
      now: now,
      actions: due ? const [_action] : const [],
      hasActiveAdultPlan: true,
      hasAdultReviewRecords: record != null,
      hasDueAdultReview: due,
    );
  }

  setUp(() async {
    await initializeIsarCoreForTests();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = _owner;
    now = DateTime.now().toUtc();
    directory = await Directory.systemTemp.createTemp('daily_review_flow_');
    isar = await Isar.open(
      [
        IsarAyahReviewRecordSchema,
        IsarV2SessionSchema,
        IsarReviewEvidenceEventSchema,
        if (!omitOutbox) IsarReviewEffectOutboxSchema,
        IsarConfusionPairSchema,
      ],
      directory: directory.path,
      name: 'review_flow_${DateTime.now().microsecondsSinceEpoch}',
    );
    final initial =
        IsarAyahReviewRecord.fromModel(AyahReviewRecordModel.initial(1, 1))
          ..compositeKey = ReviewRecordIdentity(
            ownerUserId: _owner.currentOwnerId,
            audience: ReviewRecordReadScope.adult,
            surahId: 1,
            ayahNumber: 1,
          ).storageKey
          ..ownerUserId = _owner.currentOwnerId
          ..audience = 'adult'
          ..nextReviewDate = now.subtract(const Duration(days: 1));
    await isar.writeTxn(() => isar.isarAyahReviewRecords.put(initial));
    preferences = AdultJourneyRepositoryImpl(prefs, _owner);
    final resolver = AdultJourneyLaunchResolver(
      owner: _owner,
      captureLease: barrier.capture,
      memorizationDestinations: () async => const AdultMemorizationDestinations(
        isChild: false,
        todayPlanLocation: '/memorization',
        reviewQuizLocation: _route,
      ),
    );
    journey = AdultJourneyCubit(
      loadAdultJourney: LoadAdultJourney(preferences),
      updateAdultJourney: UpdateAdultJourney(preferences),
      flags: AdultJourneyFlags((_) => true),
      owner: _owner,
      accountChanges: barrier.changes,
      now: () => now,
      launchResolver: resolver,
      loadFreshContext: freshContext,
    );
    await journey.refreshContext(await freshContext());
    expect(await journey.setTodayMinutes(5), isTrue);

    final quran = MockQuranRepository();
    final memory = MockMemorizationPlusRepository();
    final datasource = V2SessionLocalDatasource(isar, owner: _owner);
    final player = MockAudioPlayer();
    final speech = MockSpeechToText();
    final audioCache = MockAudioCacheService();
    playerStates = StreamController<PlayerState>.broadcast();
    when(player.playerStateStream).thenAnswer((_) => playerStates.stream);
    when(
      speech.initialize(
        onError: anyNamed('onError'),
        onStatus: anyNamed('onStatus'),
      ),
    ).thenAnswer((_) async => true);
    when(memory.getCustomPlan()).thenAnswer((_) async => const Right(null));
    when(
      memory.getMemorizationProfile(),
    ).thenAnswer((_) async => Right(MemorizationProfile.empty()));

    when(
      audioCache.prefetchSession(
        surahId: 1,
        ayahNumbers: anyNamed('ayahNumbers'),
      ),
    ).thenAnswer((_) async {});
    final corpus =
        jsonDecode(File('assets/data/quran.json').readAsStringSync())
            as Map<String, dynamic>;
    final row = (corpus['1'] as List).first as Map<String, dynamic>;
    final ayah = Ayah(
      number: row['global'] as int,
      surahId: 1,
      numberInSurah: row['verse'] as int,
      text: row['text'] as String,
      page: row['page'] as int,
      juz: row['juz'] as int,
    );
    const surah = Surah(
      id: 1,
      nameAr: 'الفاتحة',
      nameEn: 'Al-Fatiha',
      ayahCount: 7,
      juz: 1,
      type: 'meccan',
      page: 1,
    );
    when(
      quran.getSurahDetail(1),
    ).thenAnswer((_) async => Right(SurahDetail(surah: surah, ayahs: [ayah])));
    session = MemorizationSessionCubit(
      quranRepository: quran,
      memorizationRepository: memory,
      sessionEngine: V2SessionEngine(),
      reviewAdapter: V2SessionReviewAdapter(
        repository: memory,
        scheduler: const ScheduleNextReviewUsecase(),
      ),
      progressAdapter: V2SessionProgressAdapter(datasource: datasource),
      gamificationAdapter: V2SessionGamificationAdapter(
        xpService: MockXpService(),
        streakService: MockStreakService(),
        achievementService: MockAchievementService(),
      ),
      reviewOutcomeCommitter: V2ReviewOutcomeCommitter(
        isar: isar,
        owner: _owner,
        scheduler: const ScheduleNextReviewUsecase(),
        now: () => now,
      ),
      audioPlayer: player,
      speechToText: speech,
      audioCacheService: audioCache,
    );
  });

  tearDown(() async {
    if (!session.isClosed) await session.close();
    await journey.close();
    await playerStates.close();
    await isar.close(deleteFromDisk: true);
    if (await directory.exists()) await directory.delete(recursive: true);
    omitOutbox = false;
  });

  Future<void> openReview() async {
    expect(journey.state.todayMinutes, 5);
    expect(journey.state.dailyReviewTask?.status, DailyReviewTaskStatus.ready);
    final key = journey.state.dailyReviewTask!.decisionKey!;
    expect(
      await journey.resolveDailyReviewLaunch(expectedDecisionKey: key),
      _route,
    );
    expect(journey.canNavigateDailyReview(key), isTrue);
    await session.startSession(
      surahId: 1,
      startAyah: 1,
      blockSize: 1,
      launchContext: const LearningLaunchContext(
        ayah: AyahReference(surahId: 1, ayahNumber: 1),
        intent: LearningIntent.review,
        origin: LearningOrigin.smartCoach,
      ),
    );
    expect(session.state, isA<MSActive>());
  }

  Future<void> recall() async {
    await session.advanceToMemorizing();
    await session.advanceToReciting();
    expect(
      (session.state as MSActive).sessionState.phase,
      V2SessionPhase.reciting,
    );
    await session.submitManualRecall();
  }

  test(
    'review persists once and a fresh task reflects the committed projection',
    () async {
      await openReview();
      await recall();
      expect(await isar.isarReviewEvidenceEvents.count(), 1);
      expect(
        (await isar.isarAyahReviewRecords.where().findFirst())!.totalReviews,
        1,
      );
      final effects = await isar.isarReviewEffectOutboxs.where().findAll();
      expect(
        effects.where((effect) => effect.effectType == 'completion'),
        hasLength(1),
      );
      await journey.refreshDailyReviewContext();
      expect(
        journey.state.dailyReviewTask!.status,
        DailyReviewTaskStatus.noDueReview,
      );
      await journey.refreshDailyReviewContext();
      expect(await isar.isarReviewEvidenceEvents.count(), 1);
      final afterReturn = await isar.isarReviewEffectOutboxs.where().findAll();
      expect(
        afterReturn.where((effect) => effect.effectType == 'completion'),
        hasLength(1),
      );
    },
  );

  test(
    'exiting before assessment leaves evidence and progress unchanged',
    () async {
      await openReview();
      await session.close();
      await journey.refreshDailyReviewContext();
      expect(
        journey.state.dailyReviewTask!.status,
        DailyReviewTaskStatus.ready,
      );
      expect(await isar.isarReviewEvidenceEvents.count(), 0);
      expect(
        (await isar.isarAyahReviewRecords.where().findFirst())!.totalReviews,
        0,
      );
      expect(await isar.isarReviewEffectOutboxs.count(), 0);
    },
  );

  // Missing outbox schema forces the real transaction to roll back. The
  // expected retryable issue proves the failure branch actually ran.
  group('failed durable commit', () {
    setUpAll(() => omitOutbox = true);
    tearDownAll(() => omitOutbox = false);
    test(
      'failed commit preserves the task and records no completed review',
      () async {
        await openReview();
        await recall();
        expect(session.state, isA<MSActive>());
        expect((session.state as MSActive).persistenceIssue, isNotNull);
        expect(await isar.isarReviewEvidenceEvents.count(), 0);
        expect(
          (await isar.isarAyahReviewRecords.where().findFirst())!.totalReviews,
          0,
        );
        await journey.refreshDailyReviewContext();
        expect(
          journey.state.dailyReviewTask!.status,
          DailyReviewTaskStatus.ready,
        );
      },
    );
  });
}
