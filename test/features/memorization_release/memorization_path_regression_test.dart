import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/constants/xp_constants.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/core/theme/theme_cubit.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/hifz/domain/usecases/get_hifz_progress_usecase.dart';
import 'package:talia_quran/features/hifz/presentation/cubits/hifz_session_cubit.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/presentation/pages/home_page.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/daily_plan_cubit.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/progress/presentation/cubits/progress_cubit.dart';
import 'package:talia_quran/features/progress/presentation/pages/progress_page.dart';
import 'package:talia_quran/features/quran/domain/usecases/get_surahs_usecase.dart';
import 'package:talia_quran/features/settings/data/user_profile.dart';
import 'package:talia_quran/features/settings/domain/repositories/settings_repository.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';
import 'package:talia_quran/features/streak/presentation/cubits/streak_cubit.dart';
import 'package:talia_quran/features/xp/domain/entities/xp_gain_result.dart';

import '../memorization_plus/presentation/cubits/guardian_linking_cubit_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'onboarding_skipped': true,
      'first_action_completed': false,
      'home_tutorial_prompt_seen': true,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugin.csdcorp.com/speech_to_text'),
          (_) async => true,
        );
    await getIt.reset();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugin.csdcorp.com/speech_to_text'),
          null,
        );
    await getIt.reset();
  });

  group('Home memorization path cards and routes', () {
    testWidgets('shows Kids-specific cards and routes when profile is Kids', (
      tester,
    ) async {
      await _registerHomeDependencies(
        _homeState(isKids: true, selectedTrack: MemorizationTrack.kids),
      );

      final router = _homeRouter();
      await tester.pumpWidget(
        _AppShell(router: router, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current Mission'), findsOneWidget);
      expect(find.text('Parent Dashboard'), findsNothing);
      expect(find.text('Memorization Journey'), findsNothing);
      expect(find.text('Smart Memorization'), findsNothing);

      await tester.ensureVisible(find.text('Current Mission'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Current Mission'));
      await tester.pumpAndSettle();

      expect(find.text('memorization hub'), findsOneWidget);
    });

    testWidgets('keeps Adult cards and routes when profile is Adult', (
      tester,
    ) async {
      await _registerHomeDependencies(
        _homeState(isKids: false, selectedTrack: MemorizationTrack.adults),
      );

      final router = _homeRouter();
      await tester.pumpWidget(
        _AppShell(router: router, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text("Today's Plan"), findsWidgets);
      expect(find.text('Parent Dashboard'), findsNothing);
      expect(find.text('Smart Memorization'), findsNothing);
      expect(find.text('Memorization Journey'), findsNothing);

      await tester.ensureVisible(find.text("Today's Plan").first);
      await tester.pumpAndSettle();
      await tester.tap(find.text("Today's Plan").first);
      await tester.pumpAndSettle();

      expect(find.text('memorization hub'), findsOneWidget);
    });

    testWidgets('shows parent tools for signed-in adult parent mode', (
      tester,
    ) async {
      await _registerHomeDependencies(
        _homeState(
          isKids: false,
          selectedTrack: MemorizationTrack.adults,
          isParentMode: true,
        ),
      );

      final router = _homeRouter();
      await tester.pumpWidget(
        _AppShell(router: router, signedIn: true, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parent / Guardian Tools'), findsOneWidget);
      expect(
        find.text('Monitor your child’s progress and rewards'),
        findsOneWidget,
      );
      expect(find.text('Open Parent Dashboard'), findsOneWidget);
    });

    testWidgets('hides parent tools for child users', (tester) async {
      await _registerHomeDependencies(
        _homeState(
          isKids: true,
          selectedTrack: MemorizationTrack.kids,
          isParentMode: true,
        ),
      );

      final router = _homeRouter();
      await tester.pumpWidget(
        _AppShell(router: router, signedIn: true, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parent / Guardian Tools'), findsNothing);
    });

    testWidgets('hides parent tools without parent mode', (tester) async {
      await _registerHomeDependencies(
        _homeState(isKids: false, selectedTrack: MemorizationTrack.adults),
      );

      final router = _homeRouter();
      await tester.pumpWidget(
        _AppShell(router: router, signedIn: true, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parent / Guardian Tools'), findsNothing);
    });

    testWidgets('hides parent tools for guest adult parent mode', (
      tester,
    ) async {
      await _registerHomeDependencies(
        _homeState(
          isKids: false,
          selectedTrack: MemorizationTrack.adults,
          isParentMode: true,
        ),
      );

      final router = _homeRouter();
      await tester.pumpWidget(
        _AppShell(router: router, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parent / Guardian Tools'), findsNothing);
    });

    testWidgets('labels Kids resume by the current stage', (tester) async {
      await _registerHomeDependencies(
        _homeState(
          isKids: true,
          selectedTrack: MemorizationTrack.kids,
          lastRestorableLocation:
              '${AppRoutes.memorizationPlusKids}?surahId=2&ayahNumber=11',
        ),
      );

      final router = _homeRouter();
      await tester.pumpWidget(
        _AppShell(router: router, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue Stage 3'), findsOneWidget);
      expect(find.text('Surah Al-Baqarah, ayah 11'), findsOneWidget);
    });

    testWidgets('labels daily plan resume as today memorization', (
      tester,
    ) async {
      await _registerHomeDependencies(
        _homeState(
          isKids: false,
          selectedTrack: MemorizationTrack.adults,
          lastRestorableLocation:
              '${AppRoutes.memorizationPlusDailyPlan}?surahId=2',
        ),
      );

      final router = _homeRouter();
      await tester.pumpWidget(
        _AppShell(router: router, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text("Continue Today's Plan"), findsOneWidget);
      expect(find.text('Surah Al-Baqarah'), findsOneWidget);
    });

    testWidgets('labels Quran page resume as Quran reading', (tester) async {
      await _registerHomeDependencies(
        _homeState(
          isKids: false,
          selectedTrack: MemorizationTrack.adults,
          lastRestorableLocation: '/quran/page/42',
        ),
      );

      final router = _homeRouter();
      await tester.pumpWidget(
        _AppShell(router: router, child: const HomePage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue Quran Reading'), findsOneWidget);
      expect(find.text('Page 42'), findsOneWidget);
    });
  });

  group('Progress memorization path display', () {
    testWidgets('hides adult/global memorization totals for Kids', (
      tester,
    ) async {
      await _registerProgressDependencies(
        ProgressLoaded(
          progress: _progress(kidsPoints: 42, kidsStars: 3),
          selectedPath: MemorizationPath.child,
          isKids: true,
        ),
      );

      await tester.pumpWidget(const _AppShell(child: ProgressPage()));
      await tester.pumpAndSettle();

      expect(find.text('Kids Track'), findsOneWidget);
      expect(find.text('Points'), findsOneWidget);
      expect(find.text('Stars'), findsOneWidget);
      expect(find.text('Ayahs Memorized'), findsNothing);
      expect(find.text('0 / 6236'), findsOneWidget);
    });

    testWidgets('keeps adult memorization stats for Adult', (tester) async {
      await _registerProgressDependencies(
        ProgressLoaded(
          progress: _progress(),
          selectedPath: MemorizationPath.adult,
          isKids: false,
        ),
      );

      await tester.pumpWidget(const _AppShell(child: ProgressPage()));
      await tester.pumpAndSettle();

      expect(find.text('Ayahs Memorized'), findsOneWidget);
      expect(find.text('0 / 6236'), findsWidgets);
      expect(find.text('Kids Track'), findsNothing);
    });
  });

  group('Memorization route guards', () {
    testWidgets(
      'sends Adult memorization entry to Today Plan without forcing plan setup',
      (tester) async {
        await _registerRouteDependencies(_profile(MemorizationPath.adult));

        final router = _guardRouter(
          initialLocation: AppRoutes.memorizationPlus,
        );
        await tester.pumpWidget(_LocalizedRouter(router));
        await tester.pumpAndSettle();

        expect(find.text('adult daily plan'), findsOneWidget);
        expect(find.text('adult entry'), findsNothing);

        router.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('redirect Kids profile away from adult memorization routes', (
      tester,
    ) async {
      await _registerRouteDependencies(_profile(MemorizationPath.child));

      for (final entry in <String, String>{
        AppRoutes.memorizationPlus: 'kids hub',
        AppRoutes.memorizationPlusDailyPlan: 'kids hub',
        AppRoutes.hifz: 'kids hub',
        AppRoutes.hifzSession: 'kids hub',
        '${AppRoutes.memorizationPlusKidsJourney}/114': 'kids journey',
        '${AppRoutes.hifzSession}?surahId=114&startAyah=1': 'kids listen',
      }.entries) {
        final router = _guardRouter(initialLocation: entry.key);
        await tester.pumpWidget(_LocalizedRouter(router));
        await tester.pumpAndSettle();

        expect(find.text(entry.value), findsOneWidget);

        router.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('protects parent dashboard from Kids profiles', (tester) async {
      await _registerRouteDependencies(_profile(MemorizationPath.child));

      final router = _guardRouter(initialLocation: AppRoutes.parentDashboard);
      await tester.pumpWidget(_LocalizedRouter(router));
      await tester.pumpAndSettle();

      expect(find.text('kids hub'), findsOneWidget);
      expect(find.text('parent dashboard'), findsNothing);

      router.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('allows adult profiles to reach parent dashboard', (
      tester,
    ) async {
      await _registerRouteDependencies(_profile(MemorizationPath.adult));

      final router = _guardRouter(initialLocation: AppRoutes.parentDashboard);
      await tester.pumpWidget(_LocalizedRouter(router));
      await tester.pumpAndSettle();

      expect(find.text('parent dashboard'), findsOneWidget);

      router.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('Cubit path guards', () {
    test('DailyPlanCubit rejects Kids profile with redirect state', () async {
      final repo = _profileRepository(_profile(MemorizationPath.child));
      final generate = _CountingGenerateDailyPlanUsecase(_dailyPlan());
      final cached = _CountingCachedDailyPlanUsecase(null);
      final cubit = DailyPlanCubit(
        generate,
        cached,
        _CountingEvaluateMemorizationUsecase(),
        _CountingSaveDailyPlanUsecase(),
        MockAchievementService(),
        MockStreakService(),
        MockXpService(),
        MemorizationPathResolver(repo),
      );

      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([const DailyPlanLoading(), const DailyPlanKidsRedirect()]),
      );

      await cubit.load(surahId: 114);
      await expectation;

      expect(generate.calls, 0);
      expect(cached.calls, 0);
    });

    test('HifzSessionCubit rejects Kids profile', () async {
      final repo = _profileRepository(_profile(MemorizationPath.child));
      final saveProgress = MockSaveAyahProgressUsecase();
      final cubit = HifzSessionCubit(
        MockGetSurahsUsecase(),
        MockGetSurahDetailUsecase(),
        saveProgress,
        MockGetProgressForSurahUsecase(),
        MockGetHifzProgressUsecase(),
        MockGetHifzPathUsecase(),
        MockGenerateHifzSegmentsUsecase(),
        MockCheckNextAyahUnlockUsecase(),
        MockGetNextRequiredReviewCheckpointUsecase(),
        MockGetPassedCheckpointKeysUsecase(),
        MockMarkCheckpointReviewPassedUsecase(),
        MockSettingsRepository(),
        MockStreakService(),
        MockXpService(),
        MockAchievementService(),
        repo,
      );

      addTearDown(cubit.close);

      await cubit.startSession(114, 1);

      final state = cubit.state;
      expect(state, isA<HifzSessionError>());
      expect((state as HifzSessionError).redirectToKidsHome, isTrue);
      expect(saveProgress.calls, 0);
    });

    test(
      'opening daily plan without completion does not increase progress',
      () async {
        final repo = _profileRepository(_profile(MemorizationPath.adult));
        final cachedPlan = _dailyPlan();
        final generate = _CountingGenerateDailyPlanUsecase(_dailyPlan());
        final cached = _CountingCachedDailyPlanUsecase(cachedPlan);
        final evaluate = _CountingEvaluateMemorizationUsecase();
        final save = _CountingSaveDailyPlanUsecase();
        final cubit = DailyPlanCubit(
          generate,
          cached,
          evaluate,
          save,
          MockAchievementService(),
          MockStreakService(),
          MockXpService(),
          MemorizationPathResolver(repo),
        );

        addTearDown(cubit.close);

        await cubit.load(surahId: 114);

        expect(cubit.state, isA<DailyPlanLoaded>());
        expect(generate.calls, 0);
        expect(cached.calls, 1);
        expect(evaluate.calls, 0);
        expect(save.calls, 0);
      },
    );
  });
}

Future<void> _registerHomeDependencies(HomeLoaded state) async {
  final prefs = await SharedPreferences.getInstance();

  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<XpService>(_FakeXpService());
  getIt.registerSingleton<MemorizationPlusRepository>(
    _profileRepository(
      _profile(
        state.isKids ? MemorizationPath.child : MemorizationPath.adult,
        isParentGuardian: state.isParentMode,
      ),
    ),
  );
  getIt.registerFactory<HomeCubit>(() => _FakeHomeCubit(state));
  getIt.registerFactory<StreakCubit>(
    () => _FakeStreakCubit(
      const StreakLoaded(
        streak: StreakEntity(currentStreak: 0, longestStreak: 0),
      ),
    ),
  );
}

Future<void> _registerProgressDependencies(ProgressLoaded state) async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<AchievementService>(_FakeAchievementService());
  getIt.registerFactory<ProgressCubit>(() => _FakeProgressCubit(state));
}

Future<void> _registerRouteDependencies(MemorizationProfile profile) async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<MemorizationPlusRepository>(
    _profileRepository(profile),
  );
}

GoRouter _homeRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: AppRoutes.memorizationHub,
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('memorization hub'))),
      ),
      GoRoute(
        path: AppRoutes.memorizationPlusKidsHome,
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('kids memorization hub'))),
      ),
      GoRoute(
        path: AppRoutes.quran,
        builder: (_, _) => const Scaffold(body: Center(child: Text('quran'))),
      ),
      GoRoute(
        path: AppRoutes.parentDashboard,
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('parent dashboard'))),
      ),
      GoRoute(
        path: AppRoutes.tutorialGuide,
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('tutorial'))),
      ),
    ],
  );
}

GoRouter _guardRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.memorizationPlus,
        redirect: (_, _) => MemorizationRouteGuard.entryRedirect(),
        builder: (_, _) => const Text('adult entry'),
      ),
      GoRoute(
        path: AppRoutes.memorizationPlusDailyPlan,
        redirect: (_, _) => MemorizationRouteGuard.adultOnlyRedirect(),
        builder: (_, _) => const Text('adult daily plan'),
      ),
      GoRoute(
        path: AppRoutes.hifz,
        redirect: (_, _) => MemorizationRouteGuard.hifzRedirect(),
        builder: (_, _) => const Text('adult hifz'),
      ),
      GoRoute(
        path: AppRoutes.hifzSession,
        redirect: (_, state) =>
            MemorizationRouteGuard.hifzSessionRedirect(state),
        builder: (_, _) => const Text('adult hifz session'),
      ),
      GoRoute(
        path: AppRoutes.memorizationPlusKidsHome,
        builder: (_, _) => const Text('kids hub'),
      ),
      GoRoute(
        path: AppRoutes.parentDashboard,
        redirect: (_, _) => MemorizationRouteGuard.parentDashboardRedirect(),
        builder: (_, _) => const Text('parent dashboard'),
      ),
      GoRoute(
        path: '${AppRoutes.memorizationPlusKidsJourney}/:surahId',
        redirect: (_, _) => MemorizationRouteGuard.kidsOnlyRedirect(),
        builder: (_, _) => const Text('kids journey'),
      ),
      GoRoute(
        path: AppRoutes.memorizationPlusKids,
        builder: (_, _) => const Text('kids listen'),
      ),
    ],
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({this.child, this.router, this.signedIn = false});

  final Widget? child;
  final GoRouter? router;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => _FakeAuthCubit(signedIn)),
        BlocProvider<ProfileCubit>(create: (_) => _FakeProfileCubit()),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(getIt<SharedPreferences>())..loadTheme(),
        ),
      ],
      child: router == null
          ? _LocalizedApp(child: child!)
          : _LocalizedRouter(router!),
    );
  }
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

class _LocalizedRouter extends StatelessWidget {
  const _LocalizedRouter(this.router);

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

HomeLoaded _homeState({
  required bool isKids,
  required MemorizationTrack selectedTrack,
  bool isParentMode = false,
  String? lastRestorableLocation,
}) {
  return HomeLoaded(
    progress: _progress(kidsPoints: isKids ? 42 : 0, kidsStars: isKids ? 3 : 0),
    hifzSurahProgress: const [],
    greeting: 'Assalamu alaikum',
    selectedTrack: selectedTrack,
    isParentMode: isParentMode,
    isKids: isKids,
    lastRestorableLocation: lastRestorableLocation,
    activityStartDate: DateTime.utc(2026, 1, 1),
  );
}

OverallProgress _progress({int kidsPoints = 0, int kidsStars = 0}) {
  return OverallProgress(
    memorizedAyahs: 0,
    totalAyahs: 6236,
    memorizedSurahs: 0,
    totalSurahs: 114,
    memorizedJuz: 0,
    totalJuz: 30,
    readAyahs: 0,
    readSurahs: 0,
    readJuz: 0,
    streakDays: 0,
    lastActiveDate: null,
    achievements: const [],
    readPagesCount: 0,
    totalQuranPages: 604,
    learningAyahs: 0,
    reviewAyahs: 0,
    kidsPoints: kidsPoints,
    kidsStars: kidsStars,
  );
}

MemorizationProfile _profile(
  MemorizationPath path, {
  bool isParentGuardian = false,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return MemorizationProfile(
    schemaVersion: 1,
    selectedPath: path,
    guardianLinkStatus: GuardianLinkStatus.none,
    guardianOnboardingStatus: GuardianOnboardingStatus.skipped,
    isParentGuardian: isParentGuardian,
    createdAt: now,
    updatedAt: now,
  );
}

MemorizationPlusRepository _profileRepository(MemorizationProfile profile) =>
    _ProfileRepository(profile);

DailyPlan _dailyPlan() {
  return DailyPlan(
    generatedAt: DateTime.utc(2026, 1, 1),
    surahId: 114,
    newAyahs: const [
      DailyPlanAyah(
        surahId: 114,
        ayahNumber: 1,
        ayahText: 'test',
        record: null,
      ),
    ],
    nearRevision: const [],
    farRevision: const [],
    completedAyahNums: const [],
  );
}

class _FakeHomeCubit extends Cubit<HomeState> implements HomeCubit {
  _FakeHomeCubit(super.initialState);

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProgressCubit extends Cubit<ProgressState> implements ProgressCubit {
  _FakeProgressCubit(super.initialState);

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakCubit extends Cubit<StreakState> implements StreakCubit {
  _FakeStreakCubit(super.initialState);

  @override
  Future<void> loadStreak() async {}

  @override
  Future<StreakResult> recordActivity() async => const StreakResult.sameDay();

  @override
  Future<void> useFreeze() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _FakeAuthCubit(bool signedIn)
    : super(
        signedIn
            ? const AuthAuthenticated(
                user: AppUser(
                  id: 'adult-parent',
                  email: 'parent@example.com',
                  displayName: 'Parent',
                ),
              )
            : const AuthUnauthenticated(),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileCubit extends Cubit<ProfileState> implements ProfileCubit {
  _FakeProfileCubit() : super(const ProfileLoaded(UserProfile()));

  @override
  void loadProfile() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeXpService implements XpService {
  @override
  Future<XpGainResult> addXp(String eventKey) async =>
      const XpGainResult.zero();

  @override
  XpLevel getCurrentLevel(int xp) => XpConstants.levels.first;

  @override
  Future<int> getTotalXp() async => 0;
}

class _FakeAchievementService implements AchievementService {
  @override
  bool get hasNewCertificate => false;

  @override
  List<CertificateAward> getEarnedCertificates() => const [];

  @override
  void markCertificatesSeen() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfileRepository implements MemorizationPlusRepository {
  const _ProfileRepository(this.profile);

  final MemorizationProfile profile;

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async =>
      Right(profile);

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      Right(_dailyPlan());

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords() async =>
      const Right([]);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async =>
      const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountingGenerateDailyPlanUsecase extends GenerateDailyPlanUsecase {
  _CountingGenerateDailyPlanUsecase(this.plan)
    : super(MockMemorizationPlusRepository());

  final DailyPlan plan;
  int calls = 0;

  @override
  Future<Either<Failure, DailyPlan>> call(
    GenerateDailyPlanParams params,
  ) async {
    calls++;
    return Right(plan);
  }
}

class _CountingCachedDailyPlanUsecase extends GetCachedDailyPlanUsecase {
  _CountingCachedDailyPlanUsecase(this.plan)
    : super(MockMemorizationPlusRepository());

  final DailyPlan? plan;
  int calls = 0;

  @override
  Future<Either<Failure, DailyPlan?>> call() async {
    calls++;
    return Right(plan);
  }
}

class _CountingEvaluateMemorizationUsecase extends EvaluateMemorizationUsecase {
  _CountingEvaluateMemorizationUsecase()
    : super(MockMemorizationPlusRepository());

  int calls = 0;

  @override
  Future<Either<Failure, AyahReviewRecord>> call(
    EvaluateMemorizationParams params,
  ) async {
    calls++;
    return Right(
      AyahReviewRecord(
        surahId: params.surahId,
        ayahNumber: params.ayahNumber,
        strengthLevel: 1,
        intervalDays: 1,
        lastReviewedAt: DateTime.utc(2026, 1, 1),
        nextReviewDate: DateTime.utc(2026, 1, 2),
        totalReviews: 1,
        lastRating: params.rating,
      ),
    );
  }
}

class _CountingSaveDailyPlanUsecase extends SaveDailyPlanUsecase {
  _CountingSaveDailyPlanUsecase() : super(MockMemorizationPlusRepository());

  int calls = 0;

  @override
  Future<Either<Failure, void>> call(DailyPlan plan) async {
    calls++;
    return const Right(null);
  }
}

class MockAchievementService extends Mock implements AchievementService {}

class MockStreakService extends Mock implements StreakService {}

class MockXpService extends Mock implements XpService {}

class MockGetSurahsUsecase extends Mock implements GetSurahsUsecase {}

class MockGetSurahDetailUsecase extends Mock implements GetSurahDetailUsecase {}

class MockSaveAyahProgressUsecase extends Mock
    implements SaveAyahProgressUsecase {
  int calls = 0;

  @override
  dynamic noSuchMethod(
    Invocation invocation, {
    Object? returnValue,
    Object? returnValueForMissingStub,
  }) {
    if (invocation.memberName == #call) calls++;
    return super.noSuchMethod(
      invocation,
      returnValue: returnValue,
      returnValueForMissingStub: returnValueForMissingStub,
    );
  }
}

class MockGetProgressForSurahUsecase extends Mock
    implements GetProgressForSurahUsecase {}

class MockGetHifzProgressUsecase extends Mock
    implements GetHifzProgressUsecase {}

class MockGetHifzPathUsecase extends Mock implements GetHifzPathUsecase {}

class MockGenerateHifzSegmentsUsecase extends Mock
    implements GenerateHifzSegmentsUsecase {}

class MockCheckNextAyahUnlockUsecase extends Mock
    implements CheckNextAyahUnlockUsecase {}

class MockGetNextRequiredReviewCheckpointUsecase extends Mock
    implements GetNextRequiredReviewCheckpointUsecase {}

class MockGetPassedCheckpointKeysUsecase extends Mock
    implements GetPassedCheckpointKeysUsecase {}

class MockMarkCheckpointReviewPassedUsecase extends Mock
    implements MarkCheckpointReviewPassedUsecase {}

class MockSettingsRepository extends Mock implements SettingsRepository {}
