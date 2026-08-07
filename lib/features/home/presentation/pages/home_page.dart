import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/constants/xp_constants.dart';
import '../../../../core/widgets/activity_heatmap.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/journey/journey_feature_flags.dart';
import '../../../../core/memorization/smart_coach_recommendation.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../widgets/unified_hero_action_card.dart';
import '../../../../core/journey/unified_journey_action_mapper.dart';
import '../../../../core/journey/resume_session_presentation_mapper.dart';
import '../../../../core/journey/resume_session_presentation_input.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../memorization_plus/domain/navigation/memorization_navigation_resolver.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../../../settings/presentation/cubits/profile_cubit.dart';
import '../../../streak/presentation/cubits/streak_cubit.dart';
import '../cubits/home_cubit.dart';
part 'home_page_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // Track whether the app was backgrounded so we only trigger a reload on a
  // real resume (background → foreground), not on every lifecycle tick.
  bool _wasInBackground = false;
  late final HomeCubit _homeCubit;
  late final StreakCubit _streakCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = getIt<HomeCubit>()..load();
    _streakCubit = getIt<StreakCubit>()..loadStreak();
    WidgetsBinding.instance.addObserver(this);
    AppRouter.router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No need to subscribe to a RouteObserver for shell routes since we use GoRouter listener now
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final location =
        AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    if (location == AppRoutes.home) {
      _reloadProgress();
    }
  }

  @override
  void dispose() {
    AppRouter.router.routerDelegate.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    _homeCubit.close();
    _streakCubit.close();
    super.dispose();
  }

  /// Triggered whenever the app lifecycle changes.
  ///
  /// GoRouter's tab navigation does NOT push/pop routes in the traditional
  /// Navigator sense, so RouteAware.didPopNext() never fires when the user
  /// switches back to the Home tab from the Quran reader. Using the app
  /// lifecycle is the reliable cross-platform solution: the Quran reader
  /// pushes a full-screen route that puts the app in an "inactive" state on
  /// iOS and triggers a pause/resume cycle on Android.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasInBackground = true;
    }
    if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      _reloadProgress();
    }
  }

  void _reloadProgress() {
    if (!mounted) return;
    _homeCubit.load();
    _streakCubit.loadStreak();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeCubit),
        BlocProvider.value(value: _streakCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, _) => const _HomeView(),
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const HomeSkeletonLoader();
          }
          if (state is HomeError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<HomeCubit>().load(),
            );
          }
          if (state is HomeLoaded) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: _HomeContent(state: state, isDark: isDark),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.state, required this.isDark});
  final HomeLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isKids = state.isKids;
    return CustomScrollView(
      slivers: [
        // ─── Hero Header ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _HeroHeader(state: state, isDark: isDark),
        ),

        // ─── Sign-In Nudge Banner ───────────────────────────────────────────
        if (JourneyFeatureFlags.unifiedJourneyEnabled &&
            state.heroAction != null)
          Builder(
            builder: (context) {
              final action = state.heroAction!;
              final presentationData = const UnifiedJourneyActionMapper().map(
                context,
                action,
              );

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    0,
                  ),
                  child: UnifiedHeroActionCard(
                    data: presentationData,
                    isDark: isDark,
                    onTap: () => context.push(action.route),
                  ),
                ),
              );
            },
          )
        else if (state.lastRestorableLocation != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                0,
              ),
              child: _ResumeSessionCard(
                location: state.lastRestorableLocation!,
                isDark: isDark,
                isKids: isKids,
              ),
            ),
          )
        // Only show the "Next Best Action" card when there is no active
        // restorable session. Showing both at once is redundant since both
        // can point to the same memorization feature.
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                0,
              ),
              child: _NextBestActionCard(
                state: state,
                isDark: isDark,
                isKids: isKids,
              ),
            ),
          ),

        // ─── Daily Wird Card ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              0,
            ),
            child: _DailyWirdCard(state: state, isDark: isDark),
          ),
        ),

        // Support prompts follow today's prescribed practice, so they never
        // compete with the first action a learner sees.
        SliverToBoxAdapter(child: _SignInNudgeBanner(isDark: isDark)),

        if (state.lastRestorableLocation == null)
          SliverToBoxAdapter(child: _TutorialPromptBanner(isDark: isDark)),

        if (!isKids && state.selectedTrack == MemorizationTrack.adults)
          SliverToBoxAdapter(
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (!state.isParentMode || authState is! AuthAuthenticated) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    0,
                  ),
                  child: _ParentGuardianToolsCard(isDark: isDark),
                );
              },
            ),
          ),

        // ─── Engagement Stats ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sectionGap,
              AppSpacing.pagePadding,
              0,
            ),
            child: _HomeEngagementSection(state: state, isDark: isDark),
          ),
        ),

        // ─── Activity Heatmap ───────────────────────────────────────────────
        if (state.activityCountsByDay.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                0,
              ),
              child: _HomeActivityHeatmapSection(state: state, isDark: isDark),
            ),
          ),

        // ─── Progress Section ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              0,
            ),
            child: _ProgressSection(
              progress: state.progress,
              totalXp: state.totalXp,
              isDark: isDark,
              isKids: isKids,
              kidsPoints: state.progress.kidsPoints,
            ),
          ),
        ),

        // ─── Quick Actions ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              0,
            ),
            child: _QuickActionsGrid(isDark: isDark),
          ),
        ),

        // ─── Bottom padding (above nav bar) ──────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height:
                MediaQuery.paddingOf(context).bottom +
                AppSpacing.xxl +
                AppSpacing.lg,
          ),
        ),
      ],
    );
  }
}
