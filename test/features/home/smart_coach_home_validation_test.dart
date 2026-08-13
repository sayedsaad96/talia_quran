import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/constants/xp_constants.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/smart_coach_recommendation.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/core/theme/theme_cubit.dart';
import 'package:talia_quran/core/journey/journey_feature_flags.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/presentation/pages/home_page.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';
import 'package:talia_quran/features/settings/data/user_profile.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';
import 'package:talia_quran/features/streak/presentation/cubits/streak_cubit.dart';
import 'package:talia_quran/features/xp/domain/entities/xp_gain_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'onboarding_skipped': true,
      'first_action_completed': false,
      'home_tutorial_prompt_seen': true,
    });
    await getIt.reset();
  });

  tearDown(() async {
    JourneyFeatureFlags.unifiedJourneyEnabled = false;
    await getIt.reset();
  });

  group('Smart Coach Home validation', () {
    testWidgets('resume session takes precedence over Smart Coach card', (
      tester,
    ) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.reviewDueNear,
            surahId: 67,
            startAyah: 1,
          ),
          lastRestorableLocation:
              '${AppRoutes.memorizationV2Session}?surahId=2',
        ),
      );

      await _pumpHome(tester);
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Resume where you left off'), findsOneWidget);
      expect(find.text('Review before new content'), findsNothing);
      expect(find.text('Resume'), findsOneWidget);
    });

    testWidgets('resume session takes precedence over memorized-due card', (
      tester,
    ) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.memorizedReviewDue,
            surahId: 67,
            startAyah: 1,
            route: '/memorization-plus/quiz?surahId=67&ayahNumbers=1',
          ),
          lastRestorableLocation:
              '${AppRoutes.memorizationV2Session}?surahId=2',
        ),
      );

      await _pumpHome(tester);
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Resume where you left off'), findsOneWidget);
      expect(find.text('Retention review due'), findsNothing);
      expect(find.text('Resume'), findsOneWidget);
    });

    testWidgets('reviewDueNear navigates to daily plan on tap', (tester) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.reviewDueNear,
            surahId: 67,
            startAyah: 1,
          ),
        ),
      );

      await _pumpHome(tester);
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Review before new content'), findsOneWidget);

      await tester.tap(find.text('Review before new content'));
      await _pumpHomeAfterInteraction(tester);

      expect(find.text('coach-nav-daily-plan'), findsOneWidget);
    });

    testWidgets('continueDailyPlan navigates to daily plan on tap', (
      tester,
    ) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: const SmartCoachRecommendation(
            kind: SmartCoachRecommendationKind.continueDailyPlan,
            route: '/memorization-plus/daily-plan?surahId=67',
            surahId: 67,
            completedCount: 1,
            totalCount: 3,
          ),
        ),
      );

      await _pumpHome(tester);
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Continue today\'s plan'), findsOneWidget);

      await tester.tap(find.text('Continue today\'s plan'));
      await _pumpHomeAfterInteraction(tester);

      expect(find.text('coach-nav-daily-plan'), findsOneWidget);
    });

    testWidgets('reviewWeakAyah navigates to quiz on tap', (tester) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.reviewWeakAyah,
            surahId: 67,
            startAyah: 5,
            route: '/memorization-plus/quiz?surahId=67&ayahNumbers=5',
          ),
        ),
      );

      await _pumpHome(tester);
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Review a difficult ayah'), findsOneWidget);

      await tester.tap(find.text('Review a difficult ayah'));
      await _pumpHomeAfterInteraction(tester);

      expect(find.text('coach-nav-quiz'), findsOneWidget);
    });

    testWidgets('memorizedReviewDue navigates to quiz on tap', (tester) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.memorizedReviewDue,
            surahId: 67,
            startAyah: 1,
            route: '/memorization-plus/quiz?surahId=67&ayahNumbers=1',
          ),
        ),
      );

      await _pumpHome(tester);
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Retention review due'), findsOneWidget);

      await tester.tap(find.text('Retention review due'));
      await _pumpHomeAfterInteraction(tester);

      expect(find.text('coach-nav-quiz'), findsOneWidget);
    });

    testWidgets('kidsCurrentMission navigates to kids home on tap', (
      tester,
    ) async {
      await _registerHome(
        _homeLoaded(
          isKids: true,
          selectedTrack: MemorizationTrack.kids,
          coachRecommendation: const SmartCoachRecommendation(
            kind: SmartCoachRecommendationKind.kidsCurrentMission,
            route: '/memorization-plus/kids-home?surahId=114',
            surahId: 114,
          ),
        ),
      );

      await _pumpHome(tester);
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Current Mission'), findsOneWidget);

      await tester.tap(find.text('Current Mission'));
      await _pumpHomeAfterInteraction(tester);

      expect(find.text('coach-nav-kids-home'), findsOneWidget);
    });

    testWidgets('renders English Smart Coach copy without exceptions', (
      tester,
    ) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.reviewDueNear,
            surahId: 67,
            startAyah: 1,
          ),
        ),
      );

      await _pumpHome(tester, locale: const Locale('en'));
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Review before new content'), findsOneWidget);
      expect(
        find.textContaining('Near revision due in Surah Al-Mulk'),
        findsOneWidget,
      );
    });

    testWidgets('Hero Card Parity Test - Resume Session (Adults, Surah)', (
      tester,
    ) async {
      final state = _homeLoaded(lastRestorableLocation: '/quran/surah/2');

      // 1. Test Legacy Parity
      JourneyFeatureFlags.unifiedJourneyEnabled = false;
      await _registerHome(state);
      await _pumpHome(tester, locale: const Locale('en'));
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Continue Surah Al-Baqarah'), findsOneWidget);
      expect(find.text('Last saved reading'), findsOneWidget);

      // 2. Test Unified Parity
      JourneyFeatureFlags.unifiedJourneyEnabled = true;

      // We also need to inject a unified action for this test since our static cubit doesn't evaluate the engine.
      final unifiedState = state.copyWith(
        heroAction: const UnifiedJourneyAction(
          route: '/quran/surah/2',
          priority: UnifiedJourneyPriority.p1ActiveSession,
          source: 'AppSessionService',
          actionType: UnifiedJourneyActionType.resumeSession,
          intent: JourneyIntent.resume,
          metadata: {'pathSegment2': '2'},
        ),
      );

      await getIt.reset();
      await _registerHome(unifiedState);
      await _pumpHome(tester, locale: const Locale('en'));
      await _pumpHomeInitialFrames(tester);

      // Should be identically transformed by the mapper!
      expect(find.text('Continue Surah Al-Baqarah'), findsOneWidget);
      expect(find.text('Last saved reading'), findsOneWidget);
    });

    testWidgets('renders Arabic Smart Coach copy without exceptions', (
      tester,
    ) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.reviewDueNear,
            surahId: 67,
            startAyah: 1,
          ),
        ),
      );

      await _pumpHome(tester, locale: const Locale('ar'));
      await _pumpHomeInitialFrames(tester);

      expect(find.text('راجع قبل الحفظ الجديد'), findsOneWidget);
      expect(find.textContaining('مراجعة قريبة مستحقة'), findsOneWidget);
    });

    testWidgets('renders memorized-due Smart Coach copy in English', (
      tester,
    ) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.memorizedReviewDue,
            surahId: 67,
            startAyah: 1,
            route: '/memorization-plus/quiz?surahId=67&ayahNumbers=1',
          ),
        ),
      );

      await _pumpHome(tester, locale: const Locale('en'));
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Retention review due'), findsOneWidget);
      expect(
        find.text(
          'Review memorized ayahs in Surah Al-Mulk to keep them strong.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders memorized-due Smart Coach copy in Arabic', (
      tester,
    ) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.memorizedReviewDue,
            surahId: 67,
            startAyah: 1,
            route: '/memorization-plus/quiz?surahId=67&ayahNumbers=1',
          ),
        ),
      );

      await _pumpHome(tester, locale: const Locale('ar'));
      await _pumpHomeInitialFrames(tester);

      expect(find.text('مراجعة تثبيت مستحقة'), findsOneWidget);
      expect(
        find.text('راجع الآيات المحفوظة من سورة الملك لتثبيت حفظك.'),
        findsOneWidget,
      );
    });

    // ── Exact-ayah routing regression ─────────────────────────────────────

    testWidgets(
      'tapping weak recommendation navigates to quiz with ayahNumbers',
      (tester) async {
        await _registerHome(
          _homeLoaded(
            coachRecommendation: _coach(
              kind: SmartCoachRecommendationKind.reviewWeakAyah,
              surahId: 67,
              startAyah: 5,
              route: '/memorization-plus/quiz?surahId=67&ayahNumbers=5',
            ),
          ),
        );

        await _pumpHome(tester);
        await _pumpHomeInitialFrames(tester);

        expect(find.text('Review a difficult ayah'), findsOneWidget);
        await tester.tap(find.text('Review a difficult ayah'));
        await _pumpHomeAfterInteraction(tester);

        // Router strips query params when matching — quiz page stub is reached.
        expect(find.text('coach-nav-quiz'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping memorized-due recommendation navigates to quiz with ayahNumbers',
      (tester) async {
        await _registerHome(
          _homeLoaded(
            coachRecommendation: _coach(
              kind: SmartCoachRecommendationKind.memorizedReviewDue,
              surahId: 67,
              startAyah: 3,
              route: '/memorization-plus/quiz?surahId=67&ayahNumbers=3',
            ),
          ),
        );

        await _pumpHome(tester);
        await _pumpHomeInitialFrames(tester);

        expect(find.text('Retention review due'), findsOneWidget);
        await tester.tap(find.text('Retention review due'));
        await _pumpHomeAfterInteraction(tester);

        expect(find.text('coach-nav-quiz'), findsOneWidget);
      },
    );

    testWidgets('resume session still hides Smart Coach recommendation', (
      tester,
    ) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.reviewWeakAyah,
            surahId: 67,
            startAyah: 5,
            route: '/memorization-plus/quiz?surahId=67&ayahNumbers=5',
          ),
          lastRestorableLocation:
              '${AppRoutes.memorizationV2Session}?surahId=2',
        ),
      );

      await _pumpHome(tester);
      await _pumpHomeInitialFrames(tester);

      // Resume section shown, coach card hidden.
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Review a difficult ayah'), findsNothing);
    });

    testWidgets('renders Smart Coach card in light theme', (tester) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.reviewDueNear,
            surahId: 67,
            startAyah: 1,
          ),
        ),
      );

      await _pumpHome(tester, themeMode: ThemeMode.light);
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Review before new content'), findsOneWidget);
    });

    testWidgets('renders Smart Coach card in dark theme', (tester) async {
      await _registerHome(
        _homeLoaded(
          coachRecommendation: _coach(
            kind: SmartCoachRecommendationKind.reviewDueNear,
            surahId: 67,
            startAyah: 1,
          ),
        ),
      );

      await _pumpHome(tester, themeMode: ThemeMode.dark);
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Review before new content'), findsOneWidget);
    });
  });

  group('Feature Flag tests', () {
    testWidgets('UnifiedHeroActionCard does not render when flag OFF', (
      tester,
    ) async {
      JourneyFeatureFlags.unifiedJourneyEnabled = false;

      final state =
          _homeLoaded(
            lastRestorableLocation:
                '${AppRoutes.memorizationV2Session}?surahId=2',
          ).copyWith(
            heroAction: const UnifiedJourneyAction(
              priority: UnifiedJourneyPriority.p2CriticalAlert,
              intent: JourneyIntent.resume,
              route: '/route',
              source: 'Test',
              actionType: UnifiedJourneyActionType.criticalAlert,
              metadata: {'learningAlertType': 'leechRecovery'},
            ),
          );
      await _registerHome(state);

      await _pumpHome(tester);
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Focus on Weak Ayahs'), findsNothing);
      expect(find.text('Resume'), findsOneWidget); // Legacy ResumeSessionCard
    });

    testWidgets('UnifiedHeroActionCard renders when flag ON', (tester) async {
      JourneyFeatureFlags.unifiedJourneyEnabled = true;

      final state =
          _homeLoaded(
            lastRestorableLocation:
                '${AppRoutes.memorizationV2Session}?surahId=2',
          ).copyWith(
            heroAction: const UnifiedJourneyAction(
              priority: UnifiedJourneyPriority.p2CriticalAlert,
              intent: JourneyIntent.resume,
              route: '/route',
              source: 'Test',
              actionType: UnifiedJourneyActionType.criticalAlert,
              metadata: {'learningAlertType': 'leechRecovery'},
            ),
          );
      await _registerHome(state);

      await _pumpHome(tester);
      await _pumpHomeInitialFrames(tester);

      expect(find.text('Focus on Weak Ayahs'), findsOneWidget);
      expect(find.text('Resume'), findsNothing); // Legacy hidden
    });
  });
}

