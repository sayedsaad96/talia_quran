import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../cubits/practice_surah_cubit.dart';
import '../widgets/memorization_path_settings_sheet.dart';
import '../widgets/practice_surah_hub_banner.dart';
import '../widgets/practice_surah_tile.dart';

/// Adult practice-by-surah picker for Memorization Plus.
///
/// Surah taps open a V2 session via [MemorizationNavigationResolver].
class PracticeSurahPage extends StatelessWidget {
  const PracticeSurahPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PracticeSurahCubit>()..load(),
      child: const _PracticeSurahView(),
    );
  }
}

class _PracticeSurahView extends StatelessWidget {
  const _PracticeSurahView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: BlocBuilder<PracticeSurahCubit, PracticeSurahState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _PracticeSurahAppBar(
                isDark: isDark,
                primary: primary,
                state: state,
              ),
              if (state is PracticeSurahLoaded &&
                  state.selectedPath != null &&
                  state.selectedPath != 'backward')
                SliverToBoxAdapter(
                  child: PracticeSurahHubBanner(isDark: isDark),
                ),
              if (state is PracticeSurahLoading)
                const SliverFillRemaining(child: LoadingWidget()),
              if (state is PracticeSurahError)
                SliverFillRemaining(
                  child: ErrorStateWidget(
                    message: state.message,
                    onRetry: () => context.read<PracticeSurahCubit>().load(),
                  ),
                ),
              if (state is PracticeSurahLoaded)
                if (state.selectedPath == null) ...[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.route_rounded,
                      message: context.l10n.chooseMemorizationPath,
                    ),
                  ),
                ] else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.lg,
                        bottom: AppSpacing.sm,
                      ),
                      child: SectionHeader(title: context.l10n.selectSurah),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      0,
                      AppSpacing.pagePadding,
                      120,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => PracticeSurahTile(
                          surah: state.surahs[i],
                          isDark: isDark,
                          primary: primary,
                        ),
                        childCount: state.surahs.length,
                      ),
                    ),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _PracticeSurahAppBar extends StatelessWidget {
  const _PracticeSurahAppBar({
    required this.isDark,
    required this.primary,
    required this.state,
  });

  final bool isDark;
  final Color primary;
  final PracticeSurahState state;

  @override
  Widget build(BuildContext context) {
    final loaded = state is PracticeSurahLoaded
        ? state as PracticeSurahLoaded
        : null;
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A2A22), Color(0xFF0D1117)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A6B5A), Color(0xFF2D5A8E)],
                  ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              context.l10n.memorization,
                              style: AppTypography.headlineLarge.copyWith(
                                color: Colors.white,
                                fontFamily: 'Amiri',
                              ),
                            ),
                            Text(
                              context.l10n.selectSurah,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (loaded?.selectedPath != null)
                        IconButton(
                          icon: const Icon(
                            Icons.settings_suggest_rounded,
                            color: Colors.white,
                          ),
                          tooltip: context.l10n.changeMemorizationPath,
                          onPressed: () => showMemorizationPathSettingsSheet(
                            context,
                            isDark: isDark,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}