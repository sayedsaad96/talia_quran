import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../theme/kids_theme.dart';

/// A fixed-size recording waveform that only repaints as it moves.
///
/// Keeping every bar inside a stable slot avoids relaying out the recording
/// panel on each animation tick.
class KidsRecordingWaveform extends StatelessWidget {
  const KidsRecordingWaveform({super.key, required this.animation});

  final Animation<double> animation;

  static const _barHeights = [0.5, 0.9, 0.6, 1.0, 0.7, 0.85, 0.55, 0.75, 0.4];
  static const _colors = [
    KidsTheme.buttonGreenFace,
    KidsTheme.goldStar,
    KidsTheme.reviewPurple,
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        key: const ValueKey('kids-recording-waveform'),
        height: 40,
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, _) {
            final value = animation.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < _barHeights.length; index++) ...[
                  SizedBox(
                    key: ValueKey('kids-recording-waveform-bar-$index'),
                    width: 7,
                    height: 40,
                    child: Align(
                      child: Transform.scale(
                        alignment: Alignment.center,
                        scaleY:
                            0.4 +
                            (0.6 *
                                _barHeights[index] *
                                ((value + index * 0.15) % 1.0)),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _colors[index % _colors.length],
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  if (index < _barHeights.length - 1) const SizedBox(width: 5),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
