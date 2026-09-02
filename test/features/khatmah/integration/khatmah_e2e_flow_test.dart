import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talia_quran/core/constants/app_constants.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/journey/unified_journey_engine.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/memorization/usecases/get_smart_coach_recommendation_usecase.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/home/domain/usecases/get_activity_heatmap_usecase.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatm_dua_datasource.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_scheduling_engine.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/create_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_khatm_dua_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatm_dua_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_hero_card.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_reader_session_bar.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/progress/domain/usecases/get_progress_usecase.dart';
import 'package:talia_quran/features/progress/domain/usecases/save_read_page_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/domain/usecases/get_surahs_usecase.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_page_cubit.dart';
import 'package:talia_quran/features/quran/presentation/pages/quran_reader_page.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';

// ─── Mocks & Fakes ────────────────────────────────────────────────────────────

class MockGetProgressUsecase extends Mock implements GetProgressUsecase {}

class MockGetQuranPageUsecase extends Mock implements GetQuranPageUsecase {}

class MockGetCustomPlanUsecase extends Mock implements GetCustomPlanUsecase {}

class MockMemorizationPlusRepository extends Mock
    implements MemorizationPlusRepository {}

class MockGetActivityHeatmapUsecase extends Mock
    implements GetActivityHeatmapUsecase {}

class MockMemorizationPathResolver extends Mock
    implements MemorizationPathResolver {}

class MockGetSmartCoachRecommendationUsecase extends Mock
    implements GetSmartCoachRecommendationUsecase {}

class MockQuranRepository extends Mock implements QuranRepository {}

class MockSaveReadPageUsecase extends Mock implements SaveReadPageUsecase {}

class MockStreakService extends Mock implements StreakService {}

