import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';

/// W2 — a real celebration for finishing the whole journey. Completing the
/// Juz Amma path is the strongest milestone in the kids loop; a generic
/// empty-state under-sells it. Confetti and haptics respect the platform's
/// disable-animations setting.
class KidsJourneyCompleteCard extends StatefulWidget {
  const KidsJourneyCompleteCard({super.key});

  @override
  State<KidsJourneyCompleteCard> createState() =>
      _KidsJourneyCompleteCardState();
}

class _KidsJourneyCompleteCardState extends State<KidsJourneyCompleteCard> {
  late final ConfettiController _confetti;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    HapticFeedback.heavyImpact();
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
      alignment: Alignment.topCenter,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: KidsTheme.kidsCardGradient,
            borderRadius: KidsTheme.cardRadius,
            border: Border.all(
              color: KidsTheme.goldStar.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TaliaIcon(
                TaliaKidsIcons.trophy,
                color: KidsTheme.goldStar,
                size: 72,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.kidsGamifiedJourneyComplete,
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  color: KidsTheme.shellTextPrimary,
                  fontFamily: 'Amiri',
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.kidsJourneyCompleteHint,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: KidsTheme.shellTextSecondary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        if (!disableAnimations)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 50,
              maxBlastForce: 22,
              minBlastForce: 10,
              colors: const [
                KidsTheme.goldStar,
                KidsTheme.mintGlow,
                KidsTheme.reviewPurple,
                KidsTheme.emeraldGlow,
                KidsTheme.warmSunset,
              ],
            ),
          ),
      ],
    );
  }
}
