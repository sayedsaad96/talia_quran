import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum ErrorInfoBannerType { error, warning, info, success }

class ErrorInfoBanner extends StatelessWidget {
  const ErrorInfoBanner({
    super.key,
    required this.message,
    this.title,
    this.type = ErrorInfoBannerType.info,
    this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  final String? title;
  final String message;
  final ErrorInfoBannerType type;
  final VoidCallback? onDismissed;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = _BannerColors.fromType(type, Theme.of(context).brightness);

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(colors.icon, color: colors.foreground, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: AppTypography.titleSmall.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.text,
                      height: 1.45,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.foreground,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismissed != null) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onDismissed,
                icon: Icon(Icons.close_rounded, color: colors.foreground),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BannerColors {
  const _BannerColors({
    required this.background,
    required this.border,
    required this.foreground,
    required this.text,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final Color text;
  final IconData icon;

  factory _BannerColors.fromType(
    ErrorInfoBannerType type,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    final text = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    return switch (type) {
      ErrorInfoBannerType.error => _BannerColors(
        background: AppColors.error.withValues(alpha: isDark ? 0.16 : 0.08),
        border: AppColors.error.withValues(alpha: 0.35),
        foreground: AppColors.error,
        text: text,
        icon: Icons.error_outline_rounded,
      ),
      ErrorInfoBannerType.warning => _BannerColors(
        background: AppColors.warning.withValues(alpha: isDark ? 0.16 : 0.1),
        border: AppColors.warning.withValues(alpha: 0.35),
        foreground: AppColors.warning,
        text: text,
        icon: Icons.info_outline_rounded,
      ),
      ErrorInfoBannerType.success => _BannerColors(
        background: AppColors.success.withValues(alpha: isDark ? 0.16 : 0.09),
        border: AppColors.success.withValues(alpha: 0.35),
        foreground: AppColors.success,
        text: text,
        icon: Icons.check_circle_outline_rounded,
      ),
      ErrorInfoBannerType.info => _BannerColors(
        background: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
        border: AppColors.primary.withValues(alpha: 0.28),
        foreground: AppColors.primary,
        text: text,
        icon: Icons.tips_and_updates_outlined,
      ),
    };
  }
}
