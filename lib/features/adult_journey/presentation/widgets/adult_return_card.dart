import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../../home/presentation/widgets/glass_panel.dart';
import '../../domain/services/adult_return_policy.dart';
import '../cubits/adult_journey_cubit.dart';
import '../cubits/adult_journey_state.dart';
import 'adult_journey_error_text.dart';

/// The gentle-return invitation (spec §4.3). It only records a choice: no
/// button navigates or opens a session, and the wording never claims the user
/// left the Quran.
class AdultReturnCard extends StatefulWidget {
  const AdultReturnCard({super.key, required this.state, required this.skin});

  final AdultJourneyState state;
  final HomeSkin skin;

  @override
  State<AdultReturnCard> createState() => _AdultReturnCardState();
}

class _AdultReturnCardState extends State<AdultReturnCard> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _run(Future<bool> Function(AdultJourneyCubit) action) async {
    if (_busy) return;
    _busy = true;
    try {
      final ok = await action(context.read<AdultJourneyCubit>());
      if (mounted) setState(() => _failed = !ok);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.state.returnOffer;
    if (offer == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final skin = widget.skin;
    return GlassPanel(
      key: const ValueKey('adult_return_card'),
      skin: skin,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            offer.reason == AdultReturnReason.absence
                ? l10n.adultJourneyReturnTitleAbsence
                : l10n.adultJourneyReturnTitleSelf,
            style: AppTypography.titleMedium.copyWith(
              color: skin.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.adultJourneyReturnBody,
            style: AppTypography.bodyMedium.copyWith(
              color: skin.textSecondary,
              height: 1.5,
            ),
          ),
          if (_failed)
            if (widget.state.errorFor(AdultJourneyErrorSource.returnAction)
                case final code?)
              AdultJourneyErrorText(
                code,
                key: const ValueKey('adult_return_error'),
              ),
          const SizedBox(height: AppSpacing.md),
          _actions(),
        ],
      ),
    );
  }

  Widget _actions() {
    final l10n = context.l10n;
    final enabled = !widget.state.isSaving;
    final timeActions = widget.state.returnTimeActionsEnabled;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        TextButton(
          key: const ValueKey('adult_return_continue'),
          onPressed: enabled ? () => _run((c) => c.continueAsUsual()) : null,
          child: Text(l10n.adultJourneyReturnContinue),
        ),
        if (timeActions) ...[
          OutlinedButton(
            key: const ValueKey('adult_return_choose_time'),
            onPressed: enabled ? () => _run((c) => c.chooseReturnTime()) : null,
            child: Text(l10n.adultJourneyReturnChooseTime),
          ),
          FilledButton(
            key: const ValueKey('adult_return_light'),
            onPressed: enabled ? () => _run((c) => c.startLightReturn()) : null,
            child: Text(l10n.adultJourneyReturnLight),
          ),
        ],
      ],
    );
  }
}
