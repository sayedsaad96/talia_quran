import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../theme/kids_theme.dart';

class KidsHouseCard extends StatelessWidget {
  const KidsHouseCard({
    super.key,
    required this.stage,
    this.surahName,
    this.onTap,
    this.onLockedTap,
    this.width = 172,
  });

  final KidsJourneyStage stage;
  final String? surahName;
  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;
  final double width;

  bool get _isLocked => stage.status == KidsJourneyStageStatus.locked;

  @override
  Widget build(BuildContext context) {
    final colors = _HouseColors.forStatus(stage.status);
    final l10n = context.l10n;
    final title = stage.status == KidsJourneyStageStatus.needsReview
        ? l10n.kidsGamifiedReviewHouseTitle(stage.stageNumber)
        : l10n.kidsGamifiedHouseTitle(stage.stageNumber);
    final statusLabel = switch (stage.status) {
      KidsJourneyStageStatus.locked => l10n.kidsGamifiedLockedStage,
      KidsJourneyStageStatus.current => l10n.kidsGamifiedCurrentStage,
      KidsJourneyStageStatus.completed => l10n.kidsGamifiedCompletedStage,
      KidsJourneyStageStatus.needsReview => l10n.kidsGamifiedNeedsReview,
    };

    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: colors.background,
        borderRadius: KidsTheme.cardRadius,
        border: Border.all(color: colors.border, width: 2.0),
        boxShadow: colors.shadows,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                _assetForStatus(stage.status),
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),
              if (_isLocked)
                const Positioned(
                  right: 10,
                  top: 10,
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white70,
                    size: 26,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              color: colors.text,
              fontFamily: 'Amiri',
              letterSpacing: 0,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (surahName != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              surahName!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(
                color: colors.secondaryText,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.kidsGamifiedAyahRange(stage.startAyah, stage.endAyah),
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: colors.secondaryText,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: stage.progress.clamp(0, 1).toDouble(),
              backgroundColor: colors.progressTrack,
              valueColor: AlwaysStoppedAnimation<Color>(colors.progress),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(colors.statusIcon, size: 14, color: colors.progress),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  '${l10n.kidsGamifiedProgressCount(stage.completedCount, stage.totalAyahs)} • $statusLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.secondaryText,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Add animations based on status (bypassed in test environment)
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      if (stage.status == KidsJourneyStageStatus.current) {
        cardContent = cardContent
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.04, duration: 2.seconds, curve: Curves.easeInOut)
            .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.15));
      } else if (stage.status == KidsJourneyStageStatus.completed) {
        cardContent = cardContent
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 4.seconds, color: Colors.white.withValues(alpha: 0.3), delay: 2.seconds);
      }
    }

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLocked ? onLockedTap : onTap,
          borderRadius: KidsTheme.cardRadius,
          child: cardContent,
        ),
      ),
    );
  }

  static String _assetForStatus(KidsJourneyStageStatus status) =>
      switch (status) {
        KidsJourneyStageStatus.locked => KidsTheme.houseLockedAsset,
        KidsJourneyStageStatus.current => KidsTheme.houseCurrentAsset,
        KidsJourneyStageStatus.completed => KidsTheme.houseCompletedAsset,
        KidsJourneyStageStatus.needsReview => KidsTheme.houseReviewAsset,
      };
}

class _HouseColors {
  const _HouseColors({
    required this.background,
    required this.border,
    required this.text,
    required this.secondaryText,
    required this.progress,
    required this.progressTrack,
    required this.statusIcon,
    required this.shadows,
  });

  final Gradient background;
  final Color border;
  final Color text;
  final Color secondaryText;
  final Color progress;
  final Color progressTrack;
  final IconData statusIcon;
  final List<BoxShadow> shadows;

  static _HouseColors forStatus(KidsJourneyStageStatus status) {
    return switch (status) {
      KidsJourneyStageStatus.locked => _HouseColors(
        background: LinearGradient(
          colors: [
            KidsTheme.lockedSurface,
            KidsTheme.lockedGrey.withValues(alpha: 0.76),
          ],
        ),
        border: KidsTheme.lockedGrey.withValues(alpha: 0.52),
        text: Colors.white,
        secondaryText: Colors.white.withValues(alpha: 0.72),
        progress: KidsTheme.lockedGrey,
        progressTrack: Colors.white.withValues(alpha: 0.16),
        statusIcon: Icons.lock_rounded,
        shadows: const [],
      ),
      KidsJourneyStageStatus.current => _HouseColors(
        background: KidsTheme.currentHouseGradient,
        border: KidsTheme.mintGlow,
        text: Colors.white,
        secondaryText: Colors.white.withValues(alpha: 0.82),
        progress: KidsTheme.goldStar,
        progressTrack: Colors.white.withValues(alpha: 0.22),
        statusIcon: Icons.play_arrow_rounded,
        shadows: KidsTheme.softGlow,
      ),
      KidsJourneyStageStatus.completed => _HouseColors(
        background: KidsTheme.completedHouseGradient,
        border: KidsTheme.goldStar,
        text: KidsTheme.nightSkyDark,
        secondaryText: KidsTheme.nightSkyMid.withValues(alpha: 0.72),
        progress: KidsTheme.forestGreen,
        progressTrack: Colors.white.withValues(alpha: 0.55),
        statusIcon: Icons.star_rounded,
        shadows: KidsTheme.goldGlow,
      ),
      KidsJourneyStageStatus.needsReview => _HouseColors(
        background: const LinearGradient(
          colors: [KidsTheme.reviewPurple, Color(0xFF5B21B6)],
        ),
        border: const Color(0xFFC4B5FD),
        text: Colors.white,
        secondaryText: Colors.white.withValues(alpha: 0.82),
        progress: KidsTheme.goldStar,
        progressTrack: Colors.white.withValues(alpha: 0.22),
        statusIcon: Icons.refresh_rounded,
        shadows: const [
          BoxShadow(
            color: Color(0x557C3AED),
            blurRadius: 22,
            spreadRadius: 2,
            offset: Offset(0, 8),
          ),
        ],
      ),
    };
  }
}
