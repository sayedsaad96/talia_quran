import 'package:flutter/material.dart';

/// Fixed palette for the splash scene. It renders before the theme and
/// locale load, always on the nocturnal ground, so it can't use theme
/// tokens. Exempt from the design-token guard via the `_palette.dart` suffix.
abstract final class SplashPalette {
  /// Matches the native launch background to avoid a bright flash.
  static const background = Color(0xFF030D09);
  static const primary = Color(0xFF5CD2A5);
  static const subText = Color(0xFFD4E0D9);
  static const tagline = Color(0xFFEAEAEA);
  static const errorSurface = Color(0xFF071B14);
}
