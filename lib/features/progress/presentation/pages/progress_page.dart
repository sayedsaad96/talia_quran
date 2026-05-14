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

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays, required this.isDark});
  final int streakDays;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8C42), Color(0xFFFF5500)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$streakDays',
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            context.l10n.days,
            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
          ),
          Text(
            context.l10n.streak,
            style: AppTypography.labelSmall.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.isDark,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final bool isDark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.displaySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            unit,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detailed Progress Card ───────────────────────────────────────────────────

class _DetailRow {
  const _DetailRow({
    required this.label,
    required this.current,
    required this.total,
    required this.color,
  });
  final String label;
  final int current;
  final int total;
  final Color color;

  double get percentage => total == 0 ? 0 : current / total;
}

class _InfoChip {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final String label;
  final String value;
  final Color color;
  final bool isDark;
}

class _DetailedProgressCard extends StatelessWidget {
  const _DetailedProgressCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.percentage,
    required this.rows,
    this.extraInfo,
  });

  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final double percentage;
  final List<_DetailRow> rows;
  final List<_InfoChip>? extraInfo;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular progress
              CircularPercentIndicator(
                radius: 44,
                lineWidth: 6,
                percent: percentage.clamp(0.0, 1.0),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                progressColor: iconColor,
                backgroundColor: iconColor.withValues(alpha: 0.1),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 600,
              ),
              const SizedBox(width: AppSpacing.lg),
              // Details column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headlineSmall.copyWith(
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...rows.map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ProgressBarRow(row: row, isDark: isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Extra info chips
          if (extraInfo != null && extraInfo!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: border, height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: extraInfo!.map((chip) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: chip.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: chip.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          chip.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chip.value,
                          style: AppTypography.labelMedium.copyWith(
                            color: chip.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Progress Bar Row ─────────────────────────────────────────────────────────

class _ProgressBarRow extends StatelessWidget {
  const _ProgressBarRow({required this.row, required this.isDark});
  final _DetailRow row;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: row.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              row.label,
              style: AppTypography.labelSmall.copyWith(color: hintColor),
            ),
            const Spacer(),
            Text(
              '${row.current} / ${row.total}',
              style: AppTypography.labelSmall.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 4,
          percent: row.percentage.clamp(0.0, 1.0),
          progressColor: row.color,
          backgroundColor: row.color.withValues(alpha: 0.1),
          barRadius: const Radius.circular(4),
          animation: true,
          animationDuration: 600,
        ),
      ],
    );
  }
}

// ─── Achievement Categories ───────────────────────────────────────────────────

class _AchievementsCategorized extends StatefulWidget {
  const _AchievementsCategorized({
    required this.achievements,
    required this.isDark,
  });
  final List<Achievement> achievements;
  final bool isDark;

  @override
  State<_AchievementsCategorized> createState() =>
      _AchievementsCategorizedState();
}

class _AchievementsCategorizedState extends State<_AchievementsCategorized> {
  int _selectedTab = 0;

  static const _categories = [
    null, // All
    AchievementCategory.reading,
    AchievementCategory.memorization,
    AchievementCategory.streak,
  ];

