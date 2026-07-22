import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/journey/journey_presentation_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';

class UnifiedHeroActionCard extends StatelessWidget {
  const UnifiedHeroActionCard({
    super.key,
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  final JourneyPresentationData data;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        splashColor: AppColors.gold.withValues(alpha: 0.1),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.primaryDark.withValues(alpha: 0.7),
                      AppColors.darkSurfaceVariant.withValues(alpha: 0.9),
                    ]
                  : [
                      AppColors.lightSurface,
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isDark
                  ? AppColors.gold.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.primaryDark.withValues(alpha: 0.6)
                    : AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              if (isDark)
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.goldGradient : AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.goldDark : AppColors.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  data.icon,
                  color: isDark ? AppColors.darkBackground : Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: AppTypography.headlineSmall.copyWith(
                        color: textColor,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.gold : primary).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  context.isArabic
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: isDark ? AppColors.goldLight : primary,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }
}
