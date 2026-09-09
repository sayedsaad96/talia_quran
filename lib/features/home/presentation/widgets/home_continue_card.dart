import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/continue_recitation.dart';
import '../theme/home_skin.dart';

class HomeContinueCard extends StatelessWidget {
  const HomeContinueCard({
    super.key,
    required this.recitation,
    required this.skin,
  });

  final ContinueRecitation recitation;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final name = recitation.surahId != null
        ? (context.isArabic
              ? SurahNames.nameAr(recitation.surahId)
              : SurahNames.nameEn(recitation.surahId))
        : recitation.surahName;
    final range = recitation.startAyah != null && recitation.endAyah != null
        ? context.l10n.homeAyahRange(recitation.startAyah!, recitation.endAyah!)
        : null;
    final count = recitation.unit == ContinueRecitationUnit.pages
        ? context.l10n.homePageProgressCount(
            recitation.current,
            recitation.total,
          )
        : context.l10n.homeAyahProgressCount(
            recitation.current,
            recitation.total,
          );
    final percent = (recitation.percent * 100).round().clamp(0, 100);

    return Semantics(
      button: true,
      label: '${context.l10n.homeContinueRecitation}. $name',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          onTap: () => context.push(recitation.route),
          child: Ink(
            decoration: BoxDecoration(
              gradient: skin.heroGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: skin.shadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: Stack(
                children: [
                  PositionedDirectional(
                    end: -70,
                    top: -70,
                    child: IgnorePointer(
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              skin.gold.withValues(alpha: 0.28),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.play_circle_fill_rounded,
                              size: 16,
                              color: skin.gold,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                context.l10n.homeContinueRecitation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMedium.copyWith(
                                  color: skin.textOnHeroMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: _ContinuePill(skin: skin),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.displaySmall.copyWith(
                            fontSize: 26,
                            color: skin.textOnHero,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (range != null)
                          Text(
                            range,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: skin.textOnHeroMuted,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          child: LinearProgressIndicator(
                            value: recitation.percent.clamp(0.0, 1.0),
                            minHeight: 6,
                            color: skin.gold,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.16,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                count,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: skin.textOnHeroMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '$percent%',
                              style: AppTypography.labelMedium.copyWith(
                                color: skin.gold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
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
  }
}

class _ContinuePill extends StatelessWidget {
  const _ContinuePill({required this.skin});
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.homeContinueAction,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: skin.textOnHero,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Icon(context.forwardChevron, size: 12, color: skin.textOnHero),
        ],
      ),
    );
  }
}
