import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_reader_session_bar.dart';
import 'package:talia_quran/features/progress/domain/usecases/save_read_page_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_page_cubit.dart';
import 'package:talia_quran/features/quran/presentation/pages/quran_reader_page.dart';
import 'package:talia_quran/features/quran/presentation/widgets/app_quran_page_view.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';

class MockAppSessionService extends Mock implements AppSessionService {}

class MockQuranRepository extends Mock implements QuranRepository {}

class MockSaveReadPageUsecase extends Mock implements SaveReadPageUsecase {}

class MockStreakService extends Mock implements StreakService {}

class MockKhatmahCubit extends Mock implements KhatmahCubit {}

class MockGetActiveKhatmahUsecase extends Mock
    implements GetActiveKhatmahUsecase {}

class MockRecordKhatmahReadingUsecase extends Mock
    implements RecordKhatmahReadingUsecase {}

class MockPauseResumeKhatmahUsecase extends Mock
    implements PauseResumeKhatmahUsecase {}

class MockDeleteKhatmahUsecase extends Mock implements DeleteKhatmahUsecase {}

class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit() : super(const AuthInitial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoRouterState extends Fake implements GoRouterState {
  _FakeGoRouterState(this._uri, {Map<String, String>? pathParameters})
    : _pathParameters = pathParameters ?? const {};

  final Uri _uri;
  final Map<String, String> _pathParameters;

  @override
  Uri get uri => _uri;

  @override
  Map<String, String> get pathParameters => _pathParameters;

  @override
  Object? get extra => null;
}

class _MockBuildContext extends Mock implements BuildContext {}

Widget buildRouterApp(GoRouter router) => MaterialApp.router(
  routerConfig: router,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);

void main() {
  late MockAppSessionService mockSessionService;
  late MockQuranRepository mockQuranRepo;
  late MockSaveReadPageUsecase mockSaveRead;
  late MockStreakService mockStreak;
  late MockKhatmahCubit mockKhatmahCubit;
  late QuranAudioPlayerCubit audioCubit;
  late QuranContinuousPlayerService playerService;
  late QuranReciterService reciterService;

  const testPage = QuranPageDetail(
    pageNumber: 42,
    surahs: [
      Surah(
        id: 2,
        nameAr: 'البقرة',
        nameEn: 'Al-Baqarah',
        ayahCount: 286,
        juz: 3,
        type: 'medinan',
        page: 42,
      ),
    ],
    ayahs: [],
  );

  final testPlan = KhatmahPlan(
    id: 'test-khatmah',
    title: 'Test Khatmah',
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
    completedPages: {for (var page = 1; page <= 42; page++) page},
    status: KhatmahStatus.active,
  );

  setUpAll(() {
    registerFallbackValue(FakeKhatmahPlan());
    registerFallbackValue(KhatmahReadingSource.digital);
  });

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({
      'quran_long_press_hint_seen': true,
    });
    final prefs = await SharedPreferences.getInstance();

    mockSessionService = MockAppSessionService();
    mockQuranRepo = MockQuranRepository();
    mockSaveRead = MockSaveReadPageUsecase();
    mockStreak = MockStreakService();
    mockKhatmahCubit = MockKhatmahCubit();

    when(() => mockSessionService.saveLocation(any())).thenAnswer((_) async {});
    when(
      () => mockQuranRepo.getQuranPage(any()),
    ).thenAnswer((_) async => const Right(testPage));
    when(() => mockSaveRead(any())).thenAnswer((_) async => const Right(null));
    when(
      () => mockStreak.recordActivity(),
    ).thenAnswer((_) async => const StreakResult.sameDay());

    when(() => mockKhatmahCubit.state).thenReturn(
      KhatmahActive(plan: testPlan, wirdStartPage: 41, wirdEndPage: 44),
    );
    when(
      () => mockKhatmahCubit.stream,
    ).thenAnswer((_) => const Stream<KhatmahState>.empty());
    when(() => mockKhatmahCubit.close()).thenAnswer((_) async {});

    reciterService = QuranReciterService(prefs);
    playerService = QuranContinuousPlayerService(
      quranRepository: mockQuranRepo,
      reciterService: reciterService,
    );
    audioCubit = QuranAudioPlayerCubit(playerService);

    getIt
      ..registerSingleton<SharedPreferences>(prefs)
      ..registerSingleton<AppSessionService>(mockSessionService)
      ..registerSingleton<QuranReciterService>(reciterService)
      ..registerSingleton<AuthCubit>(_FakeAuthCubit())
      ..registerFactory<QuranPageCubit>(
        () => QuranPageCubit(mockQuranRepo, mockSaveRead, mockStreak),
      );
  });

  tearDown(() async {
    await audioCubit.close();
    playerService.dispose();
    await getIt.reset();
  });

  Widget buildReaderApp({
    required int pageNumber,
    QuranReaderMode readerMode = QuranReaderMode.free,
    KhatmahCubit? khatmahCubit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<QuranAudioPlayerCubit>.value(value: audioCubit),
        if (khatmahCubit != null)
          BlocProvider<KhatmahCubit>.value(value: khatmahCubit),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: QuranReaderPage(
          pageNumber: pageNumber,
          readerMode: readerMode,
          khatmahCubit: khatmahCubit,
        ),
      ),
    );
  }

  Future<void> triggerReadConfirmation(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.byType(AppQuranPageView));
    await tester.pump();
    await tester.pump();
  }

  Future<({KhatmahCubit cubit, MockRecordKhatmahReadingUsecase record})>
  buildRealKhatmahCubit() async {
    final getActive = MockGetActiveKhatmahUsecase();
    final record = MockRecordKhatmahReadingUsecase();
    final pauseResume = MockPauseResumeKhatmahUsecase();
    final delete = MockDeleteKhatmahUsecase();
    when(() => getActive()).thenAnswer((_) async => testPlan);
    final cubit = KhatmahCubit(getActive, record, pauseResume, delete);
    await cubit.load();
    return (cubit: cubit, record: record);
  }

  group('AppRouter mode parameter parsing', () {
    test('/quran/page/42?mode=khatmah parses mode as khatmah', () {
      final uri = Uri.parse('/quran/page/42?mode=khatmah');
      final matches = AppRouter.router.configuration.findMatch(uri);
      expect(matches.isNotEmpty, isTrue);
      expect(matches.uri.queryParameters['mode'], equals('khatmah'));

      final pageMatch = matches.matches.last;
      final route = pageMatch.route as GoRoute;
      final state = _FakeGoRouterState(
        uri,
        pathParameters: {'pageNumber': '42'},
      );
      final widget =
          route.builder!(_MockBuildContext(), state) as QuranReaderPage;
      expect(widget.pageNumber, equals(42));
      expect(widget.readerMode, equals(QuranReaderMode.khatmah));
    });

    test('/quran/page/42 without mode parses mode as free', () {
      final uri = Uri.parse('/quran/page/42');
      final matches = AppRouter.router.configuration.findMatch(uri);
      expect(matches.isNotEmpty, isTrue);
      expect(matches.uri.queryParameters['mode'], isNull);

      final pageMatch = matches.matches.last;
      final route = pageMatch.route as GoRoute;
      final state = _FakeGoRouterState(
        uri,
        pathParameters: {'pageNumber': '42'},
      );
      final widget =
          route.builder!(_MockBuildContext(), state) as QuranReaderPage;
      expect(widget.pageNumber, equals(42));
      expect(widget.readerMode, equals(QuranReaderMode.free));
    });
  });

  group('QuranReaderPage mode isolation & UI', () {
    testWidgets('free mode updates AppSessionService and hides session bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildReaderApp(pageNumber: 42, readerMode: QuranReaderMode.free),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockSessionService.saveLocation('/quran/page/42')).called(1);
      expect(find.byType(KhatmahReaderSessionBar), findsNothing);
    });

    testWidgets(
      'khatmah mode NEVER updates AppSessionService and renders session bar',
      (tester) async {
        await tester.pumpWidget(
          buildReaderApp(
            pageNumber: 42,
            readerMode: QuranReaderMode.khatmah,
            khatmahCubit: mockKhatmahCubit,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verifyNever(() => mockSessionService.saveLocation(any()));
        expect(find.byType(KhatmahReaderSessionBar), findsOneWidget);
      },
    );

    testWidgets(
      'generic confirmation success records the current Khatmah page exactly once',
      (tester) async {
        final fixture = await buildRealKhatmahCubit();
        when(
          () => fixture.record(
            testPlan,
            42,
            source: KhatmahReadingSource.digital,
          ),
        ).thenAnswer(
          (_) async => KhatmahReadingResult(
            plan: testPlan,
            newlyCompletedPages: const {},
          ),
        );

        await tester.pumpWidget(
          buildReaderApp(
            pageNumber: 42,
            readerMode: QuranReaderMode.khatmah,
            khatmahCubit: fixture.cubit,
          ),
        );
        await tester.pump();
        await triggerReadConfirmation(tester);

        verify(
          () => fixture.record(
            testPlan,
            42,
            source: KhatmahReadingSource.digital,
          ),
        ).called(1);
        verify(() => mockSaveRead(42)).called(1);
        await fixture.cubit.close();
      },
    );

    testWidgets('generic confirmation failure creates no Khatmah record', (
      tester,
    ) async {
      when(
        () => mockSaveRead(42),
      ).thenAnswer((_) async => const Left(CacheFailure('save failed')));
      final fixture = await buildRealKhatmahCubit();

      await tester.pumpWidget(
        buildReaderApp(
          pageNumber: 42,
          readerMode: QuranReaderMode.khatmah,
          khatmahCubit: fixture.cubit,
        ),
      );
      await tester.pump();
      await triggerReadConfirmation(tester);

      verifyNever(
        () => fixture.record(any(), any(), source: any(named: 'source')),
      );
      await fixture.cubit.close();
    });

    testWidgets(
      'progress failure stays visible and retry records the same page once',
      (tester) async {
        final fixture = await buildRealKhatmahCubit();
        final firstAttempt = Completer<KhatmahReadingResult>();
        when(
          () => fixture.record(
            testPlan,
            42,
            source: KhatmahReadingSource.digital,
          ),
        ).thenAnswer((_) => firstAttempt.future);

        await tester.pumpWidget(
          buildReaderApp(
            pageNumber: 42,
            readerMode: QuranReaderMode.khatmah,
            khatmahCubit: fixture.cubit,
          ),
        );
        await tester.pump();
        await triggerReadConfirmation(tester);
        firstAttempt.completeError(Exception('disk unavailable'));
        await tester.pump();

        expect(fixture.cubit.state, isA<KhatmahProgressFailure>());
        expect(find.text('لم يتم حفظ التقدم'), findsOneWidget);

        when(
          () => fixture.record(
            testPlan,
            42,
            source: KhatmahReadingSource.digital,
          ),
        ).thenAnswer(
          (_) async => KhatmahReadingResult(
            plan: testPlan,
            newlyCompletedPages: const {},
          ),
        );
        await tester.tap(
          find.widgetWithText(TextButton, 'إعادة المحاولة').first,
        );
        await tester.pump();

        verify(
          () => fixture.record(
            testPlan,
            42,
            source: KhatmahReadingSource.digital,
          ),
        ).called(2);
        await fixture.cubit.close();
      },
    );

    testWidgets(
      'persisted completion navigates once with its typed result after replay',
      (tester) async {
        final fixture = await buildRealKhatmahCubit();
        final completion = Completer<KhatmahReadingResult>();
        final completedPlan = testPlan.copyWith(
          completedPages: {for (var page = 1; page <= 604; page++) page},
          status: KhatmahStatus.completed,
        );
        final history = KhatmahHistoryEntry(
          id: completedPlan.id,
          khatmahNumber: 7,
          title: completedPlan.title,
          startDate: completedPlan.startDate,
          completedDate: DateTime(2026, 5, 1),
          totalDays: 121,
        );
        when(
          () => fixture.record(
            testPlan,
            42,
            source: KhatmahReadingSource.digital,
          ),
        ).thenAnswer((_) => completion.future);

        var completionBuilds = 0;
        KhatmahReadingResult? routedResult;
        final router = GoRouter(
          initialLocation: '/reader',
          routes: [
            GoRoute(
              path: '/reader',
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider<QuranAudioPlayerCubit>.value(value: audioCubit),
                  BlocProvider<KhatmahCubit>.value(value: fixture.cubit),
                ],
                child: QuranReaderPage(
                  key: const ValueKey('reader'),
                  pageNumber: 42,
                  readerMode: QuranReaderMode.khatmah,
                  khatmahCubit: fixture.cubit,
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.khatmahCompletion,
              builder: (context, state) {
                completionBuilds++;
                routedResult = state.extra as KhatmahReadingResult;
                return const Scaffold(body: Text('completion'));
              },
            ),
          ],
        );

        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1200, 2400);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildRouterApp(router));
        await tester.pump(const Duration(milliseconds: 100));
        await triggerReadConfirmation(tester);
        completion.complete(
          KhatmahReadingResult(
            plan: completedPlan,
            historyEntry: history,
            newlyCompletedPages: const {42},
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('completion'), findsOneWidget);
        expect(completionBuilds, 1);
        expect(routedResult?.plan, completedPlan);
        expect(routedResult?.historyEntry, history);
        expect(routedResult?.newlyCompletedPages, const {42});

        await tester.pumpWidget(buildRouterApp(router));
        await tester.pump(const Duration(milliseconds: 100));
        expect(completionBuilds, 1);
        await fixture.cubit.close();
      },
    );
  });

  group('KhatmahReaderSessionBar widget', () {
    testWidgets(
      'completed session counts explicit range rather than a new target',
      (tester) async {
        final anchored = testPlan.copyWith(
          completedPages: {1, 2, 3, 4, 6},
          dailyTargetDate: DateTime.now(),
          dailyTargetStartPage: 1,
          dailyTargetEndPage: 4,
        );
        when(
          () => mockKhatmahCubit.state,
        ).thenReturn(KhatmahWirdCompleted(plan: anchored));
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: KhatmahReaderSessionBar(cubit: mockKhatmahCubit),
            ),
          ),
        );
        await tester.pump();
        expect(find.textContaining("4 of 4 of today's wird"), findsOneWidget);
      },
    );

    testWidgets('renders active plan title, wird progress, and dedication', (
      tester,
    ) async {
      final planWithDedication = testPlan.copyWith(
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: 'والدتي',
        ),
      );

      when(() => mockKhatmahCubit.state).thenReturn(
        KhatmahActive(
          plan: planWithDedication,
          wirdStartPage: 41,
          wirdEndPage: 44,
        ),
      );

      bool exitCalled = false;

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
            body: KhatmahReaderSessionBar(
              cubit: mockKhatmahCubit,
              currentPage: 42,
              onExit: () => exitCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Test Khatmah'), findsOneWidget);
      expect(find.text('إهداء إلى: والدتي'), findsOneWidget);
      expect(find.text('صفحة ٤٢ (٢ من ٤ من ورد اليوم)'), findsOneWidget);

      final exitBtn = find.text('حفظ وخروج');
      expect(exitBtn, findsOneWidget);
      await tester.tap(exitBtn);
      expect(exitCalled, isTrue);
    });

    testWidgets('renders nothing if state is not KhatmahActive', (
      tester,
    ) async {
      when(
        () => mockKhatmahCubit.state,
      ).thenReturn(const KhatmahNoActivePlan());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KhatmahReaderSessionBar(
              cubit: mockKhatmahCubit,
              currentPage: 42,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Card), findsNothing);
      expect(find.text('Test Khatmah'), findsNothing);
    });

    testWidgets(
      'uses persisted progress when browsing far ahead of saved coverage',
      (tester) async {
        final savedAtPageOne = testPlan.copyWith(completedPages: const {1});
        when(() => mockKhatmahCubit.state).thenReturn(
          KhatmahActive(plan: savedAtPageOne, wirdStartPage: 2, wirdEndPage: 5),
        );

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
              body: KhatmahReaderSessionBar(
                cubit: mockKhatmahCubit,
                currentPage: 100,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('صفحة ١ '), findsOneWidget);
        expect(find.textContaining('صفحة ١٠٠ '), findsNothing);
      },
    );
  });
}
