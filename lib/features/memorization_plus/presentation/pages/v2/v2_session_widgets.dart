import '../../../../../core/icons/talia_icons.dart';
import '../../../../../core/utils/locale_number_formatter.dart';
// lib/features/memorization_plus/presentation/pages/v2/v2_session_widgets.dart
//
// Shared UI components used across all V2 session phase pages.
// Extracted from v2_session_page.dart for single-responsibility and reuse.

// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/memorization/v2/hint_usage.dart';
import '../../../../../core/memorization/v2/session_state.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/memorization_ayah_display.dart';
import '../../cubits/memorization_session_cubit.dart';

// ─── Base card ────────────────────────────────────────────────────────────────

class V2PhaseCard extends StatelessWidget {
  const V2PhaseCard({super.key, required this.child, this.footer});

  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.tokens.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: child),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            DefaultTextStyle(
              style: AppTypography.bodyMedium.copyWith(
                color: context.tokens.textSecondary,
              ),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Progress header ──────────────────────────────────────────────────────────

class V2ProgressHeader extends StatelessWidget {
  const V2ProgressHeader({
    super.key,
    required this.session,
    required this.primary,
  });

  final V2SessionState session;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final position = context.l10n.v2AyahOfBlock(
      context.numText(session.currentAyahIndex + 1),
      context.numText(session.totalAyahsInBlock),
    );
    // The bar alone says nothing to a screen reader or at a glance; the
    // text names where the learner is in the block.
    return Semantics(
      label: position,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: session.blockProgress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            backgroundColor: context.tokens.divider,
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            position,
            key: const Key('v2_ayah_of_block'),
            textAlign: TextAlign.center,
            style: AppTypography.labelMedium.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phase scaffold ───────────────────────────────────────────────────────────

class V2PhaseScaffold extends StatelessWidget {
  const V2PhaseScaffold({
    super.key,
    required this.session,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onPrimaryAction,
    required this.children,
    this.primaryActionEnabled = true,
  });

  final V2SessionState session;

  /// Phase icon above the title. Null when the phase's own card already
  /// shows a live icon (the recording microphone) so it is not doubled.
  final IconData? icon;
  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final Future<void> Function() onPrimaryAction;
  final bool primaryActionEnabled;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final primary = context.tokens.accent;
    // The primary action is pinned below the scrolling content so it is
    // reachable without scrolling past long ayahs on small screens.
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                V2ProgressHeader(session: session, primary: primary),
                const SizedBox(height: AppSpacing.lg),
                if (icon != null) ...[
                  Icon(icon, color: primary, size: 40),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineLarge.copyWith(
                    color: context.tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...children,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: primaryActionEnabled ? onPrimaryAction : null,
                icon: Icon(primaryActionIcon),
                label: Text(primaryActionLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ayah text card ───────────────────────────────────────────────────────────

class V2AyahTextCard extends StatelessWidget {
  const V2AyahTextCard({super.key, required this.session});

  final V2SessionState session;

  @override
  Widget build(BuildContext context) {
    final ayah = session.currentAyah;
    return V2PhaseCard(
      child: MemorizationAyahDisplay(
        text: ayah.text,
        surahId: session.surahId,
        ayahNumber: ayah.numberInSurah,
        textColor: context.tokens.textPrimary,
        decorationColor: context.tokens.accent.withValues(alpha: 0.5),
        referenceColor: context.tokens.accent,
        isCompleted: session.passedAyahNumbers.contains(ayah.numberInSurah),
      ),
      footer: null,
    );
  }
}

// ─── Hint card ────────────────────────────────────────────────────────────────

class V2HintCard extends StatelessWidget {
  const V2HintCard({super.key, required this.session, required this.hintLevel});

  final V2SessionState session;
  final V2HintLevel hintLevel;

  @override
  Widget build(BuildContext context) {
    final firstWord = session.currentAyah.text
        .trim()
        .split(RegExp(r'\s+'))
        .first;
    return switch (hintLevel) {
      V2HintLevel.none => V2PhaseCard(
        child: Icon(TaliaIcons.hide, size: 42, color: context.tokens.textHint),
        footer: Text(
          context.l10n.v2TryWithoutHint,
          textAlign: TextAlign.center,
        ),
      ),
      V2HintLevel.firstWord => V2PhaseCard(
        child: Text(
          firstWord,
          textAlign: TextAlign.center,
          style: MemorizationAyahDisplay.textStyle(),
        ),
        footer: Text(
          context.l10n.v2FirstWordRevealed,
          textAlign: TextAlign.center,
        ),
      ),
      V2HintLevel.fullAyah => V2AyahTextCard(session: session),
    };
  }
}

// ─── Hint button ──────────────────────────────────────────────────────────────

class V2HintButton extends StatelessWidget {
  const V2HintButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

// ─── Hidden text card (recitation) ───────────────────────────────────────────

class V2HiddenTextCard extends StatelessWidget {
  const V2HiddenTextCard({
    super.key,
    required this.isRecording,
    required this.isEvaluating,
    required this.speechIssue,
  });

  final bool isRecording;
  final bool isEvaluating;
  final V2SpeechIssue? speechIssue;

  @override
  Widget build(BuildContext context) {
    final primary = context.tokens.accent;
    return V2PhaseCard(
      child: Icon(
        isRecording ? TaliaIcons.waveform : TaliaIcons.mic,
        size: 64,
        color: primary,
      ),
      footer: _SpeechIssueFooter(
        isRecording: isRecording,
        isEvaluating: isEvaluating,
        speechIssue: speechIssue,
        evaluatingLabel: context.l10n.v2Evaluating,
        recordingLabel: context.l10n.v2RecordingNow,
      ),
    );
  }
}

// ─── Failure summary ──────────────────────────────────────────────────────────

class V2FailureSummary extends StatelessWidget {
  const V2FailureSummary({super.key, required this.session});

  final V2SessionState session;

  @override
  Widget build(BuildContext context) {
    final failures = session.failureTracker.failureCountFor(
      session.surahId,
      session.currentAyah.numberInSurah,
    );
    return V2PhaseCard(
      child: const Icon(TaliaIcons.refresh, size: 42, color: AppColors.warning),
      footer: Text(
        context.l10n.v2RemediationAttempts(
          LocaleNumberFormatter.format(
            (failures).toString(),
            context.l10n.localeName,
          ),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Block review summary card ────────────────────────────────────────────────

class V2BlockReviewSummaryCard extends StatelessWidget {
  const V2BlockReviewSummaryCard({
    super.key,
    required this.session,
    required this.start,
    required this.end,
  });

  final V2SessionState session;
  final int start;
  final int end;

  @override
  Widget build(BuildContext context) {
    return V2PhaseCard(
      child: Icon(TaliaIcons.checklist, size: 48, color: context.tokens.accent),
      footer: Column(
        children: [
          Text(
            context.l10n.v2AyahRange(
              context.numText(start),
              context.numText(end),
            ),
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.v2BlockProgress(
              context.numText(session.passedAyahNumbers.length),
              context.numText(session.totalAyahsInBlock),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Block review hidden card ─────────────────────────────────────────────────

class V2BlockReviewHiddenCard extends StatelessWidget {
  const V2BlockReviewHiddenCard({
    super.key,
    required this.start,
    required this.end,
    required this.isRecording,
    required this.isEvaluating,
    required this.speechIssue,
  });

  final int start;
  final int end;
  final bool isRecording;
  final bool isEvaluating;
  final V2SpeechIssue? speechIssue;

  @override
  Widget build(BuildContext context) {
    final primary = context.tokens.accent;
    final footer = _SpeechIssueFooter(
      isRecording: isRecording,
      isEvaluating: isEvaluating,
      speechIssue: speechIssue,
      evaluatingLabel: context.l10n.v2EvaluatingBlock,
      recordingLabel: context.l10n.v2RecordingBlock,
    );

    return V2PhaseCard(
      child: Column(
        children: [
          Icon(
            isRecording ? TaliaIcons.waveform : TaliaIcons.hide,
            size: 64,
            color: primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.v2AyahRange(
              context.numText(start),
              context.numText(end),
            ),
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium,
          ),
        ],
      ),
      footer: footer,
    );
  }
}

class _SpeechIssueFooter extends StatelessWidget {
  const _SpeechIssueFooter({
    required this.isRecording,
    required this.isEvaluating,
    required this.speechIssue,
    required this.evaluatingLabel,
    required this.recordingLabel,
  });

  final bool isRecording;
  final bool isEvaluating;
  final V2SpeechIssue? speechIssue;
  final String evaluatingLabel;
  final String recordingLabel;

  @override
  Widget build(BuildContext context) {
    final message = switch (speechIssue) {
      V2SpeechIssue.noSpeech => context.l10n.v2NoSpeechDetected,
      V2SpeechIssue.permissionDenied =>
        context.l10n.v2MicrophonePermissionDenied,
      V2SpeechIssue.permissionPermanentlyDenied =>
        context.l10n.v2MicrophoneOpenSettings,
      V2SpeechIssue.unavailable => context.l10n.v2MicrophoneUnavailable,
      null =>
        isEvaluating
            ? evaluatingLabel
            : isRecording
            ? recordingLabel
            : context.l10n.v2PressRecord,
    };

    return Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        if (speechIssue == V2SpeechIssue.permissionPermanentlyDenied)
          TextButton(
            onPressed: openAppSettings,
            child: Text(context.l10n.openSettingsAction),
          ),
      ],
    );
  }
}

// ─── Audio action button ──────────────────────────────────────────────────────

class V2AudioAction extends StatelessWidget {
  const V2AudioAction({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.loopMode = V2AudioLoopMode.off,
    this.onCycleLoop,
  });

  final bool isPlaying;
  final VoidCallback onPressed;
  final V2AudioLoopMode loopMode;
  final VoidCallback? onCycleLoop;

  @override
  Widget build(BuildContext context) {
    final loopLabel = switch (loopMode) {
      V2AudioLoopMode.off => context.l10n.v2LoopOff,
      V2AudioLoopMode.threeTimes => context.l10n.v2LoopThree,
      V2AudioLoopMode.endless => context.l10n.v2LoopInfinite,
    };

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(isPlaying ? TaliaIcons.volume : TaliaIcons.play),
            label: Text(
              isPlaying ? context.l10n.v2Playing : context.l10n.v2ListenToAyah,
            ),
          ),
        ),
        if (onCycleLoop != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton.outlined(
            key: const Key('v2-audio-loop-toggle'),
            tooltip: loopLabel,
            onPressed: onCycleLoop,
            style: IconButton.styleFrom(
              side: BorderSide(
                color: loopMode == V2AudioLoopMode.off
                    ? Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            icon: Badge(
              isLabelVisible: loopMode != V2AudioLoopMode.off,
              label: Text(switch (loopMode) {
                V2AudioLoopMode.threeTimes => '3',
                _ => '∞',
              }),
              child: Icon(
                loopMode == V2AudioLoopMode.off
                    ? TaliaIcons.repeat
                    : TaliaIcons.repeat,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Masked-words hint card ─────────────────────────────────────────────────

/// Middle reveal step between first-word and full-ayah hints: the ayah is
/// rendered with every word masked to its first letter, training recall
/// before the learner commits to seeing the whole verse.
class V2MaskedWordsCard extends StatelessWidget {
  const V2MaskedWordsCard({
    super.key,
    required this.text,
    required this.surahId,
    required this.ayahNumber,
    required this.revealed,
    this.onToggle,
  });

  final String text;
  final int surahId;
  final int ayahNumber;
  final bool revealed;

  /// Reveal/hide control. Null hides it (the full ayah has its own hint).
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final hintColor = context.tokens.textHint;

    return V2PhaseCard(
      child: revealed
          ? MemorizationAyahDisplay(
              text: text,
              surahId: surahId,
              ayahNumber: ayahNumber,
              textColor: context.tokens.textPrimary,
              decorationColor: context.tokens.accent.withValues(alpha: 0.5),
              referenceColor: context.tokens.accent,
            )
          : Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                for (final word in _words)
                  Text(
                    _mask(word),
                    textAlign: TextAlign.center,
                    style: MemorizationAyahDisplay.textStyle().copyWith(
                      color: hintColor,
                      letterSpacing: 2,
                    ),
                  ),
              ],
            ),
      footer: Column(
        children: [
          Text(
            revealed
                ? context.l10n.v2MaskedWordsFull
                : context.l10n.v2FirstLettersRevealed,
            textAlign: TextAlign.center,
          ),
          if (onToggle != null)
            TextButton.icon(
              key: const Key('v2-masked-words-toggle'),
              onPressed: onToggle,
              icon: Icon(
                revealed ? TaliaIcons.hide : TaliaIcons.show,
                size: 16,
              ),
              label: Text(
                revealed
                    ? context.l10n.v2MaskedWordsFull
                    : context.l10n.v2MaskedWordsHint,
              ),
            ),
        ],
      ),
    );
  }

  List<String> get _words =>
      text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  /// Masks a word to its first letter plus tashkeel-free dot placeholders.
  static String _mask(String word) {
    if (word.isEmpty) return word;
    return '${word.characters.first}${'•' * (word.characters.length - 1).clamp(0, 6)}';
  }
}

// ─── Summary row + tile ───────────────────────────────────────────────────────

class V2SummaryRow extends StatelessWidget {
  const V2SummaryRow({
    super.key,
    required this.passed,
    required this.total,
    required this.failures,
  });

  final int passed;
  final int total;
  final int failures;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: V2SummaryTile(
            label: context.l10n.v2Passed,
            value: '${context.numText(passed)}/${context.numText(total)}',
            icon: TaliaIcons.checkCircleFilled,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: V2SummaryTile(
            label: context.l10n.v2Retries,
            value: context.numText(failures),
            icon: TaliaIcons.replay,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class V2SummaryTile extends StatelessWidget {
  const V2SummaryTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return V2PhaseCard(
      child: Icon(icon, color: color, size: 32),
      footer: Column(
        children: [
          Text(value, style: AppTypography.titleLarge.copyWith(color: color)),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
