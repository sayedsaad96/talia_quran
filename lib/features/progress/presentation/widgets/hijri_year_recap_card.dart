import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/progress/hijri_year_recap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';

class HijriYearRecapCard extends StatelessWidget {
  const HijriYearRecapCard({super.key, required this.recap, this.onDismiss});
  final HijriYearRecap recap;
  final Future<void> Function()? onDismiss;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: 10),
          _stats(context),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(TaliaIcons.share),
              label: Text(context.l10n.hijriYearRecapShare),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _header(BuildContext context) => Row(
    children: [
      const Icon(TaliaIcons.history, color: AppColors.gold),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          '${context.l10n.hijriYearRecapTitle} ${context.numText(recap.hijriYear)}',
          style: AppTypography.titleMedium,
        ),
      ),
      IconButton(
        tooltip: context.l10n.hijriYearRecapDismiss,
        onPressed: onDismiss == null ? null : () => onDismiss!(),
        icon: const Icon(TaliaIcons.close),
      ),
    ],
  );

  Widget _stats(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${context.l10n.hijriYearRecapCompletions}: ${context.numText(recap.completedKhatmahs)}',
      ),
      const SizedBox(height: 4),
      Text(
        '${context.l10n.hijriYearRecapMemorizedApprox}: ${context.numText(recap.approximateMemorizedAyahs)}',
      ),
      Text(context.l10n.hijriYearRecapApproxDefinition),
      const SizedBox(height: 4),
      Text(
        '${context.l10n.hijriYearRecapLifetimeStreak}: ${context.numText(recap.lifetimeLongestStreak)}',
      ),
      const SizedBox(height: 4),
      Text(
        '${context.l10n.hijriYearRecapActivityDays}: ${context.numText(recap.activityByDay.length)}',
      ),
    ],
  );

  void _share(BuildContext context) => SocialShareSheet.show(
    context,
    SocialShareData(
      content: context.l10n.hijriYearRecapApproxDefinition,
      subtitle:
          '${context.l10n.hijriYearRecapCompletions}: ${context.numText(recap.completedKhatmahs)}; ${context.l10n.hijriYearRecapActivityDays}: ${context.numText(recap.activityByDay.length)}',
      title:
          '${context.l10n.hijriYearRecapTitle} ${context.numText(recap.hijriYear)}',
      category: SocialShareCategory.progress,
      readPagesCount: null,
      memorizedAyahsCount: recap.approximateMemorizedAyahs,
      streakDays: recap.lifetimeLongestStreak,
      memorizedAyahsLabel: context.l10n.hijriYearRecapMemorizedApprox,
      streakDaysLabel: context.l10n.hijriYearRecapLifetimeStreak,
    ),
  );
}
