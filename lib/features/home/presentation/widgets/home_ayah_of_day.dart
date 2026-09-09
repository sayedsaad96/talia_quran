import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/ayah_listen_button.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../domain/entities/ayah_of_day.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';

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
    return Semantics(
      button: true,
      label: context.l10n.homeAyahOfDay,
      hint: reference,
      child: GlassPanel(
        skin: skin,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => context.push('/quran/page/${ayah.pageNumber}'),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: skin.gold,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.l10n.homeAyahOfDay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          color: skin.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AyahListenButton(
                            surahId: ayah.surahId,
                            ayahNumber: ayah.ayahNumber,
                            size: AyahListenButtonSize.small,
                          ),
                          IconButton(
                            tooltip: context.l10n.share,
                            visualDensity: VisualDensity.compact,
                            color: skin.textSecondary,
                            onPressed: () {
                              SocialShareSheet.show(
                                context,
                                SocialShareData.quranVerse(
                                  ayahText: ayah.text,
                                  surahName: surahName,
                                  ayahNumber: ayah.ayahNumber,
                                ),
                              );
                            },
                            icon: const Icon(Icons.share_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ayah.text,
                  textAlign: TextAlign.center,
                  style: AppTypography.quranMedium.copyWith(
                    color: skin.textPrimary,
                    height: 1.9,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  reference,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: skin.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
