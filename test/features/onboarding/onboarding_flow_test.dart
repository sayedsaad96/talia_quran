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
import 'package:talia_quran/core/services/app_initializer.dart';
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
    AppInitializer.resetForTesting(initialized: true);
  });

  tearDown(() async {
    await getIt.reset();
    AppInitializer.resetForTesting();
  });

  group('SplashPage routing', () {
    testWidgets('first launch routes to onboarding', (tester) async {
      await _registerCore();
      await tester.pumpWidget(_TestRouterApp(router: _splashRouter()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('onboarding route'), findsOneWidget);
    });

    testWidgets('returning user routes to home', (tester) async {
      await _registerCore(initialPrefs: {'isFirstTimeAppOpen': false});
      await tester.pumpWidget(_TestRouterApp(router: _splashRouter()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('home route'), findsOneWidget);
    });
  });

  group('Streamlined 2-step onboarding flow', () {
    testWidgets('adult guest flow routes directly to Home and saves preferences', (
      tester,
    ) async {
      final repo = await _registerCore();
      await _pumpOnboarding(tester);

      // Step 1: Welcome -> Start Journey
      await _tapVisible(tester, 'Start Your Journey');
      // Step 2: Adult is selected by default -> Continue as guest
      await _tapVisible(tester, 'Continue as guest');
      await tester.pumpAndSettle();

      expect(find.text('home route'), findsOneWidget);
      expect(repo.selectedPaths, isEmpty);
      _expectCompletedPrefs(goal: 'reading', userType: 'adult');
    });

    testWidgets('adult sign-in routes to Login and saves preferences', (
      tester,
    ) async {
      final repo = await _registerCore();
      await _pumpOnboarding(tester);

      await _tapVisible(tester, 'Start Your Journey');
      await _tapVisible(tester, 'Sign in / Create account');
      await tester.pumpAndSettle();

      expect(find.text('login route'), findsOneWidget);
      expect(repo.selectedPaths, isEmpty);
      _expectCompletedPrefs(goal: 'reading', userType: 'adult');
    });

    testWidgets('child guest sets child path and routes directly to kids destination', (
      tester,
    ) async {
      final repo = await _registerCore();
      await _pumpOnboarding(tester);

      await _tapVisible(tester, 'Start Your Journey');
      await _tapVisible(tester, 'Kids & Buds Journey');
      await _tapVisible(tester, 'Continue as guest');
      await tester.pumpAndSettle();

      expect(find.text('kids home route'), findsOneWidget);
      expect(repo.selectedPaths, [MemorizationPath.child]);
      _expectCompletedPrefs(goal: 'child_journey', userType: 'child');
    });

    testWidgets('child sign-in sets child path and routes to Login', (
      tester,
    ) async {
      final repo = await _registerCore();
      await _pumpOnboarding(tester);

      await _tapVisible(tester, 'Start Your Journey');
      await _tapVisible(tester, 'Kids & Buds Journey');
      await _tapVisible(tester, 'Sign in / Create account');
      await tester.pumpAndSettle();

      expect(find.text('login route'), findsOneWidget);
      expect(repo.selectedPaths, [MemorizationPath.child]);
      _expectCompletedPrefs(goal: 'child_journey', userType: 'child');
    });

    testWidgets('skip onboarding routes to Home with defaults', (tester) async {
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

    testWidgets('welcome uses the hero artwork as the only brand mark', (
      tester,
    ) async {
      await _registerCore();
      await _pumpOnboarding(tester);

      expect(
        find.image(const AssetImage('assets/images/logo_new_padded.png')),
        findsNothing,
      );
      expect(
        find.image(const AssetImage('assets/images/onboarding/splash_new.png')),
        findsOneWidget,
      );
    });

    testWidgets('welcome copy stays visually separated from the hero artwork', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _registerCore();
      await _pumpOnboarding(tester);

      final heroBottom = tester
          .getRect(
            find.image(
              const AssetImage('assets/images/onboarding/splash_new.png'),
            ),
          )
          .bottom;
      final titleTop = tester.getRect(find.text('Welcome to Talia')).top;

      expect(titleTop - heroBottom, greaterThanOrEqualTo(16));
    });

    testWidgets('fork shows living previews, trust line, and two waypoints', (
      tester,
    ) async {
      await _registerCore();
      await _pumpOnboarding(tester);

      await _tapVisible(tester, 'Start Your Journey');

      // The mushaf window and the child night window prove both worlds.
      expect(find.text('وَرَتِّلِ ٱلْقُرْآنَ تَرْتِيلًا'), findsOneWidget);
      expect(
        find.image(
          const AssetImage(
            'assets/images/character/Talia_Master_Character.png',
          ),
        ),
        findsOneWidget,
      );
      // Offline-first trust line under the guest CTA.
      expect(
        find.text('Works offline · your data stays on your device'),
        findsOneWidget,
      );
      // Both destination titles are present at the fork.
      expect(find.text('Adult & General Journey'), findsOneWidget);
      expect(find.text('Kids & Buds Journey'), findsOneWidget);
    });

    testWidgets('back button returns from the fork to the horizon', (
      tester,
    ) async {
      await _registerCore();
      await _pumpOnboarding(tester);

      await _tapVisible(tester, 'Start Your Journey');
      expect(find.text('Welcome to Talia'), findsNothing);

      await tester.tap(find.byTooltip('Previous'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Talia'), findsOneWidget);
    });

    testWidgets('swiping the PageView keeps the cubit step in sync', (
      tester,
    ) async {
      await _registerCore();
      await _pumpOnboarding(tester);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Experience'), findsOneWidget);
      // Step synced: the back affordance appeared with the fork.
      expect(find.byTooltip('Previous'), findsOneWidget);
    });

    testWidgets('child-path failure shows a recovery error, skip still works', (
      tester,
    ) async {
      final repo = await _registerCore();
      await _pumpOnboarding(tester);

      await _tapVisible(tester, 'Start Your Journey');
      await _tapVisible(tester, 'Kids & Buds Journey');

      repo.failNextSelect = StateError('disk full');
      await _tapVisible(tester, 'Continue as guest');
      await tester.pumpAndSettle();

      // Localized recovery copy, not the raw exception string.
      expect(find.textContaining('Setup could not finish'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Nothing was persisted through the failure — the journey can retry.
      expect(
        getIt<SharedPreferences>().getBool('isFirstTimeAppOpen'),
        isNot(false),
      );

      // Skip is the recovery path out of the error state.
      await _tapVisible(tester, 'Skip');
      await tester.pumpAndSettle();
      expect(find.text('home route'), findsOneWidget);
      expect(getIt<SharedPreferences>().getBool('onboarding_skipped'), isTrue);
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

  /// When set, the next [selectMemorizationPath] call throws instead.
  Object? failNextSelect;

  @override
  Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
    MemorizationPath path,
  ) async {
    final failure = failNextSelect;
    if (failure != null) {
      failNextSelect = null;
      throw failure;
    }
    selectedPaths.add(path);
    profile = _profile(path);
    return Right(profile!);
  }

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async {
    return Right(profile ?? MemorizationProfile.empty());
  }

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async =>
      const Right([]);

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async =>
      const Right([]);

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
