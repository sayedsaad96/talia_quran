import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/adult_journey_preferences.dart';
import '../cubits/adult_journey_cubit.dart';
import '../cubits/adult_journey_state.dart';
import 'adult_journey_error_text.dart';

/// Opens the shared personalization sheet (Home and Settings). Nothing is
/// written until the user saves; cancelling or dismissing saves nothing.
Future<void> showAdultJourneySetupSheet(
  BuildContext context,
  AdultJourneyCubit cubit,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const AdultJourneySetupSheet()),
  );
}

class AdultJourneySetupSheet extends StatefulWidget {
  const AdultJourneySetupSheet({super.key});

  @override
  State<AdultJourneySetupSheet> createState() => _AdultJourneySetupSheetState();
}

class _AdultJourneySetupSheetState extends State<AdultJourneySetupSheet> {
  late AdultJourneyGoal? _goal;
  late AdultJourneyExperience? _experience;
  bool _failedWithoutCode = false;

  // A profile error from an earlier, dismissed sheet is not shown again.
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    // Only this feature's own earlier choice: never `user_primary_goal`.
    final prefs = context.read<AdultJourneyCubit>().state.preferences;
    _goal = prefs.profileCompleted ? prefs.goal : null;
    _experience = prefs.profileCompleted ? prefs.experience : null;
  }

  Future<void> _save() async {
    final cubit = context.read<AdultJourneyCubit>();
    final goal = _goal;
    if (goal == null || cubit.state.isSaving) return;
    setState(() => _attempted = true);
    final ok = await cubit.saveProfile(goal, _experience);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _failedWithoutCode = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: BlocBuilder<AdultJourneyCubit, AdultJourneyState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.adultJourneySetupTitle,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.adultJourneySetupGoalLabel,
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              _goalChips(l10n),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.adultJourneyExperienceLabel,
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.adultJourneyExperienceHint,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              _experienceChips(l10n),
              ..._errorAndActions(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalChips(AppLocalizations l10n) {
    final labels = {
      AdultJourneyGoal.reading: l10n.adultJourneyGoalReading,
      AdultJourneyGoal.memorization: l10n.adultJourneyGoalMemorization,
      AdultJourneyGoal.review: l10n.adultJourneyGoalReview,
      AdultJourneyGoal.azkar: l10n.adultJourneyGoalAzkar,
    };
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final goal in AdultJourneyGoal.values)
          ChoiceChip(
            key: ValueKey('adult_goal_${goal.name}'),
            label: Text(labels[goal]!),
            selected: _goal == goal,
            onSelected: (_) => setState(() => _goal = goal),
          ),
      ],
    );
  }

  Widget _experienceChips(AppLocalizations l10n) {
    final labels = {
      AdultJourneyExperience.beginner: l10n.adultJourneyExperienceBeginner,
      AdultJourneyExperience.continuing: l10n.adultJourneyExperienceContinuing,
      AdultJourneyExperience.returning: l10n.adultJourneyExperienceReturning,
    };
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final value in AdultJourneyExperience.values)
          ChoiceChip(
            key: ValueKey('adult_experience_${value.name}'),
            label: Text(labels[value]!),
            selected: _experience == value,
            // Optional: tapping the chosen value clears it.
            onSelected: (_) => setState(
              () => _experience = _experience == value ? null : value,
            ),
          ),
      ],
    );
  }

  List<Widget> _errorAndActions(BuildContext context, AdultJourneyState state) {
    final l10n = context.l10n;
    // Only a profile save's failure belongs in this sheet.
    final code = !_attempted
        ? null
        : state.errorFor(AdultJourneyErrorSource.profile) ??
              (_failedWithoutCode ? AdultJourneyErrorCode.unavailable : null);
    final failed = code != null;
    return [
      if (code != null)
        AdultJourneyErrorText(code, key: const ValueKey('adult_setup_error')),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          TextButton(
            key: const ValueKey('adult_setup_cancel'),
            onPressed: state.isSaving
                ? null
                : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('adult_setup_save'),
            onPressed: _goal == null || state.isSaving ? null : _save,
            child: Text(failed ? l10n.retryLabel : l10n.save),
          ),
        ],
      ),
    ];
  }
}
