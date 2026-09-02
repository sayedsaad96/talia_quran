import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/quran_audio_player_cubit.dart';
import 'reciter_selector_sheet.dart';

class QuranMiniPlayerBar extends StatelessWidget {
  const QuranMiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
      builder: (context, state) {
        if (!state.hasActiveAudio) {
          return const SizedBox.shrink();
        }

        final isDark = context.isDark;
        final primary = isDark ? AppColors.primaryLight : AppColors.primary;
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
                ? 'الآية ${state.currentAyahNumber}'
                : 'Ayah ${state.currentAyahNumber}')
            : '';

        return Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              onTap: () {
                HapticFeedback.selectionClick();
                if (state.currentPageNumber != null) {
                  context.push('/quran/page/${state.currentPageNumber}');
                } else if (state.currentSurahId != null) {
                  context.push('/quran/surah/${state.currentSurahId}');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: primary.withValues(alpha: 0.28), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: isDark ? 0.16 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Play/Pause Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<QuranAudioPlayerCubit>().togglePlayPause();
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: primary.withValues(alpha: 0.3)),
                        ),
                        child: Center(
                          child: state.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
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
                                  size: 26,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Next Ayah Button
                    if (state.hasNext)
                      IconButton(
                        icon: Icon(
                          context.isArabic
                              ? Icons.skip_previous_rounded
                              : Icons.skip_next_rounded,
                          size: 22,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        tooltip: context.isArabic ? 'الآية التالية' : 'Next Ayah',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.read<QuranAudioPlayerCubit>().nextAyah();
                        },
                        visualDensity: VisualDensity.compact,
                      ),

                    // Surah & Reciter Info
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  surahName,
                                  style: AppTypography.titleSmall.copyWith(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: context.isArabic ? 'Amiri' : null,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (ayahText.isNotEmpty) ...[
                                Text(
                                  ' • $ayahText',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.record_voice_over_rounded,
                                size: 12,
                                color: isDark
                                    ? AppColors.darkTextHint
                                    : AppColors.lightTextHint,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Reciter switch button
                    IconButton(
                      icon: Icon(
                        Icons.swap_vert_rounded,
                        size: 20,
                        color: primary,
                      ),
                      tooltip: context.isArabic ? 'تغيير القارئ' : 'Change Reciter',
                      onPressed: () => ReciterSelectorSheet.show(context),
                      visualDensity: VisualDensity.compact,
                    ),

                    // Stop / Close Button
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextHint
                            : AppColors.lightTextHint,
                      ),
                      tooltip: context.isArabic ? 'إغلاق المشغل' : 'Close Player',
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
          ),
        );
      },
    );
  }
}