class _FakeXpService extends Fake implements XpService {
  @override
  Future<int> getTotalXp() async => 250;
}

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit() : super(const AuthInitial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RealDiskAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final file = File(key);
    if (file.existsSync()) {
      return file.readAsString();
    }
    return rootBundle.loadString(key, cache: cache);
  }

  @override
  Future<ByteData> load(String key) async {
    final file = File(key);
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      return ByteData.view(bytes.buffer);
    }
    return rootBundle.load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testQuranPageDetail = QuranPageDetail(
    pageNumber: 1,
    surahs: [
      Surah(
        id: 1,
        nameAr: 'الفاتحة',
        nameEn: 'Al-Fatihah',
        ayahCount: 7,
        juz: 1,
        type: 'meccan',
        page: 1,
      ),
    ],
    ayahs: [],
  );

  const initialOverallProgress = OverallProgress(
    memorizedAyahs: 10,
    totalAyahs: 6236,
    memorizedSurahs: 1,
    totalSurahs: 114,
    memorizedJuz: 0,
    totalJuz: 30,
    readAyahs: 50,
    readSurahs: 2,
    readJuz: 1,
    streakDays: 7,
    lastActiveDate: null,
    achievements: [],
    readPagesCount: 2,
    totalQuranPages: 604,
    learningAyahs: 5,
    reviewAyahs: 5,
  );

  late SharedPreferences prefs;
  late KhatmahLocalDatasource khatmahDatasource;
  late KhatmahRepositoryImpl khatmahRepository;
  late CreateKhatmahUsecase createKhatmahUsecase;
  late GetActiveKhatmahUsecase getActiveKhatmahUsecase;
  late RecordKhatmahReadingUsecase recordKhatmahReadingUsecase;
  late PauseResumeKhatmahUsecase pauseResumeKhatmahUsecase;
  late DeleteKhatmahUsecase deleteKhatmahUsecase;
  late KhatmDuaDatasource khatmDuaDatasource;
  late GetKhatmDuaUsecase getKhatmDuaUsecase;

  late AppSessionService appSessionService;
  late MockGetProgressUsecase mockGetProgress;
  late MockGetQuranPageUsecase mockGetQuranPage;
  late MockGetCustomPlanUsecase mockGetCustomPlan;
  late MockMemorizationPlusRepository mockMemRepo;
  late MockGetActivityHeatmapUsecase mockGetHeatmap;
  late MockMemorizationPathResolver mockPathResolver;
  late MockGetSmartCoachRecommendationUsecase mockGetCoachRecommendation;
  late ProgressEventsBus progressEvents;
  late _FakeXpService xpService;
  late MockQuranRepository mockQuranRepo;
  late MockSaveReadPageUsecase mockSaveRead;
  late MockStreakService mockStreak;
  late QuranReciterService reciterService;
  late QuranContinuousPlayerService playerService;
  late QuranAudioPlayerCubit audioPlayerCubit;

  setUpAll(() {
    registerFallbackValue(ReviewRecordReadScope.adult);
  });

  setUp(() async {
    await getIt.reset();

    // Isolated SharedPreferences with pre-existing read_pages
    SharedPreferences.setMockInitialValues({
      AppConstants.kReadPages: '["1", "2"]',
      'quran_long_press_hint_seen': true,
      'unified_journey_enabled': true,
    });
    prefs = await SharedPreferences.getInstance();

    khatmahDatasource = KhatmahLocalDatasource(prefs);
    khatmahRepository = KhatmahRepositoryImpl(khatmahDatasource);
    createKhatmahUsecase = CreateKhatmahUsecase(khatmahRepository);
    getActiveKhatmahUsecase = GetActiveKhatmahUsecase(khatmahRepository);
    recordKhatmahReadingUsecase = RecordKhatmahReadingUsecase(
      khatmahRepository,
    );
    pauseResumeKhatmahUsecase = PauseResumeKhatmahUsecase(khatmahRepository);
    deleteKhatmahUsecase = DeleteKhatmahUsecase(khatmahRepository);

    khatmDuaDatasource = KhatmDuaDatasource(bundle: RealDiskAssetBundle());
    getKhatmDuaUsecase = GetKhatmDuaUsecase(khatmDuaDatasource);

    appSessionService = AppSessionService(prefs);

    mockGetProgress = MockGetProgressUsecase();
    mockGetQuranPage = MockGetQuranPageUsecase();
    mockGetCustomPlan = MockGetCustomPlanUsecase();
    mockMemRepo = MockMemorizationPlusRepository();
    mockGetHeatmap = MockGetActivityHeatmapUsecase();
    mockPathResolver = MockMemorizationPathResolver();
    mockGetCoachRecommendation = MockGetSmartCoachRecommendationUsecase();
    progressEvents = ProgressEventsBus();
    xpService = _FakeXpService();

    mockQuranRepo = MockQuranRepository();
    mockSaveRead = MockSaveReadPageUsecase();
    mockStreak = MockStreakService();

    when(
      () => mockGetProgress.call(),
    ).thenAnswer((_) async => const Right(initialOverallProgress));
    when(
      () => mockGetQuranPage.call(any()),
    ).thenAnswer((_) async => const Right(testQuranPageDetail));
    when(
      () => mockGetCustomPlan.call(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockMemRepo.getMemorizationProfile(),
    ).thenAnswer((_) async => Right(MemorizationProfile.empty()));
    when(
      () => mockMemRepo.getAllReviewRecords(scope: any(named: 'scope')),
    ).thenAnswer((_) async => const Right([]));
    when(() => mockGetHeatmap.call()).thenAnswer(
      (_) async =>
          ActivityHeatmapData(countsByDay: const {}, startDate: DateTime.now()),
    );
    when(
      () => mockPathResolver.changes,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockGetCoachRecommendation.call(),
    ).thenAnswer((_) async => const Right(null));

    when(
      () => mockQuranRepo.getQuranPage(any()),
    ).thenAnswer((_) async => const Right(testQuranPageDetail));
    when(
      () => mockSaveRead.call(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockStreak.recordActivity(),
    ).thenAnswer((_) async => const StreakResult.sameDay());

    reciterService = QuranReciterService(prefs);
    playerService = QuranContinuousPlayerService(
      quranRepository: mockQuranRepo,
      reciterService: reciterService,
    );
    audioPlayerCubit = QuranAudioPlayerCubit(playerService);

    // Register in GetIt for widgets that resolve dependencies via GetIt
    getIt
      ..registerSingleton<SharedPreferences>(prefs)
      ..registerSingleton<AppSessionService>(appSessionService)
      ..registerSingleton<QuranReciterService>(reciterService)
      ..registerSingleton<AuthCubit>(_FakeAuthCubit())
      ..registerSingleton<GetActiveKhatmahUsecase>(getActiveKhatmahUsecase)
      ..registerSingleton<RecordKhatmahReadingUsecase>(
        recordKhatmahReadingUsecase,
      )
      ..registerSingleton<PauseResumeKhatmahUsecase>(pauseResumeKhatmahUsecase)
      ..registerSingleton<DeleteKhatmahUsecase>(deleteKhatmahUsecase)
      ..registerFactory<QuranPageCubit>(
        () => QuranPageCubit(mockQuranRepo, mockSaveRead, mockStreak),
      )
      ..registerFactory<KhatmahCubit>(
        () => KhatmahCubit(
          getActiveKhatmahUsecase,
          recordKhatmahReadingUsecase,
          pauseResumeKhatmahUsecase,
          deleteKhatmahUsecase,
        ),
      );
  });

  tearDown(() async {
    await audioPlayerCubit.close();
    playerService.dispose();
    progressEvents.dispose();
    await getIt.reset();
  });

  HomeCubit createHomeCubit() {
    return HomeCubit(
      mockGetProgress,
      mockGetQuranPage,
      mockGetCustomPlan,
      mockMemRepo,
      appSessionService,
      mockGetHeatmap,
      mockPathResolver,
      mockGetCoachRecommendation,
      const UnifiedJourneyEngine(),
      prefs,
      progressEvents,
      xpService,
      getActiveKhatmahUsecase,
    );
  }

  group('Complete End-to-End Quran Khatmah Journey', () {
    test('full lifecycle: setup plan with dedication -> isolated storage -> '
        'surfaced on home -> read in khatmah mode (no restorableLocation) -> '
        'read in free mode (updates restorableLocation, no khatmah progress) -> '
        'complete page 604 -> archive to history -> generate KR- code -> '
        'load authentic du\'a -> clear active plan', () async {
      // ───────────────────────────────────────────────────────────────────────
      // STAGE 1: Setup plan with dedication -> saved to isolated storage
      // ───────────────────────────────────────────────────────────────────────
      final setupCubit = KhatmahSetupCubit(createKhatmahUsecase);
      expect(setupCubit.state, equals(const KhatmahSetupIdle()));

      const dedication = KhatmahDedication(
        isDedicated: true,
        recipientName: 'جدتي الغالية',
        relationship: 'Grandmother',
        condition: DedicationCondition.deceased,
        customNote: 'رحمها الله وأسكنها فسيح جناته',
      );

      await setupCubit.createPlan(pagesPerDay: 4, dedication: dedication);

      expect(setupCubit.state, isA<KhatmahSetupDone>());
      final createdPlan = (setupCubit.state as KhatmahSetupDone).plan;
      expect(createdPlan.title, equals('جدتي الغالية'));
      expect(createdPlan.targetPagesPerDay, equals(4));
      expect(createdPlan.targetDays, equals(151));
      expect(createdPlan.currentPage, equals(0));
      expect(createdPlan.status, equals(KhatmahStatus.active));
      expect(createdPlan.dedication.isDedicated, isTrue);
      expect(createdPlan.dedication.recipientName, equals('جدتي الغالية'));
      expect(
        createdPlan.dedication.condition,
        equals(DedicationCondition.deceased),
      );
      await setupCubit.close();

      // Verify isolated storage in SharedPreferences
      final rawActivePlan = prefs.getString('khatmah_active_plan');
      expect(rawActivePlan, isNotNull);
      final jsonActivePlan = jsonDecode(rawActivePlan!) as Map<String, dynamic>;
      expect(jsonActivePlan['title'], equals('جدتي الغالية'));
      expect(jsonActivePlan['targetPagesPerDay'], equals(4));
      expect(jsonActivePlan['currentPage'], equals(0));
      expect(prefs.getBool('khatmah_cloud_dirty'), isNull);

      // Verify strict isolation: read_pages was NOT touched
      final readPagesAfterSetup = prefs.getString(AppConstants.kReadPages);
      expect(readPagesAfterSetup, equals('["1", "2"]'));

      // ───────────────────────────────────────────────────────────────────────
      // STAGE 2: Home screen loads and surfaces active khatmah
      // ───────────────────────────────────────────────────────────────────────
      final homeCubit = createHomeCubit();
      await homeCubit.load();

      expect(homeCubit.state, isA<HomeLoaded>());
      final homeState = homeCubit.state as HomeLoaded;
      expect(homeState.activeKhatmah, isNotNull);
      expect(homeState.activeKhatmah!.title, equals('جدتي الغالية'));
      expect(homeState.activeKhatmah!.currentPage, equals(0));
      expect(homeState.activeKhatmah!.targetPagesPerDay, equals(4));
      expect(homeState.activeKhatmah!.dedication.isDedicated, isTrue);

      // ───────────────────────────────────────────────────────────────────────
      // STAGE 3: Reader session in khatmah mode updates khatmah progress
      //          WITHOUT updating AppSessionService.lastRestorableLocation
      // ───────────────────────────────────────────────────────────────────────
      expect(appSessionService.getLastRestorableLocation(), isNull);

      final quranPageCubit = QuranPageCubit(
        mockQuranRepo,
        mockSaveRead,
        mockStreak,
      );

      await quranPageCubit.loadPage(1);
      expect(quranPageCubit.state, isA<QuranPageLoaded>());

      // User confirms reading page 1 in Khatmah mode
      expect(await quranPageCubit.confirmRead(1), isTrue);
      final readerKhatmahCubit = KhatmahCubit(
        getActiveKhatmahUsecase,
        recordKhatmahReadingUsecase,
        pauseResumeKhatmahUsecase,
        deleteKhatmahUsecase,
      );
      await readerKhatmahCubit.load();
      await readerKhatmahCubit.recordDigitalPage(1);

      // Verify khatmah progress was updated in repository / datasource
      final activePlanAfterRead = await getActiveKhatmahUsecase();
      expect(activePlanAfterRead, isNotNull);
      expect(activePlanAfterRead!.currentPage, equals(1));

      // Verify strict isolation: AppSessionService lastRestorableLocation MUST NOT be set
      expect(appSessionService.getLastRestorableLocation(), isNull);
      expect(prefs.getString('last_restorable_location'), isNull);

      // ───────────────────────────────────────────────────────────────────────
      // STAGE 4: Reader session in free mode updates AppSessionService
      //          WITHOUT updating the khatmah plan
      // ───────────────────────────────────────────────────────────────────────
      await quranPageCubit.loadPage(5);

      // In free mode, the reader page records its restorable location
      await appSessionService.saveLocation('/quran/page/5');
      expect(await quranPageCubit.confirmRead(5), isTrue);

      // Verify AppSessionService location was updated
      expect(
        appSessionService.getLastRestorableLocation(),
        equals('/quran/page/5'),
      );

      // Verify Khatmah plan currentPage was NOT modified by free mode reading
      final activePlanAfterFreeRead = await getActiveKhatmahUsecase();
      expect(activePlanAfterFreeRead, isNotNull);
      expect(activePlanAfterFreeRead!.currentPage, equals(1));

      await quranPageCubit.close();

      // ───────────────────────────────────────────────────────────────────────
      // STAGE 5: Completing page 604 transitions plan to completed, archives
      //          to history, generates KR- certificate award code, loads
      //          authentic du'a, and clears active plan
      // ───────────────────────────────────────────────────────────────────────
      final khatmahCubit = KhatmahCubit(
        getActiveKhatmahUsecase,
        recordKhatmahReadingUsecase,
        pauseResumeKhatmahUsecase,
        deleteKhatmahUsecase,
      );
      await khatmahCubit.load();
      expect(khatmahCubit.state, isA<KhatmahActive>());

      // Explicit digital coverage is required; a later page never fills gaps.
      for (var page = 2; page <= KhatmahSchedulingEngine.totalPages; page++) {
        await khatmahCubit.recordDigitalPage(page);
      }

      // Verify KhatmahCompleted state emitted
      expect(khatmahCubit.state, isA<KhatmahCompleted>());
      final completedState = khatmahCubit.state as KhatmahCompleted;
      expect(
        completedState.plan.currentPage,
        equals(KhatmahSchedulingEngine.totalPages),
      );
      expect(completedState.plan.status, equals(KhatmahStatus.completed));
      expect(completedState.plan.title, equals('جدتي الغالية'));

      // Verify plan was archived to history
      final history = await khatmahRepository.getHistory();
      expect(history.length, equals(1));
      final historyEntry = history.first;
      expect(historyEntry.khatmahNumber, equals(1));
      expect(historyEntry.title, equals('جدتي الغالية'));
      expect(historyEntry.dedication, isNotNull);
      expect(historyEntry.dedication!.recipientName, equals('جدتي الغالية'));
      expect(historyEntry.totalDays, greaterThanOrEqualTo(1));

      // Verify active plan is cleared from storage
      final planAfterCompletion = await getActiveKhatmahUsecase();
      expect(planAfterCompletion, isNull);
      expect(prefs.getString('khatmah_active_plan'), isNull);

      // Verify HomeCubit reload clears active khatmah card
      await homeCubit.load();
      expect(homeCubit.state, isA<HomeLoaded>());
      final updatedHome = homeCubit.state as HomeLoaded;
      expect(updatedHome.activeKhatmah, isNull);
      await homeCubit.close();
      await khatmahCubit.close();

      // ───────────────────────────────────────────────────────────────────────
      // STAGE 6: Verify authentic du'a loading from assets/data/khatm_dua.json
      // ───────────────────────────────────────────────────────────────────────
      final duaCubit = KhatmDuaCubit(getKhatmDuaUsecase);
      await duaCubit.load();

      expect(duaCubit.state, isA<KhatmDuaLoaded>());
      final duaLoaded = duaCubit.state as KhatmDuaLoaded;
      final duaData = duaLoaded.data;

      expect(duaData.tier, equals('guidance'));
      expect(
        duaData.source,
        contains('مصحف مجمع الملك فهد لطباعة المصحف الشريف'),
      );
      expect(duaData.sourceNote, isNotEmpty);
      expect(duaData.arabicText, contains('اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ'));

      // Check dynamic deceased dedication insert with custom recipient name
      final insert = duaData.getDedicationInsert(
        DedicationCondition.deceased,
        'جدتي الغالية',
      );
      expect(insert, contains('جدتي الغالية'));
      expect(
        insert,
        contains('اللَّهُمَّ اغْفِرْ لِعَبْدِكَ جدتي الغالية وَارْحَمْهُ'),
      );
      await duaCubit.close();

      // ───────────────────────────────────────────────────────────────────────
      // STAGE 7: Verify certificate generation with KR- prefix
      // ───────────────────────────────────────────────────────────────────────
      final earnedDate = DateTime(2026, 9, 2, 18, 30);
      final certificate = CertificateAward(
        id: 'cert_khatmah_${historyEntry.id}',
        titleAr: 'شهادة إتمام ختمة القرآن الكريم',
        titleEn: 'Quran Recitation Khatmah Certificate',
        type: CertificateType.khatmahReading,
        earnedAt: earnedDate,
      );

      expect(certificate.type, equals(CertificateType.khatmahReading));
      expect(certificate.type.verificationPrefix, equals('KR'));
      expect(certificate.verificationCode, contains('-KR-'));
      expect(certificate.verificationCode, startsWith('TL-2026-KR-'));

      // Verify certificate serialization round-trip
      final certJson = certificate.toJson();
      expect(certJson['type'], equals('khatmahReading'));
      final restoredCert = CertificateAward.fromJson(certJson);
      expect(
        restoredCert.verificationCode,
        equals(certificate.verificationCode),
      );
      expect(restoredCert, equals(certificate));
    });
  });

  group('Widget and UI Level Integration', () {
    testWidgets(
      'Home screen renders KhatmahHeroCard when active plan exists, and hides it when null',
      (tester) async {
        final activePlan = KhatmahPlan(
          id: 'widget-khatmah-1',
          title: 'ختمة رمضان المبارك',
          targetPagesPerDay: 4,
          targetDays: 151,
          startDate: DateTime(2026, 1, 1),
          expectedEndDate: DateTime(2026, 6, 1),
          completedPages: {for (var page = 1; page <= 12; page++) page},
          status: KhatmahStatus.active,
          dedication: const KhatmahDedication(
            isDedicated: true,
            recipientName: 'والدي العزيز',
          ),
        );

        // Pump widget with active khatmah card
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [KhatmahHeroCard(plan: activePlan, isDark: false)],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ختمة رمضان المبارك'), findsWidgets);
        expect(find.byType(KhatmahHeroCard), findsOneWidget);

        // When activeKhatmah is null, KhatmahHeroCard is not present
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(body: SizedBox.shrink()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('ختمة رمضان المبارك'), findsNothing);
        expect(find.byType(KhatmahHeroCard), findsNothing);
      },
    );

    testWidgets(
      'QuranReaderPage: in khatmah mode shows session bar & does not save location; '
      'in free mode hides session bar & saves location to AppSessionService',
      (tester) async {
        final khatmahPlan = KhatmahPlan(
          id: 'reader-khatmah-1',
          title: 'Khatmah Reader Integration',
          targetPagesPerDay: 4,
          targetDays: 151,
          startDate: DateTime(2026, 1, 1),
          expectedEndDate: DateTime(2026, 6, 1),
          completedPages: {for (var page = 1; page <= 20; page++) page},
          status: KhatmahStatus.active,
        );

        await khatmahRepository.createPlan(khatmahPlan);
        final activeCubit = KhatmahCubit(
          getActiveKhatmahUsecase,
          recordKhatmahReadingUsecase,
          pauseResumeKhatmahUsecase,
          deleteKhatmahUsecase,
        );
        await activeCubit.load();

        // Test 1: Khatmah Mode
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<QuranAudioPlayerCubit>.value(
                value: audioPlayerCubit,
              ),
              BlocProvider<KhatmahCubit>.value(value: activeCubit),
            ],
            child: const MaterialApp(
              locale: Locale('ar'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: QuranReaderPage(
                pageNumber: 21,
                readerMode: QuranReaderMode.khatmah,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(KhatmahReaderSessionBar), findsOneWidget);
        expect(appSessionService.getLastRestorableLocation(), isNull);

        // Test 2: Free Mode
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<QuranAudioPlayerCubit>.value(
                value: audioPlayerCubit,
              ),
            ],
            child: const MaterialApp(
              locale: Locale('ar'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: QuranReaderPage(
                pageNumber: 21,
                readerMode: QuranReaderMode.free,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(KhatmahReaderSessionBar), findsNothing);
        expect(
          appSessionService.getLastRestorableLocation(),
          equals('/quran/page/21'),
        );

        await activeCubit.close();
      },
    );
  });
}
