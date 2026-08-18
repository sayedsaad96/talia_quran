import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_typography.dart';

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

  @override
  void initState() {
    super.initState();
    final duration = widget.type == CelebrationType.juz
        ? const Duration(seconds: 5)
        : const Duration(seconds: 2);
    _confetti = ConfettiController(duration: duration)..play();

    Future.delayed(
      widget.type == CelebrationType.juz
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

  String _getMessage() => switch (widget.type) {
    CelebrationType.ayah => 'أحسنت! +${widget.xpGained} XP ⭐',
    CelebrationType.page => 'اكتملت الصفحة! +${widget.xpGained} XP 🎯',
    CelebrationType.juz => 'مبارك! أتممت الجزء 🏆',
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Transparent barrier to block interaction during celebration
        const ModalBarrier(color: Colors.transparent),

        // Confetti from top
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFFF59E0B),
              Color(0xFF8B5CF6),
              Color(0xFF10B981),
              Color(0xFFEF4444),
              Color(0xFF3B82F6),
            ],
            numberOfParticles: widget.type == CelebrationType.juz ? 50 : 25,
            maxBlastForce: 20,
            minBlastForce: 8,
          ),
        ),

        // XP Badge appears and slides up
        Positioned(
          top: 100,
          child:
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _getMessage(),
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .animate()
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
                    style: AppTypography.displayLarge.copyWith(fontSize: 80),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text(
                    'مبارك!',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 8),
                  Text(
                    'أتممت الجزء كاملاً بإذن الله',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 24),
                  Text(
                    '+${widget.xpGained} XP 👑',
                    style: AppTypography.headlineMedium.copyWith(
                      color: const Color(0xFFF59E0B),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
