import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/family_dashboard_cubit.dart';

class ChildDetailPage extends StatelessWidget {
  const ChildDetailPage({super.key, required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.childDetailTitle(child.displayName),
          style: AppTypography.titleLarge,
        ),
        leading: IconButton(
          icon: const BackButtonIcon(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/family-dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard_rounded),
            tooltip: context.l10n.childDetailAddReward,
            onPressed: () => _showAddRewardDialog(context),
          ),
        ],
      ),
      body: _ChildDetailBody(child: child),
    );
  }

  Future<void> _showAddRewardDialog(BuildContext context) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.parentDashboardRemoteRewardTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.l10n.parentDashboardRewardHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null && title.isNotEmpty && context.mounted) {
      await context.read<FamilyDashboardCubit>().addReward(
        title,
        childId: child.isLocal ? null : child.childUserId,
      );
    }
  }
}

class _ChildDetailBody extends StatelessWidget {
  const _ChildDetailBody({required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
    final logs = child.isLocal
        ? (child.localData?.logs ?? [])
        : (child.remoteSummary?.logs ?? []);
    final rewards = child.isLocal
        ? (child.localData?.rewards ?? [])
        : (child.remoteSummary?.rewards ?? []);
    final production = child.remoteSummary?.production;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        120,
      ),
      children: [
        // â”€â”€â”€ Header avatar + name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _ChildHeaderCard(child: child),
        const SizedBox(height: AppSpacing.md),

        // â”€â”€â”€ Today summary â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _TodayCard(child: child),
        const SizedBox(height: AppSpacing.md),

        // â”€â”€â”€ Metrics row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _MetricsRow(child: child),
        const SizedBox(height: AppSpacing.md),

        // â”€â”€â”€ Memorization progress (remote only, if production available) â”€â”€
        if (production != null) ...[
          _MemorizationProgressCard(production: production),
          const SizedBox(height: AppSpacing.md),
        ],

        // â”€â”€â”€ Recent sessions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _RecentSessionsCard(logs: logs),
        const SizedBox(height: AppSpacing.md),

        // â”€â”€â”€ Rewards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (rewards.isNotEmpty) ...[
          _RewardsCard(rewards: rewards),
          const SizedBox(height: AppSpacing.md),
        ],

        // â”€â”€â”€ Open full dashboard (local child only) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (child.isLocal) ...[
          OutlinedButton.icon(
            onPressed: () {
              // Now we are ALREADY in the full dashboard hierarchy.
              // If they want to change the local child nickname, we can show a dialog.
              _showChangeNicknameDialog(context);
            },
            icon: const Icon(Icons.edit_rounded),
            label: Text(
              context.l10n.familyDashboardLocalBadge,
            ), // Change nickname
          ),
        ],
      ],
    );
  }

  Future<void> _showChangeNicknameDialog(BuildContext context) async {
    final controller = TextEditingController(text: child.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.parentDashboardEditChild),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.l10n.familyDashboardAddChild,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && context.mounted) {
      await context.read<FamilyDashboardCubit>().updateLocalChildNickname(
        newName,
      );
    }
  }
}

// â”€â”€â”€ Header card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ChildHeaderCard extends StatelessWidget {
  const _ChildHeaderCard({required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1A6B38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              child.avatarEmoji ?? (child.isLocal ? 'ðŸ‘¨â€ðŸ‘§' : 'ðŸ§’'),
              style: AppTypography.displayMedium.copyWith(fontSize: 32),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.displayName,
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (child.isLocal)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.l10n.familyDashboardLocalBadge,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Today card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return _Panel(
      title: context.l10n.parentDashboardTodaySummary,
      child: child.isActiveToday
          ? Text(
              context.l10n.childDetailTodayActivity(
                child.todaySessions,
                child.todayPoints,
              ),
              style: AppTypography.bodyMedium,
            )
          : Text(
              context.l10n.childDetailNoActivity,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
    );
  }
}

// â”€â”€â”€ Metrics row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricChip(icon: 'â­', label: 'Lv.${child.currentLevel}'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricChip(icon: 'ðŸŒŸ', label: '${child.starsEarned}'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricChip(icon: 'ðŸ”¥', label: '${child.currentStreak}'),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: AppTypography.headlineMedium),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Memorization progress card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MemorizationProgressCard extends StatelessWidget {
  const _MemorizationProgressCard({required this.production});
  final RemoteChildProductionSummary production;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: context.l10n.childDetailMemorizationProgress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${production.totalMemorizedAyahs}/${production.totalAyahsTracked} ${context.l10n.ayahs}',
                style: AppTypography.bodyMedium,
              ),
              Text(
                '${production.completionPercent.round()}%',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (production.completionPercent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          if (production.reviewsOverdue > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.parentDashboardReviewsSummary(
                production.reviewsCompleted,
                production.reviewsOverdue,
              ),
              style: AppTypography.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

// â”€â”€â”€ Recent sessions card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RecentSessionsCard extends StatelessWidget {
  const _RecentSessionsCard({required this.logs});
  final List<KidsSessionLog> logs;

  @override
  Widget build(BuildContext context) {
    final recent = logs.take(5).toList();
    return _Panel(
      title: context.l10n.childDetailRecentSessions,
      child: recent.isEmpty
          ? Text(
              context.l10n.parentDashboardNoSessionsYet,
              style: AppTypography.bodyMedium,
            )
          : Column(
              children: recent.map((log) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          context.l10n.parentDashboardSessionSummary(
                            log.surahId,
                            log.ayahNumber,
                            log.repeatsCompleted,
                            log.pointsEarned,
                          ),
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// â”€â”€â”€ Rewards card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({required this.rewards});
  final List<ParentReward> rewards;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: context.l10n.childDetailRewards(rewards.length),
      child: Column(
        children: rewards.take(3).map((reward) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  reward.status == ParentRewardStatus.claimed
                      ? Icons.star_rounded
                      : Icons.card_giftcard_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(reward.title, style: AppTypography.bodySmall),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// â”€â”€â”€ Shared panel widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
