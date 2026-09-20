import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import 'settings_section.dart';

/// A premium Apple/M3 style navigation tile for the settings hub.
///
/// Displays a colored leading icon, title, optional subtitle,
/// optional trailing badge, and a directional chevron arrow.
class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.iconBackgroundColor,
    this.trailingBadge,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDark;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? trailingBadge;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? (isDark ? AppColors.primaryLight : AppColors.primary);
    final effectiveIconBg =
        iconBackgroundColor ?? effectiveIconColor.withValues(alpha: 0.12);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              // Colored icon container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 20,
                  color: effectiveIconColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title and optional subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              if (trailingBadge != null) ...[
                trailingBadge!,
                const SizedBox(width: AppSpacing.xs),
              ],

              // Chevron
              SettingsTrailingChevron(
                color: textSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
