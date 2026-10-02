import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kids_child_policy.dart';
import '../../domain/entities/kids_home_mission.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/family_dashboard_cubit.dart';
import '../widgets/home_missions_panel.dart';
import '../widgets/kids_policy_controls.dart';
import '../widgets/parent_support_tip.dart';
import 'family_dashboard_page.dart';

/// Route payload for [ChildDetailPage]. The page is pushed as its own root
/// route, outside the dashboard's widget subtree, so the dashboard's cubit
/// travels with the route instead of being looked up from ancestors.
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
    return BlocProvider<FamilyDashboardCubit>.value(
      value: extra.cubit,
      child: ChildDetailPage(child: extra.child),
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

        // ─── Recent sessions ───────────────────────────────────────────────
        _RecentSessionsCard(logs: logs),
        const SizedBox(height: AppSpacing.md),

        // ─── Rewards ───────────────────────────────────────────────────────
        if (rewards.isNotEmpty) ...[
          _RewardsCard(rewards: rewards),
          const SizedBox(height: AppSpacing.md),
        ],

        // ─── Home missions ─────────────────────────────────────────────────
        HomeMissionsPanel(
          missions: homeMissions,
          onAdd: (title) => context.read<FamilyDashboardCubit>().addHomeMission(
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
            child: summary.policyUnavailable
                ? Text(
                    context.l10n.kidsPolicyUnavailable,
                    style: AppTypography.bodyMedium,
                  )
                : KidsPolicyEditor(
                    policy: summary.policy ?? const KidsChildPolicy(),
                    onSave: (policy) =>
                        context.read<FamilyDashboardCubit>().saveChildPolicy(
                          policy,
                          childId: child.childUserId,
                        ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ─── Edit name (local child) / name and age (linked child) ─────────
        if (child.isLocal)
          OutlinedButton.icon(
            onPressed: () => _showChangeNicknameDialog(context),
            icon: const Icon(Icons.edit_rounded),
            label: Text(context.l10n.parentDashboardEditChild),
          )
        else
          OutlinedButton.icon(
            onPressed: () => _showEditIdentityDialog(context),
            icon: const Icon(Icons.edit_rounded),
            label: Text(context.l10n.childEditIdentity),
          ),
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

// ─── Header card ──────────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
              child.avatarEmoji ?? (child.isLocal ? '👨‍👧' : '🧒'),
              style: AppTypography.displayMedium,
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
                if (child.childAge case final age?)
                  Text(
                    context.l10n.childAgeYears(age),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
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
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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

// ─── Today card ───────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
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
                color: context.tokens.textSecondary,
              ),
            ),
    );
  }
}

// ─── Metrics row ──────────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricChip(icon: '⭐', label: 'Lv.${child.currentLevel}'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricChip(icon: '🌟', label: '${child.starsEarned}'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricChip(icon: '🔥', label: '${child.currentStreak}'),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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

class _LearningSupportCard extends StatelessWidget {
  const _LearningSupportCard({required this.dashboard});

  final ParentDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final averageMinutes = (dashboard.averageSessionDurationSeconds / 60)
        .ceil();
    return _Panel(
      title: context.l10n.childDetailMemorizationProgress,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _SupportMetric(
            icon: Icons.calendar_today_rounded,
            label: context.l10n.parentCommitmentDays(dashboard.commitmentDays),
          ),
          _SupportMetric(
            icon: Icons.replay_rounded,
            label: context.l10n.parentDueReviews(dashboard.dueReviewCount),
          ),
          _SupportMetric(
            icon: Icons.volunteer_activism_rounded,
            label: context.l10n.parentNeedsSupport(
              dashboard.ayahsNeedingSupport,
            ),
          ),
          _SupportMetric(
            icon: Icons.timer_outlined,
            label: context.l10n.parentAverageDuration(averageMinutes),
          ),
          _SupportMetric(
            icon: Icons.lightbulb_outline_rounded,
            label: context.l10n.parentHintUses(dashboard.totalHintUses),
          ),
          // K35: a number needs a next step the parent can take.
          if (dashboard.ayahsNeedingSupport > 0) const ParentSupportTip(),
        ],
      ),
    );
  }
}

class _SupportMetric extends StatelessWidget {
  const _SupportMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide.none,
    );
  }
}

// ─── Memorization progress card ───────────────────────────────────────────────

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
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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

// ─── Recent sessions card ─────────────────────────────────────────────────────

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

// ─── Rewards card ─────────────────────────────────────────────────────────────

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

// ─── Shared panel widget ──────────────────────────────────────────────────────

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
        color: context.tokens.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.hintText,
    required this.actionLabel,
    this.initialText = '',
  });

  static const int maxLength = 50;

  final String title;
  final String hintText;
  final String actionLabel;
  final String initialText;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return context.l10n.fieldRequired;
    if (trimmed.length > _TextInputDialog.maxLength) {
      return context.l10n.fieldTooLong(_TextInputDialog.maxLength);
    }
    return null;
  }

  void _submit() {
    final error = _validate(_controller.text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: _TextInputDialog.maxLength,
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: _errorText,
            counterText: '',
          ),
          onChanged: (_) {
            if (_errorText != null) setState(() => _errorText = null);
          },
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
    );
  }
}

typedef _ChildIdentityDraft = ({String nickname, int age});

/// Name + age editor for a linked child, validated with the same
/// [ChildIdentityPolicy] the server enforces.
class _ChildIdentityDialog extends StatefulWidget {
  const _ChildIdentityDialog({required this.initialName, this.initialAge});

  final String initialName;
  final int? initialAge;

  @override
  State<_ChildIdentityDialog> createState() => _ChildIdentityDialogState();
}

class _ChildIdentityDialogState extends State<_ChildIdentityDialog> {
  late final TextEditingController _nameController;
  int? _age;
  String? _nameError;
  String? _ageError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _age = ChildIdentityPolicy.isValidAge(widget.initialAge)
        ? widget.initialAge
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final name = ChildIdentityPolicy.normalizeNickname(_nameController.text);
    final age = _age;
    final ageValid = ChildIdentityPolicy.isValidAge(age);
    setState(() {
      _nameError = name == null
          ? l10n.childErrorNicknameInvalid(
              ChildIdentityPolicy.maxNicknameLength,
            )
          : null;
      _ageError = ageValid
          ? null
          : l10n.childErrorAgeInvalid(
              ChildIdentityPolicy.minAge,
              ChildIdentityPolicy.maxAge,
            );
    });
    if (name == null || age == null || !ageValid) return;
    Navigator.pop<_ChildIdentityDraft>(context, (nickname: name, age: age));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.childEditIdentity),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: ChildIdentityPolicy.maxNicknameLength,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.name,
                errorText: _nameError,
                counterText: '',
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<int>(
              initialValue: _age,
              decoration: InputDecoration(
                labelText: context.l10n.age,
                errorText: _ageError,
              ),
              items: [
                for (
                  var age = ChildIdentityPolicy.minAge;
                  age <= ChildIdentityPolicy.maxAge;
                  age++
                )
                  DropdownMenuItem(
                    value: age,
                    child: Text(context.l10n.childAgeYears(age)),
                  ),
              ],
              onChanged: (value) => setState(() {
                _age = value;
                _ageError = null;
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(context.l10n.save)),
      ],
    );
  }
}
