import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';
import '../constants/app_spacing.dart';

import '../utils/locale_number_formatter.dart';

class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.activityCountsByDay,
    required this.startDate,
  });

  final Map<String, int> activityCountsByDay;
  final DateTime startDate;

  Color _getColor(int count, ColorScheme cs) {
    if (count == 0) {
      return cs.surfaceContainerHighest;
    }
    if (count < 5) {
      return cs.primary.withValues(alpha: 0.25);
    }
    if (count < 15) {
      return cs.primary.withValues(alpha: 0.50);
    }
    if (count < 30) {
      return cs.primary.withValues(alpha: 0.75);
    }
    return cs.primary;
  }

  /// The section is titled "year activity", so never render more than a
  /// year of cells (history can reach two years).
  static const int _maxDays = 365;
  static const int _minDays = 30;

  static String _dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    // Show at least 30 days so it doesn't look broken on day 1.
    final difference = today.difference(start).inDays + 1; // include today
    final totalDays = difference.clamp(_minDays, _maxDays);

    // Calendar arithmetic (not Duration) so DST shifts never skip a day.
    final days = List.generate(
      totalDays,
      (i) => DateTime(today.year, today.month, today.day - (totalDays - 1 - i)),
    );
    final activeDays = days
        .where((day) => (activityCountsByDay[_dayKey(day)] ?? 0) > 0)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.yearActivity,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            Text(
              context.l10n.progressActiveDays(
                activeDays,
                LocaleNumberFormatter.format(
                  (activeDays).toString(),
                  context.l10n.localeName,
                ),
              ),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RepaintBoundary(
          child: Wrap(
            spacing: 3,
            runSpacing: 3,
            children: days.map((day) {
              final count = activityCountsByDay[_dayKey(day)] ?? 0;
              return Tooltip(
                message:
                    '${localizations.formatMediumDate(day)}\n'
                    '${context.l10n.activityTooltip(LocaleNumberFormatter.format((count).toString(), context.l10n.localeName))}',
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getColor(count, cs),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              context.l10n.less,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            ...List.generate(
              5,
              (i) => Container(
                width: 10,
                height: 10,
                margin: const EdgeInsetsDirectional.only(end: 3),
                decoration: BoxDecoration(
                  color: _getColor([0, 3, 10, 20, 35][i], cs),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
              ),
            ),
            Text(
              context.l10n.more,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}
