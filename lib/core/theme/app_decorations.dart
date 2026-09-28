import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../constants/app_spacing.dart';

/// Shared decorations. Prefer `AppCard` and `context.tokens` for new UI;
/// these remain for existing call sites.
abstract class AppDecorations {
  /// Shared header gradient for memorization feature pages (hub, practice
  /// picker, plan setup). Centralizes the duplicated gradients so all entry
  /// headers stay visually identical in both themes.
  static LinearGradient memorizationHeader({required bool isDark}) => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2A22), Color(0xFF0D1117)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.accentBlue],
        );
  static BoxDecoration bentoCard({
    required bool isDark,
    double radius = AppSpacing.radiusLg,
    Color? accentGlow,
  }) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color:
              accentGlow ??
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

  /// بطاقة روحانية بـ gradient مستوحى من الرق والمخطوطات
  static BoxDecoration spiritualCard({required bool isDark}) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [const Color(0xFF1C2B2F), const Color(0xFF0F1E22)]
          : [const Color(0xFFF5EDD6), const Color(0xFFEDE4C8)],
    ),
    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
    border: Border.all(
      color: isDark
          ? AppColors.primary.withValues(alpha: 0.2)
          : AppColors.desertSand.withValues(alpha: 0.4),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.ambientTeal.withValues(alpha: isDark ? 0.15 : 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// بطاقة بإطار ذهبي للمحتوى المميز
  static BoxDecoration goldRimCard({required bool isDark}) => BoxDecoration(
    color: isDark ? AppColors.darkCard : AppColors.lightCard,
    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
    border: Border.all(
      color: AppColors.gold.withValues(alpha: 0.35),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.gold.withValues(alpha: 0.12),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  const AppDecorations._();
}
