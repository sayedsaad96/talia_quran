import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kids_quran_row_layout.dart';
import 'kids_talia_companion.dart';

/// The row Talia walks from to reach [currentIndex], or null when she should
/// simply stand on the current island.
///
/// The nearest celebrated index wins (ties go to the smaller one). She only
/// walks when the nearest celebrated row is within 3 rows of the current one,
/// and never when the current row itself is celebrated or there is no
/// current row.
int? kidsQuranWalkOrigin({
  required List<int> celebratedIndexes,
  required int currentIndex,
}) {
  if (celebratedIndexes.isEmpty || currentIndex < 0) return null;
  int? best;
  var bestDistance = -1;
  for (final index in celebratedIndexes) {
    final distance = (index - currentIndex).abs();
    final better =
        best == null ||
        distance < bestDistance ||
        (distance == bestDistance && index < best);
    if (better) {
      best = index;
      bestDistance = distance;
    }
  }
  if (best == null || bestDistance == 0 || bestDistance > 3) return null;
  return best;
}

/// Talia floating above the Quran journey map, standing (or walking) on the
/// current surah's island.
///
/// Pure decoration: she is wrapped in [IgnorePointer] and [ExcludeSemantics]
/// so taps and screen readers only ever see the rows beneath her. She
/// breathes gently, and when [walkFromIndex] is set she hops from the
/// celebrated row to the current one once, after the star pop has finished.
class KidsQuranTaliaOverlay extends StatefulWidget {
  const KidsQuranTaliaOverlay({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.walkFromIndex,
    required this.direction,
    this.walkKey,
  });

  final ScrollController controller;

  /// Index of the current house in the houses list, or -1 when it is not
  /// present (then the overlay renders nothing).
  final int currentIndex;

  /// Index of the row Talia walks from, or null to keep her standing.
  final int? walkFromIndex;

  final TextDirection direction;

  /// Identity of the celebration that produced [walkFromIndex] (the map
  /// passes the loaded `celebratedSurahIds` set). Talia walks once per
  /// distinct key, so a second completion on the same live map walks again
  /// while a plain rebuild never replays a walk.
  final Object? walkKey;

  @override
  State<KidsQuranTaliaOverlay> createState() => _KidsQuranTaliaOverlayState();
}

class _KidsQuranTaliaOverlayState extends State<KidsQuranTaliaOverlay>
    with TickerProviderStateMixin {
  static const _breathDuration = Duration(milliseconds: 1500);
  static const _walkDuration = Duration(milliseconds: 1500);

  /// The star pop on the current row runs 300 ms with a 150 ms stagger, so
  /// the walk starts after 600 ms to let it finish first.
  static const _starPopDelay = Duration(milliseconds: 600);

  static const _size = 72.0;

  late final AnimationController _breath;
  late final AnimationController _walk;
  Timer? _walkTimer;

  /// The [KidsQuranTaliaOverlay.walkKey] whose walk was already scheduled;
  /// starts as a private sentinel so even a null key walks once.
  Object? _walkedFor = _notWalked;
  static const _notWalked = Object();

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(vsync: this, duration: _breathDuration);
    _walk = AnimationController(vsync: this, duration: _walkDuration);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleWalk());
  }

  void _scheduleWalk() {
    if (!mounted || widget.walkFromIndex == null) return;
    if (identical(_walkedFor, widget.walkKey)) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _walkedFor = widget.walkKey;
    _walkTimer?.cancel();
    _walkTimer = Timer(_starPopDelay, () {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      unawaited(_walk.forward(from: 0));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreath();
  }

  @override
  void didUpdateWidget(covariant KidsQuranTaliaOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The map reloads its cubit while mounted, so a walk origin can arrive
    // on a widget update, not only on first mount. `_scheduleWalk` walks
    // once per celebration through `_walkedFor`.
    _scheduleWalk();
  }

  void _syncBreath() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _walkTimer?.cancel();
      if (_walk.isAnimating) _walk.stop();
      _breath
        ..stop()
        ..value = 0;
    } else if (!_breath.isAnimating) {
      unawaited(_breath.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _walkTimer?.cancel();
    _breath.dispose();
    _walk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentIndex < 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
            animation: Listenable.merge([widget.controller, _breath, _walk]),
            builder: (context, _) {
              final disabled = MediaQuery.disableAnimationsOf(context);
              final width = constraints.maxWidth;
              KidsQuranRowLayout layoutFor(int index) => kidsQuranRowLayout(
                index: index,
                size: Size(width, kKidsQuranJourneyItemExtent),
                direction: widget.direction,
                showJuz: false,
              );
              // The rows live in the ListView's scroll space; the overlay
              // lives in the viewport, so subtract the scroll offset.
              final offset = widget.controller.hasClients
                  ? widget.controller.offset
                  : 0.0;
              Offset footFor(int index) => Offset(
                layoutFor(index).taliaFoot.dx,
                index * kKidsQuranJourneyItemExtent +
                    layoutFor(index).taliaFoot.dy -
                    offset,
              );
              final foot = footFor(widget.currentIndex);
              var pose = KidsTaliaPose.readingQuran;
              var drawnFoot = foot;
              if (!disabled &&
                  _walk.isAnimating &&
                  widget.walkFromIndex != null) {
                final origin = footFor(widget.walkFromIndex!);
                final t = Curves.easeInOut.transform(_walk.value);
                drawnFoot =
                    Offset.lerp(origin, foot, t)! +
                    Offset(0, -8 * math.sin(math.pi * 4 * t));
                pose = KidsTaliaPose.celebrate;
              }
              final scale = disabled
                  ? 1.0
                  : 1 + 0.02 * Curves.easeInOut.transform(_breath.value);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: drawnFoot.dx - _size / 2,
                    top: drawnFoot.dy - _size,
                    width: _size,
                    height: _size,
                    child: Transform.scale(
                      alignment: Alignment.bottomCenter,
                      scale: scale,
                      child: Image.asset(
                        pose.asset,
                        width: _size,
                        height: _size,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
