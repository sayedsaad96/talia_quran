import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// A labeled inset group: the caption sits above one quiet surface.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final caption = isDark ? AppColors.primaryLight : AppColors.primary;
    final subtitleColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) _caption(title!, caption, subtitle, subtitleColor),
        DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: border, width: 0.7),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Material(
              color: surface,
              child: Column(children: children),
            ),
          ),
        ),
      ],
    );
  }

  Widget _caption(
    String title,
    Color caption,
    String? subtitle,
    Color subtitleColor,
  ) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        0,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: caption,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(color: subtitleColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// A short label that splits rows inside one settings surface.
class SettingsInListHeader extends StatelessWidget {
  const SettingsInListHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return ColoredBox(
      color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
