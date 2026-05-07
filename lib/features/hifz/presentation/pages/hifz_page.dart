import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/hifz_entities.dart';
import '../cubits/hifz_cubit.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../../../core/router/app_router.dart';

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
              if (state is HifzLoaded && state.selectedPath != null)
                SliverToBoxAdapter(
                  child: _MemPlusBanner(isDark: isDark),
                ),
              if (state is HifzLoading)
                const SliverFillRemaining(child: LoadingWidget()),
              if (state is HifzError)
                SliverFillRemaining(
                  child: ErrorStateWidget(
                    message: state.message,
                    onRetry: () => context.read<HifzCubit>().load(),
                  ),
                ),
              if (state is HifzLoaded) ...[
                if (state.selectedPath == null)
                  _buildPathSelection(context, primary, isDark)
                else ...[
                  if (state.progressMap.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.lg,
                          bottom: AppSpacing.sm,
                        ),
                        child: SectionHeader(
                          title: context.l10n.hifzProgress,
                          subtitle: '${state.progressMap.length} ${context.l10n.surahs}',
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _ProgressOverviewCard(
                        progressMap: state.progressMap,
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
                  ],
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
                          progress: state.progressMap[state.surahs[i].id],
                          isUnlocked: state.isSurahUnlocked(state.surahs[i].id),
                          requiredPreviousSurah:
                              i > 0 ? state.surahs[i - 1] : null,
                          index: i,
                          isDark: isDark,
                          primary: primary,
                        ),
                        childCount: state.surahs.length,
                      ),
                    ),
                  ),
                ]
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPathSelection(BuildContext context, Color primary, bool isDark) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.chooseMemorizationPath,
              style: AppTypography.headlineSmall.copyWith(color: primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            
            _PathCard(
              title: context.l10n.adultPath,
              subtitle: context.l10n.adultPathDesc,
              icon: Icons.menu_book_rounded,
              primary: primary,
              isDark: isDark,
              onTap: () => context.read<HifzCubit>().selectPath('forward'),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            _PathCard(
              title: context.l10n.beginnerPath,
              subtitle: context.l10n.beginnerPathDesc,
              icon: Icons.child_care_rounded,
              primary: Colors.green, // Visual distinction
              isDark: isDark,
              onTap: () => context.read<HifzCubit>().selectPath('backward'),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext ctx, bool isDark, Color primary, HifzState state) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (state is HifzLoaded && state.selectedPath != null)
                        IconButton(
                          icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white),
                          tooltip: ctx.l10n.changeMemorizationPath,
                          onPressed: () {
                            // Show a bottom sheet or directly navigate back to selection
                            _showPathSelectionSheet(ctx, state.selectedPath!);
                          },
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

  void _showPathSelectionSheet(BuildContext context, String currentPath) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = context.isDark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          title: Text(
            context.l10n.changeMemorizationPath,
            style: AppTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              ListTile(
                leading: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                title: Text(context.isArabic ? "مسار الكبار (تصاعدي)" : "Adult Path (Forward)"),
                subtitle: Text(context.isArabic ? "من الفاتحة إلى الناس" : "Al-Fatihah to An-Nas"),
                trailing: currentPath == 'forward' ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: () {
                  context.read<HifzCubit>().selectPath('forward');
                  Navigator.pop(dialogContext);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.child_care_rounded, color: Colors.green),
                title: Text(context.isArabic ? "مسار المبتدئين (تنازلي)" : "Beginner Path (Backward)"),
                subtitle: Text(context.isArabic ? "من الناس إلى الفاتحة" : "An-Nas to Al-Fatihah"),
                trailing: currentPath == 'backward' ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: () {
                  context.read<HifzCubit>().selectPath('backward');
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: primary.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primary, size: 36),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleLarge.copyWith(color: primary)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle, 
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ProgressOverviewCard extends StatelessWidget {
  const _ProgressOverviewCard({
    required this.progressMap,
    required this.isDark,
    required this.primary,
  });

  final Map<int, SurahHifzProgress> progressMap;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final totalMemorized = progressMap.values.fold(
      0,
      (s, p) => s + p.memorizedCount,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.heroGradientDark
            : AppColors.heroGradientLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalMemorized',
                  style: AppTypography.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.memorized,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          CircularPercentIndicator(
            radius: 36,
            lineWidth: 5,
            percent: (totalMemorized / 6236).clamp(0.0, 1.0),
            center: Text(
              '${((totalMemorized / 6236) * 100).toStringAsFixed(1)}%',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 9,
              ),
            ),
            progressColor: AppColors.gold,
            backgroundColor: Colors.white.withValues(alpha:0.2),
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _HifzSurahTile extends StatelessWidget {
  const _HifzSurahTile({
    required this.surah,
    required this.progress,
    required this.isUnlocked,
    required this.requiredPreviousSurah,
    required this.index,
    required this.isDark,
    required this.primary,
  });

  final Surah surah;
  final SurahHifzProgress? progress;
  final bool isUnlocked;
  final Surah? requiredPreviousSurah;
  final int index;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final hasProgress = progress != null;
    final percent = hasProgress
        ? progress!.memorizedCount / surah.ayahCount
        : 0.0;
    final isLocked = !isUnlocked;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final lockedText = context.isArabic
        ? 'أكمل ${requiredPreviousSurah?.nameAr ?? 'السورة السابقة'} أولاً'
        : 'Complete ${requiredPreviousSurah?.nameEn ?? 'the previous surah'} first';

    return GestureDetector(
          onTap: () {
            if (isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lockedText)),
              );
              return;
            }
            context.push(
              '/hifz/session',
              extra: {'surahId': surah.id, 'startAyah': 1},
            );
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
                        : hasProgress
                        ? primary.withValues(alpha:0.12)
                        : primary.withValues(alpha:0.06),
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
                      if (hasProgress) ...[
                        LinearPercentIndicator(
                          lineHeight: 4,
                          percent: percent.clamp(0.0, 1.0),
                          progressColor: AppColors.gold,
                          backgroundColor: primary.withValues(alpha:0.1),
                          barRadius: const Radius.circular(4),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${progress!.memorizedCount} / ${surah.ayahCount} ${context.l10n.ayahs}',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                        ),
                      ] else
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
                  isLocked ? Icons.lock_rounded : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideX(begin: 0.02, end: 0);
  }
}

// ─── MemorizationPlus Banner (Hifz Entry Point) ───────────────────────────────

class _MemPlusBanner extends StatelessWidget {
  const _MemPlusBanner({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.memorizationPlus),
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
            const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 22),
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
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
