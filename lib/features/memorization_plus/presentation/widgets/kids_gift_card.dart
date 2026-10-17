import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import '../../domain/entities/memorization_entities.dart';
import '../theme/kids_theme.dart';

/// One guardian gift in «كنوزي». An unlocked gift offers the request button;
/// the guardian still has to confirm the hand-over.
class KidsGiftCard extends StatelessWidget {
  const KidsGiftCard({
    super.key,
    required this.reward,
    this.onRequest,
    this.milestoneProgress,
    this.promiseJustKept = false,
  });

  final ParentReward reward;

  /// Saved ayahs of the surah this locked gift waits for (null: no condition).
  final ({int done, int total})? milestoneProgress;

  /// The surah promise came true on this visit.
  final bool promiseJustKept;

  /// Null hides the request button (for example while it is being sent).
  final VoidCallback? onRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, status) = switch (reward.status) {
      ParentRewardStatus.locked => (TaliaKidsIcons.lock, l10n.kidsGiftLocked),
      ParentRewardStatus.unlocked => (
        TaliaKidsIcons.gift,
        l10n.kidsGiftUnlocked,
      ),
      ParentRewardStatus.requested => (
        TaliaKidsIcons.hourglass,
        l10n.kidsGiftRequested,
      ),
      ParentRewardStatus.claimed => (
        TaliaKidsIcons.celebrate,
        l10n.kidsGiftClaimed,
      ),
    };
    final progress = reward.status == ParentRewardStatus.locked
        ? milestoneProgress
        : null;
    final canRequest =
        reward.status == ParentRewardStatus.unlocked && onRequest != null;
    return Container(
      key: ValueKey('kids-gift-${reward.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: KidsTheme.parchmentGradient,
        borderRadius: KidsTheme.cardRadius,
        border: Border.all(color: KidsTheme.parchmentEdge, width: 1.5),
        boxShadow: KidsTheme.card25DShadow,
      ),
      child: Row(
        children: [
          TaliaFeatureDoor(icon: icon, color: AppColors.kidsDoorSun, size: 40),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: KidsTheme.inkOnParchment,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  status,
                  style: AppTypography.bodySmall.copyWith(
                    color: KidsTheme.inkOnParchment,
                    letterSpacing: 0,
                  ),
                ),
                if (promiseJustKept) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.promiseUnlockedByMilestone,
                    style: AppTypography.bodySmall.copyWith(
                      color: KidsTheme.inkOnParchment,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Column(
                    key: ValueKey('kids-gift-progress-${reward.id}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: progress.total <= 0
                            ? 0
                            : (progress.done / progress.total).clamp(0.0, 1.0),
                        color: KidsTheme.goldStar,
                        backgroundColor: KidsTheme.parchmentEdge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.promiseProgress(
                          LocaleNumberFormatter.number(
                            progress.done,
                            l10n.localeName,
                          ),
                          progress.total,
                          LocaleNumberFormatter.number(
                            progress.total,
                            l10n.localeName,
                          ),
                        ),
                        style: AppTypography.bodySmall.copyWith(
                          color: KidsTheme.inkOnParchment,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (canRequest) ...[
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              key: ValueKey('kids-gift-request-${reward.id}'),
              onPressed: onRequest,
              style: FilledButton.styleFrom(
                backgroundColor: KidsTheme.goldStar,
                foregroundColor: KidsTheme.inkOnParchment,
              ),
              child: Text(l10n.kidsGiftRequestAction),
            ),
          ],
        ],
      ),
    );
  }
}
