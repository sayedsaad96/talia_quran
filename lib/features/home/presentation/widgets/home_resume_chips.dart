import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/quran_continuous_player_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/home_cubit.dart';

class HomeResumeChips extends StatelessWidget {
  const HomeResumeChips({super.key, required this.state, required this.isDark});

  final HomeLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final audio = state.audioResume;
    if (audio == null) return const SizedBox.shrink();
    final name = context.isArabic
        ? SurahNames.nameAr(audio.surahId)
        : SurahNames.nameEn(audio.surahId);
    final label = context.l10n.homeResumeListening(name);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Constrain the chip to the available width so a long surah name
        // (or a large text-scale factor) ellipsizes instead of overflowing
        // the row on narrow phones.
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: Semantics(
            button: true,
            label: label,
            child: InputChip(
              avatar: const Icon(Icons.headphones_rounded, size: 18),
              label: Text(
                label,
                style: AppTypography.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () {
                getIt<QuranContinuousPlayerService>().playAyah(
                  audio.surahId,
                  audio.ayahNumber,
                  reciter: audio.reciter,
                  scope: audio.scope,
                );
              },
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
          ),
        );
      },
    );
  }
}
