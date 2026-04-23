import 'package:flutter/material.dart';

/// Talia Design System — Color Tokens
/// Inspired by deep night sky, moonlight on parchment, and Quranic ink
abstract class AppColors {
  // ─── Brand Palette ───────────────────────────────────────────────────────────
  /// Deep indigo-teal — primary brand color
  static const Color primary = Color(0xFF1A6B5A);
  static const Color primaryLight = Color(0xFF2D8E76);
  static const Color primaryDark = Color(0xFF0F4A3E);

  /// Warm gold — accent for highlights and progress
  static const Color gold = Color(0xFFD4A843);
  static const Color goldLight = Color(0xFFE8C46A);
  static const Color goldDark = Color(0xFFAA8430);

  /// Warm amber — secondary accent
  static const Color amber = Color(0xFFF0A500);

  // ─── Light Theme ─────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF7F4EF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0EDE6);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE8E0D5);

  static const Color lightTextPrimary = Color(0xFF1A1209);
  static const Color lightTextSecondary = Color(0xFF6B5E4E);
  static const Color lightTextHint = Color(0xFFAA9E92);

  // ─── Dark Theme ──────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceVariant = Color(0xFF1C2330);
  static const Color darkCard = Color(0xFF1C2330);
  static const Color darkDivider = Color(0xFF2A3140);

  static const Color darkTextPrimary = Color(0xFFF0EDE6);
  static const Color darkTextSecondary = Color(0xFFA8B0BC);
  static const Color darkTextHint = Color(0xFF5A6370);

  // ─── Semantic Colors ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D5E);
  static const Color warning = Color(0xFFD4821A);
  static const Color error = Color(0xFFC0392B);
  static const Color info = Color(0xFF2980B9);

  // ─── Quran Reading Colors ────────────────────────────────────────────────────
  /// Warm parchment for reading surface (light)
  static const Color parchmentLight = Color(0xFFFAF6EE);
  /// Soft dark for reading surface (dark)
  static const Color parchmentDark = Color(0xFF141A20);

  // ─── Gradient Definitions ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A6B5A), Color(0xFF0F4A3E)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8C46A), Color(0xFFAA8430)],
  );

  static const LinearGradient heroGradientLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A6B5A), Color(0xFF0D3D32)],
  );

  static const LinearGradient heroGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F2D26), Color(0xFF0A1F1B)],
  );

  static const LinearGradient skyGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A6B5A), Color(0xFF2D5A8E)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient surfaceGlassLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xCCFFFFFF),
      Color(0x99FFFFFF),
    ],
  );

  static const LinearGradient surfaceGlassDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x331C2330),
      Color(0x1A1C2330),
    ],
  );

  // ─── Overlay Colors ──────────────────────────────────────────────────────────
  static const Color overlayLight = Color(0x0A000000);
  static const Color overlayMedium = Color(0x1A000000);
  static const Color overlayDark = Color(0x33000000);

  // ─── Shadow Colors ───────────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0A1A6B5A);
  static const Color shadowMedium = Color(0x1A1A6B5A);
  static const Color shadowDark = Color(0xFF000000);

  // Prevent instantiation
  const AppColors._();
}
