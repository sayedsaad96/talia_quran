// lib/features/memorization_plus/presentation/pages/v2/v2_completion_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/memorization/v2/session_state.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../../../features/settings/presentation/cubits/profile_cubit.dart';
import 'v2_session_widgets.dart';

/// V2 Phase 6: Completion — the block is fully memorized.
/// Shows a summary of passed ayahs and retry count, then navigates back.
class V2CompletionPage extends StatelessWidget {
  const V2CompletionPage({super.key, required this.finalState});

  final V2SessionState finalState;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardBorder = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            // ── Closing moment: سكينة before statistics ──
            _ClosingMomentCard(
              passedCount: finalState.passedAyahNumbers.length,
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
            const SizedBox(height: AppSpacing.lg),
            V2SummaryRow(
              passed: finalState.passedAyahNumbers.length,
              total: finalState.totalAyahsInBlock,
              failures: finalState.failureTracker.totalFailures,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.v2ClosingRestNote,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: textSecondary),
            ),
            const Spacer(),
            OutlinedButton.icon(
              key: const Key('v2_closing_dua_button'),
              onPressed: () => _showClosingDuaSheet(context, isDark),
              icon: const Icon(Icons.volunteer_activism_rounded),
              label: Text(l10n.v2ClosingDuaButton),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                final profileState = context.read<ProfileCubit>().state;
                final name = profileState is ProfileLoaded &&
                        profileState.profile.hasName
                    ? profileState.profile.displayName
                    : null;
                final data = SocialShareData.memorization(
                  ayahsCount: finalState.passedAyahNumbers.length,
                  surahsCount: 0,
                  userName: name,
                );
                SocialShareSheet.show(context, data);
              },
              icon: const Icon(Icons.share_rounded),
              label: Text(context.l10n.shareMemorizationMilestone),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.memorizationHub),
              style: FilledButton.styleFrom(backgroundColor: primary),
              icon: const Icon(Icons.hub_rounded),
              label: Text(context.l10n.v2MemorizationHub),
            ),
          ],
        ),
      ),
    );
  }

  void _showClosingDuaSheet(BuildContext context, bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
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
                  l10n.v2ClosingDua,
                  key: const Key('v2_closing_dua_text'),
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSmall.copyWith(
                    fontFamily: 'Amiri',
                    color: textPrimary,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.v2ClosingDuaAmen,
                  key: const Key('v2_closing_dua_amen'),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(
                    l10n.v2ClosingMomentLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textSecondary,
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
}

/// The serene heart of the closing moment: an ayah of tranquility and a quiet
/// summary of the session's impact, rendered before any statistics.
class _ClosingMomentCard extends StatelessWidget {
  const _ClosingMomentCard({
    required this.passedCount,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
  });

  final int passedCount;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const Key('v2_closing_moment'),
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
            l10n.v2ClosingMomentLabel,
            style: AppTypography.labelLarge.copyWith(
              color: textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.v2ClosingAyah,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              fontFamily: 'Amiri',
              color: textPrimary,
              height: 1.9,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.v2ClosingAyahSource,
            style: AppTypography.labelMedium.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.v2ClosingSummary(passedCount),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}
