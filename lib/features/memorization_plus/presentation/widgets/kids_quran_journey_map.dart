import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/kids_quran_map_visuals.dart';
import '../../domain/services/kids_surah_house_summary_builder.dart';
import '../theme/kids_theme.dart';
import 'kids_quran_row_layout.dart';
import 'kids_surah_house_card.dart';

/// The lazily built map of surah islands.
class KidsQuranJourneyMap extends StatefulWidget {
  const KidsQuranJourneyMap({
    super.key,
    required this.houses,
    required this.currentSurahId,
    required this.nameOf,
    required this.onHouseTap,
  });

  final List<KidsSurahHouse> houses;
  final int currentSurahId;
  final String Function(int surahId) nameOf;
  final ValueChanged<KidsSurahHouse> onHouseTap;

  @override
  State<KidsQuranJourneyMap> createState() => _KidsQuranJourneyMapState();
}

class _KidsQuranJourneyMapState extends State<KidsQuranJourneyMap> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final index = widget.houses.indexWhere(
      (h) => h.surahId == widget.currentSurahId,
    );
    _controller = ScrollController(
      initialScrollOffset:
          (index < 0 ? 0 : index) * kKidsQuranJourneyItemExtent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final houses = widget.houses;
    return ListView.builder(
      controller: _controller,
      itemExtent: kKidsQuranJourneyItemExtent,
      itemCount: houses.length,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      itemBuilder: (context, index) {
        final house = houses[index];
        final firstOfJuz = index == 0 || houses[index - 1].juz != house.juz;
        return _MapRow(
          index: index,
          isLast: index == houses.length - 1,
          showJuz: firstOfJuz,
          isCurrent: house.surahId == widget.currentSurahId,
          house: house,
          name: widget.nameOf(house.surahId),
          onTap: () => widget.onHouseTap(house),
        );
      },
    );
  }
}

/// One map row: road segment, island sprite, parchment card and an optional
/// juz ribbon, all placed by the shared [kidsQuranRowLayout] geometry.
class _MapRow extends StatelessWidget {
  const _MapRow({
    required this.index,
    required this.isLast,
    required this.showJuz,
    required this.isCurrent,
    required this.house,
    required this.name,
    required this.onTap,
  });

  final int index;
  final bool isLast;
  final bool showJuz;
  final bool isCurrent;
  final KidsSurahHouse house;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final islandOnStart = index.isEven;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = kidsQuranRowLayout(
          index: index,
          size: Size(constraints.maxWidth, kKidsQuranJourneyItemExtent),
          direction: direction,
          showJuz: showJuz,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: KidsQuranRoadPainter(
                  towardEnd: !islandOnStart,
                  isRtl: direction == TextDirection.rtl,
                  isFirst: index == 0,
                  isLast: isLast,
                  done: house.status == KidsSurahHouseStatus.completed,
                ),
              ),
            ),
            Positioned.fromRect(
              rect: layout.island,
              child: ExcludeSemantics(
                child: _IslandSprite(
                  index: index,
                  width: layout.island.width,
                ),
              ),
            ),
            if (showJuz && layout.juzRibbon != null)
              Positioned.fromRect(
                rect: layout.juzRibbon!,
                child: _JuzRibbon(juz: house.juz, tailOnEnd: islandOnStart),
              ),
            Positioned.fromRect(
              rect: layout.card,
              child: KidsSurahHouseCard(
                house: house,
                name: name,
                isCurrent: isCurrent,
                onTap: onTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The island sprite for a row. The artwork lands in a later task; until
/// then the error builder keeps the row clean.
class _IslandSprite extends StatelessWidget {
  const _IslandSprite({required this.index, required this.width});

  final int index;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kidsIslandForRow(index).asset,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

/// The gold juz ribbon above the card's far edge, with a folded tail.
class _JuzRibbon extends StatelessWidget {
  const _JuzRibbon({required this.juz, required this.tailOnEnd});

  final int juz;

  /// Whether the folded tail hangs on the ribbon's end side (right in LTR).
  final bool tailOnEnd;

  @override
  Widget build(BuildContext context) {
    final tailAtLeft =
        tailOnEnd != (Directionality.of(context) == TextDirection.rtl);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 28,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: KidsTheme.goldStar,
            borderRadius: BorderRadius.horizontal(
              left: tailAtLeft
                  ? Radius.zero
                  : const Radius.circular(AppSpacing.radiusMd),
              right: tailAtLeft
                  ? const Radius.circular(AppSpacing.radiusMd)
                  : Radius.zero,
            ),
            boxShadow: KidsTheme.card25DShadow,
          ),
          child: Text(
            context.l10n.kidsQuranJourneyJuz(context.numText(juz)),
            style: AppTypography.labelMedium.copyWith(
              color: KidsTheme.inkOnParchment,
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
          ),
        ),
        Positioned(
          top: 24,
          left: tailAtLeft ? 0 : null,
          right: tailAtLeft ? null : 0,
          child: CustomPaint(
            size: const Size(14, 8),
            painter: _RibbonFoldPainter(tailAtLeft: tailAtLeft),
          ),
        ),
      ],
    );
  }
}

/// The darker fold under the ribbon's tail.
class _RibbonFoldPainter extends CustomPainter {
  const _RibbonFoldPainter({required this.tailAtLeft});

  final bool tailAtLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final fold = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0);
    if (tailAtLeft) {
      fold.lineTo(0, size.height);
    } else {
      fold.lineTo(size.width, size.height);
    }
    fold.close();
    canvas.drawPath(fold, Paint()..color = KidsTheme.houseBrown);
  }

  @override
  bool shouldRepaint(_RibbonFoldPainter old) => old.tailAtLeft != tailAtLeft;
}

/// A simple winding road segment: enters from the previous row's side, bends
/// through this row's side, and leaves toward the next row's side.
class KidsQuranRoadPainter extends CustomPainter {
  const KidsQuranRoadPainter({
    required this.towardEnd,
    required this.isRtl,
    required this.isFirst,
    required this.isLast,
    required this.done,
  });

  /// True when this row's house sits on the end side (right in LTR).
  final bool towardEnd;
  final bool isRtl;
  final bool isFirst;
  final bool isLast;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    final rightHere = isRtl ? !towardEnd : towardEnd;
    final here = size.width * (rightHere ? 0.7 : 0.3);
    final other = size.width * (rightHere ? 0.3 : 0.7);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = done
          ? KidsTheme.goldStar.withValues(alpha: 0.55)
          : KidsTheme.mapSurface;
    final midY = size.height / 2;
    final path = Path()..moveTo(isFirst ? here : other, isFirst ? midY : 0);
    if (!isFirst) path.quadraticBezierTo(other, midY * 0.5, here, midY);
    if (!isLast) {
      path.quadraticBezierTo(here, midY * 1.5, other, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(KidsQuranRoadPainter old) =>
      old.towardEnd != towardEnd ||
      old.isRtl != isRtl ||
      old.isFirst != isFirst ||
      old.isLast != isLast ||
      old.done != done;
}
