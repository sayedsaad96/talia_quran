import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/quran_audio_player_cubit.dart';
import 'reciter_selector_sheet.dart';

class QuranFloatingAudioPlayer extends StatelessWidget {
  const QuranFloatingAudioPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
      builder: (context, state) {
        if (!state.hasActiveAudio) {
          return const SizedBox.shrink();
        }

        final isDark = context.isDark;
        final gold = isDark ? AppColors.primaryLight : AppColors.primary;
        final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
        final surahName = context.isArabic
            ? SurahNames.nameAr(state.currentSurahId)
            : SurahNames.nameEn(state.currentSurahId);

        final reciterName = state.reciter != null
            ? (context.isArabic
                ? state.reciter!.nameAr
                : state.reciter!.nameEn)
            : '';

        final ayahText = state.currentAyahNumber != null
            ? (context.isArabic
                ? 'آية ${state.currentAyahNumber}'
                : 'Ayah ${state.currentAyahNumber}')
            : '';

        return PositionedDirectional(
          bottom: 16,
          start: 16,
          end: 16,
          child: Material(
            color: Colors.transparent,
            elevation: 8,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: gold.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold.withValues(alpha: isDark ? 0.18 : 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<QuranAudioPlayerCubit>().togglePlayPause();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(color: gold.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: state.isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: gold,
                                ),
                              )
                            : Icon(
                                state.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: gold,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Previous Ayah
                  if (state.hasPrevious)
                    IconButton(
                      icon: Icon(
                        context.isArabic
                            ? Icons.skip_next_rounded
                            : Icons.skip_previous_rounded,
                        size: 20,
                        color: gold,
                      ),
                      tooltip: context.isArabic ? 'الآية السابقة' : 'Previous Ayah',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.read<QuranAudioPlayerCubit>().previousAyah();
                      },
                      visualDensity: VisualDensity.compact,
                    ),

                  // Next Ayah
                  if (state.hasNext)
                    IconButton(
                      icon: Icon(
                        context.isArabic
                            ? Icons.skip_previous_rounded
                            : Icons.skip_next_rounded,
                        size: 20,
                        color: gold,
                      ),
                      tooltip: context.isArabic ? 'الآية التالية' : 'Next Ayah',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.read<QuranAudioPlayerCubit>().nextAyah();
                      },
                      visualDensity: VisualDensity.compact,
                    ),

                  // Surah & Ayah Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$surahName • $ayahText',
                            style: AppTypography.titleSmall.copyWith(
                              color: gold,
                              fontWeight: FontWeight.bold,
                              fontFamily: context.isArabic ? 'Amiri' : null,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (reciterName.isNotEmpty) ...[
                            Text(
                              reciterName,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextHint
                                    : AppColors.lightTextHint,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Reciter button
                  IconButton(
                    icon: Icon(Icons.record_voice_over_rounded, size: 18, color: gold),
                    tooltip: context.isArabic ? 'تغيير القارئ' : 'Change Reciter',
                    onPressed: () => ReciterSelectorSheet.show(context),
                    visualDensity: VisualDensity.compact,
                  ),

                  // Close / Stop button
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
            ),
          ),
        );
      },
    );
  }
}
