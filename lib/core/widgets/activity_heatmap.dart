import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';

class ActivityHeatmap extends StatefulWidget {
  const ActivityHeatmap({super.key, required this.isar});
  final Isar isar;

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  Map<String, int> _activityMap = {};
  DateTime? _startDate;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // ── Source 1: Hifz review activity (one count per ayah reviewed)
    final allProgress = await widget.isar.isarAyahProgress.where().findAll();

    final map = <String, int>{};
    DateTime? earliestDate;

    for (final p in allProgress) {
      final d = p.lastReviewDate;
      if (earliestDate == null || d.isBefore(earliestDate)) {
        earliestDate = d;
      }
      final key =
          '${d.year}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + 1;
    }

    // ── Source 2: DailyActivityIsar (reading + any other tracked activity)
    final dailyRecords = await widget.isar.dailyActivityIsars.where().findAll();

    for (final r in dailyRecords) {
      final y = r.dayKey ~/ 10000;
      final m = (r.dayKey % 10000) ~/ 100;
      final d = r.dayKey % 100;
      final recordDate = DateTime(y, m, d);

      if (earliestDate == null || recordDate.isBefore(earliestDate)) {
        earliestDate = recordDate;
      }

      final key = _dayKeyToString(r.dayKey);
      // Merge: take the max between hifz count and the explicit daily count
      // so we don't double-count when both exist for the same day.
      final existing = map[key] ?? 0;
      if (r.activityCount > existing) {
        map[key] = r.activityCount;
      }
    }

    // Default to 1 year ago if no activity yet, just to show something
    earliestDate ??= DateTime.now().subtract(const Duration(days: 365));
    // Or if the earliest date is very recent, still show at least a full year?
    // The user requested from the start of usage, but if usage is 1 day old,
    // a 1-day heatmap looks weird. Let's at least show the current year or 3 months.
    // We'll show from earliest date up to today.

    if (mounted) {
      setState(() {
        _activityMap = map;
        _startDate = earliestDate;
        _loaded = true;
      });
    }
  }

  String _dayKeyToString(int dayKey) {
    final y = dayKey ~/ 10000;
    final m = (dayKey % 10000) ~/ 100;
    final d = dayKey % 100;
    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

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

    if (!_loaded) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final today = DateTime.now();
    final start = _startDate ?? today.subtract(const Duration(days: 365));

    // Ensure we show at least 30 days so it doesn't look broken on day 1
    final difference = today.difference(start).inDays;
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
          'نشاط السنة',
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
            final count = _activityMap[key] ?? 0;
            return Tooltip(
              message: '$key\n$count ${count == 1 ? 'نشاط' : 'أنشطة'}',
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
              'أقل',
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
              'أكثر',
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
