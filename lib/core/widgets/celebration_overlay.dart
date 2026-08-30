import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_spacing.dart';

enum CelebrationType { ayah, page, juz }

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.type,
    required this.xpGained,
    required this.onComplete,
  });

  final CelebrationType type;
  final int xpGained;
  final VoidCallback onComplete;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _confetti;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final duration = widget.type == CelebrationType.juz
        ? const Duration(seconds: 5)
        : const Duration(seconds: 2);
    _confetti = ConfettiController(duration: duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (!disableAnimations) _confetti.play();
    Future.delayed(
      disableAnimations
          ? const Duration(milliseconds: 400)
          : widget.type == CelebrationType.juz
          ? const Duration(milliseconds: 4500)
          : const Duration(milliseconds: 2200),
      () {
        if (mounted) widget.onComplete();
      },
    );
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _getMessage(AppLocalizations l10n) => switch (widget.type) {
    CelebrationType.ayah => l10n.celebrationAyah(widget.xpGained),
    CelebrationType.page => l10n.celebrationPage(widget.xpGained),
    CelebrationType.juz => l10n.congratulations,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final motionValue = disableAnimations ? 1.0 : null;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Transparent barrier to block interaction during celebration
        const ModalBarrier(color: Colors.transparent),

        // Confetti from top
        if (!disableAnimations)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.gold,
                AppColors.primary,
                AppColors.primaryLight,
                AppColors.success,
                AppColors.info,
              ],
              numberOfParticles: widget.type == CelebrationType.juz ? 50 : 25,
              maxBlastForce: 20,
              minBlastForce: 8,
            ),
          ),

        // XP Badge appears and slides up
        Positioned(
          top: topInset + AppSpacing.xl + AppSpacing.md,
          child:
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.itemGap + 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _getMessage(l10n),
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .animate(autoPlay: !disableAnimations, value: motionValue)
                  .fadeIn(duration: 300.ms)
                  .slideY(
                    begin: 0.5,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
        ),

        // Full celebration screen for Juz completion
        if (widget.type == CelebrationType.juz)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                        '🏆',
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 80,
                        ),
                      )
                      .animate(autoPlay: !disableAnimations, value: motionValue)
                      .scale(duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                        l10n.congratulations,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      )
                      .animate(autoPlay: !disableAnimations, value: motionValue)
                      .fadeIn(delay: 300.ms),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                        l10n.celebrationJuzDone,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white70),
                      )
                      .animate(autoPlay: !disableAnimations, value: motionValue)
                      .fadeIn(delay: 500.ms),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                        '+${widget.xpGained} XP 👑',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.goldLight,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      .animate(autoPlay: !disableAnimations, value: motionValue)
                      .fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
