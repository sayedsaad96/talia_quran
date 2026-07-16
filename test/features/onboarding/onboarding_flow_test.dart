import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/onboarding/presentation/cubits/onboarding_cubit.dart';
import 'package:talia_quran/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:talia_quran/features/splash/presentation/pages/splash_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('SplashPage routing', () {
    testWidgets('first launch routes to onboarding', (tester) async {
      await _registerCore();
      await tester.pumpWidget(_TestRouterApp(router: _splashRouter()));
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();

      expect(find.text('onboarding route'), findsOneWidget);
    });

    testWidgets('returning user routes to home', (tester) async {
      await _registerCore(initialPrefs: {'isFirstTimeAppOpen': false});
      await tester.pumpWidget(_TestRouterApp(router: _splashRouter()));
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pumpAndSettle();

      expect(find.text('home route'), findsOneWidget);
    });
  });

  group('Smart onboarding flow', () {
    testWidgets('adult + reading routes to Quran and saves preferences', (
      tester,
    ) async {
      final repo = await _registerCore();
      await _pumpOnboarding(tester);

      await _completeAdultFlow(tester, goalText: 'Daily Reading');

      expect(find.text('quran route'), findsOneWidget);
      expect(repo.selectedPaths, isEmpty);
      _expectCompletedPrefs(goal: 'reading', userType: 'adult');
    });

    testWidgets('adult + memorization sets adult path and routes safely', (
      tester,
    ) async {
      final repo = await _registerCore();
      await _pumpOnboarding(tester);

      await _completeAdultFlow(tester, goalText: 'Memorization for me');

      expect(find.text('custom plan route'), findsOneWidget);
      expect(repo.selectedPaths, [MemorizationPath.adult]);
      _expectCompletedPrefs(goal: 'memorization', userType: 'adult');
    });

    testWidgets(
      'adult + smart_review saves goal without claiming full Smart Coach',
      (tester) async {
        final repo = await _registerCore();
        await _pumpOnboarding(tester);

        await _goNext(tester);
        await _goNext(tester);
        await _tapVisible(tester, 'Review / Improve retention');

        expect(
          find.textContaining('A separate Smart Coach is not enabled'),
          findsOneWidget,
        );

        await _goNext(tester);
        await _goNext(tester);
        await _tapVisible(tester, 'Continue as guest');
        await tester.pumpAndSettle();

        expect(find.text('custom plan route'), findsOneWidget);
        expect(repo.selectedPaths, [MemorizationPath.adult]);
        _expectCompletedPrefs(goal: 'smart_review', userType: 'adult');
      },
    );

    testWidgets('adult + azkar routes to Azkar', (tester) async {
      final repo = await _registerCore();
      await _pumpOnboarding(tester);

      await _completeAdultFlow(tester, goalText: 'Azkar');

      expect(find.text('azkar route'), findsOneWidget);
      expect(repo.selectedPaths, isEmpty);
      _expectCompletedPrefs(goal: 'azkar', userType: 'adult');
    });

    testWidgets('adult + sign-in routes to Login', (tester) async {
      final repo = await _registerCore();
      await _pumpOnboarding(tester);

      await _goNext(tester);
      await _goNext(tester);
      await _tapVisible(tester, 'Daily Reading');
      await _goNext(tester);
      await _goNext(tester);
      await _tapVisible(tester, 'Sign in / Create account');
      await tester.pumpAndSettle();

      expect(find.text('login route'), findsOneWidget);
      expect(repo.selectedPaths, isEmpty);
      _expectCompletedPrefs(goal: 'reading', userType: 'adult');
    });

    testWidgets(
      'child + guest sets child path and routes to child orientation',
      (tester) async {
        final repo = await _registerCore();
        await _pumpOnboarding(tester);

        await _goNext(tester);
        await _tapVisible(tester, 'Child');
        await _goNext(tester);
        await _goNext(tester);
        await _goNext(tester);
        await _tapVisible(tester, 'Continue as guest');
        await tester.pumpAndSettle();

        expect(find.text('child orientation route'), findsOneWidget);
        expect(repo.selectedPaths, [MemorizationPath.child]);
        _expectCompletedPrefs(goal: 'child_journey', userType: 'child');
      },
    );

    testWidgets('child + sign-in sets child path and routes to Login', (
      tester,
    ) async {
      final repo = await _registerCore();
      await _pumpOnboarding(tester);

      await _goNext(tester);
      await _tapVisible(tester, 'Child');
      await _goNext(tester);
      await _goNext(tester);
      await _goNext(tester);
      await _tapVisible(tester, 'Sign in / Create account');
      await tester.pumpAndSettle();

      expect(find.text('login route'), findsOneWidget);
      expect(repo.selectedPaths, [MemorizationPath.child]);
      _expectCompletedPrefs(goal: 'child_journey', userType: 'child');
    });

    testWidgets('skip onboarding routes to Home', (tester) async {
      await _registerCore();
      await _pumpOnboarding(tester);

      await _tapVisible(tester, 'Skip');
      await tester.pumpAndSettle();

      expect(find.text('home route'), findsOneWidget);
      final prefs = getIt<SharedPreferences>();
      expect(prefs.getBool('isFirstTimeAppOpen'), isFalse);
      expect(prefs.getBool('onboarding_skipped'), isTrue);
      expect(prefs.getString('onboarding_completed_at'), isNotNull);
    });

    testWidgets('English onboarding is LTR', (tester) async {
      await _registerCore();
      await _pumpOnboarding(tester);

      final context = tester.element(find.text('Welcome to Talia'));
      expect(Directionality.of(context), TextDirection.ltr);
    });

    testWidgets('Arabic onboarding is RTL', (tester) async {
      await _registerCore();
      await _pumpOnboarding(tester, locale: const Locale('ar'));

      final context = tester.element(find.text('مرحباً بك في تالية'));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('dark and light onboarding smoke test', (tester) async {
      await _registerCore();
      await _pumpOnboarding(tester, themeMode: ThemeMode.dark);
      expect(find.text('Welcome to Talia'), findsOneWidget);

      await _pumpOnboarding(tester, themeMode: ThemeMode.light);
      expect(find.text('Welcome to Talia'), findsOneWidget);
    });

    testWidgets('guest mode remains available on final setup', (tester) async {
      await _registerCore();
      await _pumpOnboarding(tester);

      await _goNext(tester);
      await _goNext(tester);
      await _goNext(tester);
      await _goNext(tester);

      expect(find.text('Continue as guest'), findsOneWidget);
    });
  });
}

Future<_FakeMemorizationRepository> _registerCore({
  Map<String, Object>? initialPrefs,
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs ?? {});
  final prefs = await SharedPreferences.getInstance();
  final repo = _FakeMemorizationRepository();
  final resolver = MemorizationPathResolver(repo);

  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<MemorizationPlusRepository>(repo);
  getIt.registerSingleton<MemorizationPathResolver>(resolver);
  getIt.registerFactory<OnboardingCubit>(
    () => OnboardingCubit(
      prefs: getIt<SharedPreferences>(),
      memorizationRepository: getIt<MemorizationPlusRepository>(),
      pathResolver: getIt<MemorizationPathResolver>(),
    ),
  );
  return repo;
}

Future<void> _pumpOnboarding(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    _TestRouterApp(
      router: _onboardingRouter(),
      locale: locale,
      themeMode: themeMode,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _completeAdultFlow(
  WidgetTester tester, {
  required String goalText,
}) async {
  await _goNext(tester);
  await _goNext(tester);
  await _tapVisible(tester, goalText);
  await _goNext(tester);
  await _goNext(tester);
  await _tapVisible(tester, 'Continue as guest');
  await tester.pumpAndSettle();
}

Future<void> _goNext(WidgetTester tester) => _tapVisible(tester, 'Next');

Future<void> _tapVisible(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

void _expectCompletedPrefs({required String goal, required String userType}) {
  final prefs = getIt<SharedPreferences>();
  expect(prefs.getBool('isFirstTimeAppOpen'), isFalse);
  expect(prefs.getBool('onboarding_skipped'), isFalse);
  expect(prefs.getString('user_primary_goal'), goal);
  expect(prefs.getString('onboarding_user_type'), userType);
  expect(prefs.getString('onboarding_completed_at'), isNotNull);
}

GoRouter _splashRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const Scaffold(body: Text('onboarding route')),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('home route')),
      ),
    ],
  );
}

