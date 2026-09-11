import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/quran_reciter.dart';
import '../../../../core/services/quran_reciter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'reciter_selector_sheet.dart';

/// Overflow sheet for the adult reader's secondary actions (presentation).
///
/// Keeps the top bar minimal: reciter selection and focus mode live here.
/// Reading/audio state stays in the existing cubits and services.
class ReaderOverflowSheet extends StatelessWidget {
  const ReaderOverflowSheet({super.key, required this.onEnterFocus});

  final VoidCallback onEnterFocus;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onEnterFocus,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderOverflowSheet(onEnterFocus: onEnterFocus),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final reciterService = getIt<QuranReciterService>();

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ValueListenableBuilder<QuranReciter>(
              valueListenable: reciterService.currentReciter,
              builder: (context, reciter, _) {
                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    context.l10n.selectReciter,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic ? reciter.nameAr : reciter.nameEn,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  trailing: Icon(
                    context.forwardChevron,
                    size: 18,
                    color: primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                    ReciterSelectorSheet.show(context);
                  },
                );
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fullscreen_rounded,
                  color: primary,
                  size: 22,
                ),
              ),
              title: Text(
                context.l10n.enterFocusMode,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Icon(
                context.forwardChevron,
                size: 18,
                color: primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                onEnterFocus();
              },
            ),
          ],
        ),
      ),
    );
  }
}
