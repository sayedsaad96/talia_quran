import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../cubits/kids_mode_cubit.dart';
import 'kids_surah_split_sheet.dart';

class KidsLegacyResumeRecoveryPanel extends StatelessWidget {
  const KidsLegacyResumeRecoveryPanel({
    super.key,
    required this.state,
    required this.onRecover,
  });
  final KidsModeSplitChoiceRequired state;
  final Future<void> Function({required bool whole, int? stageSize}) onRecover;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.kidsLegacyResumeTitle,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.kidsLegacyResumeExplanation,
          textAlign: TextAlign.center,
        ),
        if (state.failed) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(context.l10n.kidsLegacyResumeSaveFailed),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          key: const ValueKey('kids-legacy-recovery-choose'),
          onPressed: state.saving ? null : () => _choose(context),
          child: state.saving
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.kidsLegacyResumeChoose),
        ),
      ],
    ),
  );

  Future<void> _choose(BuildContext context) async {
    final choice = await showKidsSurahSplitSheet(
      context,
      ayahCount: state.ticket.verifiedAyahCount,
      defaultStageSize: state.ticket.defaultStageSize,
    );
    if (choice != null && context.mounted) {
      await onRecover(whole: choice.whole, stageSize: choice.stageSize);
    }
  }
}
