import 'package:flutter/material.dart';

import '../../domain/entities/memorization_entities.dart';
import 'kids_house_card.dart';
import 'kids_journey_painters.dart';
import 'kids_journey_signpost.dart';

/// A single segment of the 2.5D winding path carrying an alternating
/// destination node. Extracted from the journey page (phase 5) as a reusable
/// piece; behavior and visuals are unchanged.
class KidsJourneySegment extends StatelessWidget {
  const KidsJourneySegment({
    super.key,
    required this.stage,
    required this.index,
    required this.isLeft,
    required this.isFirst,
    required this.isLast,
    required this.surahName,
    required this.showSignpost,
    required this.onTap,
    required this.onLockedTap,
  });

  final KidsJourneyStage stage;
  final int index;
  final bool isLeft;
  final bool isFirst;
  final bool isLast;
  final String surahName;
  final bool showSignpost;
  final VoidCallback onTap;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final metrics = resolveJourneySegmentMetrics(totalWidth);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              painter: WindingPathPainter(
                isLeft: isLeft,
                isFirst: isFirst,
                isLast: isLast,
                totalWidth: totalWidth,
                cardWidth: metrics.cardWidth,
                sideMargin: metrics.sideMargin,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Align(
                  alignment: isLeft
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isLeft ? metrics.sideMargin : 0,
                      right: isLeft ? 0 : metrics.sideMargin,
                    ),
                    child: KidsHouseCard(
                      width: metrics.cardWidth,
                      stage: stage,
                      surahName: surahName,
                      onTap: onTap,
                      onLockedTap: onLockedTap,
                    ),
                  ),
                ),
              ),
            ),
            if (showSignpost)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: KidsJourneySignpost(quoteIndex: index ~/ 3),
              ),
          ],
        );
      },
    );
  }
}
