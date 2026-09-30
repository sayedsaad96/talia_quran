// lib/features/memorization_plus/presentation/pages/v2/v2_recitation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/memorization/v2/self_grade.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/memorization_ayah_display.dart';
import '../../../../quran/domain/entities/quran_entities.dart';
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
                  final session = state.sessionState;
                  final verdict = await showV2SelfGradeSheet(
                    context,
                    surahId: session.surahId,
                    ayahs: [session.currentAyah],
                  );
                  if (verdict != null) {
                    await cubit.submitManualRecall(verdict.grade);
                  }
                },
          icon: const Icon(Icons.record_voice_over_rounded, size: 18),
          label: Text(context.l10n.v2SelfGradeAction),
        ),
      ],
    );
  }
}

/// An honest self-grade, plus the ayah where a block recitation broke.
typedef V2SelfGradeVerdict = ({V2SelfGrade grade, int? stumbledAyahNumber});

/// Asks the learner for an honest self-grade. Returns null when dismissed.
///
/// The grades stay locked until the learner reveals [ayahs] to compare with
/// what they recited (N5): grading from memory alone is guesswork. With more
/// than one ayah (block review), a hesitation or a lapse also asks which
/// ayah the learner stumbled on.
Future<V2SelfGradeVerdict?> showV2SelfGradeSheet(
  BuildContext context, {
  required int surahId,
  required List<Ayah> ayahs,
}) {
  return showModalBottomSheet<V2SelfGradeVerdict>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _SelfGradeSheet(surahId: surahId, ayahs: ayahs),
  );
}

class _SelfGradeSheet extends StatefulWidget {
  const _SelfGradeSheet({required this.surahId, required this.ayahs});

  final int surahId;
  final List<Ayah> ayahs;

  @override
  State<_SelfGradeSheet> createState() => _SelfGradeSheetState();
}

class _SelfGradeSheetState extends State<_SelfGradeSheet> {
  bool _revealed = false;
  V2SelfGrade? _stumbleGrade;

  bool get _isBlock => widget.ayahs.length > 1;

  void _grade(V2SelfGrade grade) {
    if (_isBlock && grade != V2SelfGrade.mastered) {
      setState(() => _stumbleGrade = grade);
      return;
    }
    Navigator.of(context).pop((grade: grade, stumbledAyahNumber: null));
  }

  @override
  Widget build(BuildContext context) {
    final stumbleGrade = _stumbleGrade;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: stumbleGrade != null
                ? _stumbledAyahStep(context, stumbleGrade)
                : _gradeStep(context, context.l10n),
          ),
        ),
      ),
    );
  }

  List<Widget> _gradeStep(BuildContext context, AppLocalizations l10n) {
    Widget option({
      required V2SelfGrade grade,
      required IconData icon,
      required Color color,
      required String title,
      String? hint,
    }) {
      return ListTile(
        key: ValueKey('v2-self-grade-${grade.name}'),
        enabled: _revealed,
        leading: Icon(icon, color: _revealed ? color : null),
        title: Text(title, style: AppTypography.titleSmall),
        subtitle: hint == null
            ? null
            : Text(hint, style: AppTypography.bodySmall),
        onTap: () => _grade(grade),
      );
    }

    return [
      _title(l10n.v2SelfGradeTitle),
      if (_revealed)
        for (final ayah in widget.ayahs)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: MemorizationAyahDisplay(
              text: ayah.text,
              surahId: widget.surahId,
              ayahNumber: ayah.numberInSurah,
              textColor: context.tokens.textPrimary,
              decorationColor: context.tokens.accent.withValues(alpha: 0.5),
              referenceColor: context.tokens.accent,
            ),
          )
      else ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            l10n.v2SelfGradeRevealHint,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Center(
            child: OutlinedButton.icon(
              key: const ValueKey('v2-self-grade-reveal'),
              onPressed: () => setState(() => _revealed = true),
              icon: const Icon(Icons.visibility_rounded),
              label: Text(
                _isBlock
                    ? l10n.v2BlockRevealAction
                    : l10n.v2SelfGradeRevealAction,
              ),
            ),
          ),
        ),
      ],
      option(
        grade: V2SelfGrade.mastered,
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        title: _isBlock ? l10n.v2BlockGradeMastered : l10n.v2SelfGradeMastered,
        hint: _isBlock ? null : l10n.v2SelfGradeMasteredHint,
      ),
      option(
        grade: V2SelfGrade.hesitated,
        icon: Icons.adjust_rounded,
        color: AppColors.warning,
        title: _isBlock
            ? l10n.v2BlockGradeHesitated
            : l10n.v2SelfGradeHesitated,
        hint: _isBlock ? null : l10n.v2SelfGradeHesitatedHint,
      ),
      option(
        grade: V2SelfGrade.forgot,
        icon: Icons.replay_rounded,
        color: AppColors.error,
        title: _isBlock ? l10n.v2BlockGradeForgot : l10n.v2SelfGradeForgot,
        hint: l10n.v2SelfGradeForgotHint,
      ),
    ];
  }

  List<Widget> _stumbledAyahStep(BuildContext context, V2SelfGrade grade) {
    return [
      _title(context.l10n.v2StumbledAyahTitle),
      for (final ayah in widget.ayahs)
        ListTile(
          key: ValueKey('v2-stumbled-ayah-${ayah.numberInSurah}'),
          leading: const Icon(Icons.flag_rounded),
          title: Text(
            context.l10n.v2StumbledAyahOption(ayah.numberInSurah),
            style: AppTypography.titleSmall,
          ),
          onTap: () => Navigator.of(
            context,
          ).pop((grade: grade, stumbledAyahNumber: ayah.numberInSurah)),
        ),
    ];
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppTypography.titleMedium,
    ),
  );
}
