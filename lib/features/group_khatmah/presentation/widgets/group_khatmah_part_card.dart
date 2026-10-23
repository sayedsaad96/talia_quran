import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/group_khatmah.dart';
import '../cubits/group_khatmah_cubit.dart';

class GroupKhatmahPartCard extends StatelessWidget {
  const GroupKhatmahPartCard({
    super.key,
    required this.part,
    required this.group,
    required this.ownerId,
    required this.busy,
    required this.cubit,
  });

  final GroupPart part;
  final GroupKhatmah group;
  final String ownerId;
  final bool busy;
  final GroupKhatmahCubit cubit;

  Future<void> _discard(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.groupKhatmahDiscardCompletion),
        content: Text(l10n.groupKhatmahDiscardConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.groupKhatmahCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.groupKhatmahConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.discardFailedCompletion(group.id, part.juz);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ownClaim =
        part.status == GroupPartStatus.claimed &&
        part.claimedBy == ownerId &&
        part.claimEpoch == group.membershipEpoch;
    final memberName = _claimantName();
    final active = group.status == GroupKhatmahStatus.active;
    return Card(
      key: Key('group-part-${part.juz}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.groupKhatmahJuz(part.juz),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              _statusText(l10n),
              key: part.isCompletionFailed
                  ? Key('group-part-failed-${part.juz}')
                  : part.isCompletionPending
                  ? Key('group-part-pending-${part.juz}')
                  : null,
            ),
            if (memberName != null) Text(memberName),
            ..._actions(context, l10n, active, ownClaim),
          ],
        ),
      ),
    );
  }

  String _statusText(AppLocalizations l10n) {
    if (part.isCompletionFailed) return l10n.groupKhatmahCompletionFailed;
    if (part.isCompletionPending) return l10n.groupKhatmahPending;
    return switch (part.status) {
      GroupPartStatus.open => l10n.groupKhatmahOpen,
      GroupPartStatus.claimed => l10n.groupKhatmahClaimed,
      GroupPartStatus.completed => l10n.groupKhatmahCompleted,
    };
  }

  List<Widget> _actions(
    BuildContext context,
    AppLocalizations l10n,
    bool active,
    bool ownClaim,
  ) {
    if (!active) return const [];
    if (part.status == GroupPartStatus.open) {
      return [
        TextButton(
          key: Key('group-part-claim-${part.juz}'),
          onPressed: busy ? null : () => cubit.claim(group.id, part.juz),
          child: Text(l10n.groupKhatmahClaim),
        ),
      ];
    }
    if (!ownClaim) return const [];
    return _ownActions(context, l10n);
  }

  List<Widget> _ownActions(BuildContext context, AppLocalizations l10n) {
    if (part.isCompletionFailed) {
      return [
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              key: Key('group-part-retry-${part.juz}'),
              onPressed: busy
                  ? null
                  : () => cubit.retryFailedCompletion(group.id, part.juz),
              child: Text(l10n.groupKhatmahRetryCompletion),
            ),
            TextButton(
              key: Key('group-part-discard-${part.juz}'),
              onPressed: busy ? null : () => _discard(context),
              child: Text(l10n.groupKhatmahDiscardCompletion),
            ),
          ],
        ),
      ];
    }
    if (part.isCompletionPending) return const [];
    return [
      Wrap(
        spacing: 8,
        children: [
          TextButton(
            key: Key('group-part-complete-${part.juz}'),
            onPressed: busy ? null : () => cubit.complete(group.id, part.juz),
            child: Text(l10n.groupKhatmahComplete),
          ),
          TextButton(
            key: Key('group-part-release-${part.juz}'),
            onPressed: busy ? null : () => cubit.release(group.id, part.juz),
            child: Text(l10n.groupKhatmahRelease),
          ),
        ],
      ),
    ];
  }

  String? _claimantName() {
    if (part.claimedBy == null) return null;
    for (final member in group.members) {
      if (member.userId == part.claimedBy && member.leftAt == null) {
        return member.displayName;
      }
    }
    return null;
  }
}
