import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubits/group_khatmah_cubit.dart';

/// Recovery remains available even before roster revalidation succeeds.
class GroupKhatmahRecoveryPanel extends StatelessWidget {
  const GroupKhatmahRecoveryPanel({
    super.key,
    required this.cubit,
    required this.state,
  });
  final GroupKhatmahCubit cubit;
  final GroupKhatmahState state;

  String _requestLabel(AppLocalizations l10n, String action) =>
      switch (action) {
        'create' => l10n.groupKhatmahCreate,
        'join' => l10n.groupKhatmahJoin,
        'claim_group_part' => l10n.groupKhatmahClaim,
        'release_group_part' => l10n.groupKhatmahRelease,
        'leave_group_khatmah' => l10n.groupKhatmahLeave,
        _ => l10n.groupKhatmahComplete,
      };

  Future<void> _discard(BuildContext context, String id) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.groupKhatmahDiscardCompletion),
        content: Text(l10n.groupKhatmahDiscardRequestConfirm),
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
    if (confirmed == true) await cubit.recoverOperation(id, discard: true);
  }

  @override
  Widget build(BuildContext context) {
    if (state.failedOperations.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.groupKhatmahFailedRequests),
            for (final failed in state.failedOperations)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_requestLabel(l10n, failed.action)),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        key: Key('group-retry-${failed.operationId}'),
                        onPressed: state.busy
                            ? null
                            : () => cubit.recoverOperation(
                                failed.operationId,
                                discard: false,
                              ),
                        child: Text(l10n.groupKhatmahRetryRequest),
                      ),
                      TextButton(
                        key: Key('group-discard-${failed.operationId}'),
                        onPressed: state.busy
                            ? null
                            : () => _discard(context, failed.operationId),
                        child: Text(l10n.groupKhatmahDiscardCompletion),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
