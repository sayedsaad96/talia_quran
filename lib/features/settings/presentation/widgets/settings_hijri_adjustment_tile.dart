import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/hijri_date_adjustment.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/domain/services/home_occasion_service.dart';

/// Lets the user shift the computed Hijri date by up to two days so Home's
/// date and seasonal occasions follow their country's month announcement.
class HijriAdjustmentTile extends StatefulWidget {
  const HijriAdjustmentTile({super.key});

  @override
  State<HijriAdjustmentTile> createState() => _HijriAdjustmentTileState();
}

class _HijriAdjustmentTileState extends State<HijriAdjustmentTile> {
  late final HijriDateAdjustment _adjustment = getIt<HijriDateAdjustment>();
  late int _days = _adjustment.days;

  Future<void> _select(int days) async {
    setState(() => _days = days);
    await _adjustment.setDays(days);
  }

  String _label(int days) {
    if (days == 0) return context.numText(0);
    return '${days > 0 ? '+' : '−'}${context.numText(days.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final today = getIt<HomeOccasionService>()
        .current(isArabic: context.isArabic)
        .hijriLabel;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.hijriAdjustmentSubtitle,
            style: AppTypography.bodySmall.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              key: const ValueKey('hijri-adjustment'),
              showSelectedIcon: false,
              segments: [
                for (
                  var days = HijriDateAdjustment.minDays;
                  days <= HijriDateAdjustment.maxDays;
                  days++
                )
                  ButtonSegment(value: days, label: Text(_label(days))),
              ],
              selected: {_days},
              onSelectionChanged: (selection) => _select(selection.single),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.hijriAdjustmentToday(today),
            key: const ValueKey('hijri-adjustment-preview'),
            style: AppTypography.bodyMedium.copyWith(
              color: context.tokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
