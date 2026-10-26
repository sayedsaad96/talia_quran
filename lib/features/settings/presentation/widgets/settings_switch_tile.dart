import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';

/// One row of the seasons and features pages: icon, name, a one-line benefit
/// and a single switch, plus an optional «try it» action that opens the
/// feature. [onChanged] null (with [showSwitch]) renders a disabled switch.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.onChanged,
    this.showSwitch = true,
    this.enabled = true,
    this.onTry,
    this.tryLabel,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showSwitch;
  final bool enabled;
  final VoidCallback? onTry;
  final String? tryLabel;

  @override
  Widget build(BuildContext context) {
    final accent = context.tokens.accent;
    final content = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: context.tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.tokens.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onTry != null && tryLabel != null) ...[
          TextButton(
            onPressed: onTry,
            child: Text(
              tryLabel!,
              style: AppTypography.labelSmall.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (showSwitch)
          Switch.adaptive(
            value: value,
            activeTrackColor: accent,
            onChanged: enabled ? onChanged : null,
          ),
      ],
    );
    if (enabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: content,
      );
    }
    return Opacity(
      opacity: 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: content,
      ),
    );
  }
}
