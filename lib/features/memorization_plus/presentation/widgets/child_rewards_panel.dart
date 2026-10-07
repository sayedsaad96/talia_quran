import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';

/// The guardian's gift list for one child. A locked gift can be opened early;
/// a gift the child asked for is confirmed once it has been handed over.
class ChildRewardsPanel extends StatefulWidget {
  const ChildRewardsPanel({
    super.key,
    required this.rewards,
    required this.onUnlock,
    required this.onApprove,
  });

  final List<ParentReward> rewards;
  final Future<void> Function(String rewardId) onUnlock;
  final Future<void> Function(String rewardId) onApprove;

  @override
  State<ChildRewardsPanel> createState() => _ChildRewardsPanelState();
}

class _ChildRewardsPanelState extends State<ChildRewardsPanel> {
  final _busy = <String>{};

  static int _order(ParentRewardStatus status) => switch (status) {
    ParentRewardStatus.requested => 0,
    ParentRewardStatus.unlocked => 1,
    ParentRewardStatus.locked => 2,
    ParentRewardStatus.claimed => 3,
  };

  Future<void> _run(String id, Future<void> Function(String) action) async {
    if (!_busy.add(id)) return;
    setState(() {});
    try {
      await action(id);
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rewards = [...widget.rewards]
      ..sort((a, b) => _order(a.status).compareTo(_order(b.status)));
    return Column(
      children: [
        for (final reward in rewards)
          _RewardRow(
            reward: reward,
            busy: _busy.contains(reward.id),
            onUnlock: () => _run(reward.id, widget.onUnlock),
            onApprove: () => _run(reward.id, widget.onApprove),
          ),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.reward,
    required this.busy,
    required this.onUnlock,
    required this.onApprove,
  });

  final ParentReward reward;
  final bool busy;
  final VoidCallback onUnlock;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, label) = switch (reward.status) {
      ParentRewardStatus.locked => (
        TaliaIcons.lock,
        l10n.parentDashboardRewardLocked,
      ),
      ParentRewardStatus.unlocked => (
        TaliaIcons.gift,
        l10n.parentRewardStatusWaitingForChild,
      ),
      ParentRewardStatus.requested => (
        TaliaIcons.bell,
        l10n.parentRewardStatusRequested,
      ),
      ParentRewardStatus.claimed => (
        TaliaIcons.starFilled,
        l10n.parentDashboardRewardClaimed,
      ),
    };
    final action = switch (reward.status) {
      ParentRewardStatus.locked => (l10n.parentRewardUnlockAction, onUnlock),
      ParentRewardStatus.requested => (
        l10n.parentRewardApproveAction,
        onApprove,
      ),
      _ => null,
    };
    return Padding(
      key: ValueKey('child-reward-${reward.id}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: AppTypography.bodyMedium),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (action case (final text, final onPressed))
            busy
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    key: ValueKey('child-reward-action-${reward.id}'),
                    onPressed: onPressed,
                    child: Text(text),
                  ),
        ],
      ),
    );
  }
}
