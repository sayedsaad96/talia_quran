import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Rasterizes [widget] at the fixed logical [size] without creating a visible
/// overlay. The physical constraints are explicit because a detached
/// [RenderView] otherwise defaults its output surface to zero dimensions.
Future<Uint8List> rasterizeSocialShareCard(
  Widget widget, {
  required BuildContext context,
  required Size size,
}) async {
  const pixelRatio = 3.0;
  var needsRebuild = false;
  final boundary = RenderRepaintBoundary();
  final focusManager = FocusManager();
  final view =
      View.maybeOf(context) ??
      WidgetsBinding.instance.platformDispatcher.views.first;
  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(alignment: Alignment.center, child: boundary),
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(size),
      physicalConstraints: BoxConstraints.tight(size * pixelRatio),
      devicePixelRatio: pixelRatio,
    ),
  );
  final pipelineOwner = PipelineOwner();
  final buildOwner = BuildOwner(
    focusManager: focusManager,
    onBuildScheduled: () => needsRebuild = true,
  );
  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();
  final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: Directionality(textDirection: TextDirection.ltr, child: widget),
  ).attachToRenderTree(buildOwner);

  try {
    _flushRenderTree(buildOwner, pipelineOwner, rootElement);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (needsRebuild) {
      _flushRenderTree(buildOwner, pipelineOwner, rootElement);
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Unable to encode social card image.');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    rootElement.update(
      RenderObjectToWidgetAdapter<RenderBox>(container: boundary),
    );
    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    pipelineOwner.rootNode = null;
    renderView.dispose();
    pipelineOwner.dispose();
    focusManager.dispose();
  }
}

void _flushRenderTree(
  BuildOwner buildOwner,
  PipelineOwner pipelineOwner,
  RenderObjectToWidgetElement<RenderBox> rootElement,
) {
  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();
  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();
}
