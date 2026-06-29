// lib/features/memorization_plus/presentation/pages/v2/v2_remediation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../cubits/memorization_session_cubit.dart';
import 'v2_session_widgets.dart';

/// V2 Phase 4: Remediation — shown after a failed recitation.
/// The user re-reads and listens before attempting again.
class V2RemediationPage extends StatelessWidget {
  const V2RemediationPage({super.key, required this.state});

  final MSActive state;

  @override
  Widget build(BuildContext context) {
    return V2PhaseScaffold(
      session: state.sessionState,
      icon: Icons.healing_rounded,
      title: context.isArabic ? 'مراجعة قصيرة' : 'Short remediation',
      subtitle: context.isArabic
          ? 'استمع واقرأ الآية مرة أخرى، ثم ارجع لمحاولة التسميع.'
          : 'Listen and read again, then return to recitation.',
      primaryActionLabel:
          context.isArabic ? 'أحاول مرة أخرى' : 'Try again',
      primaryActionIcon: Icons.replay_rounded,
      onPrimaryAction: () =>
          context.read<MemorizationSessionCubit>().completeRemediation(),
      children: [
        V2FailureSummary(session: state.sessionState),
        const SizedBox(height: AppSpacing.md),
        V2AyahTextCard(session: state.sessionState),
        const SizedBox(height: AppSpacing.md),
        V2AudioAction(
          isPlaying: state.isPlaying,
          onPressed: () =>
              context.read<MemorizationSessionCubit>().playCurrentAyah(),
        ),
      ],
    );
  }
}
