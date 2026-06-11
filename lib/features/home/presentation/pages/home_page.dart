import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/services/xp_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/memorization/smart_coach_recommendation.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../memorization_plus/presentation/navigation/memorization_navigation_resolver.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../../../settings/presentation/cubits/profile_cubit.dart';
import '../../../streak/presentation/cubits/streak_cubit.dart';
import '../cubits/home_cubit.dart';
part 'home_page_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<HomeCubit>()..load()),
        BlocProvider(create: (_) => getIt<StreakCubit>()..loadStreak()),
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
            return const Center(child: LoadingWidget());
          }
          if (state is HomeError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<HomeCubit>().load(),
            );
          }
          if (state is HomeLoaded) {
            return _HomeContent(state: state, isDark: isDark);
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
        // ─── Hero Header ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _HeroHeader(state: state, isDark: isDark),
        ),

        // ─── Sign-In Nudge Banner ───────────────────────────────────────────
        SliverToBoxAdapter(child: _SignInNudgeBanner(isDark: isDark)),

        if (state.lastRestorableLocation != null)
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

        // ─── Daily Wird Card ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sectionGap,
              AppSpacing.pagePadding,
              0,
            ),
            child: _DailyWirdCard(state: state, isDark: isDark),
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
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}
