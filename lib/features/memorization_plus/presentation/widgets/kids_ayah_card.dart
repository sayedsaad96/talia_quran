import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/qcf_hifz_verse_view.dart';
import '../theme/kids_theme.dart';

class KidsAyahCard extends StatelessWidget {
  const KidsAyahCard({
    super.key,
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
    this.isCompleted = false,
    this.isAudioLoading = false,
    this.audioUnavailable = false,
  });

  final int surahId;
  final int ayahNumber;
  final String ayahText;
  final bool isCompleted;
  final bool isAudioLoading;
  final bool audioUnavailable;

  @override
  Widget build(BuildContext context) {
    final audioMessage = audioUnavailable
        ? context.l10n.kidsGamifiedAudioUnavailable
        : isAudioLoading
        ? context.l10n.kidsGamifiedAudioLoading
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: KidsTheme.parchmentGradient,
        borderRadius: KidsTheme.cardRadius,
        border: Border.all(color: KidsTheme.parchmentEdge, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: KidsTheme.forestGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${context.l10n.ayah} $ayahNumber',
                    style: AppTypography.labelMedium.copyWith(
                      color: KidsTheme.forestGreen,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.auto_stories_rounded,
                  color: KidsTheme.houseBrown.withValues(alpha: 0.42),
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // The card always has a cream/parchment background, so we
            // always use a dark text color for readability — even in dark
            // mode where the theme's default text color would be too light.
            Theme(
              data: Theme.of(context).copyWith(brightness: Brightness.light),
              child: QcfHifzVerseView(
                surahNumber: surahId,
                verseNumber: ayahNumber,
                fallbackText: ayahText,
                isUnlocked: true,
                isMemorized: isCompleted,
                displayMode: HifzVerseDisplayMode.single,
                textAlign: TextAlign.center,
              ),
            ),
            if (audioMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _AudioStatusMessage(
                message: audioMessage,
                isLoading: isAudioLoading && !audioUnavailable,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AudioStatusMessage extends StatelessWidget {
  const _AudioStatusMessage({required this.message, required this.isLoading});

  final String message;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: KidsTheme.goldStar.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: KidsTheme.goldStar.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.volume_off_rounded,
              color: KidsTheme.houseBrown,
              size: 20,
            ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: KidsTheme.nightSkyDark,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
