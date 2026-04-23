import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../constants/app_spacing.dart';

abstract class AppDecorations {
  static BoxDecoration card({
    required bool isDark,
    double radius = AppSpacing.radiusLg,
  }) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        width: 0.5,
      ),
    );
  }

  static BoxDecoration glass({required bool isDark}) {
    return BoxDecoration(
      gradient: isDark
          ? AppColors.surfaceGlassDark
          : AppColors.surfaceGlassLight,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.6),
      ),
    );
  }

  static BoxDecoration primary({double radius = AppSpacing.radiusMd}) {
    return BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  const AppDecorations._();
}
