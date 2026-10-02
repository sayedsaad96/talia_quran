import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';
import 'kids_chunky_button.dart';

/// W2 — multi-sensory celebration: the reward card plays a confetti burst and
/// a celebratory haptic when it appears. Both respect the platform's
/// disable-animations setting; the haptic still fires for reduced-motion
/// users because it is not visual motion.
class KidsRewardDialog extends StatefulWidget {
  const KidsRewardDialog({
    super.key,
    required this.starsEarned,
    this.pointsEarned = 0,
    this.leveledUpTo,
    this.showNextButton = true,
    this.dailyGoalCap,
    this.sessionGoalReached = false,
    this.onNext,
    this.onReturnToMap,
  });

  final int starsEarned;

  /// K36 — today's sessions reached the session goal: a gentle note that
  /// it is fine to stop, without hiding "Next".
  final bool sessionGoalReached;

  /// K11: session points shown as a second reward pill when positive.
  final int pointsEarned;

  /// K11: new level when this session triggered a level-up; null otherwise.
  final int? leveledUpTo;
  final bool showNextButton;

  /// Today's new-ayah quota when this completion used it up (N3); the card
  /// then celebrates the finished day in place of the "Next" mission.
  final int? dailyGoalCap;
  final VoidCallback? onNext;
  final VoidCallback? onReturnToMap;

  @override
  State<KidsRewardDialog> createState() => _KidsRewardDialogState();
}

class _KidsRewardDialogState extends State<KidsRewardDialog> {
  late final ConfettiController _confetti;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // A level-up is the strongest moment in the loop — pair it with a
    // heavier haptic so the celebration is felt, not just seen.
    final haptic = widget.leveledUpTo != null
        ? HapticFeedback.heavyImpact
        : HapticFeedback.mediumImpact;
    haptic();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _confetti.play();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        _RewardCard(
          starsEarned: widget.starsEarned,
          pointsEarned: widget.pointsEarned,
          leveledUpTo: widget.leveledUpTo,
          showNextButton: widget.showNextButton,
          dailyGoalCap: widget.dailyGoalCap,
          sessionGoalReached: widget.sessionGoalReached,
          onNext: widget.onNext,
          onReturnToMap: widget.onReturnToMap,
        ),
        // Confetti bursts from behind the card's top edge — the visual peak
        // of the celebration, skipped entirely for reduced-motion users.
        if (!disableAnimations)
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: widget.leveledUpTo != null ? 45 : 25,
                maxBlastForce: 18,
                minBlastForce: 8,
                colors: const [
                  KidsTheme.goldStar,
                  KidsTheme.forestGreen,
                  KidsTheme.mintGlow,
                  KidsTheme.reviewPurple,
                  KidsTheme.skyTop,
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.starsEarned,
    required this.pointsEarned,
    this.leveledUpTo,
    this.showNextButton = true,
    this.dailyGoalCap,
    this.sessionGoalReached = false,
    this.onNext,
    this.onReturnToMap,
  });

  final int starsEarned;
  final bool sessionGoalReached;
  final int pointsEarned;
  final int? leveledUpTo;
  final bool showNextButton;

  /// Today's new-ayah quota when this completion used it up (N3); the card
  /// then celebrates the finished day in place of the "Next" mission.
  final int? dailyGoalCap;
  final VoidCallback? onNext;
  final VoidCallback? onReturnToMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        gradient: KidsTheme.backgroundGradient,
        borderRadius: KidsTheme.cardRadius,
        boxShadow: KidsTheme.goldGlow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Image.asset(
              KidsTheme.starRewardAsset,
              width: 132,
              height: 132,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.kidsGamifiedWellDone,
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontFamily: 'Amiri',
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              // A review earns gems, not stars: "+0 stars" would read as a
              // lesser effort, so the pill only shows real stars (K23).
              if (starsEarned > 0)
                _RewardPill(
                  icon: Icons.star_rounded,
                  label: context.l10n.kidsGamifiedEarnedStars(
                    starsEarned,
                    context.numText(starsEarned),
                  ),
                  color: KidsTheme.goldStar,
                ),
              // K11: real session points next to the stars, when any.
              if (pointsEarned > 0)
                _RewardPill(
                  icon: Icons.diamond_rounded,
                  label: context.l10n.kidsGamifiedEarnedGems(pointsEarned),
                  color: KidsTheme.mintGlow,
                ),
              // K11: level-up celebration pill on top of the session rewards.
              if (leveledUpTo != null)
                _RewardPill(
                  icon: Icons.military_tech_rounded,
                  label: context.l10n.kidsLevelValue(leveledUpTo!),
                  color: KidsTheme.reviewPurple,
                ),
            ],
          ),
          if (dailyGoalCap != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.kidsGamifiedDailyLimitReached(dailyGoalCap!),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
          ] else if (sessionGoalReached) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.kidsGamifiedEnoughForToday,
              key: const ValueKey('kids-enough-for-today'),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _RewardActions(
            showNextButton: showNextButton,
            onNext: onNext,
            onReturnToMap: onReturnToMap,
          ),
        ],
      ),
    );
  }
}

/// "Return to map" and "Start mission": side by side, or stacked (the next
/// mission on top) when large text would squeeze them past the card (K29).
class _RewardActions extends StatelessWidget {
  const _RewardActions({
    required this.showNextButton,
    required this.onNext,
    required this.onReturnToMap,
  });

  final bool showNextButton;
  final VoidCallback? onNext;
  final VoidCallback? onReturnToMap;

  static const double _stackAboveTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final returnToMap = KidsChunkyButton(
      onPressed: onReturnToMap,
      icon: Icons.map_rounded,
      label: context.l10n.kidsGamifiedReturnToMap,
      tone: KidsButtonTone.soft,
      height: AppSpacing.buttonHeight,
    );
    if (!showNextButton) return returnToMap;

    final next = KidsChunkyButton(
      onPressed: onNext,
      // Mirrors itself under RTL: it points left in Arabic.
      icon: Icons.arrow_forward_rounded,
      label: context.l10n.kidsGamifiedStartMission,
      tone: KidsButtonTone.gold,
      height: AppSpacing.buttonHeight,
    );

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    if (textScale > _stackAboveTextScale) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          next,
          const SizedBox(height: AppSpacing.sm),
          returnToMap,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: returnToMap),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: next),
      ],
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.xs),
          // Wraps under large text instead of running past the card (K29).
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
