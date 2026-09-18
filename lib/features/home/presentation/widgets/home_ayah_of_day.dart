import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
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
    return Semantics(
      button: true,
      label: contextLabel == null
          ? context.l10n.homeAyahOfDay
          : '${context.l10n.homeAyahOfDay}, $contextLabel',
      hint: reference,
      child: SpringTap(
        onTap: () => context.push('/quran/page/${ayah.pageNumber}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  ayah.text,
                  textAlign: TextAlign.center,
                  style: AppTypography.quranMedium.copyWith(
                    fontSize: 24,
                    height: 2.0,
                    color: skin.textPrimary,
                  ),
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
              const SizedBox(height: AppSpacing.md),
              // Ghost action icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GhostIcon(
                    icon: Icons.play_circle_outline_rounded,
                    skin: skin,
                    onTap: () { /* listen */ },
                  ),
                  const SizedBox(width: AppSpacing.lg),
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
        ),
      ),
    );
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
  });

  final IconData icon;
  final HomeSkin skin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      color: skin.textSecondary.withValues(alpha: 0.6),
      splashRadius: 20,
    );
  }
}
