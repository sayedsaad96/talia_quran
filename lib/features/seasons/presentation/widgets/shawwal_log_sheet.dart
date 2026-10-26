import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import '../../data/shawwal_six_store.dart';

/// Civil dates of Shawwal from its 2nd day through today ([hijriDay] is
/// today's Hijri day in Shawwal), paired with their Hijri day number. The 1st
/// of Shawwal is Eid, a day a voluntary fast is not offered, so it is left out.
List<({int hijriDay, DateTime date})> shawwalLoggableDays(
  DateTime today,
  int hijriDay,
) {
  return [
    for (var n = 2; n <= hijriDay; n++)
      (
        hijriDay: n,
        date: DateTime(today.year, today.month, today.day - (hijriDay - n)),
      ),
  ];
}

/// Opens the sheet that logs fasted days of Shawwal, including past ones.
Future<void> showShawwalLogSheet(
  BuildContext context, {
  required ShawwalSixStore store,
  required int hijriYear,
  required DateTime today,
  required int hijriDay,
  required Future<void> Function() onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => ShawwalLogSheet(
      store: store,
      hijriYear: hijriYear,
      today: today,
      hijriDay: hijriDay,
      onChanged: onChanged,
    ),
  );
}

/// One row per civil day of Shawwal (from the 2nd to today); tapping marks or
/// unmarks that day. No more than [ShawwalSixStore.target] marks.
class ShawwalLogSheet extends StatefulWidget {
  const ShawwalLogSheet({
    super.key,
    required this.store,
    required this.hijriYear,
    required this.today,
    required this.hijriDay,
    required this.onChanged,
  });

  final ShawwalSixStore store;
  final int hijriYear;
  final DateTime today;
  final int hijriDay;

  /// Runs after each change (badge award, card refresh).
  final Future<void> Function() onChanged;

  @override
  State<ShawwalLogSheet> createState() => _ShawwalLogSheetState();
}

class _ShawwalLogSheetState extends State<ShawwalLogSheet> {
  bool _busy = false;

  Future<void> _toggle(DateTime date) async {
    if (_busy) return;
    final marked = widget.store.isMarked(widget.hijriYear, date);
    if (!marked &&
        widget.store.count(widget.hijriYear) >= ShawwalSixStore.target) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.store.toggle(widget.hijriYear, date);
      await widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final days = shawwalLoggableDays(widget.today, widget.hijriDay);
    final full = widget.store.count(widget.hijriYear) >= ShawwalSixStore.target;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                0,
                AppSpacing.pagePadding,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.seasonShawwalLogTitle,
                style: AppTypography.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final day in days)
                    Builder(
                      builder: (_) {
                        final marked = widget.store.isMarked(
                          widget.hijriYear,
                          day.date,
                        );
                        return CheckboxListTile(
                          key: ValueKey('shawwal_log_row_${day.hijriDay}'),
                          value: marked,
                          onChanged: _busy || (full && !marked)
                              ? null
                              : (_) => unawaited(_toggle(day.date)),
                          title: Text(
                            l10n.seasonShawwalLogDayRow(
                              LocaleNumberFormatter.number(day.hijriDay, lang),
                            ),
                          ),
                          subtitle: Text(
                            LocaleNumberFormatter.format(
                              '${day.date.day}/${day.date.month}',
                              lang,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
