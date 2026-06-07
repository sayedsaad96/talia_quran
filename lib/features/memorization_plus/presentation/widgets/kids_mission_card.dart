import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../theme/kids_theme.dart';

class KidsMissionCard extends StatelessWidget {
  const KidsMissionCard({
    super.key,
    required this.stage,
    this.surahName,
    this.onContinue,
  });

  final KidsJourneyStage? stage;
  final String? surahName;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final currentStage = stage;
    final title = currentStage == null
        ? context.l10n.kidsStartFirstStageToday
        : context.l10n.kidsGamifiedHouseTitle(currentStage.stageNumber);
    final subtitle = currentStage == null
        ? context.l10n.kidsFirstMissionSubtitle
        : [
            ?surahName,
            context.l10n.kidsGamifiedAyahRange(
              currentStage.startAyah,
              currentStage.endAyah,
            ),
            context.l10n.kidsGamifiedProgressCount(
              currentStage.completedCount,
              currentStage.totalAyahs,
            ),
          ].join(' • ');

    final banner = Image.asset(
      KidsTheme.ribbonBannerAsset,
      width: 64,
      height: 64,
      fit: BoxFit.contain,
    );

    final missionText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.kidsGamifiedLastMission,
          style: AppTypography.labelMedium.copyWith(
            color: KidsTheme.forestGreen,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleLarge.copyWith(
            color: KidsTheme.nightSkyDark,
            fontFamily: 'Amiri',
            letterSpacing: 0,
          ),
        ),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: KidsTheme.nightSkyMid.withValues(alpha: 0.72),
            letterSpacing: 0,
          ),
        ),
      ],
    );

    final continueButton = FilledButton(
      onPressed: onContinue,
      style: FilledButton.styleFrom(
        backgroundColor: KidsTheme.forestGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: const RoundedRectangleBorder(
          borderRadius: KidsTheme.buttonRadius,
        ),
      ),
      child: Text(
        context.l10n.kidsGamifiedContinueNow,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactLayout = constraints.maxWidth < 340;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: KidsTheme.creamParchment,
            borderRadius: KidsTheme.cardRadius,
            border: Border.all(color: KidsTheme.parchmentEdge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: useCompactLayout
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        banner,
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: missionText),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    continueButton,
                  ],
                )
              : Row(
                  children: [
                    banner,
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: missionText),
                    const SizedBox(width: AppSpacing.sm),
                    continueButton,
                  ],
                ),
        );
      },
    );
  }
}
