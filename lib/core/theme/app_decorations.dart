import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../constants/app_spacing.dart';

abstract class AppDecorations {
  static BoxDecoration card({
    required bool isDark,
    double radius = AppSpacing.radiusLg,
    bool elevated = false,
  }) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark 
            ? AppColors.darkDivider 
            : AppColors.lightDivider,
        width: 0.8,
      ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ]
          : null,
    );
  }

  static BoxDecoration royalGlass({required bool isDark, double radius = AppSpacing.radiusLg}) {
    return BoxDecoration(
      gradient: isDark
          ? AppColors.surfaceGlassDark
          : AppColors.surfaceGlassLight,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? AppColors.gold.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.8),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration glass({required bool isDark}) {
    return royalGlass(isDark: isDark);
  }

  static BoxDecoration bentoCard({
    required bool isDark,
    double radius = AppSpacing.radiusLg,
    Color? accentGlow,
  }) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? AppColors.glassBorderDark
            : AppColors.glassBorderLight,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: accentGlow ??
              (isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : AppColors.primary.withValues(alpha: 0.05)),
          blurRadius: 16,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
      ],
    );
  }

  static BoxDecoration floatingGlass({
    required bool isDark,
    double radius = AppSpacing.radiusFull,
  }) {
    return BoxDecoration(
      color: isDark
          ? AppColors.darkSurface.withValues(alpha: 0.85)
          : AppColors.lightSurface.withValues(alpha: 0.90),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? AppColors.glassBorderDark
            : AppColors.glassBorderLight,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.45)
              : AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 2,
        ),
      ],
    );
  }

  static BoxDecoration primary({double radius = AppSpacing.radiusMd}) {
    return BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.35),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  static BoxDecoration goldAccent({double radius = AppSpacing.radiusMd}) {
    return BoxDecoration(
      gradient: AppColors.goldGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.goldDark.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  const AppDecorations._();
}
