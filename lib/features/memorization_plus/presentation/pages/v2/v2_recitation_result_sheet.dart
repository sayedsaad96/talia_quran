// lib/features/memorization_plus/presentation/pages/v2/v2_recitation_result_sheet.dart
//
// Presentation-only result sheet shown right after a recitation evaluation.
// Renders V2EvaluationFeedback (similarity + word diff) with follow-up
// actions. Reads no domain logic and writes nothing — every action is a
// Cubit callback supplied by the session view.

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/memorization/v2/recitation_word_diff.dart';
import '../../../../../core/memorization/v2/recitation_evaluator.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../cubits/memorization_session_cubit.dart';

/// Shows the modal result sheet for the latest evaluation feedback.
///
/// Returns the chosen follow-up action so the caller (session view) can
/// drive the Cubit without this sheet touching it directly.
Future<V2RecitationResultAction?> showV2RecitationResultSheet(
  BuildContext context,
  V2EvaluationFeedback feedback,
) {
  return showModalBottomSheet<V2RecitationResultAction>(
    context: context,
    useRootNavigator: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        V2RecitationResultSheet(feedback: feedback),
  );
}

enum V2RecitationResultAction { retryNow, reviewAyah, dismiss }

/// Bottom sheet that turns the silent pass/fail transition into a clear,
/// encouraging feedback moment with a colour-coded word comparison.
class V2RecitationResultSheet extends StatelessWidget {
  const V2RecitationResultSheet({super.key, required this.feedback});

  final V2EvaluationFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final result = feedback.result;
    final diff = feedback.wordDiff;

    final accent = _accentFor(result, isDark);
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _ResultHeader(result: result, accent: accent),
              const SizedBox(height: AppSpacing.lg),
              if (!result.passed && diff.words.isNotEmpty) ...[
                _WordDiffView(diff: diff, isDark: isDark),
                const SizedBox(height: AppSpacing.md),
                _DiffLegend(diff: diff, isDark: isDark),
                const SizedBox(height: AppSpacing.lg),
              ],
              const SizedBox(height: AppSpacing.sm),
              _ResultActions(result: result, accent: accent),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentFor(V2RecitationResult result, bool isDark) {
    if (result.passed) {
      return isDark ? AppColors.primaryLight : AppColors.success;
    }
    return result.verdict == RecitationVerdict.retry
        ? AppColors.warning
        : AppColors.error;
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.result, required this.accent});

  final V2RecitationResult result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final icon = result.passed
        ? Icons.check_circle_rounded
        : Icons.error_outline_rounded;
    final title = result.passed
        ? (result.similarityScore != null &&
                result.similarityScore! >= 0.999
            ? context.l10n.v2ResultExcellent
            : context.l10n.v2ResultPassed)
        : (result.verdict == RecitationVerdict.retry
            ? context.l10n.v2ResultRetrying
            : context.l10n.v2ResultNeedsWork);

    return Column(
      children: [
        Icon(icon, color: accent, size: 56),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.headlineSmall.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (result.assessmentMethod == V2AssessmentMethod.manual)
          Text(
            context.l10n.v2ResultManualGrade,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: context.isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          )
        else if (result.similarityScore != null)
          Text(
            context.l10n.v2ResultSimilarity(
              (result.similarityScore!.clamp(0.0, 1.0) * 100).round(),
            ),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: context.isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
      ],
    );
  }
}

/// Colour-coded word-by-word comparison of the recitation attempt.
class _WordDiffView extends StatelessWidget {
  const _WordDiffView({required this.diff, required this.isDark});

  final RecitationWordDiffResult diff;
  final bool isDark;

  Color _colorFor(RecitationWordStatus status) => switch (status) {
    RecitationWordStatus.match => AppColors.success,
    RecitationWordStatus.missing => AppColors.error,
    RecitationWordStatus.wrong => AppColors.error,
    RecitationWordStatus.extra => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.darkDivider
              : AppColors.lightDivider,
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        alignment: WrapAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          for (final word in diff.words)
            Text(
              word.display,
              style: AppTypography.quranLarge.copyWith(
                fontSize: 20,
                color: _colorFor(word.status),
                fontWeight: word.status == RecitationWordStatus.match
                    ? FontWeight.w600
                    : FontWeight.w800,
                // Missing words get a dotted underline so gaps are visible
                // even where the word itself is absent.
                decoration:
                    word.status == RecitationWordStatus.missing
                        ? TextDecoration.underline
                        : TextDecoration.none,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
        ],
      ),
    );
  }
}

class _DiffLegend extends StatelessWidget {
  const _DiffLegend({required this.diff, required this.isDark});

  final RecitationWordDiffResult diff;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final entries = <(String, int, Color)>[
      (
        context.l10n.v2ResultWordsCorrect,
        diff.matchCount,
        AppColors.success,
      ),
      if (diff.missingCount > 0)
        (
          context.l10n.v2ResultWordsMissing,
          diff.missingCount,
          AppColors.error,
        ),
      if (diff.wrongCount > 0)
        (
          context.l10n.v2ResultWordsWrong,
          diff.wrongCount,
          AppColors.error,
        ),
      if (diff.extraCount > 0)
        (
          context.l10n.v2ResultWordsExtra,
          diff.extraCount,
          AppColors.warning,
        ),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: [
        for (final (label, count, color) in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$label: $count',
                style: AppTypography.labelMedium.copyWith(
                  color: secondary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({required this.result, required this.accent});

  final V2RecitationResult result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (result.passed) {
      return FilledButton.icon(
        key: const Key('v2-result-continue'),
        style: FilledButton.styleFrom(backgroundColor: accent),
        onPressed: () => Navigator.of(context).pop(
          V2RecitationResultAction.dismiss,
        ),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(context.l10n.v2ResultContinue),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('v2-result-retry-now'),
          style: FilledButton.styleFrom(backgroundColor: accent),
          onPressed: () => Navigator.of(context).pop(
            V2RecitationResultAction.retryNow,
          ),
          icon: const Icon(Icons.mic_rounded),
          label: Text(context.l10n.v2ResultRetryNow),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('v2-result-review-ayah'),
          onPressed: () => Navigator.of(context).pop(
            V2RecitationResultAction.reviewAyah,
          ),
          icon: const Icon(Icons.menu_book_rounded),
          label: Text(context.l10n.v2ResultReviewAyah),
        ),
      ],
    );
  }
}
