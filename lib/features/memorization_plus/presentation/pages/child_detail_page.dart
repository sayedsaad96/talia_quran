import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kids_child_policy.dart';
import '../../domain/entities/kids_home_mission.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/family_dashboard_cubit.dart';
import '../widgets/child_activity_summary.dart';
import '../widgets/family_child_name.dart';
import '../widgets/child_pin_recovery_panel.dart';
import '../widgets/child_rewards_panel.dart';
import '../widgets/guardian_session_scope.dart';
import '../widgets/home_missions_panel.dart';
import '../widgets/kids_policy_controls.dart';
import '../widgets/parent_support_tip.dart';
import '../widgets/remove_child_from_family_button.dart';
import 'family_dashboard_page.dart';

import '../../../../core/utils/locale_number_formatter.dart';

/// Route payload for [ChildDetailPage]. The page is pushed as its own root
/// route, outside the dashboard's widget subtree, so the dashboard's cubit
/// travels with the route instead of being looked up from ancestors.

part 'child_detail_sections.dart';
part 'child_detail_dialogs.dart';

class ChildDetailRouteArgs {
  const ChildDetailRouteArgs({required this.child, required this.cubit});

  final FamilyChildEntry child;
  final FamilyDashboardCubit cubit;
}

/// Expects a [FamilyDashboardCubit] above it (the route provides the
/// dashboard's own instance). Rebuilds from the cubit so edits such as a new
/// nickname appear immediately instead of showing the entry captured at push.
class ChildDetailPage extends StatelessWidget {
  const ChildDetailPage({super.key, required this.child});
  final FamilyChildEntry child;

