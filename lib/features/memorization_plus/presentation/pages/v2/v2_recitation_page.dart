// lib/features/memorization_plus/presentation/pages/v2/v2_recitation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/memorization/v2/self_grade.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../cubits/memorization_session_cubit.dart';
import 'v2_session_widgets.dart';

/// V2 Phase 3: Recitation — the ayah text is hidden.
/// The user records their recitation via STT for automated evaluation.
class V2RecitationPage extends StatelessWidget {
  const V2RecitationPage({super.key, required this.state});

  final MSActive state;

  @override
  Widget build(BuildContext context) {
    final isRecording = state.isRecording;
    final isEvaluating = state.isEvaluating;
    return V2PhaseScaffold(
      session: state.sessionState,
      icon: Icons.mic_rounded,
      title: context.l10n.v2RecitationTitle,
      subtitle: context.l10n.v2RecitationSubtitle,
      primaryActionLabel: isEvaluating
          ? context.l10n.v2Evaluating
          : isRecording
          ? context.l10n.v2StopRecording
          : context.l10n.v2StartRecording,
      primaryActionIcon: isRecording ? Icons.stop_rounded : Icons.mic_rounded,
      primaryActionEnabled: !isEvaluating,
      onPrimaryAction: () {
        final cubit = context.read<MemorizationSessionCubit>();
        return isRecording ? cubit.stopRecording() : cubit.startRecording();
      },
      children: [
        V2HiddenTextCard(
          isRecording: isRecording,
          isEvaluating: state.isEvaluating,
          speechIssue: state.speechIssue,
        ),
        // V1-M8 — clearly labelled manual/self-grade route for when STT or
        // the network is unavailable. The learner picks an honest verdict;
        // "forgot" routes to remediation instead of recording a pass.
        TextButton.icon(
          key: const ValueKey('v2-manual-recall'),
          onPressed: isEvaluating || isRecording
              ? null
              : () async {
                  final cubit = context.read<MemorizationSessionCubit>();
                  final grade = await showV2SelfGradeSheet(context);
                  if (grade != null) await cubit.submitManualRecall(grade);
                },
          icon: const Icon(Icons.record_voice_over_rounded, size: 18),
          label: Text(context.l10n.v2SelfGradeAction),
        ),
      ],
    );
  }
}

/// Asks the learner for an honest self-grade. Returns null when dismissed.
Future<V2SelfGrade?> showV2SelfGradeSheet(BuildContext context) {
  return showModalBottomSheet<V2SelfGrade>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      Widget option({
        required V2SelfGrade grade,
        required IconData icon,
        required Color color,
        required String title,
        required String hint,
      }) {
        return ListTile(
          key: ValueKey('v2-self-grade-${grade.name}'),
          leading: Icon(icon, color: color),
          title: Text(title, style: AppTypography.titleSmall),
          subtitle: Text(hint, style: AppTypography.bodySmall),
          onTap: () => Navigator.of(sheetContext).pop(grade),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  l10n.v2SelfGradeTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium,
                ),
              ),
              option(
                grade: V2SelfGrade.mastered,
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                title: l10n.v2SelfGradeMastered,
                hint: l10n.v2SelfGradeMasteredHint,
              ),
              option(
                grade: V2SelfGrade.hesitated,
                icon: Icons.adjust_rounded,
                color: AppColors.warning,
                title: l10n.v2SelfGradeHesitated,
                hint: l10n.v2SelfGradeHesitatedHint,
              ),
              option(
                grade: V2SelfGrade.forgot,
                icon: Icons.replay_rounded,
                color: AppColors.error,
                title: l10n.v2SelfGradeForgot,
                hint: l10n.v2SelfGradeForgotHint,
              ),
            ],
          ),
        ),
      );
    },
  );
}
