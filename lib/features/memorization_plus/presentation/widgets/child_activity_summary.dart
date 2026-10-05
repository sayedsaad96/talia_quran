import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/remote_child_activity.dart';

/// Body of the guardian's "child activity" panel for a linked child. A null
/// [activity] means the child device has not published one yet, which is
/// stated explicitly instead of being rendered as zeros.
class ChildActivitySummary extends StatelessWidget {
  const ChildActivitySummary({super.key, required this.activity, this.now});

  final RemoteChildActivity? activity;

  /// Clock override for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final activity = this.activity;
    if (activity == null) {
      return Text(
        context.l10n.childDetailActivityNotReceived,
        style: AppTypography.bodyMedium.copyWith(
          color: context.tokens.textSecondary,
        ),
      );
    }
    final isToday = activity.isForDay(now ?? DateTime.now());
    final todayPages = isToday ? activity.todayReadPagesCount : 0;
    final updatedAt = activity.updatedAt.toLocal();
    final material = MaterialLocalizations.of(context);
    final updatedLabel =
        '${material.formatMediumDate(updatedAt)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(updatedAt))}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.childDetailActivityStreak(
            context.numText(activity.currentStreak),
            context.numText(activity.longestStreak),
          ),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.childDetailActivityActiveDays(
            context.numText(activity.activeDaysLast30),
          ),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.childDetailActivityPages(
            context.numText(activity.readPagesCount),
            context.numText(todayPages),
          ),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.childDetailActivityUpdatedAt(updatedLabel),
          style: AppTypography.bodySmall.copyWith(
            color: context.tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}
