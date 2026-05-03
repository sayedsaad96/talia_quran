import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../features/hifz/data/models/isar_ayah_progress.dart';

class ActivityHeatmap extends StatefulWidget {
  const ActivityHeatmap({super.key, required this.isar});
  final Isar isar;

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  Map<String, int> _activityMap = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Get all progress from the last 365 days
    final since = DateTime.now().subtract(const Duration(days: 365));
    final allProgress = await widget.isar.isarAyahProgress
        .filter()
        .lastReviewDateGreaterThan(since)
        .findAll();

    final map = <String, int>{};
    for (final p in allProgress) {
      final d = p.lastReviewDate;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + 1;
    }

    if (mounted) setState(() { _activityMap = map; _loaded = true; });
  }

  Color _getColor(int count, ColorScheme cs) {
    if (count == 0) return cs.surfaceContainerHighest.withValues(alpha: 0.3);
    if (count < 5)  return cs.primary.withValues(alpha: 0.25);
    if (count < 15) return cs.primary.withValues(alpha: 0.5);
    if (count < 30) return cs.primary.withValues(alpha: 0.75);
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!_loaded) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
    }

    final today = DateTime.now();
    final days = List.generate(365, (i) => today.subtract(Duration(days: 364 - i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نشاط السنة',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: days.map((day) {
            final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final count = _activityMap[key] ?? 0;
            return Tooltip(
              message: '$key\n$count آية',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('أقل', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(width: 4),
            ...List.generate(5, (i) => Container(
              width: 10, height: 10,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: _getColor([0, 3, 10, 20, 35][i], cs),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            Text('أكثر', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}
