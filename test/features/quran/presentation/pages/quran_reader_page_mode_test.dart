import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/widgets/khatmah_reader_session_bar.dart';
import 'package:talia_quran/features/progress/domain/usecases/save_read_page_usecase.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_page_cubit.dart';
import 'package:talia_quran/features/quran/presentation/pages/quran_reader_page.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';

class MockAppSessionService extends Mock implements AppSessionService {}

class MockQuranRepository extends Mock implements QuranRepository {}

class MockSaveReadPageUsecase extends Mock implements SaveReadPageUsecase {}

class MockStreakService extends Mock implements StreakService {}

class MockKhatmahCubit extends Mock implements KhatmahCubit {}

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
    currentPage: 42,
    status: KhatmahStatus.active,
  );

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

    when(() => mockSessionService.saveLocation(any()))
        .thenAnswer((_) async {});
    when(() => mockQuranRepo.getQuranPage(any()))
        .thenAnswer((_) async => const Right(testPage));
    when(() => mockSaveRead(any())).thenAnswer((_) async => const Right(null));
    when(() => mockStreak.recordActivity()).thenAnswer(
      (_) async => const StreakResult.sameDay(),
    );

    when(() => mockKhatmahCubit.state).thenReturn(
      KhatmahActive(
        plan: testPlan,
        wirdStartPage: 41,
        wirdEndPage: 44,
      ),
    );
    when(() => mockKhatmahCubit.stream)
        .thenAnswer((_) => const Stream<KhatmahState>.empty());
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
        buildReaderApp(
          pageNumber: 42,
          readerMode: QuranReaderMode.free,
        ),
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
    });
  });

  group('KhatmahReaderSessionBar widget', () {
    testWidgets('renders active plan title, wird progress, and dedication',
        (tester) async {
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
      expect(find.text('إهداء: والدتي'), findsOneWidget);
      expect(find.text('صفحة ٤٢ (٢ من ٤ من ورد اليوم)'), findsOneWidget);

      final exitBtn = find.text('حفظ وخروج');
      expect(exitBtn, findsOneWidget);
      await tester.tap(exitBtn);
      expect(exitCalled, isTrue);
    });

    testWidgets('renders nothing if state is not KhatmahActive',
        (tester) async {
      when(() => mockKhatmahCubit.state)
          .thenReturn(const KhatmahNoActivePlan());

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
  });
}
