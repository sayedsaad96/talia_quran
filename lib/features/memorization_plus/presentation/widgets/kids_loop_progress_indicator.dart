import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';

/// Shows completed mandatory listens and gives the newest completion one
/// brief acknowledgement without replaying restored progress.
class KidsLoopProgressIndicator extends StatefulWidget {
  const KidsLoopProgressIndicator({
    super.key,
    required this.completedLoops,
    required this.maxLoops,
  });

  final int completedLoops;
  final int maxLoops;

  @override
  State<KidsLoopProgressIndicator> createState() =>
      _KidsLoopProgressIndicatorState();
}

class _KidsLoopProgressIndicatorState extends State<KidsLoopProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late int _lastCompletedLoop;
  int? _pulsingStarIndex;

  @override
  void initState() {
    super.initState();
    // Restored progress is never a new reward.
    _lastCompletedLoop = widget.completedLoops;
    _pulseController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 320),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _pulsingStarIndex = null);
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _stopPulse();
    }
  }

  @override
  void didUpdateWidget(covariant KidsLoopProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final completedLoops = widget.completedLoops;
    if (MediaQuery.disableAnimationsOf(context)) {
      _lastCompletedLoop = completedLoops;
      _stopPulse();
      return;
    }

    if (completedLoops > _lastCompletedLoop) {
      _pulsingStarIndex = completedLoops - 1;
      _pulseController.forward(from: 0);
    } else if (completedLoops < _lastCompletedLoop) {
      _stopPulse();
    }
    // State updates such as buffering can rebuild with the same completed
    // count; they must not interrupt the acknowledgement already in flight.
    _lastCompletedLoop = completedLoops;
  }

  void _stopPulse() {
    _pulseController.reset();
    _pulsingStarIndex = null;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isDone =
        widget.completedLoops >= widget.maxLoops && widget.maxLoops > 0;

    return AnimatedContainer(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _kidsSoftCardDecoration.copyWith(
        border: isDone
            ? Border.all(color: KidsTheme.forestGreen, width: 2)
            : null,
      ),
      child: Column(
        children: [
          Text(
            context.l10n.kidsGamifiedRepeatStep,
            style: AppTypography.titleMedium.copyWith(
              color: isDone ? KidsTheme.forestGreen : KidsTheme.inkOnParchment,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (var index = 0; index < widget.maxLoops; index++)
                _LoopProgressStar(
                  index: index,
                  isReached: index < widget.completedLoops,
                  pulse: !reduceMotion && _pulsingStarIndex == index
                      ? _pulseController
                      : null,
                ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
                child: Text(
                  '${context.numText(widget.completedLoops)}/${context.numText(widget.maxLoops)}',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDone
                        ? KidsTheme.forestGreen
                        : KidsTheme.buttonGoldBase,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _kidsSoftCardDecoration = BoxDecoration(
  color: KidsTheme.creamParchment,
  borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusXl)),
  border: Border.fromBorderSide(
    BorderSide(color: KidsTheme.parchmentEdge, width: 2),
  ),
  boxShadow: KidsTheme.card25DShadow,
);

class _LoopProgressStar extends StatelessWidget {
  const _LoopProgressStar({
    required this.index,
    required this.isReached,
    this.pulse,
  });

  final int index;
  final bool isReached;
  final Animation<double>? pulse;

  @override
  Widget build(BuildContext context) {
    final star = TaliaIcon(
      key: ValueKey('kids-loop-star-$index'),
      isReached ? TaliaKidsIcons.starFilled : TaliaKidsIcons.star,
      size: 38,
      color: isReached
          ? KidsTheme.goldStar
          : KidsTheme.lockedGrey.withValues(alpha: 0.5),
    );
    if (pulse == null) return star;

    return AnimatedBuilder(
      animation: pulse!,
      child: star,
      builder: (_, child) => Transform.scale(
        key: ValueKey('kids-loop-star-pulse-$index'),
        scale: TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
        ]).evaluate(pulse!),
        child: child,
      ),
    );
  }
}
