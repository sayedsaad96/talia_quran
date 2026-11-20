import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../domain/entities/good_impact.dart';
import '../../domain/entities/invite_activity_target.dart';
import '../../domain/entities/invite_types.dart';
import '../../domain/services/invite_target_labeler.dart';
import '../cubits/good_impact_cubit.dart';

class GoodImpactPage extends StatefulWidget {
  const GoodImpactPage({super.key, required this.cubit, required this.labeler});
  final GoodImpactCubit cubit;
  final InviteTargetLabeler labeler;
  @override
  State<GoodImpactPage> createState() => _GoodImpactPageState();
}

class _GoodImpactPageState extends State<GoodImpactPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.cubit.refresh(force: true);
    if (!mounted) return;
    await widget.cubit.markSeen();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.goodImpactTitle)),
      body: BlocBuilder<GoodImpactCubit, GoodImpactState>(
        bloc: widget.cubit,
        builder: (context, state) {
          if (state is GoodImpactLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GoodImpactUnavailable || state is GoodImpactIdle) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.goodImpactError),
                  TextButton(onPressed: _load, child: Text(l10n.retryLabel)),
                ],
              ),
            );
          }
          final ready = state as GoodImpactReady;
          if (!widget.cubit.isCurrent(ready)) {
            return Center(child: Text(l10n.goodImpactError));
          }
          final impact = ready.impact;
          final now = DateTime.now();
          final active = impact.invites
              .where(
                (i) =>
                    i.status == InviteLifecycleStatus.active &&
                    i.expiresAt.isAfter(now),
              )
              .toList();
          final expired = impact.invites
              .where(
                (i) =>
                    i.status != InviteLifecycleStatus.revoked &&
                    (i.status == InviteLifecycleStatus.expired ||
                        !i.expiresAt.isAfter(now)) &&
                    !i.expiresAt.isBefore(
                      now.subtract(const Duration(days: 30)),
                    ),
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(l10n.goodImpactResponses(impact.responses)),
              Text(l10n.goodImpactCompletions(impact.completions)),
              Text(l10n.goodImpactReach(impact.downstreamReach)),
              const SizedBox(height: 20),
              for (final milestone in ready.milestones)
                ListTile(
                  leading: const Icon(TaliaIcons.sparkle),
                  title: Text(_milestone(context, milestone)),
                ),
              if (impact.acknowledgements.isNotEmpty) ...[
                Text(
                  l10n.goodImpactAcknowledgements,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final acknowledgement in impact.acknowledgements)
                  ListTile(
                    title: Text(acknowledgement.visibleName),
                    subtitle: _TargetLabel(
                      target: acknowledgement.target,
                      labeler: widget.labeler,
                    ),
                  ),
              ],
              Text(
                l10n.goodImpactActive,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (active.isEmpty) Text(l10n.goodImpactEmpty),
              for (final invite in active)
                _InviteSummary(invite: invite, labeler: widget.labeler),
              const SizedBox(height: 16),
              Text(
                l10n.goodImpactRecentlyExpired,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (expired.isEmpty) Text(l10n.goodImpactEmpty),
              for (final invite in expired)
                _InviteSummary(invite: invite, labeler: widget.labeler),
            ],
          );
        },
      ),
    );
  }

  String _milestone(BuildContext context, GoodImpactMilestone milestone) =>
      switch (milestone) {
        GoodImpactMilestone.firstChainStarted =>
          context.l10n.goodImpactMilestoneFirstChain,
        GoodImpactMilestone.fiveReach =>
          context.l10n.goodImpactMilestoneFiveReach,
        GoodImpactMilestone.tenResponses =>
          context.l10n.goodImpactMilestoneTenResponses,
        GoodImpactMilestone.twentyFiveReach =>
          context.l10n.goodImpactMilestoneTwentyFiveReach,
      };
}

class _InviteSummary extends StatelessWidget {
  const _InviteSummary({required this.invite, required this.labeler});
  final InviteImpactSummary invite;
  final InviteTargetLabeler labeler;
  @override
  Widget build(BuildContext context) => ListTile(
    title: _TargetLabel(target: invite.target, labeler: labeler),
    subtitle: Text(context.l10n.goodImpactCompletions(invite.completions)),
  );
}

class _TargetLabel extends StatelessWidget {
  const _TargetLabel({required this.target, required this.labeler});
  final InviteActivityTarget target;
  final InviteTargetLabeler labeler;
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: labeler.label(target, arabic: context.isArabic),
    builder: (context, snapshot) =>
        Text(snapshot.data?.fold((_) => '', (label) => label.title) ?? ''),
  );
}
