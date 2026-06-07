import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/memorization_entities.dart';
import '../theme/kids_theme.dart';
import 'kids_house_card.dart';

typedef KidsStageLabelBuilder = String Function(KidsJourneyStage stage);
typedef KidsStageTapCallback = void Function(KidsJourneyStage stage);

class KidsJourneyMap extends StatelessWidget {
  const KidsJourneyMap({
    super.key,
    required this.stages,
    this.surahNameBuilder,
    this.onStageTap,
    this.onLockedStageTap,
  });

  final List<KidsJourneyStage> stages;
  final KidsStageLabelBuilder? surahNameBuilder;
  final KidsStageTapCallback? onStageTap;
  final KidsStageTapCallback? onLockedStageTap;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();

    const cardWidth = 172.0;
    const cardHeight = 230.0;
    const verticalGap = 34.0;
    final mapHeight = stages.length * (cardHeight + verticalGap);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const leftX = AppSpacing.md;
        final rightX = (maxWidth - cardWidth - AppSpacing.md)
            .clamp(AppSpacing.md, maxWidth)
            .toDouble();

        return SingleChildScrollView(
          child: SizedBox(
            height: mapHeight,
            width: maxWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _KidsJourneyPathPainter(
                        itemCount: stages.length,
                        cardHeight: cardHeight,
                        verticalGap: verticalGap,
                      ),
                    ),
                  ),
                ),
                for (var index = 0; index < stages.length; index++)
                  Positioned(
                    top: index * (cardHeight + verticalGap),
                    left: index.isEven ? leftX : rightX,
                    child: KidsHouseCard(
                      width: cardWidth,
                      stage: stages[index],
                      surahName: surahNameBuilder?.call(stages[index]),
                      onTap: onStageTap == null
                          ? null
                          : () => onStageTap!(stages[index]),
                      onLockedTap: onLockedStageTap == null
                          ? null
                          : () => onLockedStageTap!(stages[index]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KidsJourneyPathPainter extends CustomPainter {
  const _KidsJourneyPathPainter({
    required this.itemCount,
    required this.cardHeight,
    required this.verticalGap,
  });

  final int itemCount;
  final double cardHeight;
  final double verticalGap;

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount < 2) return;

    final centerX = size.width / 2;
    final step = cardHeight + verticalGap;
    final path = Path()..moveTo(centerX, cardHeight * 0.45);

    for (var index = 1; index < itemCount; index++) {
      final y = index * step + cardHeight * 0.45;
      final previousY = (index - 1) * step + cardHeight * 0.45;
      final controlOffset = index.isEven
          ? -size.width * 0.28
          : size.width * 0.28;
      path.cubicTo(
        centerX + controlOffset,
        previousY + step * 0.34,
        centerX - controlOffset,
        y - step * 0.34,
        centerX,
        y,
      );
    }

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, shadowPaint);

    final pathPaint = Paint()
      ..shader = const LinearGradient(
        colors: [KidsTheme.goldWarm, KidsTheme.goldStar],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, pathPaint);

    final dashPaint = Paint()
      ..color = KidsTheme.creamParchment.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    _drawDashedPath(canvas, path, dashPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 14).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 26;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KidsJourneyPathPainter oldDelegate) {
    return oldDelegate.itemCount != itemCount ||
        oldDelegate.cardHeight != cardHeight ||
        oldDelegate.verticalGap != verticalGap;
  }
}
