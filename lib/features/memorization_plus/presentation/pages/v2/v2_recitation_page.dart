// lib/features/memorization_plus/presentation/pages/v2/v2_recitation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/extensions/context_extensions.dart';
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
      ],
    );
  }
}
