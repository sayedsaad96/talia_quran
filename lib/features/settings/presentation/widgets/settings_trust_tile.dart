import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import 'settings_section.dart';

/// Entry to the trust center, shown only while its experience flag is on.
class TrustCenterTile extends StatelessWidget {
  const TrustCenterTile({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = context.tokens.accent;
    final textColor = context.tokens.textPrimary;
    final subtextColor = context.tokens.textSecondary;

    return InkWell(
      onTap: () => context.push(AppRoutes.trustCenter),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(TaliaIcons.shield, color: primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.l10n.trustCenterTitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SettingsTrailingChevron(color: subtextColor),
          ],
        ),
      ),
    );
  }
}
