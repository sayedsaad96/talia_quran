import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../settings/presentation/cubits/profile_cubit.dart';
import '../../domain/entities/progress_entities.dart';
import '../cubits/progress_cubit.dart';
import 'package:go_router/go_router.dart';

part '../widgets/progress_stat_cards.dart';
part '../widgets/progress_detailed_card.dart';
part '../widgets/progress_achievements.dart';
part '../widgets/progress_smart_memorization.dart';
part '../widgets/progress_certificates.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProgressCubit>()..load(),
      child: const _ProgressView(),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: BlocBuilder<ProgressCubit, ProgressState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, isDark, state),
              if (state is ProgressLoading)
                const SliverFillRemaining(child: LoadingWidget()),
              if (state is ProgressError)
                SliverFillRemaining(
                  child: ErrorStateWidget(
                    message: state.message,
                    onRetry: () => context.read<ProgressCubit>().load(),
                  ),
                ),
              if (state is ProgressLoaded) ...[
                SliverToBoxAdapter(
                  child: _ProgressContent(
                    progress: state.progress,
                    isDark: isDark,
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
    BuildContext context,
    bool isDark,
    ProgressState state,
  ) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        if (state is ProgressLoaded)
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: context.l10n.shareProgress,
            onPressed: () {
              final profileState = context.read<ProfileCubit>().state;
              final hasName =
                  profileState is ProfileLoaded && profileState.profile.hasName;
              final text = hasName
                  ? context.l10n.shareProgressWithName(
                      state.progress.memorizedAyahs,
                      profileState.profile.displayName,
                      state.progress.readPagesCount,
                      state.progress.streakDays,
                    )
                  : context.l10n.shareProgressText(
                      state.progress.memorizedAyahs,
                      state.progress.readPagesCount,
                      state.progress.streakDays,
                    );
              SharePlus.instance.share(ShareParams(text: text));
            },
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1520), Color(0xFF0D1117)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2D5A8E), Color(0xFF1A3A5C)],
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
                  Text(
                    context.l10n.progress,
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  Text(
                    context.l10n.quranProgress,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
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

// ─── Main Content (StatefulWidget for controlled animations) ──────────────────

class _ProgressContent extends StatefulWidget {
  const _ProgressContent({required this.progress, required this.isDark});
  final OverallProgress progress;
  final bool isDark;

  @override
  State<_ProgressContent> createState() => _ProgressContentState();
}

class _ProgressContentState extends State<_ProgressContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation immediately
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final isDark = widget.isDark;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.lg,
            AppSpacing.pagePadding,
            120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Hero Stats Row ─────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StreakCard(
                      streakDays: p.streakDays,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      label: context.l10n.pagesRead,
                      value: '${p.readPagesCount}',
                      unit: context.l10n.pages,
                      icon: Icons.auto_stories_rounded,
                      isDark: isDark,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ─── Reading Progress Section ───────────────────
              SectionHeader(
                title: context.l10n.readingProgress,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailedProgressCard(
                isDark: isDark,
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.info,
                title: context.l10n.reading,
                percentage: p.quranPercentage,
                rows: [
                  _DetailRow(
                    label: context.l10n.pages,
                    current: p.readPagesCount,
                    total: p.totalQuranPages,
                    color: AppColors.info,
                  ),
                  _DetailRow(
                    label: context.l10n.juzCountLabel,
                    current: p.readJuz,
                    total: p.totalJuz,
                    color: AppColors.primary,
                  ),
                  _DetailRow(
                    label: context.l10n.ayahsRead,
                    current: p.readAyahs,
                    total: p.totalAyahs,
                    color: AppColors.gold,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ─── Memorization Progress Section ──────────────
              SectionHeader(
                title: context.l10n.memorizationProgressTitle,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailedProgressCard(
                isDark: isDark,
                icon: Icons.psychology_rounded,
                iconColor: AppColors.primary,
                title: context.l10n.memorization,
                percentage: p.memorizedAyahsPercentage,
                rows: [
                  _DetailRow(
                    label: context.l10n.memorizedAyahs,
                    current: p.memorizedAyahs,
                    total: p.totalAyahs,
                    color: AppColors.primary,
                  ),
                  _DetailRow(
                    label: context.l10n.memorizedSurahsLabel,
                    current: p.memorizedSurahs,
                    total: p.totalSurahs,
                    color: AppColors.gold,
                  ),
                  _DetailRow(
                    label: context.l10n.memorizedJuzLabel,
                    current: p.memorizedJuz,
                    total: p.totalJuz,
                    color: AppColors.info,
                  ),
                ],
                extraInfo: [
                  _InfoChip(
                    label: context.l10n.learning,
                    value: '${p.learningAyahs}',
                    color: AppColors.warning,
                    isDark: isDark,
                  ),
                  _InfoChip(
                    label: context.l10n.reviewing,
                    value: '${p.reviewAyahs}',
                    color: AppColors.info,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sectionGap),

              // ─── Smart Memorization Progress Section ─────────
              if (p.smartMemorizedAyahs > 0 ||
                  p.smartReviewAyahs > 0 ||
                  p.kidsPoints > 0) ...[
                SectionHeader(
                  title: context.l10n.smartMemorization,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.md),
                _SmartMemorizationCard(progress: p, isDark: isDark),
                const SizedBox(height: AppSpacing.sectionGap),
              ],

              // ─── Certificates Section ─────────────────────────
              _CertificatesSection(isDark: isDark),
              const SizedBox(height: AppSpacing.sectionGap),

              // ─── Achievements Section ───────────────────────
              Row(
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: context.l10n.achievements,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isDark ? AppColors.primaryLight : AppColors.primary)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      '${p.unlockedAchievements} / ${p.achievements.length}',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Achievement category tabs
              _AchievementsCategorized(
                achievements: p.achievements,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Streak Card ──────────────────────────────────────────────────────────────
