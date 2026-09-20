// lib/features/memorization_plus/presentation/pages/v2/v2_completion_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/widgets/closing_moment.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/memorization/v2/session_state.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../../../features/settings/presentation/cubits/profile_cubit.dart';
import 'v2_session_widgets.dart';

/// V2 Phase 6: Completion â€” the block is fully memorized.
/// Shows a summary of passed ayahs and retry count, then navigates back.
class V2CompletionPage extends StatelessWidget {
  const V2CompletionPage({super.key, required this.finalState});

  final V2SessionState finalState;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            // â”€â”€ Closing moment: Ø³ÙƒÙŠÙ†Ø© before statistics â”€â”€
            ClosingMomentAyahCard(
              key: const Key('v2_closing_moment'),
              summary: l10n.closingSummaryMemorization(
                finalState.passedAyahNumbers.length,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            V2SummaryRow(
              passed: finalState.passedAyahNumbers.length,
              total: finalState.totalAyahsInBlock,
              failures: finalState.failureTracker.totalFailures,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.closingRestNote,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: textSecondary),
            ),
            const Spacer(),
            OutlinedButton.icon(
              key: const Key('v2_closing_dua_button'),
              onPressed: () => showClosingDuaSheet(context),
              icon: const Icon(Icons.volunteer_activism_rounded),
              label: Text(l10n.closingDuaButton),
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

}
