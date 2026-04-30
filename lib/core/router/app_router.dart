import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/quran/presentation/pages/quran_page.dart';
import '../../features/quran/presentation/pages/quran_reader_page.dart';
import '../../features/hifz/presentation/pages/hifz_page.dart';
import '../../features/hifz/presentation/pages/hifz_session_page.dart';
import '../../features/azkar/presentation/pages/azkar_page.dart';
import '../../features/azkar/presentation/pages/azkar_category_page.dart';
import '../../features/azkar/presentation/pages/general_azkar_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/memorization_plus/presentation/pages/track_selection_page.dart';
import '../../features/memorization_plus/presentation/pages/daily_plan_page.dart';
import '../../features/memorization_plus/presentation/pages/kids_mode_page.dart';
import '../../features/memorization_plus/presentation/pages/custom_plan_setup_page.dart';
import '../../features/memorization_plus/presentation/pages/quiz_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../widgets/app_shell.dart';

abstract class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String quran = '/quran';
  static const String hifz = '/hifz';
  static const String azkar = '/azkar';
  static const String progress = '/progress';
  static const String settings = '/settings';
  static const String memorizationPlus = '/memorization-plus';
  static const String memorizationPlusDailyPlan = '/memorization-plus/daily-plan';
  static const String memorizationPlusKids = '/memorization-plus/kids';
  static const String memorizationPlusCustomPlan = '/memorization-plus/custom-plan';
  static const String memorizationPlusQuiz = '/memorization-plus/quiz';
}

abstract class AppRouter {
  // UX-4 FIX: Removed _shellNavigatorKey — no longer needed with StatefulShellRoute.
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    routes: [
      // ── Full-screen routes (push over shell, own back button) ─────────────
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quran/surah/:surahId',
        builder: (context, state) {
          final surahId =
              int.tryParse(state.pathParameters['surahId'] ?? '1') ?? 1;
          return QuranReaderPage(surahId: surahId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/quran/page/:pageNumber',
        builder: (context, state) {
          final pageNumber =
              int.tryParse(state.pathParameters['pageNumber'] ?? '1') ?? 1;
          return QuranReaderPage(pageNumber: pageNumber);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/hifz/session',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return HifzSessionPage(
            surahId: extra?['surahId'] as int? ?? 1,
            startAyah: extra?['startAyah'] as int? ?? 1,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/azkar/:category',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'morning';
          if (category == 'general') {
            return const GeneralAzkarPage();
          }
          return AzkarCategoryPage(category: category);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlus,
        builder: (context, state) => const TrackSelectionPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusDailyPlan,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final surahId = extra?['surahId'] as int? ?? 1;
          return DailyPlanPage(surahId: surahId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusKids,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return KidsModePage(
            surahId: extra?['surahId'] as int? ?? 1,
            ayahNumber: extra?['ayahNumber'] as int? ?? 1,
            ayahText: extra?['ayahText'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusCustomPlan,
        builder: (context, state) => const CustomPlanSetupPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusQuiz,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final surahId = extra?['surahId'] as int? ?? 1;
          final ayahNumbers = extra?['ayahNumbers'] as List<int>?;
          return QuizPage(surahId: surahId, ayahNumbers: ayahNumbers);
        },
      ),

      // ── Shell (bottom nav) ─────────────────────────────────────────────────
      // UX-4 FIX: StatefulShellRoute.indexedStack preserves each tab's
      // Navigator stack independently, so scroll position and BLoC state
      // are NOT destroyed when the user switches between bottom-nav tabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.quran,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: QuranPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.hifz,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: HifzPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.azkar,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: AzkarPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: ProgressPage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  const AppRouter._();
}
