import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/v2/session_phase.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/kids_mode_cubit.dart';
import '../theme/kids_theme.dart';

/// Talia's official poses (cropped from `assets/talia/`), one per session
/// moment.
enum KidsTaliaPose {
  listening('assets/images/talia/talia_listening.png'),
  thinking('assets/images/talia/talia_thinking.png'),
  speaking('assets/images/talia/talia_speaking.png'),
  encourage('assets/images/talia/talia_encourage.png'),
  celebrate('assets/images/talia/talia_celebrate.png'),
  pointRight('assets/images/talia/talia_point_right.png'),
  idle('assets/images/talia/talia_idle.png'),
  wave('assets/images/talia/talia_wave.png'),
  happy('assets/images/talia/talia_happy.png'),
  readingQuran('assets/images/talia/talia_reading_quran.png');

  const KidsTaliaPose(this.asset);

  final String asset;
}

/// Which pose Talia takes for the current session moment.
KidsTaliaPose kidsTaliaPoseFor(KidsModeLoaded state) {
  if (state.isRecording) return KidsTaliaPose.speaking;
  if (state.isCompleted) return KidsTaliaPose.celebrate;
  if (state.hasWordFeedback) return KidsTaliaPose.encourage;
  if (state.isReview && state.isAwaitingRecitation) {
    return KidsTaliaPose.pointRight;
  }
  if (state.isRecallingFromMemory || state.sessionState.phase.textHidden) {
    return KidsTaliaPose.thinking;
  }
  return KidsTaliaPose.listening;
}

/// Talia's speech-bubble line for [pose].
String kidsTaliaBubbleFor(BuildContext context, KidsTaliaPose pose) {
  final l10n = context.l10n;
  return switch (pose) {
    // idle/wave/happy/readingQuran reuse the listen line until Task 9 adds
    // moment-specific bubbles.
    KidsTaliaPose.listening ||
    KidsTaliaPose.idle ||
    KidsTaliaPose.wave ||
    KidsTaliaPose.happy ||
    KidsTaliaPose.readingQuran => l10n.kidsTaliaListenBubble,
    KidsTaliaPose.thinking => l10n.kidsTaliaRecallBubble,
    KidsTaliaPose.speaking => l10n.kidsTaliaRecordingBubble,
    KidsTaliaPose.encourage => l10n.kidsTaliaEncourageBubble,
    KidsTaliaPose.celebrate => l10n.kidsTaliaCelebrateBubble,
    KidsTaliaPose.pointRight => l10n.kidsTaliaReviewBubble,
  };
}

/// Talia beside a speech bubble. She "breathes" gently while [animate] is
/// true; callers keep her still during recitation playback and recording,
/// and reduced motion always keeps her still.
class KidsTaliaCompanion extends StatefulWidget {
  const KidsTaliaCompanion({
    super.key,
    required this.pose,
    required this.message,
    this.animate = true,
    this.height = 112,
  });

  final KidsTaliaPose pose;
  final String message;
  final bool animate;
  final double height;

  @override
  State<KidsTaliaCompanion> createState() => _KidsTaliaCompanionState();
}

class _KidsTaliaCompanionState extends State<KidsTaliaCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreath();
  }

  @override
  void didUpdateWidget(KidsTaliaCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncBreath();
  }

  void _syncBreath() {
    final animate = widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (animate) {
      if (!_breath.isAnimating) unawaited(_breath.repeat(reverse: true));
    } else {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final talia = ScaleTransition(
      alignment: Alignment.bottomCenter,
      scale: Tween<double>(
        begin: 1,
        end: 1.03,
      ).animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOut)),
      child: AnimatedSwitcher(
        duration: reduceMotion || !widget.animate
            ? Duration.zero
            : const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: Image.asset(
          widget.pose.asset,
          key: ValueKey(widget.pose),
          height: widget.height,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => SizedBox(height: widget.height),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(width: widget.height * 0.85, child: talia),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _SpeechBubble(message: widget.message),
          ),
        ),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomPaint(
          size: const Size(12, 18),
          painter: _BubbleTailPainter(pointsRight: isRtl),
        ),
        Expanded(
          child: Container(
            key: const ValueKey('kids-talia-bubble'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: KidsTheme.cardRadius,
              boxShadow: KidsTheme.card25DShadow,
            ),
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              child: Text(
                message,
                key: ValueKey(message),
                style: AppTypography.titleSmall.copyWith(
                  color: KidsTheme.inkOnParchment,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.pointsRight});

  /// The tail points back toward Talia, who sits at the row's start.
  final bool pointsRight;

  @override
  void paint(Canvas canvas, Size size) {
    final tip = pointsRight ? size.width : 0.0;
    final base = pointsRight ? 0.0 : size.width;
    final path = Path()
      ..moveTo(base, 0)
      ..lineTo(tip, size.height / 2)
      ..lineTo(base, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter oldDelegate) =>
      oldDelegate.pointsRight != pointsRight;
}
