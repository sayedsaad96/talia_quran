// lib/core/widgets/closing_moment.dart
//
// Talia's shared "closing moment" (لحظة الختام) building blocks.
// Used by session-ending flows (memorization completion, khatmah wird
// completion, …) to close with serenity instead of promotional noise.

import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The serene heart of a closing moment: an ayah of tranquility and a quiet
/// summary of the session's impact, rendered before any statistics.
class ClosingMomentAyahCard extends StatelessWidget {
  const ClosingMomentAyahCard({super.key, required this.summary});

  /// Pre-localized, caller-specific summary line (e.g. ayahs memorized or
  /// khatmah wird page range).
  final String summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = context.isDark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? cardBorder
              : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.nightlight_round, color: AppColors.gold, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.closingMomentLabel,
            style: AppTypography.labelLarge.copyWith(
              color: textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.closingAyah,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              fontFamily: 'Amiri',
              color: textPrimary,
              height: 1.9,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.closingAyahSource,
            style: AppTypography.labelMedium.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            summary,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Opens the serene closing-dua bottom sheet shared by all closing moments.
Future<void> showClosingDuaSheet(BuildContext context) {
  final isDark = context.isDark;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (sheetContext) {
      final sheetL10n = sheetContext.l10n;
      final sheetIsDark = sheetContext.isDark;
      final sheetTextPrimary = sheetIsDark
          ? AppColors.darkTextPrimary
          : AppColors.lightTextPrimary;
      final sheetTextSecondary = sheetIsDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.volunteer_activism_rounded,
                color: AppColors.gold,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                sheetL10n.closingDua,
                key: const Key('closing_dua_text'),
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall.copyWith(
                  fontFamily: 'Amiri',
                  color: sheetTextPrimary,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                sheetL10n.closingDuaAmen,
                key: const Key('closing_dua_amen'),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: sheetTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(
                  sheetL10n.closingMomentLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: sheetTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
