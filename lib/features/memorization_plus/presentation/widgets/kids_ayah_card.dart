import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/memorization_ayah_display.dart';
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
    this.recalledWords,
  });

  final int surahId;
  final int ayahNumber;
  final String ayahText;
  final bool isCompleted;
  final bool isAudioLoading;
  final bool audioUnavailable;

  /// K32 — after a miss, the words the child recited right are tinted.
  final List<bool>? recalledWords;

  @override
  Widget build(BuildContext context) {
    final audioMessage = audioUnavailable
        ? context.l10n.kidsGamifiedAudioUnavailable
        : isAudioLoading
        ? context.l10n.kidsGamifiedAudioLoading
        : null;

    final borderColor = isCompleted
        ? KidsTheme.forestGreen
        : KidsTheme.goldStar.withValues(alpha: 0.7);
    final borderShadow = isCompleted
        ? const [
            BoxShadow(
              color: AppColors.primaryGlow,
              blurRadius: 18,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ]
        : KidsTheme.card25DShadow;

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: KidsTheme.parchmentGradient,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppSpacing.radiusXl),
          ),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: borderShadow,
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
                      gradient: KidsTheme.completedHouseGradient,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${context.l10n.ayah} ${context.numText(ayahNumber)}',
                          style: AppTypography.labelLarge.copyWith(
                            color: KidsTheme.inkOnParchment,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
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
              // The card always has a parchment background, so its Quran text
              // stays dark even when the app itself uses a dark theme.
              MemorizationAyahDisplay(
                text: ayahText,
                surahId: surahId,
                ayahNumber: ayahNumber,
                textColor: KidsTheme.nightSkyDark,
                decorationColor: KidsTheme.houseBrown.withValues(alpha: 0.5),
                referenceColor: KidsTheme.forestGreen,
                isCompleted: isCompleted,
                wordHighlights: recalledWords,
                highlightColor: KidsTheme.forestGreen.withValues(alpha: 0.18),
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
