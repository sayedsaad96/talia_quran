import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../theme/kids_theme.dart';

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
    final levelProgress = (progress.levelProgress.clamp(0, 1) * 100).round();
    final greeting = childName == null || childName!.trim().isEmpty
        ? context.l10n.kidsGamifiedWelcome
        : '${context.l10n.kidsGamifiedWelcome} ${childName!.trim()}';

    final avatar = InkWell(
      onTap: onAvatarTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: KidsTheme.goldStar.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: KidsTheme.goldStar.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 34,
          backgroundColor: KidsTheme.nightSkyDark,
          child: ClipOval(
            child: Image.asset(
              KidsTheme.kidAvatarAsset,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(
      begin: 0.97,
      end: 1.03,
      duration: 2.seconds,
      curve: Curves.easeInOut,
    );

    final progressDetails = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontFamily: 'Amiri',
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.kidsGamifiedLevelProgress(
            progress.currentLevel,
            levelProgress,
          ),
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress.levelProgress.clamp(0, 1).toDouble(),
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            valueColor: const AlwaysStoppedAnimation<Color>(KidsTheme.goldStar),
          ),
        ),
      ],
    );
    final settingsButton = onSettingsTap == null
        ? null
        : IconButton(
            tooltip: context.l10n.changeMemorizationPath,
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_suggest_rounded),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.13),
              fixedSize: const Size(48, 48),
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactLayout = constraints.maxWidth < 340;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: KidsTheme.cardRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
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
                        avatar,
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: progressDetails),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _StarCounter(count: progress.starsEarned),
                        if (settingsButton != null) ...[
                          const Spacer(),
                          settingsButton,
                        ],
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    avatar,
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: progressDetails),
                    const SizedBox(width: AppSpacing.md),
                    _StarCounter(count: progress.starsEarned),
                    if (settingsButton != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      settingsButton,
                    ],
                  ],
                ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0, curve: Curves.easeOut);
      },
    );
  }
}

class _StarCounter extends StatelessWidget {
  const _StarCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: KidsTheme.goldStar, size: 28)
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2.seconds, color: Colors.white),
          const SizedBox(height: 2),
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
