import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';

/// Fixed palette for the onboarding night scene.
///
/// Onboarding always renders on the dark night ground regardless of the
/// user's theme, so these colors are intentionally not theme tokens. They
/// live here (exempt from the design-token guard via the `_palette.dart`
/// suffix) instead of as literals scattered across the slides.
abstract final class OnboardingPalette {
  /// #148275 teal and #C0392B error lack 4.5:1 headroom as small-text
  /// colors on #021210, so labels lift to these lighter siblings while
  /// borders and tints stay on-token.
  static const nightTealText = Color(0xFF3BD6BC);
  static const nightErrorText = Color(0xFFE57368);

  /// "Mastered / offline-safe" status accent in the feature previews.
  static const emerald = Color(0xFF10B981);
  static const emeraldText = Color(0xFF34D399);

  /// Inner surface of the preview mock cards.
  static const previewSurface = Color(0xFF0C2B27);

  /// Moon halo in the night sky.
  static const moonGlow = [Color(0x2EF59E0B), Color(0x00F59E0B)];
}

abstract final class OnboardingStyles {
  /// Slide headline: 24 in Arabic, 20 in English (Latin reads larger at the
  /// same size). Callers add the Amiri family, weight and color.
  static TextStyle titleBase(BuildContext context) => context.isArabic
      ? AppTypography.headlineLarge
      : AppTypography.headlineMedium;
}
