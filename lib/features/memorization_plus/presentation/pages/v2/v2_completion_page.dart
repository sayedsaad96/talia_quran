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
    final title = context.l10n.v2CompletionTitle;
    final subtitle = context.l10n.v2CompletionSubtitle;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(Icons.verified_rounded, size: 72, color: primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            V2SummaryRow(
              passed: finalState.passedAyahNumbers.length,
              total: finalState.totalAyahsInBlock,
              failures: finalState.failureTracker.totalFailures,
            ),
            const Spacer(),
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
              icon: const Icon(Icons.hub_rounded),
              label: Text(context.l10n.v2MemorizationHub),
            ),
          ],
        ),
      ),
    );
  }
}