  List<Achievement> get _filtered {
    final cat = _categories[_selectedTab];
    if (cat == null) return widget.achievements;
    return widget.achievements.where((a) => a.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    final tabLabels = [
      context.l10n.all,
      context.l10n.reading,
      context.l10n.memorization,
      context.l10n.streakTerm,
    ];

    return Column(
      children: [
        // Tab bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(tabLabels.length, (i) {
              final selected = _selectedTab == i;
              return Padding(
                padding: EdgeInsets.only(
                  right: i < tabLabels.length - 1 ? 8.0 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? primary
                          : primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      tabLabels[i],
                      style: AppTypography.labelMedium.copyWith(
                        color: selected ? Colors.white : primary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Achievement grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.72,
          ),
          itemCount: _filtered.length,
          itemBuilder: (context, i) =>
              _AchievementTile(achievement: _filtered[i], isDark: isDark),
        ),
      ],
    );
  }
}

// ─── Achievement Tile ─────────────────────────────────────────────────────────

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.isDark});
  final Achievement achievement;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final title = context.localizedAchievementTitle(achievement);

    return GestureDetector(
      onTap: () => _showAchievementDetail(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: unlocked ? primary.withValues(alpha: 0.08) : surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: unlocked ? primary.withValues(alpha: 0.25) : border,
            width: unlocked ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Text(
              achievement.icon,
              style:
                  TextStyle(
                    fontSize: 26,
                    color: unlocked ? null : Colors.transparent,
                  ).copyWith(
                    shadows: [
                      if (!unlocked)
                        Shadow(
                          color: Colors.grey.withValues(alpha: 0.5),
                          blurRadius: 0,
                        ),
                    ],
                  ),
            ),
            const SizedBox(height: 4),

            // Title
            Text(
              title,
              style: AppTypography.labelSmall.copyWith(
                color: unlocked ? primary : hintColor,
                fontWeight: unlocked ? FontWeight.w600 : FontWeight.w400,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Progress bar or lock
            if (unlocked)
              Icon(Icons.check_circle_rounded, size: 14, color: primary)
            else ...[
              // Mini progress bar
              SizedBox(
                width: 50,
                child: LinearPercentIndicator(
                  padding: EdgeInsets.zero,
                  lineHeight: 3,
                  percent: achievement.progressPercent,
                  progressColor: primary.withValues(alpha: 0.5),
                  backgroundColor: primary.withValues(alpha: 0.08),
                  barRadius: const Radius.circular(4),
                  animation: true,
                  animationDuration: 400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${achievement.currentValue}/${achievement.targetValue}',
                style: AppTypography.labelSmall.copyWith(
                  color: hintColor,
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(BuildContext context) {
    final isDark = this.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final title = context.localizedAchievementTitle(achievement);
    final description = context.localizedAchievementDescription(achievement);
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkDivider
                      : AppColors.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(achievement.icon, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.headlineMedium.copyWith(
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: AppTypography.bodyMedium.copyWith(color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Progress bar
              LinearPercentIndicator(
                lineHeight: 8,
                percent: achievement.progressPercent,
                progressColor: achievement.isUnlocked
                    ? AppColors.success
                    : primary,
                backgroundColor: primary.withValues(alpha: 0.1),
                barRadius: const Radius.circular(4),
                center: Text(
                  '${(achievement.progressPercent * 100).toStringAsFixed(0)}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 7,
                  ),
                ),
                animation: true,
                animationDuration: 500,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${achievement.currentValue} / ${achievement.targetValue}',
                style: AppTypography.labelMedium.copyWith(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (achievement.isUnlocked) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.achieved,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final profileState = context.read<ProfileCubit>().state;
                      final hasName =
                          profileState is ProfileLoaded &&
                          profileState.profile.hasName;
                      final isMemorizationAchievement =
                          achievement.category ==
                          AchievementCategory.memorization;
                      final text = hasName
                          ? (isMemorizationAchievement
                                ? context.l10n
                                      .shareMemorizationAchievementWithName(
                                        description,
                                        profileState.profile.displayName,
                                        title,
                                      )
                                : context.l10n.shareAchievementWithName(
                                    description,
                                    profileState.profile.displayName,
                                    title,
                                  ))
                          : (isMemorizationAchievement
                                ? context.l10n.shareMemorizationAchievementText(
                                    description,
                                    title,
                                  )
                                : context.l10n.shareAchievementText(
                                    description,
                                    title,
                                  ));
                      SharePlus.instance.share(ShareParams(text: text));
                    },
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: Text(context.l10n.shareAchievement),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Smart Memorization Progress Card ─────────────────────────────────────────

class _SmartMemorizationCard extends StatelessWidget {
  const _SmartMemorizationCard({required this.progress, required this.isDark});
  final OverallProgress progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Adult Track Stats
          if (progress.smartMemorizedAyahs > 0 ||
              progress.smartReviewAyahs > 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  context.l10n.adultsTrack,
                  style: AppTypography.titleMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ProgressBarRow(
                    row: _DetailRow(
                      label: context.l10n.memorizedTerm,
                      current: progress.smartMemorizedAyahs,
                      total: 6236,
                      color: const Color(0xFF2D8E4C),
                    ),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.l10n.reviewingPrefix,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          '${progress.smartReviewAyahs}',
                          style: AppTypography.labelMedium.copyWith(
                            color: const Color(0xFFFF8C42),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (progress.kidsPoints > 0) const Divider(height: 32),
          ],

          // Kids Track Stats
          if (progress.kidsPoints > 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  context.l10n.kidsTrack,
                  style: AppTypography.titleMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: context.l10n.points,
                    value: '${progress.kidsPoints}',
                    icon: Icons.military_tech_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatBox(
                    label: context.l10n.stars,
                    value: '${progress.kidsStars}',
                    icon: Icons.star_rounded,
                    color: AppColors.gold,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Certificates Section ─────────────────────────────────────────────────────

class _CertificatesSection extends StatefulWidget {
  const _CertificatesSection({required this.isDark});
  final bool isDark;

  @override
  State<_CertificatesSection> createState() => _CertificatesSectionState();
}

class _CertificatesSectionState extends State<_CertificatesSection> {
  List<CertificateAward> _certificates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    final service = getIt<AchievementService>();
    final certs = service.getEarnedCertificates();
    if (service.hasNewCertificate) {
      service.markCertificatesSeen();
    }
    if (mounted) {
      setState(() {
        _certificates = certs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    if (_certificates.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: context.l10n.myCertificates,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: widget.isDark
                    ? AppColors.darkDivider
                    : AppColors.lightDivider,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 48,
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.earnCertificatesHint,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: widget.isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.myCertificates,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: IntrinsicHeight(
            child: Row(
              children: List.generate(_certificates.length, (index) {
                final cert = _certificates[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _certificates.length - 1 ? AppSpacing.md : 0,
                  ),
                  child: SizedBox(
                    width: 240,
                    child: _CertificateCard(cert: cert, isDark: widget.isDark),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.cert, required this.isDark});
  final CertificateAward cert;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isJuz = cert.type == CertificateType.juz;
    final color = isJuz ? AppColors.gold : AppColors.primary;
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: isDark ? 0.2 : 0.1),
        color.withValues(alpha: 0.05),
      ],
    );

    return GestureDetector(
      onTap: () {
        context.push(
          '/certificate',
          extra: {
            'award': cert,
            'userName': context.read<ProfileCubit>().state is ProfileLoaded
                ? (context.read<ProfileCubit>().state as ProfileLoaded)
                      .profile
                      .displayName
                : context.l10n.taliaUser,
          },
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isJuz
                    ? Icons.workspace_premium_rounded
                    : Icons.verified_rounded,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.localizedCertificateTitle(cert),
              textAlign: TextAlign.center,
              style: AppTypography.labelMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${cert.earnedAt.day}/${cert.earnedAt.month}/${cert.earnedAt.year}',
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
