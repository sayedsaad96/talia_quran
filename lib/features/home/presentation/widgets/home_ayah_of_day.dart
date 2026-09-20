import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../quran/presentation/cubits/quran_audio_player_cubit.dart';
import '../../domain/entities/ayah_of_day.dart';
import '../theme/home_skin.dart';
import 'spring_tap.dart';

class HomeAyahOfDayCard extends StatelessWidget {
  const HomeAyahOfDayCard({
    super.key,
    required this.ayah,
    required this.skin,
  });

  final AyahOfDay ayah;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final surahName = context.isArabic ? ayah.surahNameAr : ayah.surahNameEn;
    final reference = context.l10n.surahAyahFormat(surahName, ayah.ayahNumber);
    final contextLabel = _contextLabel(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          // Tappable Ayah section with spring tap leading to Quran reader page
          Semantics(
            button: true,
            label: contextLabel == null
                ? context.l10n.homeAyahOfDay
                : '${context.l10n.homeAyahOfDay}, $contextLabel',
            hint: reference,
            child: SpringTap(
              onTap: () => context.push('/quran/page/${ayah.pageNumber}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    // Decorative quotation mark
                    Text(
                      '﴿',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 32,
                        color: skin.gold.withValues(alpha: 0.5),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Ayah text — editorial floating
                    Text(
                      ayah.text,
                      textAlign: TextAlign.center,
                      style: AppTypography.quranMedium.copyWith(
                        fontSize: 24,
                        height: 2.0,
                        color: skin.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Closing quotation mark
                    Text(
                      '﴾',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 32,
                        color: skin.gold.withValues(alpha: 0.5),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Surah reference
                    Text(
                      reference,
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: skin.gold,
                      ),
                    ),
                    // Factual surah context (revelation type + ayah count) —
                    // governed data only, never authored interpretation.
                    if (ayah.surahType != null && ayah.surahAyahCount != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          context.l10n.ayahOfDaySurahMeta(
                            _revelationLabel(context, ayah.surahType!),
                            _formatCount(context, ayah.surahAyahCount!),
                          ),
                          style: AppTypography.labelSmall.copyWith(
                            color: skin.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Action icons (Play & Share)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Pause button integrated with app-wide QuranAudioPlayerCubit
              BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
                builder: (context, audioState) {
                  final isThisAyah = audioState.currentSurahId == ayah.surahId &&
                      audioState.currentAyahNumber == ayah.ayahNumber;
                  final isPlaying = isThisAyah && audioState.isPlaying;
                  final isLoading = isThisAyah && audioState.isLoading;

                  if (isLoading) {
                    return SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: skin.gold,
                          ),
                        ),
                      ),
                    );
                  }

                  return _GhostIcon(
                    icon: isPlaying
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    skin: skin,
                    color: isPlaying ? skin.gold : null,
                    onTap: () async {
                      final cubit = context.read<QuranAudioPlayerCubit>();
                      try {
                        if (isPlaying) {
                          await cubit.pause();
                        } else if (isThisAyah && audioState.isPaused) {
                          await cubit.resume();
                        } else {
                          await cubit.playAyah(ayah.surahId, ayah.ayahNumber);
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.audioPlayError),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
              const SizedBox(width: AppSpacing.lg),
              // Read the full surah
              _GhostIcon(
                icon: Icons.menu_book_outlined,
                skin: skin,
                onTap: () => context.push('/quran/surah/${ayah.surahId}'),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Share button
              _GhostIcon(
                icon: Icons.share_outlined,
                skin: skin,
                onTap: () {
                  SocialShareSheet.show(
                    context,
                    SocialShareData.quranVerse(
                      ayahText: ayah.text,
                      surahName: surahName,
                      ayahNumber: ayah.ayahNumber,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Factual revelation label — Meccan/Medinan is well-established Quran
  /// structure data, not authored interpretation.
  String _revelationLabel(BuildContext context, String surahType) {
    final l10n = context.l10n;
    return surahType == 'medinan'
        ? l10n.surahRevelationMedinan
        : l10n.surahRevelationMeccan;
  }

  String _formatCount(BuildContext context, int count) {
    final isArabic = context.isArabic;
    return isArabic
        ? MushafHizbHelper.toArabicNumber(count)
        : count.toString();
  }

  String? _contextLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (ayah.context) {
      DailyAyahContext.general => null,
      DailyAyahContext.friday => l10n.homeAyahContextFriday,
      DailyAyahContext.ramadanStart => l10n.homeAyahContextRamadanStart,
      DailyAyahContext.ramadan => l10n.homeAyahContextRamadan,
      DailyAyahContext.lastTenNights => l10n.homeAyahContextLastTenNights,
      DailyAyahContext.dhulHijjah => l10n.homeAyahContextDhulHijjah,
      DailyAyahContext.arafah => l10n.homeAyahContextArafah,
      DailyAyahContext.eidAlAdha => l10n.homeAyahContextEidAlAdha,
      DailyAyahContext.reading => l10n.homeAyahContextReading,
      DailyAyahContext.memorization => l10n.homeAyahContextMemorization,
      DailyAyahContext.smartReview => l10n.homeAyahContextSmartReview,
      DailyAyahContext.azkar => l10n.homeAyahContextAzkar,
      DailyAyahContext.childJourney => l10n.homeAyahContextChildJourney,
    };
  }
}

class _GhostIcon extends StatelessWidget {
  const _GhostIcon({
    required this.icon,
    required this.skin,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final HomeSkin skin;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 26),
      color: color ?? skin.textSecondary.withValues(alpha: 0.7),
      splashRadius: 22,
    );
  }
}
