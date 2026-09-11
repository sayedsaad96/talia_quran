import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../theme/kids_theme.dart';

/// 2.5D companion hero card featuring the child's memorization companion,
/// level progression, motivation, and collected star count.
class KidsProgressHeader extends StatelessWidget {
  const KidsProgressHeader({
    super.key,
    required this.progress,
    this.childName,
    this.onAvatarTap,
    this.onSettingsTap,
  });

  final KidsProgress progress;
  final String? childName;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final levelProgress = (progress.levelProgress.clamp(0, 1) * 100).round();
    final greeting = childName == null || childName!.trim().isEmpty
        ? l10n.kidsGamifiedWelcome
        : '${l10n.kidsGamifiedWelcome} ${childName!.trim()}';
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    Widget avatarImage = Image.asset(
      KidsTheme.kidAvatarAsset,
      width: 64,
      height: 64,
      fit: BoxFit.contain,
    );

    final enableAnimation =
        !reducedMotion && Animate.defaultDuration > Duration.zero;

    if (enableAnimation) {
      avatarImage = avatarImage
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(
            begin: 0,
            end: -4,
            duration: 2000.ms,
            curve: Curves.easeInOut,
          );
    }

    final avatarCircle = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF26A69A),
            Color(0xFF004D40),
          ],
        ),
        border: Border.all(
          color: KidsTheme.goldStar.withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: avatarImage),
    );

    final avatarWidget = RepaintBoundary(
      child: onAvatarTap == null
          ? avatarCircle
          : InkWell(
              onTap: onAvatarTap,
              customBorder: const CircleBorder(),
              child: avatarCircle,
            ),
    );

    final settingsButton = onSettingsTap == null
        ? null
        : IconButton(
            tooltip: l10n.changeMemorizationPath,
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_suggest_rounded),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              fixedSize: const Size(42, 42),
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Container(
          decoration: BoxDecoration(
            gradient: KidsTheme.heroCardGradient,
            borderRadius: KidsTheme.cardRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.5,
            ),
            boxShadow: KidsTheme.card25DShadow,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Avatar + Greeting + Settings
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  avatarWidget,
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.kidsJourneyMotivation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontFamily: 'Amiri',
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?settingsButton,
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Bottom Row / Section: Level & XP Bar + Star Counter
              if (isCompact) ...[
                _LevelProgressSection(
                  level: progress.currentLevel,
                  percentage: levelProgress,
                  progressValue: progress.levelProgress,
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _StarCounter(count: progress.starsEarned),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _LevelProgressSection(
                        level: progress.currentLevel,
                        percentage: levelProgress,
                        progressValue: progress.levelProgress,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StarCounter(count: progress.starsEarned),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LevelProgressSection extends StatelessWidget {
  const _LevelProgressSection({
    required this.level,
    required this.percentage,
    required this.progressValue,
  });

  final int level;
  final int percentage;
  final double progressValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.kidsGamifiedLevelProgress(level, percentage),
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progressValue.clamp(0, 1).toDouble(),
            backgroundColor: Colors.black.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(KidsTheme.goldStar),
          ),
        ),
      ],
    );
  }
}

class _StarCounter extends StatelessWidget {
  const _StarCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: KidsTheme.goldStar.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: KidsTheme.goldStar,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.kidsGamifiedStarsCount(count),
            textAlign: TextAlign.center,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
