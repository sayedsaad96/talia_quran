import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/fallback_pop_scope.dart';
import '../../../../core/widgets/talia_app_bar.dart';
import '../../domain/entities/khatmah_history_entry.dart';
import '../../domain/entities/khatmah_history_stats.dart';
import '../cubits/khatmah_history_cubit.dart';
import '../khatmah_localizations.dart';

class KhatmahHistoryPage extends StatefulWidget {
  const KhatmahHistoryPage({super.key, this.cubit});

  final KhatmahHistoryCubit? cubit;

  @override
  State<KhatmahHistoryPage> createState() => _KhatmahHistoryPageState();
}

class _KhatmahHistoryPageState extends State<KhatmahHistoryPage> {
  late final KhatmahHistoryCubit _cubit;
  late final bool _ownsCubit;

  @override
  void initState() {
    super.initState();
    _ownsCubit = widget.cubit == null;
    _cubit = widget.cubit ?? getIt<KhatmahHistoryCubit>();
    _cubit.load();
  }

  @override
  void dispose() {
    if (_ownsCubit) _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    // The completion screen opens history with `context.go`.
    child: FallbackPopScope(
      fallbackLocation: AppRoutes.khatmahDashboard,
      child: Scaffold(
        appBar: AppBar(
          leading: FallbackPopScope.hasHistory(context)
              ? null
              : const TaliaBackButton(
                  key: Key('khatmah_history_back_button'),
                  fallbackLocation: AppRoutes.khatmahDashboard,
                ),
          title: Text(context.l10n.khatmahRecentCompletions),
        ),
        body: BlocBuilder<KhatmahHistoryCubit, KhatmahHistoryState>(
          builder: (context, state) => switch (state) {
            KhatmahHistoryInitial() || KhatmahHistoryLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            KhatmahHistoryEmpty() => _HistoryMessage(
              key: const Key('khatmah_history_empty'),
              icon: Icons.history_rounded,
              message: context.l10n.khatmahHistoryEmpty,
            ),
            KhatmahHistoryFailure() => _HistoryMessage(
              key: const Key('khatmah_history_failure'),
              icon: Icons.error_outline_rounded,
              message: context.l10n.khatmahHistoryLoadError,
              action: FilledButton.icon(
                key: const Key('khatmah_history_retry'),
                onPressed: _cubit.load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.khatmahRetry),
              ),
            ),
            KhatmahHistoryCorrupt(:final validEntries) =>
              validEntries.isEmpty
                  ? _HistoryMessage(
                      key: const Key('khatmah_history_corrupt'),
                      icon: Icons.warning_amber_rounded,
                      message: context.l10n.khatmahHistoryCorrupt,
                      action: _HistoryRetryButton(onPressed: _cubit.load),
                    )
                  : _HistoryList(
                      entries: validEntries,
                      corruptWarning: context.l10n.khatmahHistoryCorrupt,
                      onRetry: _cubit.load,
                    ),
            KhatmahHistoryLoaded(:final entries) => _HistoryList(
              entries: entries,
            ),
          },
        ),
      ),
    ),
  );
}

class _HistoryRetryButton extends StatelessWidget {
  const _HistoryRetryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: const Key('khatmah_history_retry'),
    onPressed: onPressed,
    icon: const Icon(Icons.refresh_rounded),
    label: Text(context.l10n.khatmahRetry),
  );
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.entries,
    this.corruptWarning,
    this.onRetry,
  });

  final List<KhatmahHistoryEntry> entries;
  final String? corruptWarning;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final hasWarning = corruptWarning != null;
    final stats = KhatmahHistoryStats.from(entries);
    final lead = (stats != null ? 1 : 0) + (hasWarning ? 1 : 0);
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: entries.length + lead,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (stats != null) {
          if (index == 0) return _HistoryStatsCard(stats: stats);
          index--;
        }
        if (hasWarning && index == 0) {
          return Card(
            key: const Key('khatmah_history_corrupt'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    corruptWarning!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _HistoryRetryButton(onPressed: onRetry!),
                ],
              ),
            ),
          );
        }
        return _HistoryCard(entry: entries[index - (hasWarning ? 1 : 0)]);
      },
    );
  }
}

class _HistoryStatsCard extends StatelessWidget {
  const _HistoryStatsCard({required this.stats});

  final KhatmahHistoryStats stats;

  @override
  Widget build(BuildContext context) {
    String number(int value) => context.numText(value);
    return Card(
      key: const Key('khatmah_history_stats'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.insights_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.khatmahHistoryStats(
                  number(stats.count),
                  number(stats.averageDays),
                  number(stats.fastestDays),
                ),
                style: AppTypography.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final KhatmahHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final award = entry.certificate!;
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(entry.completedDate.toLocal());
    final dedication = entry.dedication;
    final recipient = dedication?.recipientName?.trim();
    final condition = localizedKhatmahCondition(context, dedication?.condition);
    final dedicationText = recipient == null || recipient.isEmpty
        ? null
        : context.l10n.khatmahDedicatedTo(
            condition.isEmpty ? recipient : '$recipient ($condition)',
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizedKhatmahPlanTitle(context, entry.title),
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(context.l10n.khatmahCompletedOn(date)),
            if (dedicationText != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(dedicationText),
            ],
            const SizedBox(height: AppSpacing.md),
            Semantics(
              button: true,
              label: context.l10n.khatmahReopenCertificate,
              child: FilledButton.icon(
                key: Key('khatmah_history_reopen_${entry.id}'),
                onPressed: () => context.push(
                  AppRoutes.certificate,
                  extra: <String, dynamic>{'award': award},
                ),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text(context.l10n.khatmahReopenCertificate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
