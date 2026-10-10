import 'package:flutter/material.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/custom_memorization_plan.dart';
import 'plan_details_section.dart';

class PlanDetailsSettings extends StatelessWidget {
  const PlanDetailsSettings({super.key, required this.plan});
  final CustomMemorizationPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PlanDetailsSection(
      title: l10n.planDetailsSettings,
      children: [
        ..._scope(context),
        const Divider(),
        ..._schedule(context),
        ..._reviews(context),
      ],
    );
  }

  List<Widget> _scope(BuildContext context) {
    final l10n = context.l10n;
    return [
      Text(l10n.planDetailsActive),
      PlanDetailsRow(
        label: l10n.customPlanTargetUserTitle,
        value: l10n.customPlanAdult,
      ),
      PlanDetailsRow(
        label: l10n.customPlanFromSurah,
        value: _name(context, plan.startSurahId),
      ),
      PlanDetailsRow(
        label: l10n.customPlanToSurah,
        value: _name(context, plan.endSurahId),
      ),
      PlanDetailsRow(
        label: l10n.customPlanFromAyah,
        value: context.numText(plan.startAyah),
      ),
      Text(
        plan.startSurahId <= plan.endSurahId
            ? l10n.customPlanDirectionForward(
                _name(context, plan.startSurahId),
                _name(context, plan.endSurahId),
              )
            : l10n.customPlanDirectionBackward(
                _name(context, plan.startSurahId),
                _name(context, plan.endSurahId),
              ),
      ),
    ];
  }

  List<Widget> _schedule(BuildContext context) {
    final l10n = context.l10n;
    return [
      PlanDetailsRow(
        label: l10n.customPlanNewAyahsPerDay,
        value: context.numText(plan.newAyahsPerDay),
      ),
      PlanDetailsRow(
        label: l10n.customPlanDaysPerWeek,
        value: context.numText(plan.availableDaysPerWeek),
      ),
      PlanDetailsRow(
        label: l10n.customPlanSessionDuration,
        value:
            '${context.numText(plan.sessionMinutes)} ${l10n.customPlanMinuteUnit}',
      ),
      PlanDetailsRow(
        label: l10n.customPlanDifficulty,
        value: _difficulty(context),
      ),
    ];
  }

  List<Widget> _reviews(BuildContext context) {
    final l10n = context.l10n;
    return [
      PlanDetailsRow(
        label: l10n.customPlanNearRevision,
        value: _revision(
          context,
          plan.enableNearRevision,
          plan.nearRevisionCount,
        ),
      ),
      PlanDetailsRow(
        label: l10n.customPlanFarRevision,
        value: _revision(
          context,
          plan.enableFarRevision,
          plan.farRevisionCount,
        ),
      ),
      PlanDetailsRow(
        label: l10n.planDetailsCreated,
        value: context.digitText(
          MaterialLocalizations.of(
            context,
          ).formatMediumDate(plan.createdAt.toLocal()),
        ),
      ),
    ];
  }

  String _name(BuildContext context, int id) =>
      context.isArabic ? SurahNames.nameAr(id) : SurahNames.nameEn(id);

  String _revision(BuildContext context, bool enabled, int count) => enabled
      ? '${context.l10n.planDetailsEnabled} (${context.numText(count)})'
      : context.l10n.planDetailsDisabled;

  String _difficulty(BuildContext context) => switch (plan.difficulty) {
    MemorizationDifficulty.easy => context.l10n.customPlanDifficultyEasy,
    MemorizationDifficulty.moderate =>
      context.l10n.customPlanDifficultyModerate,
    MemorizationDifficulty.challenging =>
      context.l10n.customPlanDifficultyChallenging,
  };
}
