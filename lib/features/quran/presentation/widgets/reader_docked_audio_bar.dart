import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/quran_audio_player_cubit.dart';

/// Docked audio bar for the adult reader (presentation only).
///
/// Replaces the floating overlay player: it participates in the reader
/// layout directly above the footer instead of covering the Mushaf. It reads
/// the same [QuranAudioPlayerCubit] — no second controller or audio state.
class ReaderDockedAudioBar extends StatelessWidget {
  const ReaderDockedAudioBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
      builder: (context, state) {
        if (!state.hasActiveAudio) {
          return const SizedBox.shrink();
        }

        final isDark = context.isDark;
        final primary = isDark ? AppColors.primaryLight : AppColors.primary;
        final bg = isDark ? AppColors.parchmentDark : AppColors.parchmentLight;
        final surahName = context.isArabic
            ? SurahNames.nameAr(state.currentSurahId)
            : SurahNames.nameEn(state.currentSurahId);
        final ayahText = state.currentAyahNumber != null
            ? (context.isArabic
                ? 'آية ${state.currentAyahNumber}'
                : 'Ayah ${state.currentAyahNumber}')
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
                        state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
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
                        ? Icons.skip_next_rounded
                        : Icons.skip_previous_rounded,
                    size: 20,
                    color: primary,
                  ),
                  tooltip: context.isArabic ? 'الآية السابقة' : 'Previous Ayah',
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
                        ? Icons.skip_previous_rounded
                        : Icons.skip_next_rounded,
                    size: 20,
                    color: primary,
                  ),
                  tooltip: context.isArabic ? 'الآية التالية' : 'Next Ayah',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.read<QuranAudioPlayerCubit>().nextAyah();
                  },
                  visualDensity: VisualDensity.compact,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
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
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextHint
                      : AppColors.lightTextHint,
                ),
                tooltip: context.isArabic ? 'إيقاف التلاوة' : 'Stop Recitation',
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
