import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/widgets/section_header.dart';
import '../cubits/hifz_cubit.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../../core/router/app_router.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../memorization_plus/domain/navigation/memorization_navigation_resolver.dart';
import '../../../memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart';

class HifzPage extends StatelessWidget {
  const HifzPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HifzCubit>()..load(),
      child: const _HifzView(),
    );
  }
}

class _HifzView extends StatelessWidget {
  const _HifzView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: BlocBuilder<HifzCubit, HifzState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, isDark, primary, state),
              // ─── MemorizationPlus entry banner ─────────────────────────────
              // T-07: Hide MemPlus entry banner for child profiles.
              // Kids are redirected by the router, but belt-and-suspenders:
              // don't show the adult MemPlus banner if they somehow land here.
              if (state is HifzLoaded &&
                  state.selectedPath != null &&
                  state.selectedPath != 'backward')
                SliverToBoxAdapter(child: _MemPlusBanner(isDark: isDark)),
              if (state is HifzLoading)
                const SliverFillRemaining(child: LoadingWidget()),
              if (state is HifzError)
                SliverFillRemaining(
                  child: ErrorStateWidget(
                    message: state.message,
                    onRetry: () => context.read<HifzCubit>().load(),
                  ),
                ),
              if (state is HifzLoaded)
                // T028: When no path is set, delegate to the authoritative
                // MemorizationPlus identity gate rather than showing the
                // duplicate inline path-chooser.
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
                      120, // Prevent cutoff by bottom nav
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _HifzSurahTile(
                          surah: state.surahs[i],
                          isUnlocked: state.isSurahUnlocked(state.surahs[i].id),
                          requiredPreviousSurah: i > 0
                              ? state.surahs[i - 1]
                              : null,
                          index: i,
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

  SliverAppBar _buildAppBar(
    BuildContext ctx,
    bool isDark,
    Color primary,
    HifzState state,
  ) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
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
                              ctx.l10n.memorization,
                              style: AppTypography.headlineLarge.copyWith(
                                color: Colors.white,
                                fontFamily: 'Amiri',
                              ),
                            ),
                            Text(
                              ctx.l10n.selectSurah,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state is HifzLoaded && state.selectedPath != null)
                        IconButton(
                          icon: const Icon(
                            Icons.settings_suggest_rounded,
                            color: Colors.white,
                          ),
                          tooltip: ctx.l10n.changeMemorizationPath,
                          // T028: Path changes are managed exclusively through
                          // the Settings page (Reset / Change path control)
                          // to preserve shared identity integrity.
                          // UPDATE: User requested to not go to the main settings page.
                          onPressed: () => showMemorizationPathSettingsSheet(
                            ctx,
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

class _HifzSurahTile extends StatelessWidget {
  const _HifzSurahTile({
    required this.surah,
    required this.isUnlocked,
    required this.requiredPreviousSurah,
    required this.index,
    required this.isDark,
    required this.primary,
  });

  final Surah surah;
  final bool isUnlocked;
  final Surah? requiredPreviousSurah;
  final int index;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final isLocked = !isUnlocked;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final previousSurahName = context.isArabic
        ? requiredPreviousSurah?.nameAr ?? context.l10n.surah
        : requiredPreviousSurah?.nameEn ?? context.l10n.surah;
    final lockedText = context.l10n.completePreviousSurahFirst(
      previousSurahName,
    );

    return GestureDetector(
      onTap: () async {
        if (isLocked) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(lockedText)));
          return;
        }
        final route =
            await MemorizationNavigationResolver(
              getIt<MemorizationPlusRepository>(),
            ).practiceSurahSessionLocation(
              surah.id,
              surahAyahCount: surah.ayahCount,
            );
        if (!context.mounted) return;
        await context.push(route);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isLocked ? surface.withValues(alpha: 0.82) : surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isLocked ? border.withValues(alpha: 0.65) : border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isLocked
                    ? (isDark ? Colors.white10 : Colors.black12)
                    : primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: Text(
                  '${surah.id}',
                  style: AppTypography.labelMedium.copyWith(
                    color: isLocked
                        ? (isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint)
                        : primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.isArabic ? surah.nameAr : surah.nameEn,
                    style: context.isArabic
                        ? AppTypography.surahTitle.copyWith(
                            color: isLocked
                                ? (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary)
                                : primary,
                            fontSize: 18,
                          )
                        : AppTypography.titleMedium.copyWith(
                            color: isLocked
                                ? (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary)
                                : isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                  ),
                  const SizedBox(height: 6),
                  if (isLocked) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lockedText,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextHint
                                  : AppColors.lightTextHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    '${surah.ayahCount} ${context.l10n.ayahs}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              isLocked
                  ? Icons.lock_rounded
                  : context.isArabic
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.02, end: 0);
  }
}

// ─── MemorizationPlus Banner (Hifz Entry Point) ───────────────────────────────

class _MemPlusBanner extends StatelessWidget {
  const _MemPlusBanner({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.memorizationHub),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.md,
          AppSpacing.pagePadding,
          0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF1A3A5C), Color(0xFF1A6B5A)],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.smartMemorization,
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  Text(
                    context.l10n.smartMemorizationSubtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              context.isArabic
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
