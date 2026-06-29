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
      title: context.isArabic ? 'مراجعة المقطع' : 'Block review',
      subtitle: context.isArabic
          ? 'أنهيت الآيات منفردة. الخطوة التالية تسميع المقطع كاملاً من الذاكرة.'
          : 'All individual ayahs passed. Next, recite the full block from memory.',
      primaryActionLabel:
          context.isArabic ? 'ابدأ مراجعة المقطع' : 'Start Block Review',
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
    return V2PhaseScaffold(
      session: session,
      icon: Icons.mic_external_on_rounded,
      title: context.isArabic ? 'سمّع المقطع كاملاً' : 'Recite the full block',
      subtitle: context.isArabic
          ? 'النص مخفي الآن. سجّل الآيات $start-$end كاملة بدون تلميحات.'
          : 'Text is hidden. Record ayahs $start-$end together without hints.',
      primaryActionLabel: isRecording
          ? (context.isArabic ? 'إيقاف التسجيل' : 'Stop recording')
          : (context.isArabic ? 'بدء التسجيل' : 'Start recording'),
      primaryActionIcon:
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
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
      ],
    );
  }
}
