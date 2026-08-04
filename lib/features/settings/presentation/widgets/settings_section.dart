import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = (isDark ? AppColors.darkDivider : AppColors.lightDivider)
        .withValues(alpha: isDark ? 0.55 : 0.8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
              letterSpacing: 0,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Material(
          color: surface,
          elevation: isDark ? 0 : 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: border, width: 0.6),
            ),
            child: Column(children: children),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.025, end: 0);
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
      indent: 64,
    );
  }
}

class SettingsTrailingChevron extends StatelessWidget {
  const SettingsTrailingChevron({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      context.isArabic
          ? Icons.arrow_back_ios_rounded
          : Icons.arrow_forward_ios_rounded,
      size: 16,
      color: color,
    );
  }
}

class SettingsInlineHeader extends StatelessWidget {
  const SettingsInlineHeader({
    super.key,
    required this.isDark,
    required this.icon,
    required this.title,
  });

  final bool isDark;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final iconColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
