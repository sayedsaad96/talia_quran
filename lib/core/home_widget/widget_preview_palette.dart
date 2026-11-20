import 'package:material_ui/material_ui.dart';

/// Matches Android's widget_colors.xml; the preview depicts the launcher
/// widget, whose palette is independent of the in-app theme.
class HomeWidgetPreviewPalette {
  const HomeWidgetPreviewPalette(
    this.background,
    this.primary,
    this.secondary, {
    required this.progress,
    required this.progressTrack,
    required this.border,
  });

  final Color background;
  final Color primary;
  final Color secondary;
  final Color progress;
  final Color progressTrack;
  final Color border;

  static const radius = 20.0;
  static const light = HomeWidgetPreviewPalette(
    Color(0xFFFCF8F2),
    Color(0xFF173B32),
    Color(0xFF355C50),
    progress: Color(0xFF1F6B56),
    progressTrack: Color(0xFFE4EFEA),
    border: Color(0x26173B32),
  );
  static const dark = HomeWidgetPreviewPalette(
    Color(0xFF15211C),
    Color(0xFFE6F3ED),
    Color(0xFFB7D0C6),
    progress: Color(0xFF8FCBB4),
    progressTrack: Color(0xFF24332D),
    border: Color(0x2EE6F3ED),
  );

  static HomeWidgetPreviewPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
