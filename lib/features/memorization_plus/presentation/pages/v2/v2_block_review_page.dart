// lib/features/memorization_plus/presentation/pages/v2/v2_block_review_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../cubits/memorization_session_cubit.dart';
import 'v2_session_widgets.dart';

/// V2 Phase 5a: Block Review Pending — all individual ayahs passed.
/// The user is prompted to recite the full block from memory.
class V2BlockReviewPendingPage extends StatelessWidget {
  const V2BlockReviewPendingPage({super.key, required this.state});

  final MSActive state;

  @override
  Widget build(BuildContext context) {
    final session = state.sessionState;
    final start = session.blockAyahs.first.numberInSurah;
    final end = session.blockAyahs.last.numberInSurah;
    return V2PhaseScaffold(
      session: session,
      icon: Icons.fact_check_rounded,
      title: context.l10n.v2BlockReviewPendingTitle,
      subtitle: context.l10n.v2BlockReviewPendingSubtitle,
      primaryActionLabel: context.l10n.v2StartBlockReview,
      primaryActionIcon: Icons.play_arrow_rounded,
      onPrimaryAction: () =>
          context.read<MemorizationSessionCubit>().startBlockReview(),
      children: [
        V2BlockReviewSummaryCard(session: session, start: start, end: end),
      ],
    );
  }
}

/// V2 Phase 5b: Block Review — reciting the full block with text hidden.
/// STT records the full multi-ayah recitation for evaluation.
class V2BlockReviewPage extends StatelessWidget {
  const V2BlockReviewPage({super.key, required this.state});

  final MSActive state;

  @override
  Widget build(BuildContext context) {
    final session = state.sessionState;
    final start = session.blockAyahs.first.numberInSurah;
    final end = session.blockAyahs.last.numberInSurah;
    final isRecording = state.isRecording;
    final isEvaluating = state.isEvaluating;
    return V2PhaseScaffold(
      session: session,
      icon: Icons.mic_external_on_rounded,
      title: context.l10n.v2BlockReviewTitle,
      subtitle: context.l10n.v2BlockReviewSubtitle(start, end),
      primaryActionLabel: isEvaluating
          ? context.l10n.v2EvaluatingBlock
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
        V2BlockReviewHiddenCard(
          start: start,
          end: end,
          isRecording: isRecording,
          isEvaluating: state.isEvaluating,
          speechIssue: state.speechIssue,
        ),
        // V1-M8 — clearly labelled manual/self-grade route for when STT or
        // the network is unavailable.
        TextButton.icon(
          key: const ValueKey('v2-manual-block-review'),
          onPressed: isEvaluating || isRecording
              ? null
              : () => context
                    .read<MemorizationSessionCubit>()
                    .submitManualRecall(),
          icon: const Icon(Icons.record_voice_over_rounded, size: 18),
          label: Text(context.l10n.v2ManualBlockReviewAction),
        ),
      ],
    );
  }
}
