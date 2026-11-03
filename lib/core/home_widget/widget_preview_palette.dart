import 'package:flutter/material.dart';

/// Matches Android's widget_colors.xml; the preview depicts the launcher
/// widget, whose palette is independent of the in-app theme.
class HomeWidgetPreviewPalette {
  const HomeWidgetPreviewPalette(this.background, this.primary, this.secondary);

  final Color background;
  final Color primary;
  final Color secondary;
  static const radius = 20.0;
  static const light = HomeWidgetPreviewPalette(
    Color(0xFFFCF8F2),
    Color(0xFF173B32),
    Color(0xFF355C50),
  );
  static const dark = HomeWidgetPreviewPalette(
    Color(0xFF15211C),
    Color(0xFFE6F3ED),
    Color(0xFFB7D0C6),
  );

  static HomeWidgetPreviewPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
