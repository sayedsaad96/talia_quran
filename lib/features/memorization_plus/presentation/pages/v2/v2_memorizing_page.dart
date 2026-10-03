import 'dart:async';
// lib/features/memorization_plus/presentation/pages/v2/v2_memorizing_page.dart


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/memorization/v2/hint_usage.dart';
import '../../cubits/memorization_session_cubit.dart';
import 'v2_session_widgets.dart';

/// V2 Phase 2: Memorizing — the user trains from memory.
///
/// The ayah starts hidden. Hints escalate: first word → first letter of
/// every word → full ayah. Every hint reaches the tracker before it shows,
/// so a prompted recall is never graded as a hint-free one. First letters
/// share the first-word tier (a partial prompt, graded average); the enum
/// stays unchanged because its index is persisted in checkpoints/evidence.
class V2MemorizingPage extends StatefulWidget {
  const V2MemorizingPage({super.key, required this.state});

  final MSActive state;

  @override
  State<V2MemorizingPage> createState() => _V2MemorizingPageState();
}

class _V2MemorizingPageState extends State<V2MemorizingPage> {
  /// View-local choice of partial prompt — resets when the ayah changes.
  bool _showFirstLetters = false;
  int _promptAyahNumber = -1;

  void _useHint(V2HintLevel level, {bool firstLetters = false}) {
    unawaited(context.read<MemorizationSessionCubit>().useHint(level));
    if (firstLetters) setState(() => _showFirstLetters = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final session = state.sessionState;
    final ayahNumber = session.currentAyah.numberInSurah;
    if (_promptAyahNumber != ayahNumber) {
      _promptAyahNumber = ayahNumber;
      _showFirstLetters = false;
    }
    final hintLevel = session.hintTracker.levelFor(session.surahId, ayahNumber);
    final showFirstLetters =
        _showFirstLetters && hintLevel != V2HintLevel.fullAyah;

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
        if (showFirstLetters)
          V2MaskedWordsCard(
            text: session.currentAyah.text,
            surahId: session.surahId,
            ayahNumber: ayahNumber,
            revealed: false,
          )
        else
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
          alignment: WrapAlignment.center,
          children: [
            V2HintButton(
              label: context.l10n.v2FirstWordHint,
              icon: Icons.short_text_rounded,
              onPressed: () => _useHint(V2HintLevel.firstWord),
            ),
            V2HintButton(
              key: const Key('v2-first-letters-hint'),
              label: context.l10n.v2FirstLettersHint,
              icon: Icons.text_fields_rounded,
              onPressed: () =>
                  _useHint(V2HintLevel.firstWord, firstLetters: true),
            ),
            V2HintButton(
              label: context.l10n.v2ShowAyahHint,
              icon: Icons.visibility_rounded,
              onPressed: () => _useHint(V2HintLevel.fullAyah),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.v2HintSchedulingNotice,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
