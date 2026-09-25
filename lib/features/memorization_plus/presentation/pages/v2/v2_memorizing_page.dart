// lib/features/memorization_plus/presentation/pages/v2/v2_memorizing_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/memorization/v2/hint_usage.dart';
import '../../cubits/memorization_session_cubit.dart';
import 'v2_session_widgets.dart';

/// V2 Phase 2: Memorizing — the user trains from memory.
/// Hints (masked words / first word / full ayah) are only available here.
class V2MemorizingPage extends StatefulWidget {
  const V2MemorizingPage({super.key, required this.state});

  final MSActive state;

  @override
  State<V2MemorizingPage> createState() => _V2MemorizingPageState();
}

class _V2MemorizingPageState extends State<V2MemorizingPage> {
  /// View-local masked-words reveal — resets when the ayah changes.
  bool _maskedRevealed = false;
  int _maskedAyahNumber = -1;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final session = state.sessionState;
    final ayahNumber = session.currentAyah.numberInSurah;
    if (_maskedAyahNumber != ayahNumber) {
      _maskedAyahNumber = ayahNumber;
      _maskedRevealed = false;
    }
    final hintLevel = session.hintTracker.levelFor(
      session.surahId,
      ayahNumber,
    );
    final showMaskedCard =
        hintLevel == V2HintLevel.none || hintLevel == V2HintLevel.firstWord;

    return V2PhaseScaffold(
      session: session,
      icon: Icons.psychology_rounded,
      title: context.l10n.v2MemorizingTitle,
      subtitle: context.l10n.v2MemorizingSubtitle,
      primaryActionLabel: context.l10n.v2ReadyToRecite,
      primaryActionIcon: Icons.mic_rounded,
      onPrimaryAction: () =>
          context.read<MemorizationSessionCubit>().advanceToReciting(),
      children: [
        if (showMaskedCard) ...[
          V2MaskedWordsCard(
            text: session.currentAyah.text,
            revealed: _maskedRevealed,
            onToggle: () => setState(() => _maskedRevealed = !_maskedRevealed),
          ),
        ] else
          V2HintCard(session: session, hintLevel: hintLevel),
        const SizedBox(height: AppSpacing.md),
        V2AudioAction(
          isPlaying: state.isPlaying,
          onPressed: () =>
              context.read<MemorizationSessionCubit>().playCurrentAyah(),
          loopMode: state.audioLoopMode,
          onCycleLoop: () =>
              context.read<MemorizationSessionCubit>().cycleAudioLoopMode(),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            V2HintButton(
              label: context.l10n.v2FirstWordHint,
              icon: Icons.short_text_rounded,
              onPressed: () => unawaited(
                context.read<MemorizationSessionCubit>().useHint(
                  V2HintLevel.firstWord,
                ),
              ),
            ),
            V2HintButton(
              label: context.l10n.v2ShowAyahHint,
              icon: Icons.visibility_rounded,
              onPressed: () => unawaited(
                context.read<MemorizationSessionCubit>().useHint(
                  V2HintLevel.fullAyah,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
