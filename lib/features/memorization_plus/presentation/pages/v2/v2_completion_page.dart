import 'dart:async';
import '../../../../../core/icons/talia_icons.dart';
import '../../../../../core/utils/locale_number_formatter.dart';
// lib/features/memorization_plus/presentation/pages/v2/v2_completion_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/widgets/closing_moment.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/memorization/v2/session_state.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../../../features/settings/presentation/cubits/profile_cubit.dart';
import '../../../domain/navigation/memorization_navigation_resolver.dart';
import '../../../domain/repositories/memorization_plus_repository.dart';
import 'v2_session_widgets.dart';

/// V2 Phase 6: Completion — the block is fully memorized.
/// Shows a summary of passed ayahs and retry count, then navigates back.
/// Loads the next step of today's plan; null when nothing remains.
typedef V2NextStepLoader = Future<({String route, int remaining})?> Function();

class V2CompletionPage extends StatefulWidget {
  const V2CompletionPage({
    super.key,
    required this.finalState,
    this.nextStepLoader,
  });

  final V2SessionState finalState;

  /// Visible for tests; production resolves today's plan via DI.
  final V2NextStepLoader? nextStepLoader;

  @override
  State<V2CompletionPage> createState() => _V2CompletionPageState();
}

class _V2CompletionPageState extends State<V2CompletionPage> {
  ({String route, int remaining})? _nextStep;

  V2SessionState get finalState => widget.finalState;

  @override
  void initState() {
    super.initState();
    unawaited(_loadNextStep());
  }

  Future<void> _loadNextStep() async {
    final loader =
        widget.nextStepLoader ??
        (getIt.isRegistered<MemorizationPlusRepository>()
            ? MemorizationNavigationResolver(
                getIt<MemorizationPlusRepository>(),
              ).nextDailyPlanStep
            : null);
    if (loader == null) return;
    try {
      final next = await loader();
      if (mounted) setState(() => _nextStep = next);
    } catch (_) {
      // The hub stays available; a lookup failure only hides the shortcut.
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.tokens.accent;
    final textSecondary = context.tokens.textSecondary;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            // ── Closing moment: سكينة before statistics ──
            ClosingMomentAyahCard(
              key: const Key('v2_closing_moment'),
              summary: finalState.isReview
                  ? l10n.closingSummaryReview
                  : l10n.closingSummaryMemorization(
                      finalState.passedAyahNumbers.length,
                      context.numText(finalState.passedAyahNumbers.length),
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
            if (kClosingDuaApproved)
              OutlinedButton.icon(
                key: const Key('v2_closing_dua_button'),
                onPressed: () => showClosingDuaSheet(context),
                icon: const Icon(TaliaIcons.dua),
                label: Text(l10n.closingDuaButton),
              ),
            if (!finalState.isReview) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  final profileState = context.read<ProfileCubit>().state;
                  final name =
                      profileState is ProfileLoaded &&
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
                icon: const Icon(TaliaIcons.share),
                label: Text(context.l10n.shareMemorizationMilestone),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            if (_nextStep case final next?) ...[
              FilledButton.icon(
                key: const Key('v2_next_plan_item_button'),
                // Replace this finished session so "back" returns to where
                // the learner started, not to a completed screen.
                onPressed: () => context.pushReplacement(next.route),
                style: FilledButton.styleFrom(backgroundColor: primary),
                icon: const Icon(TaliaIcons.skipNext),
                label: Text(
                  l10n.v2NextPlanItem(
                    LocaleNumberFormatter.format(
                      (next.remaining).toString(),
                      l10n.localeName,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.memorizationHub),
                icon: const Icon(TaliaIcons.hub),
                label: Text(context.l10n.v2MemorizationHub),
              ),
            ] else
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.memorizationHub),
                style: FilledButton.styleFrom(backgroundColor: primary),
                icon: const Icon(TaliaIcons.hub),
                label: Text(context.l10n.v2MemorizationHub),
              ),
          ],
        ),
      ),
    );
  }
}
