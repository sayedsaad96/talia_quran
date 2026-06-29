// lib/features/memorization_plus/presentation/pages/v2/v2_learning_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../cubits/memorization_session_cubit.dart';
import 'v2_session_widgets.dart';

/// V2 Phase 1: Learning — the user reads and listens to the ayah before
/// attempting to memorize it. No time limit, hints not applicable here.
class V2LearningPage extends StatelessWidget {
  const V2LearningPage({super.key, required this.state});

  final MSActive state;

  @override
  Widget build(BuildContext context) {
    return V2PhaseScaffold(
      session: state.sessionState,
      icon: Icons.menu_book_rounded,
      title: context.isArabic ? 'تعلّم الآية' : 'Learn the ayah',
      subtitle: context.isArabic
          ? 'استمع واقرأ الآية بهدوء قبل محاولة حفظها.'
          : 'Listen and read before trying to memorize.',
      primaryActionLabel:
          context.isArabic ? 'انتقل للحفظ' : 'Start memorizing',
      primaryActionIcon: Icons.psychology_rounded,
      onPrimaryAction: () =>
          context.read<MemorizationSessionCubit>().advanceToMemorizing(),
      children: [
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
