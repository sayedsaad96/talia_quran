import 'package:flutter/material.dart';

/// Pinch-zoom and double-tap zoom for a mushaf page.
///
/// Pan stays disabled at rest so single-finger swipes keep turning pages;
/// it is only enabled while zoomed, when the drag belongs to the content.
/// Double-tap toggles between 1x and a reading-friendly 2.25x centered on
/// the tapped point.
class MushafZoomablePage extends StatefulWidget {
  const MushafZoomablePage({
    super.key,
    required this.child,
    this.onZoomChanged,
  });

  final Widget child;
  final ValueChanged<bool>? onZoomChanged;

  @override
  State<MushafZoomablePage> createState() => _MushafZoomablePageState();
}

class _MushafZoomablePageState extends State<MushafZoomablePage> {
  static const _maxScale = 3.0;
  static const _doubleTapScale = 2.25;

  final TransformationController _controller = TransformationController();
  Offset? _doubleTapPosition;
  bool _lastZoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_reportZoomChange);
  }

  void _reportZoomChange() {
    final zoomed = _isZoomed(_controller.value);
    if (zoomed == _lastZoomed) return;
    _lastZoomed = zoomed;
    widget.onZoomChanged?.call(zoomed);
  }

  bool _isZoomed(Matrix4 matrix) => matrix.getMaxScaleOnAxis() > 1.01;

  void _handleDoubleTap() {
    final position = _doubleTapPosition;
    if (_isZoomed(_controller.value)) {
      _controller.value = Matrix4.identity();
      return;
    }
    if (position == null) {
      _controller.value = Matrix4.identity()
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
      return;
    }
    // Scale around the tapped point: T(p) · S(s) · T(-p).
    _controller.value = Matrix4.identity()
      ..translateByDouble(position.dx, position.dy, 0, 1)
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1)
      ..translateByDouble(-position.dx, -position.dy, 0, 1);
  }

  @override
  void dispose() {
    _controller.removeListener(_reportZoomChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Matrix4>(
      valueListenable: _controller,
      builder: (context, matrix, child) {
        return InteractiveViewer(
          transformationController: _controller,
          panEnabled: _isZoomed(matrix),
          scaleEnabled: true,
          minScale: 1.0,
          maxScale: _maxScale,
          child: GestureDetector(
            onDoubleTapDown: (details) =>
                _doubleTapPosition = details.localPosition,
            onDoubleTap: _handleDoubleTap,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
