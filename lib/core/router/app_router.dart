import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../constants/app_constants.dart';
import '../di/injection.dart';
import '../l10n/app_localizations.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/quran/presentation/pages/kids_quran_reader_page.dart';
import '../../features/quran/presentation/pages/quran_page.dart';
import '../../features/quran/presentation/pages/quran_reader_page.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../../features/memorization_plus/presentation/pages/practice_surah_page.dart';
import '../../features/azkar/presentation/pages/azkar_page.dart';
import '../../features/azkar/presentation/pages/azkar_category_page.dart';
import '../../features/azkar/presentation/pages/general_azkar_page.dart';
import '../../features/azkar/domain/entities/azkar_entities.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/memorization_plus/presentation/pages/path_selection_page.dart';
import '../../features/memorization_plus/presentation/pages/guardian_linking_page.dart';
import '../../features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart';
import '../../features/memorization_plus/presentation/pages/kids_gamified_home_page.dart';
import '../../features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart';
import '../../features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart';
import '../../features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart';
import '../../features/memorization_plus/presentation/pages/daily_plan_page.dart';
import '../../features/memorization_plus/presentation/pages/memorization_hub_page.dart';
import '../../features/memorization_plus/presentation/pages/custom_plan_setup_page.dart';
import '../../features/memorization_plus/presentation/pages/qcf_rendering_poc_page.dart';
import '../../features/memorization_plus/presentation/pages/v2_session_page.dart';
import '../../features/memorization_plus/presentation/pages/family_dashboard_page.dart';
import '../../features/memorization_plus/presentation/pages/child_detail_page.dart';
import '../../features/memorization_plus/domain/navigation/memorization_navigation_resolver.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/certificate/presentation/pages/certificate_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/update_password_page.dart';
import '../../features/tutorial_guide/presentation/pages/tutorial_guide_page.dart';
import '../../features/settings/presentation/pages/privacy_policy_page.dart';
import '../services/achievement_service.dart';
import '../widgets/app_shell.dart';

abstract class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String childOnboarding = '/onboarding/child';
  static const String home = '/';
  static const String quran = '/quran';
  static const String quranDaily = '/quran/daily';
  static const String hifz = '/hifz';

  /// Surah picker for adult "Practice by Surah" (replaces bare `/hifz` browse).
  static const String hifzPracticeSurah = '/memorization/practice-surah';
  static const String memorizationHub = '/memorization';
  static const String azkar = '/azkar';
  static const String progress = '/progress';
  static const String settings = '/settings';
  static const String memorizationPlus = '/memorization-plus';
  static const String memorizationPlusGuardianLinking =
      '/memorization-plus/guardian-linking';
  static const String memorizationPlusKidsJourney =
      '/memorization-plus/kids-journey';
  static const String memorizationPlusKids = '/memorization-plus/kids';
  static const String memorizationPlusKidsHome = '/memorization-plus/kids-home';
  static const String memorizationPlusKidsQuran =
      '/memorization-plus/kids-quran';
  static const String memorizationPlusKidsStage =
      '/memorization-plus/kids-stage';
  static const String memorizationPlusKidsCompletion =
      '/memorization-plus/kids-completion';

  static const String familyDashboard = '/family-dashboard';
  static const String childDetail = '/family-dashboard/child';
  static const String memorizationPlusCustomPlan =
      '/memorization-plus/custom-plan';
  static const String memorizationPlusDailyPlan =
      '/memorization-plus/daily-plan';
  static const String memorizationV2Session = '/memorization-v2/session';
  static const String qcfRenderingPoc = '/debug/qcf-rendering-poc';
  static const String login = '/login';
  static const String updatePassword = '/auth/update-password';
  static const String updatePasswordAlias = '/update-password';
  static const String certificate = '/certificate';
  static const String tutorialGuide = '/tutorial-guide';
  static const String privacyPolicy = '/settings/privacy-policy';
}

/// Bridges [AuthCubit] state stream into a [Listenable] so [GoRouter]
/// re-evaluates its [redirect] automatically whenever auth state changes.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthCubit cubit) {
    _sub = cubit.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Routes that are always accessible without authentication.
