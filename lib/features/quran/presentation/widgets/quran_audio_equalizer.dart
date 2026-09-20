import 'package:flutter/material.dart';

/// Animated audio waveform equalizer representing active recitation playback.
///
/// Displays 4 rounded vertical bars that animate with staggered curves when
/// [isPlaying] is true, and settle to a calm resting height when paused.
class QuranAudioEqualizer extends StatefulWidget {
  const QuranAudioEqualizer({
    super.key,
    required this.isPlaying,
    required this.color,
    this.maxHeight = 16.0,
    this.barWidth = 3.0,
    this.spacing = 2.5,
  });

  final bool isPlaying;
  final Color color;
  final double maxHeight;
  final double barWidth;
  final double spacing;

  @override
  State<QuranAudioEqualizer> createState() => _QuranAudioEqualizerState();
}

class _QuranAudioEqualizerState extends State<QuranAudioEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(QuranAudioEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0.2, duration: const Duration(milliseconds: 250));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Staggered fractions for 4 bars:
        final h1 = (0.2 + 0.8 * (0.5 + 0.5 * (t * 2 - 1).abs())).clamp(0.2, 1.0);
        final h2 = (0.3 + 0.7 * t).clamp(0.2, 1.0);
        final h3 = (0.2 + 0.8 * (1.0 - t)).clamp(0.2, 1.0);
        final h4 = (0.25 + 0.75 * (0.5 + 0.5 * ((t * 1.5) % 1.0))).clamp(0.2, 1.0);

        final heights = [h1, h2, h3, h4];

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (index) {
            final barHeight = widget.isPlaying
                ? (heights[index] * widget.maxHeight).clamp(4.0, widget.maxHeight)
                : 4.0;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              width: widget.barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.barWidth),
              ),
            );
          }),
        );
      },
    );
  }
}
