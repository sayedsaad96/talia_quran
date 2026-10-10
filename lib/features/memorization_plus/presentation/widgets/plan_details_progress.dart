import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/plan_details.dart';
import 'plan_details_section.dart';

class PlanDetailsProgress extends StatelessWidget {
  const PlanDetailsProgress({super.key, required this.details});
  final PlanDetails details;

  @override
  Widget build(BuildContext context) {
    final metrics = details.metrics;
    final l10n = context.l10n;
    return PlanDetailsSection(
      title: l10n.planDetailsProgress,
      children: [
        LinearProgressIndicator(value: metrics.memorizationCompletionPercent),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${context.numText((metrics.memorizationCompletionPercent * 100).round())}%',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        ..._counts(context),
        const Divider(),
        ..._mastery(context),
      ],
    );
  }

  List<Widget> _counts(BuildContext context) {
    final l10n = context.l10n;
    final metrics = details.metrics;
    return [
      PlanDetailsRow(
        label: l10n.planDetailsTotal,
        value: context.numText(details.totalAyahs),
      ),
      PlanDetailsRow(
        label: l10n.memorizedAyahs,
        value: context.numText(metrics.memorizedAyahs),
        valueKey: const Key('plan_details_memorized'),
      ),
      PlanDetailsRow(
        label: l10n.planDetailsLearning,
        value: context.numText(metrics.learningAyahs),
      ),
      PlanDetailsRow(
        label: l10n.planDetailsUnstarted,
        value: context.numText(details.unstartedAyahs),
      ),
      PlanDetailsRow(
        label: l10n.planDetailsRemaining,
        value: context.numText(details.remainingAyahs),
        valueKey: const Key('plan_details_remaining'),
      ),
    ];
  }

  List<Widget> _mastery(BuildContext context) {
    final l10n = context.l10n;
    final metrics = details.metrics;
    return [
      PlanDetailsRow(
        label: l10n.planDetailsMastery,
        value: metrics.startedAyahs == 0
            ? l10n.planDetailsNoAssessment
            : '${context.numText((metrics.retentionRate * 100).round())}%',
      ),
      Text(
        l10n.planDetailsMasteryHint,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        l10n.planDetailsInScope,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }
}

class PlanDetailsSurahs extends StatelessWidget {
  const PlanDetailsSurahs({super.key, required this.details});
  final PlanDetails details;

  @override
  Widget build(BuildContext context) => PlanDetailsSection(
    title: context.l10n.planDetailsBySurah,
    children: [
      Text(context.l10n.planDetailsScopeHint),
      const SizedBox(height: AppSpacing.sm),
      for (final surah in details.surahProgress) _surah(context, surah),
    ],
  );

  Widget _surah(BuildContext context, PlanSurahProgress surah) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.isArabic
              ? SurahNames.nameAr(surah.surahId)
              : SurahNames.nameEn(surah.surahId),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        PlanDetailsRow(
          label: context.l10n.memorizedAyahs,
          value:
              '${context.numText(surah.memorizedAyahs)}/${context.numText(surah.totalAyahs)}',
        ),
        LinearProgressIndicator(value: surah.progress),
        PlanDetailsRow(
          label: context.l10n.planDetailsLearning,
          value: context.numText(surah.learningAyahs),
        ),
      ],
    ),
  );
}
