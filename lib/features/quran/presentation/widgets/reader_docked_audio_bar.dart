import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/experience/experience_feature_flags.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/services/sleep_timer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/quran_audio_player_cubit.dart';
import 'quran_audio_equalizer.dart';
import 'reader_repeat_sheet.dart';

/// Docked audio bar for the adult reader (presentation only).
///
/// Replaces the floating overlay player: it participates in the reader
/// layout directly above the footer instead of covering the Mushaf. It reads
/// the same [QuranAudioPlayerCubit] — no second controller or audio state.
class ReaderDockedAudioBar extends StatelessWidget {
  const ReaderDockedAudioBar({super.key, this.showRepeatControls});

  /// Overrides the [ExperienceFeature.readerRepeat] lookup (tests).
  final bool? showRepeatControls;

  bool get _repeatEnabled {
    final override = showRepeatControls;
    if (override != null) return override;
    try {
      return getIt.isRegistered<ExperienceFlags>() &&
          getIt<ExperienceFlags>().isEnabled(ExperienceFeature.readerRepeat);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
      builder: (context, state) {
        if (!state.hasActiveAudio) {
          return const SizedBox.shrink();
        }

        final isDark = context.isDark;
        final primary = context.tokens.accent;
        final bg = isDark ? AppColors.parchmentDark : AppColors.parchmentLight;
        final surahName = context.isArabic
            ? SurahNames.nameAr(state.currentSurahId)
            : SurahNames.nameEn(state.currentSurahId);
        final ayahText = state.currentAyahNumber != null
            ? (context.isArabic
                  ? 'آية ${context.numText(state.currentAyahNumber!)}'
                  : 'Ayah ${context.numText(state.currentAyahNumber!)}')
            : '';

        return Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              top: BorderSide(
                color: primary.withValues(alpha: 0.18),
                width: 0.8,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              IconButton(
                icon: state.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      )
                    : Icon(
                        state.isPlaying ? TaliaIcons.pause : TaliaIcons.play,
                        color: primary,
                        size: 24,
                      ),
                tooltip: state.isPlaying
                    ? context.l10n.pause
                    : context.l10n.play,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<QuranAudioPlayerCubit>().togglePlayPause();
                },
                style: IconButton.styleFrom(
                  backgroundColor: primary.withValues(alpha: 0.1),
                  minimumSize: const Size(48, 48),
                ),
              ),
              if (state.hasPrevious)
                IconButton(
                  icon: Icon(
                    context.isArabic
                        ? TaliaIcons.skipNext
                        : TaliaIcons.skipPrevious,
                    size: 20,
                    color: primary,
                  ),
                  tooltip: context.l10n.prevAyah,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.read<QuranAudioPlayerCubit>().previousAyah();
                  },
                  visualDensity: VisualDensity.compact,
                ),
              if (state.hasNext)
                IconButton(
                  icon: Icon(
                    context.isArabic
                        ? TaliaIcons.skipPrevious
                        : TaliaIcons.skipNext,
                    size: 20,
                    color: primary,
                  ),
                  tooltip: context.l10n.nextAyah,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.read<QuranAudioPlayerCubit>().nextAyah();
                  },
                  visualDensity: VisualDensity.compact,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          ayahText.isEmpty
                              ? surahName
                              : '$surahName • $ayahText',
                          style: AppTypography.titleSmall.copyWith(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontFamily: context.isArabic ? 'Amiri' : null,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      QuranAudioEqualizer(
                        isPlaying: state.isPlaying,
                        color: primary,
                        maxHeight: 12,
                        barWidth: 2.2,
                      ),
                    ],
                  ),
                ),
              ),
              if (_repeatEnabled)
                IconButton(
                  key: const ValueKey('reader-repeat-button'),
                  icon: Icon(
                    TaliaIcons.repeat,
                    size: 20,
                    color: state.repeat.isDefault &&
                            state.sleepChoice == SleepTimerChoice.off
                        ? context.tokens.textHint
                        : primary,
                  ),
                  tooltip: context.l10n.readerRepeatTitle,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ReaderRepeatSheet.show(context);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              IconButton(
                icon: Icon(
                  TaliaIcons.close,
                  size: 18,
                  color: context.tokens.textHint,
                ),
                tooltip: context.l10n.stopRecitation,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<QuranAudioPlayerCubit>().stop();
                },
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
      },
    );
  }
}
