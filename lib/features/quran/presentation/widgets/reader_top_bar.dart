import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/quran_continuous_player_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../cubits/quran_audio_player_cubit.dart';

/// Minimal top bar of the adult Mushaf reader (presentation only):
/// `[Back] [Surah • Juz • Page] [Primary audio action] [⋯]`.
///
/// Secondary actions (reciter, focus mode) live in the overflow sheet.
/// Routine actions use the primary color; gold is reserved for progress.
class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.surahName,
    required this.juzNumber,
    required this.pageNumber,
    required this.primary,
    required this.bg,
    required this.onBack,
    required this.onOpenMenu,
  });

  final String surahName;
  final int juzNumber;
  final int pageNumber;
  final Color primary;
  final Color bg;
  final VoidCallback onBack;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(
            color: primary.withValues(alpha: 0.14),
            width: 0.8,
          ),
        ),
      ),
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xs,
        end: AppSpacing.xs,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onBack();
            },
            tooltip: context.l10n.closeReader,
            icon: Icon(
              context.isArabic
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
            ),
            color: primary,
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  surahName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.quranHeader.copyWith(
                    color: primary,
                    height: 1.4,
                  ),
                ),
                Text(
                  context.isArabic
                      ? 'الجزء ${MushafHizbHelper.getJuzName(juzNumber)} • ${context.l10n.page} $pageNumber'
                      : 'Juz $juzNumber • ${context.l10n.page} $pageNumber',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: primary.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
            builder: (context, audioState) {
              final isPlayingThisPage =
                  audioState.scope == PlayScope.page &&
                  audioState.currentPageNumber == pageNumber &&
                  audioState.hasActiveAudio;
              final isPlaying = isPlayingThisPage && audioState.isPlaying;
              final isLoading = isPlayingThisPage && audioState.isLoading;

              return IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.read<QuranAudioPlayerCubit>().playPage(pageNumber);
                },
                tooltip: isPlaying
                    ? (context.isArabic ? 'إيقاف التلاوة' : 'Pause Recitation')
                    : (context.isArabic ? 'تلاوة الصفحة' : 'Play Page'),
                icon: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : (isPlayingThisPage
                                  ? Icons.play_circle_fill_rounded
                                  : Icons.play_circle_outline_rounded),
                      ),
                color: primary,
                style: IconButton.styleFrom(
                  backgroundColor: primary.withValues(
                    alpha: isPlayingThisPage ? 0.20 : 0.08,
                  ),
                  minimumSize: const Size(48, 48),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onOpenMenu();
            },
            tooltip: context.isArabic ? 'المزيد' : 'More',
            icon: const Icon(Icons.more_vert_rounded),
            color: primary,
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
    );
  }
}
