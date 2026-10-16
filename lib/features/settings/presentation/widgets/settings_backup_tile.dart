import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import 'settings_section.dart';

/// Entry to export/restore, shown only while the local backup flag is on.
class BackupTile extends StatelessWidget {
  const BackupTile({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = context.tokens.accent;

    return InkWell(
      onTap: () => context.push(AppRoutes.backup),
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
              child: Icon(TaliaIcons.library, color: primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.l10n.backupTitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.tokens.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SettingsTrailingChevron(color: context.tokens.textSecondary),
          ],
        ),
      ),
    );
  }
}
