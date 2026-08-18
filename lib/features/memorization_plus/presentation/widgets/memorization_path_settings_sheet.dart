import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/memorization_path_resolver.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

Future<void> showMemorizationPathSettingsSheet(
  BuildContext context, {
  required bool isDark,
  String replacementLocation = AppRoutes.memorizationPlus,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ctx.l10n.changeMemorizationPath,
              style: AppTypography.headlineSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontFamily: 'Amiri',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restart_alt_rounded,
                  color: AppColors.warning,
                ),
              ),
              title: Text(
                ctx.l10n.resetMemorizationPathTileTitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                ctx.l10n.resetMemorizationPathPreserveProgressDesc,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              onTap: () async {
                final resetQuestion = ctx.l10n.resetMemorizationPathQuestion;
                final resetDialog =
                    ctx.l10n.resetMemorizationPathPreserveProgressDialog;
                final cancelLabel = ctx.l10n.cancel;
                final resetLabel = ctx.l10n.reset;
                Navigator.pop(ctx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(
                      resetQuestion,
                      style: AppTypography.headlineSmall.copyWith(
                        fontFamily: 'Amiri',
                      ),
                    ),
                    content: Text(resetDialog),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(cancelLabel),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.warning,
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(resetLabel),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final result = await getIt<MemorizationPlusRepository>()
                      .resetMemorizationIdentity();
                  final failure = result.fold(
                    (failure) => failure,
                    (_) => null,
                  );
                  if (failure != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(failure.message)));
                    }
                    return;
                  }
                  getIt<MemorizationPathResolver>().notifyChanged();
                  if (context.mounted) {
                    context.pushReplacement(replacementLocation);
                  }
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
}