final _publicRoutes = <String>[
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.childOnboarding,
  AppRoutes.login,
  AppRoutes.updatePassword,
  AppRoutes.updatePasswordAlias,
  AppRoutes.home,
  AppRoutes.quran,
  AppRoutes.hifz,
  AppRoutes.hifzPracticeSurah,
  AppRoutes.memorizationHub,
  AppRoutes.azkar,
  AppRoutes.progress,
  AppRoutes.settings,
  AppRoutes.certificate,
  AppRoutes.tutorialGuide,
  AppRoutes.privacyPolicy,
  AppRoutes.memorizationPlus,
  AppRoutes.memorizationV2Session,
  if (kDebugMode) AppRoutes.qcfRenderingPoc,
];

final _remoteProtectedRoutes = <String>[AppRoutes.familyDashboard];

class MemorizationRouteGuard {
  const MemorizationRouteGuard._();

  static Future<MemorizationProfile?> _readProfile() async {
    try {
      final repo = getIt<MemorizationPlusRepository>();
      final profileResult = await repo.getMemorizationProfile();
      final profile = profileResult.fold((_) => null, (profile) => profile);
      return profile;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> entryRedirect() async {
    try {
      final repo = getIt<MemorizationPlusRepository>();
      final profileResult = await repo.getMemorizationProfile();
      final profile = profileResult.fold((_) => null, (p) => p);
      if (profile == null || !profile.hasSelectedPath) return null;

      if (profile.isChild) return AppRoutes.memorizationPlusKidsHome;

      if (profile.isAdult) {
        return await MemorizationNavigationResolver(repo).adultEntryLocation();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> adultOnlyRedirect() async {
    final profile = await _readProfile();
    return profile?.isChild == true ? AppRoutes.memorizationPlusKidsHome : null;
  }

  /// Guard for the V2 memorization session route.
  ///
  /// Checks condition:
  ///   1. Profile must be adult (kids go to their own home).
  static Future<String?> v2SessionRedirect(GoRouterState state) async {
    // Check 1: adult-only guard.
    final profile = await _readProfile();
    if (profile?.isChild == true) return AppRoutes.memorizationPlusKidsHome;

    return invalidV2SessionRedirect(state);
  }

  /// Safe destination for malformed V2 session deep links.
  static const invalidV2SessionLocation = AppRoutes.memorizationHub;

  static String? invalidV2SessionRedirect(GoRouterState state) {
    final extra = state.extra as Map<String, dynamic>?;
    final surahId =
        extra?['surahId'] as int? ??
        int.tryParse(state.uri.queryParameters['surahId'] ?? '');
    final startAyah =
        extra?['startAyah'] as int? ??
        int.tryParse(state.uri.queryParameters['startAyah'] ?? '') ??
        1;
    final blockSize =
        extra?['blockSize'] as int? ??
        int.tryParse(state.uri.queryParameters['blockSize'] ?? '') ??
        5;
    if (!AppRouter._isValidSurahId(surahId) || startAyah < 1 || blockSize < 1) {
      return invalidV2SessionLocation;
    }
    return null;
  }

  static Future<String?> kidsOnlyRedirect() async {
    final profile = await _readProfile();
    if (profile == null || profile.isChild) return null;
    return AppRoutes.memorizationPlus;
  }

  /// Resolves a notification's generic Kids journey link to the active map.
  static Future<String?> kidsJourneyRedirect(GoRouterState state) async {
    final profile = await _readProfile();
    if (profile != null && !profile.isChild) return AppRoutes.memorizationPlus;

    final surahId = int.tryParse(state.uri.queryParameters['surahId'] ?? '');
    if (AppRouter._isValidSurahId(surahId)) return null;

    try {
      final repository = getIt<MemorizationPlusRepository>();
      return (await MemorizationNavigationResolver(
        repository,
      ).resolve()).kidsJourneyLocation;
    } catch (_) {
      return AppRoutes.memorizationPlusKidsHome;
    }
  }

  static Future<String?> parentDashboardRedirect() async {
    try {
      final authState = getIt<AuthCubit>().state;
      if (authState is! AuthAuthenticated && authState is! AuthInitial) {
        return AppRoutes.login;
      }
    } catch (_) {
      // Tests and isolated guard callers may not register AuthCubit.
    }

    final profile = await _readProfile();
    return profile?.isChild == true ? AppRoutes.memorizationPlusKidsHome : null;
  }

  /// Legacy `/hifz` deep links: Hub (or V2 via [PendingAyahResolver] when
  /// `surahId` is present). Surah browsing lives at [AppRoutes.hifzPracticeSurah].
  static Future<String?> hifzRedirect(GoRouterState state) async {
    try {
      final profile = await _readProfile();
      if (profile?.isChild == true) {
        return AppRoutes.memorizationPlusKidsHome;
      }

      final hasPath = profile?.hasSelectedPath == true;
      if (!hasPath) {
        final prefs = getIt<SharedPreferences>();
        final legacyPath = prefs.getString(AppConstants.kHifzPathMode);
        if (legacyPath == null || legacyPath.isEmpty) {
          return AppRoutes.memorizationPlus;
        }
      }

      final surahId = int.tryParse(state.uri.queryParameters['surahId'] ?? '');
      if (AppRouter._isValidSurahId(surahId)) {
        final repository = getIt<MemorizationPlusRepository>();
        final ayahCount = await _surahAyahCount(surahId!);
        return await MemorizationNavigationResolver(
          repository,
        ).practiceSurahSessionLocation(surahId, surahAyahCount: ayahCount);
      }

      // Bare `/hifz` → Memorization Hub (preserve non-surah query if any).
      final params = Map<String, String>.from(state.uri.queryParameters)
        ..remove('surahId')
        ..remove('startAyah')
        ..remove('ayahNumber');
      if (params.isEmpty) return AppRoutes.memorizationHub;
      return Uri(
        path: AppRoutes.memorizationHub,
        queryParameters: params,
      ).toString();
    } catch (_) {
      return AppRoutes.memorizationHub;
    }
  }

  static Future<int?> _surahAyahCount(int surahId) async {
    final result = await getIt<QuranRepository>().getSurahDetail(surahId);
    return result.fold((_) => null, (detail) => detail.ayahs.length);
  }
}

abstract class AppRouter {
  // UX-4 FIX: Removed _shellNavigatorKey — no longer needed with StatefulShellRoute.
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Minimal router used before DI is initialized.
  /// Only contains the splash route — no auth guards or DI dependencies.
  static final GoRouter splashOnlyRouter = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
    ],
  );

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    // AUTH GATE: redirect unauthenticated users to /login for all protected routes.
    refreshListenable: _AuthNotifier(getIt<AuthCubit>()),
    redirect: (context, state) {
      final authState = getIt<AuthCubit>().state;
      final location = state.matchedLocation;
      if (requiresAuthentication(location)) {
        if (authState is AuthAuthenticated) return null;
        if (authState is AuthInitial) return null;
        return AppRoutes.login;
      }
      if (isPublicLocation(location)) return null;
      if (authState is AuthAuthenticated) return null;
      if (authState is AuthInitial) return null; // still initialising
      return AppRoutes.login; // unauthenticated on protected route
    },
    // OFFLINE-SAFE: GoRouter wraps any exception thrown inside an async
    // redirect as a GoException and re-throws it as an uncaught async error.
    // This handler silently swallows network-related redirect failures
    // (e.g. AuthRetryableFetchException when Supabase is unreachable)
    // and keeps the user on their current page rather than crashing.
    onException: (context, state, router) {
      // No-op: let the user stay on the current page.
      // The per-route try-catch blocks already return safe fallbacks for
      // known network errors; this is a last-resort safety net.
    },
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
        path: AppRoutes.childOnboarding,
        redirect: (context, state) => AppRoutes.memorizationPlusKidsHome,
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.updatePassword,
        builder: (context, state) => const UpdatePasswordPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.updatePasswordAlias,
        builder: (context, state) => const UpdatePasswordPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.tutorialGuide,
        builder: (context, state) => const TutorialGuidePage(),
      ),
      if (kDebugMode)
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: AppRoutes.qcfRenderingPoc,
          builder: (context, state) => const QcfRenderingPocPage(),
        ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/certificate',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final l10n = AppLocalizations.of(context);
          final userName = extra?['userName'] as String? ?? l10n.taliaUser;

          CertificateAward? award;
          final rawAward = extra?['award'];
          if (rawAward is CertificateAward) {
            award = rawAward;
          } else if (rawAward is Map<String, dynamic>) {
            award = CertificateAward.fromJson(rawAward);
          }

          if (award == null) {
            return Scaffold(
              body: Center(child: Text(l10n.certificateNotFound)),
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
        path: AppRoutes.quranDaily,
        redirect: (context, state) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final random = Random(today.millisecondsSinceEpoch);
          final pageNumber = random.nextInt(604) + 1;
          return '/quran/page/$pageNumber';
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
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlus,
        redirect: (context, state) => MemorizationRouteGuard.entryRedirect(),
        builder: (context, state) {
          final preferredPath = state.uri.queryParameters['preferred'] == 'kids'
              ? MemorizationPath.child
              : null;
          return PathSelectionPage(preferredPath: preferredPath);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusGuardianLinking,
        // T036 route guard: only reachable for children who still need
        // guardian onboarding. Adults, skipped children, and already-linked
        // children are redirected back to the track-selection entry point.
        // OFFLINE-SAFE: catch(Object) ensures network failures never propagate
        // out of the redirect callback and crash GoRouter.
        redirect: (context, state) async {
          try {
            final repo = getIt<MemorizationPlusRepository>();
            final profileResult = await repo.getMemorizationProfile();
            final redirectRoute = profileResult.fold(
              (_) => null, // on data error, show guardian page (offline-safe)
              (profile) {
                // Allow only: child with onboarding still required
                if (profile.isChild &&
                    profile.guardianOnboardingStatus ==
                        GuardianOnboardingStatus.required) {
                  return null; // permit navigation
                }
                return AppRoutes.memorizationPlus; // redirect all other states
              },
            );
            return redirectRoute;
          } catch (_) {
            // Network unavailable — allow guardian-linking page to load;
            // it will show its own offline-aware UI.
            return null;
          }
        },
        builder: (context, state) => const GuardianLinkingPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusKidsJourney,
        redirect: (context, state) =>
            MemorizationRouteGuard.kidsJourneyRedirect(state),
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final surahId =
              extra?['surahId'] as int? ??
              int.tryParse(state.uri.queryParameters['surahId'] ?? '');
          if (!_isValidSurahId(surahId)) {
            return const PathSelectionPage();
          }
          return KidsGamifiedJourneyPage(surahId: surahId!);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusKids,
        redirect: (context, state) => MemorizationRouteGuard.kidsOnlyRedirect(),
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
            return const PathSelectionPage();
          }
          final resolvedSurahId = surahId!;
          final ayahText = extra?['ayahText'] as String? ?? '';
          return KidsGamifiedListenPage(
            surahId: resolvedSurahId,
            ayahNumber: ayahNumber,
            ayahText: ayahText,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusKidsHome,
        redirect: (context, state) => MemorizationRouteGuard.kidsOnlyRedirect(),
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final surahId =
              extra?['surahId'] as int? ??
              int.tryParse(state.uri.queryParameters['surahId'] ?? '') ??
              1;
          if (!_isValidSurahId(surahId)) {
            return const PathSelectionPage();
          }
          return KidsGamifiedHomePage(surahId: surahId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusKidsQuran,
        redirect: (context, state) => MemorizationRouteGuard.kidsOnlyRedirect(),
        builder: (context, state) {
          final surahId = int.tryParse(
            state.uri.queryParameters['surahId'] ?? '',
          );
          final pageNumber = int.tryParse(
            state.uri.queryParameters['pageNumber'] ?? '',
          );
          return KidsQuranReaderPage(
            surahId: _isValidSurahId(surahId) ? surahId : null,
            pageNumber: pageNumber,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusKidsStage,
        redirect: (context, state) => MemorizationRouteGuard.kidsOnlyRedirect(),
        builder: (context, state) {
          final stage = _parseKidsJourneyStage(state);
          if (stage == null || !_isValidSurahId(stage.surahId)) {
            return const PathSelectionPage();
          }
          return KidsGamifiedStagePage(
            stage: stage,
            surahName: state.uri.queryParameters['surahName'],
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusKidsCompletion,
        redirect: (context, state) => MemorizationRouteGuard.kidsOnlyRedirect(),
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final surahId =
              extra?['surahId'] as int? ??
              int.tryParse(state.uri.queryParameters['surahId'] ?? '');
          final completedAyahNumber =
              extra?['completedAyahNumber'] as int? ??
              int.tryParse(
                state.uri.queryParameters['completedAyahNumber'] ?? '',
              );
          if (!_isValidSurahId(surahId) ||
              completedAyahNumber == null ||
              completedAyahNumber < 1) {
            return const PathSelectionPage();
          }
          final starsEarned = resolveKidsCompletionStarsEarned(
            extra: extra,
            queryParameters: state.uri.queryParameters,
          );
          return KidsGamifiedCompletionPage(
            surahId: surahId!,
            completedAyahNumber: completedAyahNumber,
            starsEarned: starsEarned,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.familyDashboard,
        redirect: (context, state) =>
            MemorizationRouteGuard.parentDashboardRedirect(),
        builder: (context, state) => const FamilyDashboardPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.childDetail,
        redirect: (context, state) =>
            MemorizationRouteGuard.parentDashboardRedirect(),
        builder: (context, state) {
          final child = state.extra as FamilyChildEntry?;
          if (child == null) return const FamilyDashboardPage();
          return ChildDetailPage(child: child);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusCustomPlan,
        redirect: (context, state) =>
            MemorizationRouteGuard.adultOnlyRedirect(),
        builder: (context, state) => const CustomPlanSetupPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationPlusDailyPlan,
        redirect: (context, state) =>
            MemorizationRouteGuard.adultOnlyRedirect(),
        builder: (context, state) => const DailyPlanPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.memorizationV2Session,
        redirect: (context, state) =>
            MemorizationRouteGuard.v2SessionRedirect(state),
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final surahId =
              extra?['surahId'] as int? ??
              int.tryParse(state.uri.queryParameters['surahId'] ?? '');
          final startAyah =
              extra?['startAyah'] as int? ??
              int.tryParse(state.uri.queryParameters['startAyah'] ?? '') ??
              1;
          final blockSize =
              extra?['blockSize'] as int? ??
              int.tryParse(state.uri.queryParameters['blockSize'] ?? '') ??
              5;
          if (!_isValidSurahId(surahId) || startAyah < 1 || blockSize < 1) {
            return const MemorizationHubPage();
          }
          return V2SessionPage(
            surahId: surahId!,
            startAyah: startAyah,
            blockSize: blockSize,
          );
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
                path: AppRoutes.memorizationHub,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: MemorizationHubPage()),
              ),
              GoRoute(
                path: AppRoutes.hifz,
                redirect: (context, state) =>
                    MemorizationRouteGuard.hifzRedirect(state),
                // Page never builds — redirect always returns a location.
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: SizedBox.shrink()),
              ),
              GoRoute(
                path: AppRoutes.hifzPracticeSurah,
                redirect: (context, state) =>
                    MemorizationRouteGuard.adultOnlyRedirect(),
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: PracticeSurahPage()),
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

  static bool requiresAuthentication(String location) {
    return _remoteProtectedRoutes.any((r) => location.startsWith(r));
  }

  static bool isPublicLocation(String location) {
    return _publicRoutes.any((r) {
      if (r == AppRoutes.home) return location == AppRoutes.home;
      return location.startsWith(r);
    });
  }

  static bool _isValidSurahId(int? surahId) =>
      surahId != null && surahId >= 1 && surahId <= 114;

  @visibleForTesting
  static int resolveKidsCompletionStarsEarned({
    Map<String, dynamic>? extra,
    Map<String, String> queryParameters = const {},
  }) {
    return extra?['starsEarned'] as int? ??
        int.tryParse(queryParameters['starsEarned'] ?? '') ??
        0;
  }

  static KidsJourneyStage? _parseKidsJourneyStage(GoRouterState state) {
    final extra = state.extra;
    if (extra is KidsJourneyStage) {
      return KidsJourneyStage(
        stageNumber: extra.stageNumber,
        surahId: extra.surahId,
        startAyah: extra.startAyah,
        endAyah: extra.endAyah,
        completedAyahs: extra.completedAyahs,
        status: KidsJourneyStageStatus.locked,
      );
    }

    final extraMap = extra is Map<String, dynamic> ? extra : null;
    final query = state.uri.queryParameters;
    final surahId =
        extraMap?['surahId'] as int? ?? int.tryParse(query['surahId'] ?? '');
    final stageNumber =
        extraMap?['stageNumber'] as int? ??
        int.tryParse(query['stageNumber'] ?? '');
    final startAyah =
        extraMap?['startAyah'] as int? ??
        int.tryParse(query['startAyah'] ?? '');
    final endAyah =
        extraMap?['endAyah'] as int? ?? int.tryParse(query['endAyah'] ?? '');

    if (!_isValidSurahId(surahId) ||
        stageNumber == null ||
        stageNumber < 1 ||
        startAyah == null ||
        startAyah < 1 ||
        endAyah == null ||
        endAyah < startAyah) {
      return null;
    }

    final completedAyahs = extraMap?['completedAyahs'] is List<int>
        ? extraMap!['completedAyahs'] as List<int>
        : _parseAyahNumbers(query['completedAyahs']) ?? const <int>[];
    return KidsJourneyStage(
      stageNumber: stageNumber,
      surahId: surahId!,
      startAyah: startAyah,
      endAyah: endAyah,
      completedAyahs: completedAyahs,
      status: KidsJourneyStageStatus.locked,
    );
  }

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
