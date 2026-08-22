import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/onboarding/presentation/cubits/onboarding_cubit.dart';
import 'package:talia_quran/features/onboarding/presentation/pages/onboarding_page.dart';

/// Renders the onboarding with real fonts and real assets and captures
/// golden screenshots for visual inspection. Run with --update-goldens to
/// (re)write the PNGs under .impeccable/shots/.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadRealFonts();
  });

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    await _registerCore();
  });

  tearDown(() async {
    await getIt.reset();
  });

  final variants = [
    ('ar_welcome', const Locale('ar'), 0, false),
    ('ar_fork_adult', const Locale('ar'), 1, false),
    ('ar_fork_child', const Locale('ar'), 1, true),
    ('en_welcome', const Locale('en'), 0, false),
    ('en_fork_adult', const Locale('en'), 1, false),
  ];

  for (final (name, locale, step, selectChild) in variants) {
    testWidgets('capture $name', (tester) async {
      await _bindPhoneSurface(tester);
      // Real image decoding needs real async IO; fake-async never resolves
      // it. Pump a throwaway app to get a context, precache every asset the
      // flow paints, then build the real one.
      await tester.pumpWidget(const MaterialApp());
      final hostContext = tester.element(find.byType(MaterialApp));
      await tester.runAsync(() async {
        for (final asset in _shotAssets) {
          await precacheImage(AssetImage(asset), hostContext);
        }
      });
      await tester.pumpWidget(
        _ShotApp(locale: locale, router: _onboardingRouter()),
      );

      if (step == 1) {
        await tester.tap(find.text(_startJourneyLabel(locale)));
        await tester.pumpAndSettle();
      }
      if (selectChild) {
        await tester.ensureVisible(find.text(_kidsJourneyLabel(locale)).first);
        await tester.tap(find.text(_kidsJourneyLabel(locale)).first);
        await tester.pumpAndSettle();
      }
      // Delayed entrance animations start on timers; step the clock past
      // every delay, then settle so the frame is fully advanced.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(OnboardingPage),
        matchesGoldenFile('../../../.impeccable/shots/onboarding_$name.png'),
      );
    });
  }
}

const _shotAssets = [
  'assets/images/onboarding/splash_new.png',
  'assets/images/logo_new_padded.png',
  'assets/images/character/Talia_Master_Character.png',
];

String _startJourneyLabel(Locale locale) =>
    locale.languageCode == 'ar' ? 'ابدأ رحلتك' : 'Start Your Journey';

String _kidsJourneyLabel(Locale locale) => locale.languageCode == 'ar'
    ? 'مسار البراعم والأطفال'
    : 'Kids & Buds Journey';

Future<void> _bindPhoneSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(780, 1688); // 390x844 @2x
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

Future<void> _loadRealFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final data = rootBundle.load(path);
      loader.addFont(data);
    }
    await loader.load();
  }

  await load('Amiri', [
    'assets/fonts/Amiri/Amiri-Regular.ttf',
    'assets/fonts/Amiri/Amiri-Bold.ttf',
  ]);
  await load('Noto_Naskh_Arabic', [
    'assets/fonts/Noto_Naskh_Arabic/NotoNaskhArabic-Regular.ttf',
    'assets/fonts/Noto_Naskh_Arabic/NotoNaskhArabic-Bold.ttf',
  ]);
}

GoRouter _onboardingRouter() {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
    ],
  );
}

class _ShotApp extends StatelessWidget {
  const _ShotApp({required this.locale, required this.router});

  final Locale locale;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      locale: locale,
      themeMode: ThemeMode.light,
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

Future<void> _registerCore() async {
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
}

class _FakeMemorizationRepository implements MemorizationPlusRepository {
  MemorizationProfile? profile;
  final List<MemorizationPath> selectedPaths = [];

  @override
  Future<dartz.Either<Failure, MemorizationProfile>> selectMemorizationPath(
    MemorizationPath path,
  ) async {
    selectedPaths.add(path);
    profile = _profile(path);
    return dartz.Right(profile!);
  }

  @override
  Future<dartz.Either<Failure, MemorizationProfile>>
  getMemorizationProfile() async {
    return dartz.Right(profile ?? MemorizationProfile.empty());
  }

  @override
  Future<dartz.Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      const dartz.Right(null);

  @override
  Future<dartz.Either<Failure, CustomMemorizationPlan?>>
  getCustomPlan() async => const dartz.Right(null);

  @override
  Future<dartz.Either<Failure, List<KidsSessionLog>>>
  getKidsSessionLogs() async => const dartz.Right([]);

  @override
  Future<dartz.Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async => const dartz.Right([]);

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
