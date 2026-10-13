import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kids_family_practice_step.dart';
import '../cubits/kids_family_practice_cubit.dart';

/// Opens «نتعلم سوا» for the ayah the child is on. The sheet is guidance
/// only: it never starts audio or the microphone, and closing it at any
/// step leaves the session exactly as it was.
///
/// With [recorder] and [verifyGuardian], a finished practice can be
/// confirmed by the guardian (PIN on this device) into a receipt.
Future<void> showKidsFamilyPracticeSheet(
  BuildContext context, {
  required int surahId,
  required int ayahNumber,
  KidsFamilyPracticeRecorder? recorder,
  Future<bool> Function(BuildContext context)? verifyGuardian,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => BlocProvider(
    create: (_) => KidsFamilyPracticeCubit(
      surahId: surahId,
      ayahNumber: ayahNumber,
      recorder: recorder,
    )..begin(),
    child: KidsFamilyPracticePanel(
      surahId: surahId,
      ayahNumber: ayahNumber,
      verifyGuardian: verifyGuardian,
    ),
  ),
);

class KidsFamilyPracticePanel extends StatelessWidget {
  const KidsFamilyPracticePanel({
    super.key,
    required this.surahId,
    required this.ayahNumber,
    this.verifyGuardian,
  });

  final int surahId;
  final int ayahNumber;

  /// Proves the guardian before a receipt is recorded; null hides confirming.
  final Future<bool> Function(BuildContext context)? verifyGuardian;

  static String _stepText(
    AppLocalizations l10n,
    KidsFamilyPracticeStep step,
  ) => switch (step) {
    KidsFamilyPracticeStep.listenTogether => l10n.kidsFamilyPracticeStepListen,
    KidsFamilyPracticeStep.grownUpRecites => l10n.kidsFamilyPracticeStepGrownUp,
    KidsFamilyPracticeStep.childTries => l10n.kidsFamilyPracticeStepChildTries,
    KidsFamilyPracticeStep.praiseEffort => l10n.kidsFamilyPracticeStepPraise,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surah = l10n.localeName == 'ar'
        ? SurahNames.nameAr(surahId)
        : SurahNames.nameEn(surahId);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: BlocBuilder<KidsFamilyPracticeCubit, KidsFamilyPracticeState>(
          builder: (context, state) {
            final step = state.step;
            return Column(
              key: const ValueKey('kids-family-practice'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.kidsFamilyPracticeAction,
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.kidsFamilyPracticeContext(
                    surah,
                    context.numText(ayahNumber),
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (step != null) ...[
                  Text(
                    l10n.kidsFamilyPracticeStepCounter(
                      context.numText(state.stepIndex + 1),
                      context.numText(KidsFamilyPracticeStep.ordered.length),
                    ),
                    style: AppTypography.labelSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _stepText(l10n, step),
                    key: ValueKey('kids-family-practice-step-${step.name}'),
                    style: AppTypography.bodyLarge,
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        TaliaIcons.idea,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.kidsFamilyPracticeFinished,
                          key: const ValueKey('kids-family-practice-finished'),
                          style: AppTypography.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                if (step == null &&
                    verifyGuardian != null &&
                    context.read<KidsFamilyPracticeCubit>().canConfirm) ...[
                  const SizedBox(height: AppSpacing.md),
                  _GuardianConfirm(
                    confirmation: state.confirmation,
                    verifyGuardian: verifyGuardian!,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.kidsFamilyPracticeNote,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    TextButton(
                      key: const ValueKey('kids-family-practice-close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.close),
                    ),
                    const Spacer(),
                    if (step != null)
                      FilledButton(
                        key: const ValueKey('kids-family-practice-next'),
                        onPressed: () =>
                            context.read<KidsFamilyPracticeCubit>().advance(),
                        child: Text(state.isLastStep ? l10n.done : l10n.next),
                      )
                    else
                      FilledButton(
                        key: const ValueKey('kids-family-practice-done'),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.done),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// «نعم، تعلّمنا معًا»: the guardian proves themselves (PIN) and the
/// finished practice is recorded once. A second tap while the PIN dialog
/// is open does nothing.
class _GuardianConfirm extends StatefulWidget {
  const _GuardianConfirm({
    required this.confirmation,
    required this.verifyGuardian,
  });

  final KidsFamilyPracticeConfirmation confirmation;
  final Future<bool> Function(BuildContext context) verifyGuardian;

  @override
  State<_GuardianConfirm> createState() => _GuardianConfirmState();
}

class _GuardianConfirmState extends State<_GuardianConfirm> {
  bool _verifying = false;

  Future<void> _confirm() async {
    if (_verifying) return;
    setState(() => _verifying = true);
    try {
      final cubit = context.read<KidsFamilyPracticeCubit>();
      final verified = await widget.verifyGuardian(context);
      if (!verified || !mounted) return;
      await cubit.confirm();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = widget.confirmation;
    if (c == KidsFamilyPracticeConfirmation.saved) {
      return Row(
        key: const ValueKey('kids-family-practice-confirmed'),
        children: [
          Icon(TaliaIcons.check, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.kidsFamilyPracticeConfirmed,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      );
    }
    final busy = _verifying || c == KidsFamilyPracticeConfirmation.saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('kids-family-practice-confirm'),
          onPressed: busy ? null : _confirm,
          icon: const Icon(TaliaIcons.verified),
          label: Text(l10n.kidsFamilyPracticeConfirm),
        ),
        if (c == KidsFamilyPracticeConfirmation.failed) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.kidsFamilyPracticeConfirmFailed,
            key: const ValueKey('kids-family-practice-confirm-failed'),
            style: AppTypography.bodySmall.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