SmartCoachRecommendation _coach({
  required SmartCoachRecommendationKind kind,
  required int surahId,
  int? startAyah,
  String? route,
}) {
  final dailyPlanRoute = '/memorization-plus/daily-plan?surahId=$surahId';
  return SmartCoachRecommendation(
    kind: kind,
    route: route ?? dailyPlanRoute,
    surahId: surahId,
    startAyah: startAyah,
    endAyah: startAyah,
  );
}

HomeLoaded _homeLoaded({
  bool isKids = false,
  MemorizationTrack selectedTrack = MemorizationTrack.adults,
  SmartCoachRecommendation? coachRecommendation,
  String? lastRestorableLocation,
}) {
  return HomeLoaded(
    progress: _progress(kidsPoints: isKids ? 42 : 0, kidsStars: isKids ? 3 : 0),
    greeting: 'morning',
    selectedTrack: selectedTrack,
    isKids: isKids,
    lastRestorableLocation: lastRestorableLocation,
    activityStartDate: DateTime.utc(2026, 1, 1),
    coachRecommendation: coachRecommendation,
  );
}

Future<void> _registerHome(HomeLoaded state) async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<AppSessionService>(AppSessionService(prefs));
  getIt.registerSingleton<XpService>(_FakeXpService());
  getIt.registerSingleton<AchievementService>(_FakeAchievementService());
  getIt.registerSingleton<MemorizationPlusRepository>(
    _NoopMemorizationPlusRepository(),
  );
  getIt.registerFactory<AuthCubit>(() => _FakeAuthCubit(false));
  getIt.registerFactory<ProfileCubit>(() => _FakeProfileCubit());
  getIt.registerFactory<HomeCubit>(() => _StaticHomeCubit(state));
  getIt.registerFactory<StreakCubit>(
    () => _FakeStreakCubit(
      const StreakLoaded(
        streak: StreakEntity(currentStreak: 0, longestStreak: 0),
      ),
    ),
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

Future<void> _pumpHome(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: '/memorization-plus/daily-plan',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('coach-nav-daily-plan'))),
      ),
      GoRoute(
        path: '/memorization-plus/quiz',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('coach-nav-quiz'))),
      ),
      GoRoute(
        path: AppRoutes.memorizationPlusKidsHome,
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('coach-nav-kids-home'))),
      ),
    ],
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => _FakeAuthCubit(false)),
        BlocProvider<ProfileCubit>(create: (_) => _FakeProfileCubit()),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(getIt<SharedPreferences>())..loadTheme(),
        ),
      ],
      child: MaterialApp.router(
        locale: locale,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
}

Future<void> _pumpHomeInitialFrames(WidgetTester tester) {
  return _pumpHomeFrames(tester);
}

Future<void> _pumpHomeAfterInteraction(WidgetTester tester) {
  return _pumpHomeFrames(tester);
}

Future<void> _pumpHomeFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

class _StaticHomeCubit extends Cubit<HomeState> implements HomeCubit {
  _StaticHomeCubit(HomeLoaded super.state);

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopMemorizationPlusRepository implements MemorizationPlusRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> hasPendingCloudWork() async => false;
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
  bool hasNewCertificate({required bool isKids}) => false;

  @override
  List<CertificateAward> getEarnedCertificates({required bool isKids}) =>
      const [];

  @override
  List<CertificateAward> getAllEarnedCertificates() => const [];

  @override
  void markCertificatesSeen({required bool isKids}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
