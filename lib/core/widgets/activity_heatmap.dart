import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';

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
      return cs.surfaceContainerHighest.withValues(alpha: 0.3);
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final today = DateTime.now();

    // Ensure we show at least 30 days so it doesn't look broken on day 1
    final difference = today.difference(startDate).inDays;
    final totalDays = difference < 30
        ? 30
        : difference + 1; // +1 to include today

    final days = List.generate(
      totalDays,
      (i) => today.subtract(Duration(days: totalDays - 1 - i)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.yearActivity,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: days.map((day) {
            final key =
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final count = activityCountsByDay[key] ?? 0;
            return Tooltip(
              message: '$key\n${context.l10n.activityTooltip(count)}',
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getColor(count, cs),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }).toList(),
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
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: _getColor([0, 3, 10, 20, 35][i], cs),
                  borderRadius: BorderRadius.circular(2),
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
