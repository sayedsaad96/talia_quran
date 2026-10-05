import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../theme/kids_theme.dart';

/// One guardian gift in «كنوزي». An unlocked gift offers the request button;
/// the guardian still has to confirm the hand-over.
class KidsGiftCard extends StatelessWidget {
  const KidsGiftCard({super.key, required this.reward, this.onRequest});

  final ParentReward reward;

  /// Null hides the request button (for example while it is being sent).
  final VoidCallback? onRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, status) = switch (reward.status) {
      ParentRewardStatus.locked => (Icons.lock_rounded, l10n.kidsGiftLocked),
      ParentRewardStatus.unlocked => (
        Icons.card_giftcard_rounded,
        l10n.kidsGiftUnlocked,
      ),
      ParentRewardStatus.requested => (
        Icons.hourglass_top_rounded,
        l10n.kidsGiftRequested,
      ),
      ParentRewardStatus.claimed => (
        Icons.celebration_rounded,
        l10n.kidsGiftClaimed,
      ),
    };
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
          Icon(icon, color: KidsTheme.houseBrown, size: 32),
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
