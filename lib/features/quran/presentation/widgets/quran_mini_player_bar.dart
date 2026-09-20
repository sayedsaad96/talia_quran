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
import 'quran_audio_equalizer.dart';
import 'reciter_selector_sheet.dart';

/// Premium floating bottom mini-player bar for continuous Quran recitation.
///
/// Features:
/// - Ornate Mushaf artwork badge with glowing state during playback
/// - Dynamic animated audio wave equalizer reacting to playing/paused states
/// - Micro-progress line indicating progress through the Surah
/// - Quick controls: previous, play/pause, next, reciter selector, and close
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
        final primary = isDark ? AppColors.goldLight : AppColors.primary;
        final bg = isDark ? const Color(0xFF14241D) : Colors.white;
        final borderColor = isDark
            ? AppColors.goldLight.withValues(alpha: 0.32)
            : AppColors.primary.withValues(alpha: 0.22);

        final surahName = context.isArabic
            ? SurahNames.nameAr(state.currentSurahId)
            : SurahNames.nameEn(state.currentSurahId);

        final reciterName = state.reciter != null
            ? (context.isArabic ? state.reciter!.nameAr : state.reciter!.nameEn)
            : '';

        final currentAyah = state.currentAyahNumber ?? 1;
        final totalAyahs = SurahNames.ayahCount(state.currentSurahId);
        final progress = totalAyahs > 0 ? (currentAyah / totalAyahs).clamp(0.0, 1.0) : 0.0;

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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : AppColors.primary)
                            .withValues(alpha: isDark ? 0.45 : 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      if (state.isPlaying)
                        BoxShadow(
                          color: (isDark ? AppColors.goldLight : AppColors.primary)
                              .withValues(alpha: isDark ? 0.14 : 0.08),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Micro Progress Line
                      if (totalAyahs > 0)
                        SizedBox(
                          height: 2.5,
                          child: Stack(
                            children: [
                              Container(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.06),
                              ),
                              FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        isDark ? AppColors.goldLight : AppColors.primaryLight,
                                        isDark ? AppColors.primaryLight : AppColors.primary,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            // 1. Ornate Artwork / Mushaf Badge
                            _MushafArtworkBadge(
                              surahId: state.currentSurahId,
                              isPlaying: state.isPlaying,
                              isDark: isDark,
                              accentColor: primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),

                            // 2. Surah & Reciter Details + Equalizer Wave
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
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: context.isArabic ? 'Amiri' : null,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primary.withValues(alpha: isDark ? 0.16 : 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          context.isArabic
                                              ? 'آية $currentAyah'
                                              : 'Ayah $currentAyah',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Animated Sound Wave
                                      QuranAudioEqualizer(
                                        isPlaying: state.isPlaying,
                                        color: isDark
                                            ? AppColors.goldLight
                                            : AppColors.primary,
                                        maxHeight: 14,
                                        barWidth: 2.5,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.record_voice_over_rounded,
                                        size: 13,
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
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                            fontSize: 11.5,
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

                            // 3. Skip Previous
                            if (state.hasPrevious)
                              IconButton(
                                icon: Icon(
                                  context.isArabic
                                      ? Icons.skip_next_rounded
                                      : Icons.skip_previous_rounded,
                                  size: 20,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                tooltip: context.isArabic ? 'الآية السابقة' : 'Previous Ayah',
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  context.read<QuranAudioPlayerCubit>().previousAyah();
                                },
                                visualDensity: VisualDensity.compact,
                              ),

                            // 4. Play / Pause Button with Gradient
                            _PlayPausePillButton(
                              state: state,
                              primary: primary,
                              isDark: isDark,
                            ),

                            // 5. Skip Next
                            if (state.hasNext)
                              IconButton(
                                icon: Icon(
                                  context.isArabic
                                      ? Icons.skip_previous_rounded
                                      : Icons.skip_next_rounded,
                                  size: 20,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                tooltip: context.isArabic ? 'الآية التالية' : 'Next Ayah',
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  context.read<QuranAudioPlayerCubit>().nextAyah();
                                },
                                visualDensity: VisualDensity.compact,
                              ),

                            // 6. Reciter Switcher
                            IconButton(
                              icon: Icon(
                                Icons.swap_vert_rounded,
                                size: 20,
                                color: isDark
                                    ? AppColors.darkTextHint
                                    : AppColors.lightTextHint,
                              ),
                              tooltip: context.isArabic ? 'تغيير القارئ' : 'Change Reciter',
                              onPressed: () => ReciterSelectorSheet.show(context),
                              visualDensity: VisualDensity.compact,
                            ),

                            // 7. Close Button
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MushafArtworkBadge extends StatelessWidget {
  const _MushafArtworkBadge({
    required this.surahId,
    required this.isPlaying,
    required this.isDark,
    required this.accentColor,
  });

  final int? surahId;
  final bool isPlaying;
  final bool isDark;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A2D), const Color(0xFF0F1F17)]
              : [const Color(0xFFFAF6EE), const Color(0xFFEDE4D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isPlaying
              ? accentColor.withValues(alpha: 0.65)
              : accentColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: accentColor,
            size: 22,
          ),
          if (surahId != null)
            Positioned(
              bottom: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$surahId',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayPausePillButton extends StatelessWidget {
  const _PlayPausePillButton({
    required this.state,
    required this.primary,
    required this.isDark,
  });

  final QuranAudioPlayerState state;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<QuranAudioPlayerCubit>().togglePlayPause();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.goldLight, const Color(0xFFC89938)]
                : [AppColors.primaryLight, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.goldLight : AppColors.primary)
                  .withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: state.isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                )
              : Icon(
                  state.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: isDark ? Colors.black : Colors.white,
                  size: 24,
                ),
        ),
      ),
    );
  }
}
