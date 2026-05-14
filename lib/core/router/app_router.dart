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
import '../../features/azkar/domain/entities/azkar_entities.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/memorization_plus/presentation/pages/track_selection_page.dart';
import '../../features/memorization_plus/presentation/pages/daily_plan_page.dart';
import '../../features/memorization_plus/presentation/pages/kids_journey_page.dart';
import '../../features/memorization_plus/presentation/pages/kids_mode_page.dart';
import '../../features/memorization_plus/presentation/pages/parent_dashboard_page.dart';
import '../../features/memorization_plus/presentation/pages/custom_plan_setup_page.dart';
import '../../features/memorization_plus/presentation/pages/quiz_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/certificate/presentation/pages/certificate_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/tutorial_guide/presentation/pages/tutorial_guide_page.dart';
import '../services/achievement_service.dart';
import '../widgets/app_shell.dart';

abstract class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String quran = '/quran';
  static const String hifz = '/hifz';
  static const String azkar = '/azkar';
  static const String progress = '/progress';
  static const String hifzSession = '/hifz/session';
  static const String settings = '/settings';
  static const String memorizationPlus = '/memorization-plus';
  static const String memorizationPlusDailyPlan =
      '/memorization-plus/daily-plan';
  static const String memorizationPlusKidsJourney =
      '/memorization-plus/kids-journey';
  static const String memorizationPlusKids = '/memorization-plus/kids';
  static const String parentDashboard = '/memorization-plus/parent-dashboard';
  static const String memorizationPlusCustomPlan =
      '/memorization-plus/custom-plan';
  static const String memorizationPlusQuiz = '/memorization-plus/quiz';
  static const String login = '/login';
  static const String certificate = '/certificate';
  static const String tutorialGuide = '/tutorial-guide';
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
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.tutorialGuide,
        builder: (context, state) => const TutorialGuidePage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/certificate',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final userName = extra?['userName'] as String? ?? 'مستخدم تالية';

          CertificateAward? award;
          final rawAward = extra?['award'];
          if (rawAward is CertificateAward) {
            award = rawAward;
          } else if (rawAward is Map<String, dynamic>) {
            award = CertificateAward.fromJson(rawAward);
          }

          if (award == null) {
            return const Scaffold(
              body: Center(child: Text('لم يتم العثور على الشهادة')),
            );
          }
          return CertificatePage(award: award, userName: userName);
        },
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
        path: AppRoutes.hifzSession,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final surahId =
              extra?['surahId'] as int? ??
              int.tryParse(state.uri.queryParameters['surahId'] ?? '');
          final startAyah =
              extra?['startAyah'] as int? ??
              int.tryParse(state.uri.queryParameters['startAyah'] ?? '');
          return HifzSessionPage(
            surahId: _isValidSurahId(surahId) ? surahId! : 1,
            startAyah: startAyah != null && startAyah > 0 ? startAyah : 1,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/azkar/:category',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'morning';
          if (category == 'general' || category == 'duas') {
            return GeneralAzkarPage(
              category: category == 'duas'
                  ? AzkarCategory.duas
                  : AzkarCategory.general,
            );
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
          final surahId =
              extra?['surahId'] as int? ??
              int.tryParse(state.uri.queryParameters['surahId'] ?? '');
          if (!_isValidSurahId(surahId)) {
            return const TrackSelectionPage();
          }
          return DailyPlanPage(surahId: surahId!);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusKidsJourney,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final surahId =
              extra?['surahId'] as int? ??
              int.tryParse(state.uri.queryParameters['surahId'] ?? '');
          if (!_isValidSurahId(surahId)) {
            return const TrackSelectionPage();
          }
          return KidsJourneyPage(surahId: surahId!);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusKids,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final surahId =
              extra?['surahId'] as int? ??
              int.tryParse(state.uri.queryParameters['surahId'] ?? '');
          final ayahNumber =
              extra?['ayahNumber'] as int? ??
              int.tryParse(state.uri.queryParameters['ayahNumber'] ?? '');
          if (!_isValidSurahId(surahId) ||
              ayahNumber == null ||
              ayahNumber < 1) {
            return const TrackSelectionPage();
          }
          return KidsModePage(
            surahId: surahId!,
            ayahNumber: ayahNumber,
            ayahText: extra?['ayahText'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.parentDashboard,
        builder: (context, state) {
          final surahId =
              int.tryParse(state.uri.queryParameters['surahId'] ?? '') ?? 1;
          return ParentDashboardPage(
            surahId: _isValidSurahId(surahId) ? surahId : 1,
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
          final surahId =
              extra?['surahId'] as int? ??
              int.tryParse(state.uri.queryParameters['surahId'] ?? '');
          if (!_isValidSurahId(surahId)) {
            return const TrackSelectionPage();
          }
          final rawAyahNumbers = extra?['ayahNumbers'];
          final ayahNumbers = rawAyahNumbers is List<int>
              ? rawAyahNumbers
              : rawAyahNumbers is List
              ? rawAyahNumbers.whereType<int>().toList()
              : _parseAyahNumbers(state.uri.queryParameters['ayahNumbers']);
          return QuizPage(surahId: surahId!, ayahNumbers: ayahNumbers);
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

  static bool _isValidSurahId(int? surahId) =>
      surahId != null && surahId >= 1 && surahId <= 114;

  static List<int>? _parseAyahNumbers(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final numbers = value
        .split(',')
        .map((item) => int.tryParse(item.trim()))
        .whereType<int>()
        .where((number) => number > 0)
        .toList();
    return numbers.isEmpty ? null : numbers;
  }
}
