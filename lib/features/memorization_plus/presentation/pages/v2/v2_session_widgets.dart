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
import '../../../../../core/widgets/qcf_hifz_verse_view.dart';
import '../../cubits/memorization_session_cubit.dart';

// ─── Base card ────────────────────────────────────────────────────────────────

class V2PhaseCard extends StatelessWidget {
  const V2PhaseCard({super.key, required this.child, required this.footer});

  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: child),
          const SizedBox(height: AppSpacing.md),
          DefaultTextStyle(
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            child: footer,
          ),
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
    final isDark = context.isDark;
    return LinearProgressIndicator(
      value: session.blockProgress,
      minHeight: 8,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      backgroundColor: isDark ? AppColors.darkDivider : AppColors.lightDivider,
      valueColor: AlwaysStoppedAnimation<Color>(primary),
    );
  }
}

// ─── Phase scaffold ───────────────────────────────────────────────────────────

class V2PhaseScaffold extends StatelessWidget {
  const V2PhaseScaffold({
    super.key,
    required this.session,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onPrimaryAction,
    required this.children,
    this.primaryActionEnabled = true,
  });

  final V2SessionState session;
  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final Future<void> Function() onPrimaryAction;
  final bool primaryActionEnabled;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          V2ProgressHeader(session: session, primary: primary),
          const SizedBox(height: AppSpacing.lg),
          Icon(icon, color: primary, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: primaryActionEnabled ? onPrimaryAction : null,
            icon: Icon(primaryActionIcon),
            label: Text(primaryActionLabel),
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
    final isDark = context.isDark;
    return V2PhaseCard(
      child: QcfHifzVerseView(
        surahNumber: session.surahId,
        verseNumber: ayah.numberInSurah,
        fallbackText: ayah.text,
        isUnlocked: true,
        isMemorized: session.passedAyahNumbers.contains(ayah.numberInSurah),
        displayMode: HifzVerseDisplayMode.single,
        textAlign: TextAlign.center,
      ),
      footer: Text(
        context.l10n.hifzAyahNumberLabel(ayah.numberInSurah),
        textAlign: TextAlign.center,
        style: AppTypography.labelMedium.copyWith(
          color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
        ),
      ),
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
        child: Icon(
          Icons.visibility_off_rounded,
          size: 42,
          color: context.isDark
              ? AppColors.darkTextHint
              : AppColors.lightTextHint,
        ),
        footer: Text(
          context.l10n.v2TryWithoutHint,
          textAlign: TextAlign.center,
        ),
      ),
      V2HintLevel.firstWord => V2PhaseCard(
        child: Text(
          firstWord,
          textAlign: TextAlign.center,
          style: AppTypography.quranLarge,
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
    final primary = context.isDark ? AppColors.primaryLight : AppColors.primary;
    return V2PhaseCard(
      child: Icon(
        isRecording ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
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
      child: const Icon(
        Icons.refresh_rounded,
        size: 42,
        color: AppColors.warning,
      ),
      footer: Text(
        context.l10n.v2RemediationAttempts(failures),
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
      child: Icon(
        Icons.checklist_rtl_rounded,
        size: 48,
        color: context.isDark ? AppColors.primaryLight : AppColors.primary,
      ),
      footer: Column(
        children: [
          Text(
            context.l10n.v2AyahRange(start, end),
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.v2BlockProgress(
              session.passedAyahNumbers.length,
              session.totalAyahsInBlock,
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
    final primary = context.isDark ? AppColors.primaryLight : AppColors.primary;
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
            isRecording
                ? Icons.graphic_eq_rounded
                : Icons.visibility_off_rounded,
            size: 64,
            color: primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.v2AyahRange(start, end),
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
      null => isEvaluating
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
            icon: Icon(
              isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
            ),
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
                    ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            icon: Badge(
              isLabelVisible: loopMode != V2AudioLoopMode.off,
              label: Text(
                switch (loopMode) {
                  V2AudioLoopMode.threeTimes => '3',
                  _ => '∞',
                },
              ),
              child: Icon(
                loopMode == V2AudioLoopMode.off
                    ? Icons.repeat_rounded
                    : Icons.repeat_on_rounded,
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
    required this.revealed,
    required this.onToggle,
  });

  final String text;
  final bool revealed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final hintColor =
        isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return V2PhaseCard(
      child: revealed
          ? Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.quranLarge,
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
                    style: AppTypography.quranLarge.copyWith(
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
                : context.l10n.v2MaskedWordsRevealed,
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            key: const Key('v2-masked-words-toggle'),
            onPressed: onToggle,
            icon: Icon(
              revealed
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
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
            value: '$passed/$total',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: V2SummaryTile(
            label: context.l10n.v2Retries,
            value: '$failures',
            icon: Icons.replay_rounded,
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
