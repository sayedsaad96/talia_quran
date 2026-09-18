// lib/features/home/presentation/widgets/spring_tap.dart
import 'package:flutter/material.dart';

import '../theme/home_skin.dart';

/// Wraps [child] in a tactile spring-scale animation on press.
/// Scale drops to [pressedScale] on tap-down, returns on tap-up/cancel.
class SpringTap extends StatefulWidget {
  const SpringTap({
    super.key,
    required this.onTap,
    required this.child,
    this.pressedScale = 0.98,
  });

  final VoidCallback onTap;
  final Widget child;
  final double pressedScale;

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: HomeSkin.springDuration,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: HomeSkin.springCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return GestureDetector(onTap: widget.onTap, child: widget.child);
    }
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
