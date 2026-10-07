import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Actions available when exiting while Quran audio is playing.
enum QuranBackgroundExitAction {
  /// Continue audio in the background with mobile notification controls.
  continueInBackground,

  /// Stop audio playback completely and exit.
  stopAndExit,
}

/// Displays an exit confirmation dialog when the user attempts to leave the app
/// while Quran recitation is actively playing.
Future<QuranBackgroundExitAction?> showQuranBackgroundExitDialog({
  required BuildContext context,
  String? surahName,
}) {
  final isDark = context.isDark;
  final titleColor = context.tokens.textPrimary;
  final subtitleColor = context.tokens.textSecondary;
  final iconBgColor = (isDark ? AppColors.goldLight : AppColors.primary)
      .withValues(alpha: 0.14);
  final primaryAccent = isDark ? AppColors.goldLight : AppColors.primary;

  final l10n = context.l10n;
  final displayName = (surahName != null && surahName.isNotEmpty)
      ? '${l10n.surah} $surahName'
      : l10n.currentSurah;

  return showDialog<QuranBackgroundExitAction>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          backgroundColor: context.tokens.card,
          titlePadding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.lg,
            AppSpacing.pagePadding,
            AppSpacing.xs,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.md,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            0,
            AppSpacing.pagePadding,
            AppSpacing.md,
          ),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(TaliaIcons.listen, color: primaryAccent, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.exitDialogTitle,
                  style: AppTypography.titleMedium.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.exitDialogBody(displayName),
                style: AppTypography.bodyMedium.copyWith(
                  color: subtitleColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    QuranBackgroundExitAction.continueInBackground,
                  ),
                  icon: const Icon(TaliaIcons.playCircle, size: 20),
                  label: Text(l10n.exitDialogContinueBackground),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    QuranBackgroundExitAction.stopAndExit,
                  ),
                  icon: const Icon(TaliaIcons.stopCircle, size: 20),
                  label: Text(l10n.exitDialogStopAndExit),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: Text(
                    l10n.exitDialogStayInApp,
                    style: TextStyle(color: subtitleColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
