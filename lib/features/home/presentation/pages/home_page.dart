import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/router/app_router.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../settings/data/profile_cubit.dart';
import '../cubits/home_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..load(),
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


        // ─── Daily Wird Card ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
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
              AppSpacing.sectionGap,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: SectionHeader(
              title: context.l10n.overallProgress,
              padding: EdgeInsets.zero,
              action: GestureDetector(
                onTap: () => context.go('/progress'),
                child: Text(
                  'عرض الكل',
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

        // ─── Bottom padding (above nav bar) ──────────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.state, required this.isDark});
  final HomeLoaded state;
  final bool isDark;

  String _greetingText(BuildContext ctx) => switch (state.greeting) {
    'morning' => ctx.l10n.greetingMorning,
    'afternoon' => ctx.l10n.greetingAfternoon,
    'evening' => ctx.l10n.greetingEvening,
    _ => ctx.l10n.greetingNight,
  };

  IconData _greetingIcon() => switch (state.greeting) {
    'morning' => Icons.wb_sunny_rounded,
    'afternoon' => Icons.wb_cloudy_rounded,
    'evening' => Icons.wb_twilight_rounded,
    _ => Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.heroGradientDark
            : AppColors.heroGradientLight,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.lg,
            AppSpacing.pagePadding,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top row ────────────────────────────────────────────────
              Row(
                children: [
                  Icon(_greetingIcon(), color: AppColors.goldLight, size: 22),
                  const SizedBox(width: 8),
                  BlocBuilder<ProfileCubit, ProfileState>(
                    builder: (context, profileState) {
                      final hasName = profileState is ProfileLoaded && profileState.profile.hasName;
                      final nameStr = hasName ? ', ${profileState.profile.displayName}' : '';
                      return Text(
                        '${_greetingText(context)}$nameStr',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  // Settings button
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.settings),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 200.ms),

              const SizedBox(height: AppSpacing.lg),

              // ─── App name + Bismillah ────────────────────────────────────
              Text(
                'تالية',
                style: AppTypography.displayMedium.copyWith(
                  fontFamily: 'Amiri',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.02),

              const SizedBox(height: 4),

              Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white60,
                  fontFamily: 'Amiri',
                  fontSize: 14,
                ),
                textDirection: TextDirection.rtl,
              ).animate().fadeIn(duration: 200.ms),

              const SizedBox(height: AppSpacing.xl),

              // ─── Streak pill & Achievement Badges ───────────────────────
              Builder(builder: (context) {
                final readingAchievements = state.progress.achievements.where(
                    (a) => a.isUnlocked && a.category == AchievementCategory.reading);
                final memAchievements = state.progress.achievements.where(
                    (a) => a.isUnlocked && a.category == AchievementCategory.memorization);

                final highestReading = readingAchievements.isNotEmpty ? readingAchievements.last : null;
                final highestMem = memAchievements.isNotEmpty ? memAchievements.last : null;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Right side (RTL): Streak Pill
                    _StreakPill(
                      days: state.progress.streakDays,
                      isDark: isDark,
                    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04),
                    
                    // Left side (RTL): Achievement Badges
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          if (highestReading != null)
                            _AchievementBadge(
                              achievement: highestReading,
                              isDark: isDark,
                            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04),
                          if (highestMem != null)
                            _AchievementBadge(
                              achievement: highestMem,
                              isDark: isDark,
                            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04),
                          if (highestReading == null && highestMem == null)
                            const _AchievementBadge(
                              achievement: null,
                              isDark: false,
                            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days, required this.isDark});
  final int days;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFF8C42),
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '$days ${context.l10n.days}',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.streak,
            style: AppTypography.bodySmall.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.achievement, required this.isDark});
  final Achievement? achievement;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    String badgeTitle = 'مبتدئ'; // Default rank
    IconData badgeIcon = Icons.stars_rounded;
    Color badgeColor = const Color(0xFFC0C0C0); // Silver for default
    String categoryLabel = '';

    if (achievement != null) {
      final best = achievement!;
      badgeTitle = best.titleKey; // The titles are already translated strings (e.g., 'نصف القرآن')
      
      // Determine color, icon, and label based on category
      if (best.category == AchievementCategory.memorization) {
        badgeColor = const Color(0xFFFFD700); // Gold for memorization
        badgeIcon = Icons.workspace_premium_rounded;
        categoryLabel = 'حفظ';
      } else {
        badgeColor = const Color(0xFF82C8E5); // Light blue/cyan for reading
        badgeIcon = Icons.menu_book_rounded;
        categoryLabel = 'قراءة';
      }
      
      // Special override for highest achievements
      if (badgeTitle.contains('ختم') || badgeTitle.contains('حافظ')) {
        badgeColor = const Color(0xFFE5C158); // Premium gold
        badgeIcon = Icons.diamond_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor.withValues(alpha: 0.25),
            badgeColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: badgeColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          if (categoryLabel.isNotEmpty) ...[
            Text(
              categoryLabel,
              style: AppTypography.titleSmall.copyWith(
                color: badgeColor.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              height: 16,
              width: 1.5,
              color: badgeColor.withValues(alpha: 0.4),
            ),
          ],
          Text(
            badgeTitle,
            style: AppTypography.titleMedium.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Daily Wird Card ──────────────────────────────────────────────────────────

class _DailyWirdCard extends StatelessWidget {
  const _DailyWirdCard({required this.state, required this.isDark});
  final HomeLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pageNumber = state.dailyWirdPageDetail?.pageNumber ?? 1;
    String wird = context.isArabic
        ? 'قراءة الصفحة $pageNumber من القرآن الكريم'
        : 'Read page $pageNumber of the Holy Quran';

    if (state.dailyWirdPageDetail != null &&
        state.dailyWirdPageDetail!.surahs.isNotEmpty) {
      final surah = state.dailyWirdPageDetail!.surahs.first;
      final surahName = context.isArabic ? surah.nameAr : surah.nameEn;
      wird = context.isArabic
          ? 'سورة $surahName — صفحة $pageNumber'
          : 'Surah $surahName — Page $pageNumber';
    }

    return GestureDetector(
      onTap: () => context.push('/quran/page/$pageNumber'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A2A1A), const Color(0xFF0D1A12)]
                : [const Color(0xFFE8F5EF), const Color(0xFFD4EDE0)],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.dailyWird,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wird,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontFamily: context.isArabic ? 'Amiri' : null,
                    ),
                    textDirection: context.isArabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.03);
  }
}

// ─── Progress Section ──────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.progress, required this.isDark});
  final OverallProgress progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Column(
      children: [
        // ── Streak pill ─────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8C42), Color(0xFFFF6B00)],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                '${progress.streakDays}',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.days,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.streak,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.03),

        const SizedBox(height: AppSpacing.md),

        // ── Two progress cards side by side ─────────────────────────
        Row(
          children: [
            // Reading card
            Expanded(
              child: _MiniProgressCard(
                icon: Icons.menu_book_rounded,
                iconColor: AppColors.primary,
                gradientColors: isDark
                    ? [const Color(0xFF0D2818), const Color(0xFF0A1F14)]
                    : [const Color(0xFFE8F5EF), const Color(0xFFD4EDE0)],
                title: 'القراءة',
                value: progress.readPagesCount,
                total: progress.totalQuranPages,
                unit: 'صفحة',
                isDark: isDark,
                surface: surface,
                border: border,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Memorization card
            Expanded(
              child: _MiniProgressCard(
                icon: Icons.auto_stories_rounded,
                iconColor: const Color(0xFF2D5A8E),
                gradientColors: isDark
                    ? [const Color(0xFF0D1A2E), const Color(0xFF0A1422)]
                    : [const Color(0xFFE8EEF5), const Color(0xFFD4DEE8)],
                title: 'الحفظ',
                value: progress.memorizedAyahs,
                total: progress.totalAyahs,
                unit: 'آية',
                isDark: isDark,
                surface: surface,
                border: border,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 250.ms, delay: 100.ms),
      ],
    );
  }
}

class _MiniProgressCard extends StatelessWidget {
  const _MiniProgressCard({
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.title,
    required this.value,
    required this.total,
    required this.unit,
    required this.isDark,
    required this.surface,
    required this.border,
  });

  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;
  final String title;
  final int value;
  final int total;
  final String unit;
  final bool isDark;
  final Color surface;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Big number
          Text(
            '$value',
            style: AppTypography.displaySmall.copyWith(
              color: iconColor,
              fontWeight: FontWeight.w700,
              fontSize: 28,
            ),
          ),
          Text(
            '$unit من $total',
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: iconColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              minHeight: 5,
            ),
          ),

          const SizedBox(height: 4),

          // Percentage
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              '${(pct * 100).toStringAsFixed(1)}%',
              style: AppTypography.labelSmall.copyWith(
                color: iconColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Azkar Shortcut Row ───────────────────────────────────────────────────────

class _AzkarShortcutRow extends StatelessWidget {
  const _AzkarShortcutRow({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: context.l10n.azkar,
          padding: EdgeInsets.zero,
          action: GestureDetector(
            onTap: () => context.go('/azkar'),
            child: Text(
              'عرض الكل',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _AzkarShortcut(
                label: context.l10n.morningAzkar,
                icon: Icons.wb_sunny_rounded,
                route: '/azkar/morning',
                colors: const [Color(0xFFFF8C42), Color(0xFFFF6B00)],
                isDark: isDark,
                delay: 0,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AzkarShortcut(
                label: context.l10n.eveningAzkar,
                icon: Icons.nightlight_round,
                route: '/azkar/evening',
                colors: const [Color(0xFF2D5A8E), Color(0xFF1A3A5C)],
                isDark: isDark,
                delay: 80,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AzkarShortcut extends StatelessWidget {
  const _AzkarShortcut({
    required this.label,
    required this.icon,
    required this.route,
    required this.colors,
    required this.isDark,
    required this.delay,
  });

  final String label;
  final IconData icon;
  final String route;
  final List<Color> colors;
  final bool isDark;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontFamily: 'Amiri',
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.03, end: 0);
  }
}

// ─── MemorizationPlus Card (Entry Point) ─────────────────────────────────────

class _MemorizationPlusCard extends StatelessWidget {
  const _MemorizationPlusCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.memorizationPlus),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3A5C), Color(0xFF1A6B5A)],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نظام الحفظ الذكي',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'مسار الكبار • مسار الأطفال • تكرار ذكي',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.03, end: 0);
  }
}

// ─── Active Custom Plan Card ─────────────────────────────────────────────────

class _ActiveCustomPlanCard extends StatelessWidget {
  const _ActiveCustomPlanCard({required this.plan, required this.isDark});
  final CustomMemorizationPlan plan;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/memorization-plus/daily-plan',
        extra: {'surahId': plan.startSurahId},
      ).then((_) {
        if (context.mounted) {
          context.read<HomeCubit>().load();
        }
      }),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6C3483).withValues(alpha: 0.9),
              AppColors.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C3483).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan.newAyahsPerDay} آيات يومياً • ${plan.sessionMinutes} دقيقة',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Text(
                'متابعة الحفظ',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.03, end: 0);
  }
}
