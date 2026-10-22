import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_typography.dart';

/// Small dismissible key for the memorization-strength colours in the reader.
class StrengthOverlayLegend extends StatelessWidget {
  const StrengthOverlayLegend({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    Widget entry(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: tokens.textSecondary),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.md,
            end: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    entry(tokens.warning, l10n.strengthLegendDue),
                    entry(tokens.error, l10n.strengthLegendWeak),
                    entry(tokens.info, l10n.strengthLegendBuilding),
                    entry(tokens.success, l10n.strengthLegendSolid),
                  ],
                ),
              ),
              IconButton(
                key: const Key('strength-legend-dismiss'),
                onPressed: onDismiss,
                icon: Icon(
                  TaliaIcons.close,
                  size: 16,
                  color: tokens.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
                tooltip: l10n.close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
