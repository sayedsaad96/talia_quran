import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/kids_quran_map_visuals.dart';
import '../../domain/services/kids_surah_house_summary_builder.dart';
import '../../domain/services/kids_world_phase.dart';
import '../theme/kids_theme.dart';
import '../world/kids_world_palette.dart';
import 'kids_quran_road_painter.dart';
import 'kids_quran_row_layout.dart';
import 'kids_quran_talia_overlay.dart';
import 'kids_surah_house_card.dart';

/// The lazily built map of surah islands.
class KidsQuranJourneyMap extends StatefulWidget {
  const KidsQuranJourneyMap({
    super.key,
    required this.houses,
    required this.currentSurahId,
    required this.nameOf,
    required this.onHouseTap,
    this.celebratedSurahIds = const {},
  });

  final List<KidsSurahHouse> houses;
  final int currentSurahId;
  final String Function(int surahId) nameOf;
  final ValueChanged<KidsSurahHouse> onHouseTap;

  /// Surahs completed since the last visit: their stars pop once when their
  /// row first shows, and Talia may walk from the nearest one to the current
  /// house.
  final Set<int> celebratedSurahIds;

  @override
  State<KidsQuranJourneyMap> createState() => _KidsQuranJourneyMapState();
}

class _KidsQuranJourneyMapState extends State<KidsQuranJourneyMap> {
  late final ScrollController _controller;

  /// Surahs whose star pop has already played; rows are rebuilt as they
  /// scroll, but each pop must play only once.
  final Set<int> _popped = {};

  @override
  void initState() {
    super.initState();
    final index = _currentIndex();
    _controller = ScrollController(
      initialScrollOffset:
          (index < 0 ? 0 : index) * kKidsQuranJourneyItemExtent,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centreOnCurrent(index);
    });
  }

  int _currentIndex() => widget.houses.indexWhere(
    (h) => h.surahId == widget.currentSurahId,
  );

  /// Puts the current row near the viewport centre; [initialScrollOffset]
  /// above keeps the very first frame at the row's top so nothing jumps.
  void _centreOnCurrent(int index) {
    if (index < 0 || !_controller.hasClients) return;
    final position = _controller.position;
    final target =
        index * kKidsQuranJourneyItemExtent -
        (position.viewportDimension - kKidsQuranJourneyItemExtent) / 2;
    final clamped = target.clamp(0.0, position.maxScrollExtent).toDouble();
    // Skip the no-op jump: it would still churn the scroll activity and
    // rebuild the visible rows.
    if (clamped == position.pixels) return;
    _controller.jumpTo(clamped);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final houses = widget.houses;
    final currentIndex = _currentIndex();
    final celebratedIndexes = <int>[
      for (var i = 0; i < houses.length; i++)
        if (widget.celebratedSurahIds.contains(houses[i].surahId)) i,
    ];
    return Stack(
      children: [
        ListView.builder(
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
              currentIndex: currentIndex,
              isCurrent: house.surahId == widget.currentSurahId,
              house: house,
              name: widget.nameOf(house.surahId),
              popStars:
                  widget.celebratedSurahIds.contains(house.surahId) &&
                  _popped.add(house.surahId),
              onTap: () => widget.onHouseTap(house),
            );
          },
        ),
        if (currentIndex >= 0)
          Positioned.fill(
            child: KidsQuranTaliaOverlay(
              controller: _controller,
              currentIndex: currentIndex,
              walkFromIndex: kidsQuranWalkOrigin(
                celebratedIndexes: celebratedIndexes,
                currentIndex: currentIndex,
              ),
              direction: Directionality.of(context),
            ),
          ),
      ],
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
    required this.currentIndex,
    required this.isCurrent,
    required this.house,
    required this.name,
    required this.popStars,
    required this.onTap,
  });

  final int index;
  final bool isLast;
  final bool showJuz;

  /// Index of the current house in the houses list, or -1 when it is not
  /// present (then no road segment is lit).
  final int currentIndex;
  final bool isCurrent;
  final KidsSurahHouse house;
  final String name;
  final bool popStars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final night = KidsWorldPhaseScope.phaseOf(context) == KidsWorldPhase.night;
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final islandOnStart = index.isEven;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = kidsQuranRowLayout(
          index: index,
          size: Size(constraints.maxWidth, kKidsQuranJourneyItemExtent),
          direction: direction,
          showJuz: showJuz,
        );
        Offset neighbourFoot(int rowIndex) => kidsQuranRowLayout(
          index: rowIndex,
          size: Size(constraints.maxWidth, kKidsQuranJourneyItemExtent),
          direction: direction,
          showJuz: false,
        ).taliaFoot;
        KidsQuranRoadPainter roadPainter(double shimmer) =>
            KidsQuranRoadPainter(
              hereX: layout.taliaFoot.dx,
              previousX: index == 0 ? 0 : neighbourFoot(index - 1).dx,
              nextX: isLast ? 0 : neighbourFoot(index + 1).dx,
              isFirst: index == 0,
              isLast: isLast,
              incomingLit: currentIndex >= 0 && index <= currentIndex && index > 0,
              outgoingLit: currentIndex >= 0 && index < currentIndex,
              night: night,
              seed: index,
              shimmer: shimmer,
            );
        // One shimmer flash (0 → 1 over 600 ms) when the row is built; the
        // painter maps it to the coin highlight. Fixed at 0 when animations
        // are disabled.
        final road = animationsDisabled
            ? RepaintBoundary(
                child: CustomPaint(painter: roadPainter(0)),
              )
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, shimmer, _) => RepaintBoundary(
                  child: CustomPaint(painter: roadPainter(shimmer)),
                ),
              );
        return Stack(
          children: [
            Positioned.fill(child: road),
            if (night && (house.status == KidsSurahHouseStatus.completed || isCurrent))
              Positioned.fromRect(
                rect: layout.island,
                child: DecoratedBox(
                  key: ValueKey('kids-quran-halo-${house.surahId}'),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        KidsTheme.goldLight.withValues(alpha: 0.35),
                        KidsTheme.goldLight.withValues(alpha: 0.0),
                      ],
                    ),
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
            Positioned.fromRect(
              rect: layout.card,
              child: KidsSurahHouseCard(
                house: house,
                name: name,
                isCurrent: isCurrent,
                popStars: popStars,
                onTap: onTap,
              ),
            ),
            // After the card: the ribbon is a tab overlapping its top edge.
            if (showJuz && layout.juzRibbon != null)
              Positioned.fromRect(
                rect: layout.juzRibbon!,
                child: _JuzRibbon(juz: house.juz, tailOnEnd: islandOnStart),
              ),
          ],
        );
      },
    );
  }
}

/// The island sprite for a row. A missing or undecodable image leaves the
/// row without an island rather than breaking it.
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