  /// Builds the child-detail route from its `extra`. The page acts through
  /// the dashboard's unlocked cubit; without it (deep link, restored route)
  /// the parent goes back through the dashboard and its PIN gate.
  static Widget forRoute(Object? extra) {
    if (extra is! ChildDetailRouteArgs || extra.cubit.isClosed) {
      return const FamilyDashboardPage();
    }
    return GuardianSessionScope(
      child: BlocProvider<FamilyDashboardCubit>.value(
        value: extra.cubit,
        child: ChildDetailPage(child: extra.child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyDashboardCubit, FamilyDashboardState>(
      builder: (context, state) => _buildFor(context, _currentEntry(state)),
    );
  }

  FamilyChildEntry _currentEntry(FamilyDashboardState state) {
    if (state is! FamilyDashboardLoaded) return child;
    for (final entry in state.dashboard.children) {
      if (entry.childUserId == child.childUserId &&
          entry.isLocal == child.isLocal) {
        return entry;
      }
    }
    return child;
  }

  Widget _buildFor(BuildContext context, FamilyChildEntry child) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.childDetailTitle(child.shownName(context.l10n)),
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
            icon: const Icon(TaliaIcons.gift),
            tooltip: context.l10n.childDetailAddReward,
            onPressed: () => _showAddRewardDialog(context, child),
          ),
        ],
      ),
      body: _ChildDetailBody(child: child),
    );
  }

  Future<void> _showAddRewardDialog(
    BuildContext context,
    FamilyChildEntry child,
  ) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _TextInputDialog(
        title: context.l10n.parentDashboardRemoteRewardTitle,
        hintText: context.l10n.parentDashboardRewardHint,
        actionLabel: context.l10n.save,
      ),
    );
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
    final homeMissions = child.isLocal
        ? (child.localData?.homeMissions ?? const <KidsHomeMission>[])
        : (child.remoteSummary?.homeMissions ?? const <KidsHomeMission>[]);
    final production = child.remoteSummary?.production;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        120,
      ),
      children: [
        // ─── Header avatar + name ──────────────────────────────────────────
        _ChildHeaderCard(child: child),
        const SizedBox(height: AppSpacing.md),
        if (!child.isLocal)
          ChildPinRecoveryPanel(childUserId: child.childUserId),

        // ─── Today summary ─────────────────────────────────────────────────
        _TodayCard(child: child),
        const SizedBox(height: AppSpacing.md),

        // ─── Metrics row ───────────────────────────────────────────────────
        _MetricsRow(child: child),
        const SizedBox(height: AppSpacing.md),

        if (child.localData case final localData?) ...[
          _LearningSupportCard(dashboard: localData),
          const SizedBox(height: AppSpacing.md),
        ],

        // ─── Memorization progress (remote only, if production available) ──
        if (production != null) ...[
          _MemorizationProgressCard(production: production),
          const SizedBox(height: AppSpacing.md),
        ],

        if (child.remoteSummary case final summary? when !child.isLocal) ...[
          _Panel(
            title: context.l10n.childDetailActivityTitle,
            child: ChildActivitySummary(activity: summary.activity),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ─── Recent sessions ───────────────────────────────────────────────
        _RecentSessionsCard(logs: logs),
        const SizedBox(height: AppSpacing.md),

        // ─── Rewards ───────────────────────────────────────────────────────
        if (rewards.isNotEmpty) ...[
          _Panel(
            title: context.l10n.childDetailRewards(
              context.numText(rewards.length),
            ),
            child: ChildRewardsPanel(
              rewards: rewards,
              onUnlock: (id) =>
                  context.read<FamilyDashboardCubit>().unlockReward(
                    id,
                    childId: child.isLocal ? null : child.childUserId,
                  ),
              onApprove: (id) =>
                  context.read<FamilyDashboardCubit>().approveReward(
                    id,
                    childId: child.isLocal ? null : child.childUserId,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ─── Home missions ─────────────────────────────────────────────────
        if (child.remoteSummary?.detailsLoading ?? false)
          _Panel(
            title: context.l10n.childDetailHomeMissions,
            child: const _DetailsLoading(
              key: ValueKey('child-missions-loading'),
            ),
          )
        else if (child.remoteSummary?.homeMissionsUnavailable ?? false)
          _Panel(
            title: context.l10n.childDetailHomeMissions,
            child: Text(
              context.l10n.kidsHomeMissionsUnavailable,
              key: const ValueKey('child-home-missions-unavailable'),
              style: AppTypography.bodyMedium,
            ),
          )
        else
          HomeMissionsPanel(
            missions: homeMissions,
            onAdd: (title) =>
                context.read<FamilyDashboardCubit>().addHomeMission(
                  title,
                  childId: child.isLocal ? null : child.childUserId,
                ),
            onAcknowledge: (id) =>
                context.read<FamilyDashboardCubit>().acknowledgeHomeMission(
                  id,
                  childId: child.isLocal ? null : child.childUserId,
                ),
          ),
        const SizedBox(height: AppSpacing.md),

        // ─── Child policy (linked child; CAS with the version read) ────────
        if (child.remoteSummary case final summary? when !child.isLocal) ...[
          _Panel(
            title: context.l10n.settings,
            child: summary.detailsLoading
                ? const _DetailsLoading(key: ValueKey('child-policy-loading'))
                : summary.policyUnavailable
                ? Text(
                    context.l10n.kidsPolicyUnavailable,
                    style: AppTypography.bodyMedium,
                  )
                : KidsPolicyEditor(
                    policy: summary.policy ?? const KidsChildPolicy(),
                    onSave: (policy) => context
                        .read<FamilyDashboardCubit>()
                        .saveChildPolicy(policy, childId: child.childUserId),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ─── Edit name (local child) / name and age (linked child) ─────────
        if (child.isLocal)
          OutlinedButton.icon(
            onPressed: () => _showChangeNicknameDialog(context),
            icon: const Icon(TaliaIcons.edit),
            label: Text(context.l10n.parentDashboardEditChild),
          )
        else ...[
          OutlinedButton.icon(
            onPressed: () => _showEditIdentityDialog(context),
            icon: const Icon(TaliaIcons.edit),
            label: Text(context.l10n.childEditIdentity),
          ),
          const SizedBox(height: AppSpacing.lg),
          RemoveChildFromFamilyButton(
            childUserId: child.childUserId,
            childName: child.shownName(context.l10n),
          ),
        ],
      ],
    );
  }

  Future<void> _showEditIdentityDialog(BuildContext context) async {
    final identity = await showDialog<_ChildIdentityDraft>(
      context: context,
      builder: (_) => _ChildIdentityDialog(
        initialName: child.displayName,
        initialAge: child.childAge,
      ),
    );
    if (identity != null && context.mounted) {
      await context.read<FamilyDashboardCubit>().updateRemoteChildIdentity(
        childUserId: child.childUserId,
        nickname: identity.nickname,
        age: identity.age,
      );
    }
  }

  Future<void> _showChangeNicknameDialog(BuildContext context) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _TextInputDialog(
        title: context.l10n.parentDashboardEditChild,
        hintText: context.l10n.name,
        actionLabel: context.l10n.save,
        initialText: child.displayName,
      ),
    );
    if (newName != null && context.mounted) {
      await context.read<FamilyDashboardCubit>().updateLocalChildNickname(
        newName,
      );
    }
  }
}
