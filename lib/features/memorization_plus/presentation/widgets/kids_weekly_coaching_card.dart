import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/kids_weekly_coaching.dart';

/// The guardian's weekly summary for the child: a few counted facts and one
/// practical step. It only reads [coaching]; nothing here changes progress.
/// The caller supplies the surrounding panel and its title
/// (`kidsWeeklyCoachingTitle`).
class KidsWeeklyCoachingCard extends StatelessWidget {
  const KidsWeeklyCoachingCard({super.key, required this.coaching});

  final KidsWeeklyCoaching coaching;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeyedSubtree(
      key: const ValueKey('kids-weekly-coaching'),
      child: switch (coaching.status) {
        KidsWeeklyCoachingStatus.incompleteHistory => Text(
          l10n.kidsWeeklyCoachingUnavailable,
          key: const ValueKey('kids-weekly-coaching-unavailable'),
          style: AppTypography.bodyMedium,
        ),
        KidsWeeklyCoachingStatus.noHistory => Text(
          l10n.kidsWeeklyCoachingNoHistory,
          key: const ValueKey('kids-weekly-coaching-empty'),
          style: AppTypography.bodyMedium,
        ),
        KidsWeeklyCoachingStatus.ready => _Facts(coaching: coaching),
      },
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.coaching});

  final KidsWeeklyCoaching coaching;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tip = coaching.tip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.kidsWeeklyCoachingSessions(context.numText(coaching.sessions)),
          style: AppTypography.bodyMedium,
        ),
        Text(
          l10n.kidsWeeklyCoachingActiveDays(
            context.numText(coaching.activeDays),
          ),
          style: AppTypography.bodyMedium,
        ),
        Text(
          l10n.kidsWeeklyCoachingReviews(context.numText(coaching.reviews)),
          style: AppTypography.bodyMedium,
        ),
        Text(
          l10n.kidsWeeklyCoachingHints(
            context.numText(coaching.sessionsWithHints),
          ),
          style: AppTypography.bodyMedium,
        ),
        if (tip != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _Tip(text: _tipText(l10n, tip)),
        ],
      ],
    );
  }

  static String _tipText(
    AppLocalizations l10n,
    KidsWeeklyCoachingTip tip,
  ) => switch (tip) {
    KidsWeeklyCoachingTip.listenTogether =>
      l10n.kidsWeeklyCoachingTipListenTogether,
    KidsWeeklyCoachingTip.celebrateEffort =>
      l10n.kidsWeeklyCoachingTipCelebrateEffort,
    KidsWeeklyCoachingTip.keepRhythm => l10n.kidsWeeklyCoachingTipKeepRhythm,
    KidsWeeklyCoachingTip.addReview => l10n.kidsWeeklyCoachingTipAddReview,
    KidsWeeklyCoachingTip.startSmall => l10n.kidsWeeklyCoachingTipStartSmall,
  };
}

class _Tip extends StatelessWidget {
  const _Tip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      key: const ValueKey('kids-weekly-coaching-tip'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(TaliaIcons.idea, color: accent, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: context.tokens.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
