import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../theme/kids_theme.dart';

class KidsStageDetails extends StatelessWidget {
  const KidsStageDetails({
    super.key,
    required this.stage,
    required this.surahName,
    this.onStartMission,
  });

  final KidsJourneyStage stage;
  final String surahName;
  final VoidCallback? onStartMission;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RibbonHeader(stage: stage, surahName: surahName),
        const SizedBox(height: AppSpacing.lg),
        _MissionStep(
          icon: Icons.headphones_rounded,
          title: context.l10n.kidsGamifiedListenStep,
          subtitle: context.l10n.kidsGamifiedListenStepSubtitle,
          color: KidsTheme.forestGreen,
        ),
        const SizedBox(height: AppSpacing.sm),
        _MissionStep(
          icon: Icons.record_voice_over_rounded,
          title: context.l10n.kidsGamifiedRepeatStep,
          subtitle: context.l10n.kidsGamifiedRepeatStepSubtitle,
          color: KidsTheme.goldWarm,
        ),
        const SizedBox(height: AppSpacing.sm),
        _MissionStep(
          icon: Icons.psychology_alt_rounded,
          title: context.l10n.kidsGamifiedTestStep,
          subtitle: context.l10n.kidsGamifiedTestStepSubtitle,
          color: KidsTheme.reviewPurple,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onStartMission,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(context.l10n.kidsGamifiedStartMission),
          style: FilledButton.styleFrom(
            backgroundColor: KidsTheme.forestGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
            shape: const RoundedRectangleBorder(
              borderRadius: KidsTheme.buttonRadius,
            ),
            textStyle: AppTypography.titleMedium.copyWith(
              fontFamily: 'Amiri',
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _RibbonHeader extends StatelessWidget {
  const _RibbonHeader({required this.stage, required this.surahName});

  final KidsJourneyStage stage;
  final String surahName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: KidsTheme.backgroundGradient,
        borderRadius: KidsTheme.cardRadius,
      ),
      child: Column(
        children: [
          Image.asset(
            KidsTheme.ribbonBannerAsset,
            height: 72,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.kidsGamifiedHouseTitle(stage.stageNumber),
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontFamily: 'Amiri',
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$surahName • ${context.l10n.kidsGamifiedAyahRange(stage.startAyah, stage.endAyah)}',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionStep extends StatelessWidget {
  const _MissionStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: KidsTheme.nightSkyDark,
                    fontFamily: 'Amiri',
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: KidsTheme.nightSkyMid.withValues(alpha: 0.72),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
