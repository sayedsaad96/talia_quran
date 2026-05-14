import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/xp_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/services/xp_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/activity_heatmap.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
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
    return CustomScrollView(
      slivers: [
        // ─── Hero Header ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _HeroHeader(state: state, isDark: isDark),
        ),

        // ─── Streak & XP Row ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              0,
            ),
            child: _StreakXpRow(isDark: isDark),
          ),
        ),

        // ─── Sign-In Nudge Banner ───────────────────────────────────────────
        SliverToBoxAdapter(child: _SignInNudgeBanner(isDark: isDark)),

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

        // ─── Continue Reading Chip ───────────────────────────────────────────
        if (state.lastRestorableLocation != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.sm,
                AppSpacing.pagePadding,
                0,
              ),
              child: _ContinueReadingChip(
                location: state.lastRestorableLocation!,
                isDark: isDark,
              ),
            ),
          ),

        // ─── Progress Section ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: SectionHeader(
              title: context.l10n.overallProgress,
              padding: EdgeInsets.zero,
              action: GestureDetector(
                onTap: () => context.go('/progress'),
                child: Text(
                  context.l10n.viewAll,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: _ProgressSection(progress: state.progress, isDark: isDark),
          ),
        ),

        // ─── Azkar Shortcut ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              0,
            ),
            child: _AzkarShortcutRow(isDark: isDark),
          ),
        ),

        // ─── Active Custom Plan Card (If available) ──────────────────────────
        if (state.customPlan != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                0,
              ),
              child: _ActiveCustomPlanCard(
                plan: state.customPlan!,
                isDark: isDark,
              ),
            ),
          ),

        // ─── MemorizationPlus Card ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              0,
            ),
            child: _MemorizationPlusCard(isDark: isDark),
          ),
        ),

        // ─── Parent Dashboard Shortcut (If Parent Mode / Kids Track) ──────────
        if (state.selectedTrack == MemorizationTrack.kids || state.isParentMode)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                0,
              ),
              child: _ParentDashboardShortcutCard(isDark: isDark),
            ),
          ),

        // ─── Activity Heatmap ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sectionGap,
              AppSpacing.pagePadding,
              0,
            ),
            child: ActivityHeatmap(isar: getIt<Isar>()),
          ),
        ),

        // ─── Debug Certificate Preview (Debug Mode Only) ──────────────────
        if (kDebugMode)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                0,
              ),
              child: _DebugCertificatePreview(isDark: isDark),
            ),
          ),

        // ─── Bottom padding (above nav bar) ──────────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}
