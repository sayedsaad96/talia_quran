import 'package:flutter/material.dart';

/// Medal colors for achievement badges, by rank.
///
/// Metal/gem colors carry meaning (bronze < silver < gold < diamond <
/// legendary) and must look the same in every theme, so they are a fixed
/// palette rather than theme tokens. Exempt from the design-token guard via
/// the `_palette.dart` suffix.
abstract final class AchievementTierPalette {
  static const lockedDark = [Color(0xFF303030), Color(0xFF1A1A1A)];
  static const lockedLight = [Color(0xFFE0E0E0), Color(0xFFBDBDBD)];

  /// Returns the badge gradient and glow for an unlocked [rank]
  /// (0 bronze, 1 silver, 2 gold, 3 diamond, 4 legendary).
  static ({List<Color> gradient, Color glow}) forRank(int rank) {
    return switch (rank) {
      4 => (
        gradient: const [Color(0xFFE5C158), Color(0xFF8A2BE2)],
        glow: const Color(0xFF8A2BE2),
      ),
      3 => (
        gradient: const [Color(0xFF00F2FE), Color(0xFF4FACFE)],
        glow: const Color(0xFF00F2FE),
      ),
      2 => (
        gradient: const [Color(0xFFFFD700), Color(0xFFFFA500)],
        glow: const Color(0xFFFFD700),
      ),
      1 => (
        gradient: const [Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
        glow: const Color(0xFF9E9E9E),
      ),
      _ => (
        gradient: const [Color(0xFFCD7F32), Color(0xFF8B4513)],
        glow: const Color(0xFFCD7F32),
      ),
    };
  }
}