GoRouter _onboardingRouter() {
  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('home route')),
      ),
      GoRoute(
        path: AppRoutes.quran,
        builder: (_, _) => const Scaffold(body: Text('quran route')),
      ),
      GoRoute(
        path: AppRoutes.azkar,
        builder: (_, _) => const Scaffold(body: Text('azkar route')),
      ),
      GoRoute(
        path: AppRoutes.memorizationPlusCustomPlan,
        builder: (_, _) => const Scaffold(body: Text('custom plan route')),
      ),
      GoRoute(
        path: AppRoutes.memorizationPlusKidsHome,
        builder: (_, _) => const Scaffold(body: Text('kids home route')),
      ),
      GoRoute(
        path: AppRoutes.childOnboarding,
        builder: (_, _) =>
            const Scaffold(body: Text('child orientation route')),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Scaffold(body: Text('login route')),
      ),
    ],
  );
}

class _TestRouterApp extends StatelessWidget {
  const _TestRouterApp({
    required this.router,
    this.locale = const Locale('en'),
    this.themeMode = ThemeMode.light,
  });

  final GoRouter router;
  final Locale locale;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      locale: locale,
      themeMode: themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
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

class _FakeMemorizationRepository implements MemorizationPlusRepository {
  MemorizationProfile? profile;
  final List<MemorizationPath> selectedPaths = [];

  @override
  Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
    MemorizationPath path,
  ) async {
    selectedPaths.add(path);
    profile = _profile(path);
    return Right(profile!);
  }

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async {
    return Right(profile ?? MemorizationProfile.empty());
  }

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> hasPendingCloudWork() async => false;
}

MemorizationProfile _profile(MemorizationPath path) {
  final now = DateTime.utc(2026, 1, 1);
  return MemorizationProfile(
    schemaVersion: 1,
    selectedPath: path,
    guardianLinkStatus: GuardianLinkStatus.none,
    guardianOnboardingStatus: path == MemorizationPath.child
        ? GuardianOnboardingStatus.required
        : GuardianOnboardingStatus.completed,
    isParentGuardian: false,
    createdAt: now,
    updatedAt: now,
  );
}
