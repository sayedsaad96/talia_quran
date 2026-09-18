import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/home_skin.dart';
import 'islamic_pattern_painter.dart';
import 'spring_tap.dart';

class HomeFirstRun extends StatelessWidget {
  const HomeFirstRun({super.key, required this.skin});

  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: () => context.push(AppRoutes.quran),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          gradient: skin.meshGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: skin.shadow,
        ),
        child: Stack(
          children: [
            IslamicPatternOverlay(
              color: skin.textOnHero,
              opacity: skin.heroCardTextureOpacity,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.homeFirstRunTitle,
                  style: AppTypography.displaySmall.copyWith(
                    color: skin.textOnHero,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.homeFirstRunBody,
                  style: AppTypography.bodyMedium.copyWith(
                    color: skin.textOnHeroMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      context.l10n.homeFirstRunRead,
                      style: AppTypography.labelMedium.copyWith(
                        color: skin.textOnHero,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
