import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class AzkarPage extends StatelessWidget {
  const AzkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              120, // Prevent cutoff by bottom nav
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _AzkarCategoryCard(
                  titleAr: 'أذكار الصباح',
                  titleEn: context.l10n.morningAzkar,
                  subtitle: '12 ذكر',
                  icon: Icons.wb_sunny_rounded,
                  gradientColors: const [Color(0xFFFF8C42), Color(0xFFFF6B00)],
                  route: 'morning',
                  delay: 0,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),
                _AzkarCategoryCard(
                  titleAr: 'أذكار المساء',
                  titleEn: context.l10n.eveningAzkar,
                  subtitle: '13 ذكر',
                  icon: Icons.nightlight_round,
                  gradientColors: const [Color(0xFF2D5A8E), Color(0xFF1A3A5C)],
                  route: 'evening',
                  delay: 80,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),
                _AzkarCategoryCard(
                  titleAr: 'أذكار عامة',
                  titleEn: context.l10n.generalAzkar,
                  subtitle: '6 أذكار',
                  icon: Icons.spa_rounded,
                  gradientColors: const [Color(0xFF1A6B5A), Color(0xFF0F4A3E)],
                  route: 'general',
                  delay: 160,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),
                _DailyTip(isDark: isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
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
                    colors: [Color(0xFF1A0A00), Color(0xFF0D1117)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF8C42), Color(0xFFD4A843)],
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
                    context.l10n.azkar,
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  Text(
                    'اذكر الله كثيراً',
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

class _AzkarCategoryCard extends StatelessWidget {
  const _AzkarCategoryCard({
    required this.titleAr,
    required this.titleEn,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.route,
    required this.delay,
    required this.isDark,
  });

  final String titleAr;
  final String titleEn;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String route;
  final int delay;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: () => context.push('/azkar/$route'),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha:0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background icon decoration
                Positioned(
                  right: -16,
                  bottom: -16,
                  child: Icon(
                    icon,
                    size: 100,
                    color: Colors.white.withValues(alpha:0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              titleAr,
                              style: AppTypography.surahTitle.copyWith(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              titleEn,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Text(
                                subtitle,
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                ),
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
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.03, end: 0, curve: Curves.easeOut);
  }
}

class _DailyTip extends StatelessWidget {
  const _DailyTip({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: primary.withValues(alpha:0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: primary.withValues(alpha:0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_rounded, color: AppColors.gold, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'قُلْ هُوَ اللَّهُ أَحَدٌ — قراءة المعوذتين ثلاثًا تكفيك من كل شيء',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontFamily: 'Amiri',
                height: 1.7,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}
