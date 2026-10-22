import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/kids_remote_plan.dart';

/// Controlled guardian inputs; the parent editor owns persistence and errors.
class KidsRemotePlanControls extends StatelessWidget {
  const KidsRemotePlanControls({
    super.key,
    required this.plan,
    required this.onChanged,
    this.enabled = true,
  });

  final KidsRemotePlan plan;
  final ValueChanged<KidsRemotePlan> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final clean = plan.sanitized();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _surahChoice(context, clean),
        const SizedBox(height: AppSpacing.sm),
        _sizeChoice(context, clean),
        const SizedBox(height: AppSpacing.sm),
        _days(context, clean),
      ],
    );
  }

  Widget _surahChoice(BuildContext context, KidsRemotePlan clean) => _choice(
    context,
    keyName: 'remote-plan-surah',
    label: context.l10n.kidsRemotePlanNextSurah,
    value: clean.nextSurahId ?? 0,
    values: List.generate(114, (index) => index + 1),
    text: (id) => context.isArabic ? SurahNames.nameAr(id) : SurahNames.nameEn(id),
    changed: (id) => _change(
      clean,
      nextSurahId: id == 0 ? null : id,
      clearSurah: id == 0,
    ),
  );

  Widget _sizeChoice(BuildContext context, KidsRemotePlan clean) => _choice(
    context,
    keyName: 'remote-plan-size',
    label: context.l10n.kidsRemotePlanSize,
    value: clean.ayahsPerSession ?? 0,
    values: List.generate(10, (index) => index + 1),
    text: context.numText,
    changed: (size) => _change(
      clean,
      ayahsPerSession: size == 0 ? null : size,
      clearSize: size == 0,
    ),
  );

  Widget _days(BuildContext context, KidsRemotePlan clean) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.kidsRemotePlanDays),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.kidsRemotePlanDeviceDefault),
          value: clean.practiceDays == null,
          onChanged: enabled
              ? (useDefault) => _change(
                  clean,
                  practiceDays: useDefault == true ? null : 127,
                  clearDays: useDefault == true,
                )
              : null,
        ),
        _dayChoices(l10n, clean),
        Text(l10n.kidsRemotePlanDaysHint, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _dayChoices(AppLocalizations l10n, KidsRemotePlan clean) => Wrap(
    spacing: AppSpacing.xs,
    children: [
      for (var day = 1; day <= 7; day++) _dayChoice(l10n, clean, day),
    ],
  );

  Widget _dayChoice(AppLocalizations l10n, KidsRemotePlan clean, int day) {
    final bit = 1 << (day - 1);
    final mask = clean.practiceDays ?? 127;
    return FilterChip(
      key: Key('remote-plan-day-$day'),
      label: Text(_day(l10n, day)),
      selected: (mask & bit) != 0,
      onSelected: enabled
          ? (selected) => _change(
              clean,
              practiceDays: selected ? mask | bit : mask & ~bit,
            )
          : null,
    );
  }

  void _change(
    KidsRemotePlan current, {
    int? nextSurahId,
    int? ayahsPerSession,
    int? practiceDays,
    bool clearSurah = false,
    bool clearSize = false,
    bool clearDays = false,
  }) => onChanged(
    KidsRemotePlan(
      nextSurahId: clearSurah ? null : nextSurahId ?? current.nextSurahId,
      ayahsPerSession: clearSize
          ? null
          : ayahsPerSession ?? current.ayahsPerSession,
      practiceDays: clearDays ? null : practiceDays ?? current.practiceDays,
    ),
  );

  Widget _choice(
    BuildContext context, {
    required String keyName,
    required String label,
    required int value,
    required List<int> values,
    required String Function(int) text,
    required ValueChanged<int> changed,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label),
      DropdownButton<int>(
        key: Key(keyName),
        isExpanded: true,
        value: value,
        items: [
          DropdownMenuItem(
            value: 0,
            child: Text(context.l10n.kidsRemotePlanDeviceDefault),
          ),
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(text(item))),
        ],
        onChanged: enabled
            ? (next) {
                if (next != null) changed(next);
              }
            : null,
      ),
    ],
  );

  String _day(AppLocalizations l10n, int day) => switch (day) {
    1 => l10n.weekdayMonday,
    2 => l10n.weekdayTuesday,
    3 => l10n.weekdayWednesday,
    4 => l10n.weekdayThursday,
    5 => l10n.weekdayFriday,
    6 => l10n.weekdaySaturday,
    _ => l10n.weekdaySunday,
  };
}
