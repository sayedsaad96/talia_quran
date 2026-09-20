import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
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
  final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  final subtitleColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  final iconBgColor = (isDark ? AppColors.goldLight : AppColors.primary).withValues(alpha: 0.14);
  final primaryAccent = isDark ? AppColors.goldLight : AppColors.primary;

  final displayName = (surahName != null && surahName.isNotEmpty)
      ? 'سورة $surahName'
      : 'السورة الحالية';

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
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
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
                child: Icon(
                  Icons.headphones_rounded,
                  color: primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'التلاوة قيد التشغيل',
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
                'تستمع الآن إلى $displayName.\nهل تود استمرار الاستماع في الخلفية مع التحكم من شريط الإشعارات، أم إيقاف التلاوة والخروج؟',
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
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                  label: const Text('متابعة في الخلفية'),
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
                  icon: const Icon(Icons.stop_circle_outlined, size: 20),
                  label: const Text('إيقاف التلاوة والخروج'),
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
                    'البقاء في التطبيق',
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
