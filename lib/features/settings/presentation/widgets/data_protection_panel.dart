import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/data_protection_status.dart';
import '../cubits/data_protection_cubit.dart';

class DataProtectionPanel extends StatelessWidget {
  const DataProtectionPanel({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DataProtectionCubit, DataProtectionViewState>(
        builder: (context, state) {
          final status = state.status;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.protectionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (state.loading) const LinearProgressIndicator(),
                  if (state.failed) Text(context.l10n.protectionUnknown),
                  if (status != null)
                    for (final domain in ProtectionDomain.values)
                      _domain(context, domain, status.forDomain(domain)),
                  Text(context.l10n.protectionImportScope),
                ],
              ),
            ),
          );
        },
      );
  Widget _domain(
    BuildContext context,
    ProtectionDomain domain,
    ProtectionDomainStatus status,
  ) {
    final name = switch (domain) {
      ProtectionDomain.progress => context.l10n.protectionProgress,
      ProtectionDomain.review => context.l10n.protectionReview,
      ProtectionDomain.bookmarks => context.l10n.protectionBookmarks,
      ProtectionDomain.checkpoint => context.l10n.protectionCheckpoint,
    };
    final label = switch (status.state) {
      ProtectionState.localOnly => context.l10n.protectionOnDevice,
      ProtectionState.unknown => context.l10n.protectionUnknown,
      ProtectionState.pending => context.l10n.protectionPending,
      ProtectionState.synced => context.l10n.protectionSynced,
      ProtectionState.failed => context.l10n.protectionFailed,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$name: $label'),
          if (status.pendingCount != null)
            Text(
              '${context.l10n.protectionPendingCount}: ${status.pendingCount}',
            ),
          if (status.lastSuccess != null)
            Text(
              '${context.l10n.protectionLastSuccess}: ${MaterialLocalizations.of(context).formatShortDate(status.lastSuccess!.toLocal())}',
            ),
        ],
      ),
    );
  }
}
