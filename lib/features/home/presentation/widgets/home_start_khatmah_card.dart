import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';

class HomeStartKhatmahCard extends StatelessWidget {
  const HomeStartKhatmahCard({
    super.key,
    required this.skin,
    required this.isDark,
    this.onStart,
  });

  final HomeSkin skin;
  final bool isDark;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final handleStart = onStart ?? () => context.push(AppRoutes.khatmahSetup);
    final headline = context.l10n.homeStartKhatmahTitle;
    final subtitle = context.l10n.homeStartKhatmahSubtitle;
    final cta = context.l10n.homeStartKhatmahCta;

    return Semantics(
      button: true,
      label: headline,
      child: GlassPanel(
        skin: skin,
        padding: EdgeInsets.zero,
        gradient: skin.heroGradient,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          onTap: handleStart,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: skin.gold.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 20,
                          color: skin.gold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          headline,
                          style: AppTypography.titleMedium.copyWith(
                            color: skin.textOnHero,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: skin.textOnHeroMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AppButton(
                      label: cta,
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.goldPrimary,
                      onPressed: handleStart,
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
